import os

from pathlib import Path

from jinja2 import Environment, FileSystemLoader

templates = Environment(
    loader=FileSystemLoader(Path(__file__).parent.parent / "templates"),
    autoescape=True,
)

nginx_template = templates.get_template("nginx.template.conf")

variables = {
    "upstream_name": "es",
    "upstream_service": "es01",
    "upstream_port": os.environ.get("ES_PORT"),
    "certbot_root": "/var/www/certbot",
    "letsencrypt_root": "/etc/letsencrypt",
    "domain": os.environ.get("CERTBOT_DOMAIN").split(",")[0],  # Prevents www.
}

output = nginx_template.render(variables)

nginx_dir = Path(__file__).parent.parent / "data"

file = nginx_dir / "config" / "prod" / "prod.nginx.conf"

file.touch()

with open(file, "w") as f:
    f.write(output)
