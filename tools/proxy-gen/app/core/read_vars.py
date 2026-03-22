import yaml
import subprocess
import secrets
import os


# --------------------------------------------------
# YAML loader
# --------------------------------------------------

def load_yaml(path: str) -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f)


# --------------------------------------------------
# Helpers
# --------------------------------------------------

def generate_secret() -> str:
    return secrets.token_hex(64)


def get_bool(svc: dict, key: str) -> bool:
    value = svc.get(key, False)

    if isinstance(value, bool):
        return value

    if isinstance(value, str):
        return value.lower() in ("true", "yes", "1")

    return bool(value)


def hash_password(password: str) -> str:
    result = subprocess.run(
        [
            "docker", "run", "--rm",
            "authelia/authelia",
            "authelia", "crypto", "hash", "generate", "argon2",
            "--password", password,
            "--no-confirm"
        ],
        capture_output=True,
        text=True,
        check=True
    )

    for line in result.stdout.splitlines():
        if "Digest:" in line:
            return line.split()[-1]

    raise RuntimeError("Failed to generate password hash")

def find_auth_service(services_cfg: dict) -> dict:
    matches = []

    for name, svc in services_cfg.items():
        if name == "auth" or get_bool(svc, "is_auth"):
            matches.append((name, svc))

    if not matches:
        raise ValueError("No auth service found")

    if len(matches) > 1:
        names = [name for name, _ in matches]
        raise ValueError(f"Multiple auth services found: {names}")

    return matches[0][1]

def load_existing_secrets(path: str) -> dict:
    if not os.path.exists(path):
        return {}

    try:
        with open(path, "r") as f:
            data = yaml.safe_load(f) or {}
    except Exception:
        return {}

    secrets = {}

    # session secret
    secrets["session_secret"] = (
        data.get("session", {}).get("secret")
    )

    # jwt secret
    secrets["jwt_secret"] = (
        data.get("identity_validation", {})
        .get("reset_password", {})
        .get("jwt_secret")
    )

    # storage encryption key
    secrets["storage_key"] = (
        data.get("storage", {}).get("encryption_key")
    )

    return secrets

# --------------------------------------------------
# Main builder
# --------------------------------------------------

def build_context(config: dict) -> dict:
    # -------------------------
    # Domain logic
    # -------------------------
    domain_cfg = config.get("domain", {})
    mode = domain_cfg.get("mode")

    if mode == "nip":
        ip = domain_cfg.get("ip")
        suffix = domain_cfg.get("suffix", "nip.io")

        if not ip:
            raise ValueError("domain.ip is required for nip mode")

        domain = f"{ip}.{suffix}"

    elif mode == "static":
        domain = domain_cfg.get("name")
        if not domain:
            raise ValueError("domain.name is required for static mode")

    else:
        raise ValueError("Invalid domain.mode (use 'nip' or 'static')")

    auth_service = find_auth_service(config.get("services", {}))
    auth_prefix = auth_service.get("host_prefix")
    if not auth_prefix:
        raise ValueError("Auth service must define host_prefix")

    auth_domain = f"{auth_prefix}.{domain}"

    # -------------------------
    # Certificate logic
    # -------------------------
    cert_cfg = config.get("certificate", {})
    cert_mode = cert_cfg.get("mode")

    if cert_mode == "selfsigned":
        cert = {
            "mode": "selfsigned",
            "name": cert_cfg.get("name"),
        }

    elif cert_mode == "provided":
        cert_file = cert_cfg.get("cert_file")
        key_file = cert_cfg.get("key_file")

        if not cert_file or not key_file:
            raise ValueError("cert_file and key_file required for provided mode")

        cert = {
            "mode": "provided",
            "cert_file": cert_file,
            "key_file": key_file,
        }

    else:
        raise ValueError("Invalid certificate.mode")

    # -------------------------
    # Secrets
    # -------------------------
    config_path = "/app/nginx/authelia/configuration.yml"

    if os.path.exists(config_path):
        existing = load_existing_secrets(config_path)

        session_secret = existing.get("session_secret") or generate_secret()
        jwt_secret = existing.get("jwt_secret") or generate_secret()
        storage_key = existing.get("storage_key") or generate_secret()

        print("[SECRETS] Existing config found → reusing where possible")

    else:
        session_secret = generate_secret()
        jwt_secret = generate_secret()
        storage_key = generate_secret()

        print("[SECRETS] First run → generating new secrets")

    # -------------------------
    # Services
    # -------------------------
    services = []

    auth_container = None
    auth_port = None

    for name, svc in config.get("services", {}).items():
        host_prefix = svc["host_prefix"]

        service_entry = {
            "name": name,
            "container": svc["container_name"],
            "host_prefix": host_prefix,
            "host": f"{host_prefix}.{domain}",
            "port": svc["port"],
            "requires_auth": get_bool(svc,"requires_auth"),

            "websocket": get_bool(svc, "websocket"),
            "nolog": get_bool(svc,"nolog"),
            "upload": get_bool(svc,"upload"),

            "allowed_groups": svc.get("allowed_groups", ["admins"]),
        }

        services.append(service_entry)
        if name == "auth" or get_bool(svc, "is_auth"):
            auth_container = svc["container_name"]
            auth_port = svc["port"]

    # -------------------------
    # Users
    # -------------------------
    users = []

    for _, user in config.get("auth_users", {}).items():
        password_hash = hash_password(user["password"])

        users.append({
            "username": user["username"],
            "email": user["email"],
            "password_hash": password_hash,
            "groups": user.get("groups", []),
        })

    # -------------------------
    # Final context
    # -------------------------
    context = {
        "domain": domain,
        "auth_domain": auth_domain,
        "certificate": cert,

        "session_secret": session_secret,
        "jwt_secret": jwt_secret,
        "storage_key": storage_key,

        "services": services,
        "users": users,
        
        "auth_service": {
        "container": auth_container,
        "port": auth_port,
        }
    }

    return context