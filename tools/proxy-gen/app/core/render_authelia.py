from jinja2 import Environment, FileSystemLoader
import os


def render_authelia_users(context: dict, output_path: str):
    env = Environment(
        loader=FileSystemLoader("templates"),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    template = env.get_template("authelia_users.yml.j2")

    rendered = template.render(users=context["users"])

    with open(output_path, "w") as f:
        f.write(rendered)

    print(f"[OK] Authelia users written to {output_path}")

def render_authelia_config(context: dict, output_path: str):
    env = Environment(
        loader=FileSystemLoader("templates"),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    template = env.get_template("authelia_configuration.yml.j2")

    rendered = template.render(**context)

    with open(output_path, "w") as f:
        f.write(rendered)

    print(f"[OK] Authelia config written to {output_path}")