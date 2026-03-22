import os
import subprocess
from jinja2 import Environment, FileSystemLoader


# --------------------------------------------------
# Render wildcard OpenSSL config
# --------------------------------------------------

def render_wildcard_cert_config(context: dict, output_path: str):
    env = Environment(
        loader=FileSystemLoader("templates"),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    template = env.get_template("wildcard.cnf.j2")

    rendered = template.render(domain=context["domain"])

    with open(output_path, "w") as f:
        f.write(rendered)

    print(f"[OK] Wildcard cert config written to {output_path}")


# --------------------------------------------------
# Generate self-signed certificate
# --------------------------------------------------

def generate_selfsigned_cert(context: dict, cert_dir: str):
    cert_name = context["certificate"]["name"]

    crt_file = os.path.join(cert_dir, f"{cert_name}.crt")
    key_file = os.path.join(cert_dir, f"{cert_name}.key")
    conf_file = os.path.join(cert_dir, "wildcard.cnf")

    # --------------------------------------------------
    # Check if certificate already exists
    # --------------------------------------------------
    if os.path.exists(crt_file) and os.path.exists(key_file):
        print("[SKIP] Certificate already exists")
        return

    print("[STEP] Generating self-signed certificate...")

    # --------------------------------------------------
    # Ensure config exists
    # --------------------------------------------------
    if not os.path.exists(conf_file):
        raise RuntimeError(
            "Wildcard config not found. Did you run render_wildcard_cert_config()?"
        )

    # --------------------------------------------------
    # Run openssl
    # --------------------------------------------------
    subprocess.run(
        [
            "openssl",
            "req",
            "-x509",
            "-nodes",
            "-days", "3650",
            "-newkey", "rsa:2048",
            "-keyout", key_file,
            "-out", crt_file,
            "-config", conf_file,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True
    )

    print(f"[OK] Certificate generated: {crt_file}")
    print(f"[OK] Key generated: {key_file}")