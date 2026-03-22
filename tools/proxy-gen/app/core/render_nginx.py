from jinja2 import Environment, FileSystemLoader


def render_nginx_config(context: dict, output_path: str):
    env = Environment(
        loader=FileSystemLoader("templates"),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    template = env.get_template("nginx.conf.j2")

    rendered = template.render(**context)

    with open(output_path, "w") as f:
        f.write(rendered)

    print(f"[OK] nginx.conf written to {output_path}")