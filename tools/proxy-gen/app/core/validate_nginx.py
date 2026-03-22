import os
import subprocess

def validate_nginx_config(context: dict, nginx_conf_container_path: str, certs_host_dir: str, nginx_conf_host_path: str):
    print("[STEP] Validating nginx configuration...")

    # --- read original config (container path) ---
    with open(nginx_conf_container_path, "r") as f:
        content = f.read()

    # --- rewrite upstreams to localhost ---
    for svc in context["services"]:
        container = svc["container"]
        port = svc["port"]
        content = content.replace(f"{container}:{port}", f"127.0.0.1:{port}")

    content = content.replace("authelia:9091", "127.0.0.1:9091")

    # --- TEMP FILE (MUST be inside bind-mounted dir) ---
    tmp_container_path = "/app/nginx/conf.d/.tmp_nginx.conf"
    tmp_host_path = os.path.join(os.path.dirname(nginx_conf_host_path), ".tmp_nginx.conf")

    # write temp config
    with open(tmp_container_path, "w") as f:
        f.write(content)

    try:
        result = subprocess.run(
            [
                "docker", "run", "--rm",

                # mount temp config (REAL host file)
                "-v", f"{tmp_host_path}:/etc/nginx/conf.d/test.conf:ro",

                # mount certs
                "-v", f"{certs_host_dir}:/etc/nginx/certs:ro",

                # disable default config safely
                "-v", "/dev/null:/etc/nginx/conf.d/default.conf",

                "nginx:stable",
                "nginx", "-t"
            ],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print(" [OK] nginx configuration valid")
        else:
            print(" [ERROR] nginx configuration invalid\n")

            if result.stdout:
                print(" STDOUT:\n", result.stdout)

            if result.stderr:
                print(" STDERR:\n", result.stderr)

            raise RuntimeError("nginx config validation failed")

    finally:
        # cleanup temp file
        if os.path.exists(tmp_container_path):
            os.remove(tmp_container_path)