from jinja2 import Environment, FileSystemLoader
import os

TEMPLATE_DIR = "/app/templates/dashboard"

env = Environment(
    loader=FileSystemLoader(TEMPLATE_DIR),
    autoescape=False,
)


def render_dashboard(context: dict, output_dir: str) -> None:
    os.makedirs(output_dir, exist_ok=True)

    files = [
        ("index.html.j2", "index.html"),
        ("dashboard.css.j2", "dashboard.css"),
        ("dashboard.js.j2", "dashboard.js"),
    ]

    for template_name, output_name in files:
        template = env.get_template(template_name)

        with open(
            os.path.join(output_dir, output_name),
            "w",
            encoding="utf-8",
        ) as f:
            f.write(template.render(**context))
    
    print(f"[OK] Dashboard files written to {output_dir}")
