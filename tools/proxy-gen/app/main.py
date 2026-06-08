import os
from pprint import pprint
from core.read_vars import load_yaml, build_context
from core.render_authelia import render_authelia_users, render_authelia_config
from core.validate_authelia import validate_authelia_config
from core.render_cert import render_wildcard_cert_config, generate_selfsigned_cert
from core.render_nginx import render_nginx_config
from core.validate_nginx import validate_nginx_config
from core.copy_static_files import copy_static_files

def main():
    host_base = os.environ.get("HOST_NGINX_PATH")
    if not host_base:
        raise RuntimeError("HOST_NGINX_PATH is not set")

    config = load_yaml("config.yml")
    context = build_context(config)

    #print("=== GENERATED CONTEXT ===")
    #pprint(context)

    BASE_DIR = "/app/nginx"
    # ensure base mount exists
    os.makedirs(BASE_DIR, exist_ok=True)

    AUTHELIA_DIR = os.path.join(BASE_DIR, "authelia")
    CERTS_DIR = os.path.join(BASE_DIR, "certs")
    CONF_DIR = os.path.join(BASE_DIR, "conf.d")

    # --- ensure directories exist (container side, bind-mounted to host) ---
    os.makedirs(AUTHELIA_DIR, exist_ok=True)
    os.makedirs(os.path.join(AUTHELIA_DIR, "db"), exist_ok=True)

    # --- render authelia ---
    render_authelia_users(context, os.path.join(AUTHELIA_DIR, "users.yml"))
    render_authelia_config(context, os.path.join(AUTHELIA_DIR, "configuration.yml"))

    # --- resolve host path + validate authelia ---
    authelia_host_dir = os.path.join(host_base, "authelia")
    validate_authelia_config(authelia_host_dir)

    # --- certs ---
    os.makedirs(CERTS_DIR, exist_ok=True)

    certificate = context["certificate"]
    # render wildcard if the certificate mode = selfsigned
    if certificate["mode"] == "selfsigned":
        conf_path = os.path.join(CERTS_DIR, "wildcard.cnf")

        # 1. Render config
        render_wildcard_cert_config(context, conf_path)

        # 2. Generate cert
        generate_selfsigned_cert(context, CERTS_DIR)
    elif certificate["mode"] == "provided":
        cert_path = os.path.join(CERTS_DIR, certificate["cert_file"])
        key_path = os.path.join(CERTS_DIR, certificate["key_file"])
        if not os.path.exists(cert_path):
            raise RuntimeError(f"Certificate not found: {cert_path}")
        if not os.path.exists(key_path):
            raise RuntimeError(f"Key not found: {key_path}")
        

    # --- nginx ---
    os.makedirs(CONF_DIR, exist_ok=True)
    nginx_conf_path = os.path.join(CONF_DIR, "default.conf")

    # --- copy static files ---
    copy_static_files(src_dir="/app/files/nginx", dst_dir="/app/nginx/static")

    render_nginx_config(context, nginx_conf_path)

    # --- resolve host paths + validate nginx ---
    nginx_host_conf = os.path.join(host_base, "conf.d", "default.conf")
    certs_host_dir = os.path.join(host_base, "certs")

    validate_nginx_config(
        context,
        nginx_conf_path,      # container path (/nginx/...)
        certs_host_dir,       # host path
        nginx_host_conf       # host path
    )

if __name__ == "__main__":
    main()