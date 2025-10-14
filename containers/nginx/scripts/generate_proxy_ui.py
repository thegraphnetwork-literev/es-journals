"""Generate proxy configuration."""

from __future__ import annotations

import os

from pathlib import Path

from jinja2 import Environment, FileSystemLoader

ENV = os.environ.get("ENV", "staging")
DOMAIN_ENV = os.environ.get("DOMAIN_ENV")

print(f"Generating nginx config for: {DOMAIN_ENV}...")

# Set up Jinja2 environment
templates = Environment(
    loader=FileSystemLoader(Path(__file__).parent.parent / "templates"),
    autoescape=True,
)

nginx_template = templates.get_template("nginx.template.conf")
domains = os.environ.get("CERTBOT_DOMAIN", "")

# Define variables for the template
variables = {
    "upstream_name": "webapp",
    "upstream_service": "literev",  # django container hostname
    "upstream_port": os.environ.get("FRONTEND_HOST_PORT", 8000),
    "certbot_root": "/var/www/certbot",
    "letsencrypt_root": "/etc/letsencrypt",
    "domain": domains.split(",")[0],  # Prevents www.
}

# Render the template with variables
output = nginx_template.render(variables)

nginx_dir = Path(__file__).parent.parent / "data" / "config" / f"{ENV}"

nginx_dir.mkdir(parents=True, exist_ok=True)

output_file = nginx_dir / f"{DOMAIN_ENV}.nginx.conf"

output_file.write_text(output)
