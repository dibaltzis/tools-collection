import subprocess

def validate_authelia_config(host_config_dir: str):
    print("[STEP] Validating Authelia configuration...")

    result = subprocess.run(
        [
            "docker", "run", "--rm",
            "-v", f"{host_config_dir}:/config",
            "authelia/authelia:latest",
            "authelia", "config", "validate",
            "--config", "/config/configuration.yml"
        ],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        print(" [OK] Authelia configuration valid")
    else:
        print(" [ERROR] Authelia configuration invalid\n")

        if result.stdout:
            print(" STDOUT:\n", result.stdout)

        if result.stderr:
            print(" STDERR:\n", result.stderr)

        raise RuntimeError("Authelia config validation failed")