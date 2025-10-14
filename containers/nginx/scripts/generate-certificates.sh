#!/bin/bash

set -ex

# Check if sugar is avaiable
if ! [ -x "$(command -v sugar)" ]; then
    echo "Error: sugar is not installed." >&2
    exit 1
fi

# Paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
project_dir="$script_dir/"

# Check .env exists for environment variabes
if [[ -f "$project_dir/.env" ]]; then
  echo "Loading .env file..."
  source "$project_dir/.env"
else
  echo 'Error: .env file not found.' >&2
  exit 1
fi

## Check if ENV is set to prod or staging
if [[ "${ENV:-}" != "prod" && "${ENV:-}" != "staging" ]]; then
  echo 'Error: ENV should be set to prod or staging.' >&2
  exit 1
fi

# Check if CERTBOT_DOMAIN is set and not empty
if [[ -z "${CERTBOT_DOMAIN:-}" ]]; then
  echo 'Error: CERTBOT_DOMAIN is not set or empty.' >&2
  exit 1
fi

# Check if CERTBOT_EMAIL is set and not empty
if [[ -z "${CERTBOT_EMAIL:-}" ]]; then
  echo 'Error: CERTBOT_EMAIL is not set or empty.' >&2
  exit 1
fi

DOMAINS=("$CERTBOT_DOMAIN")
RSA_KEY_SIZE=4096
EMAIL="$CERTBOT_EMAIL"
STAGING="${STAGING:-0}"  # use STAGING=1 in env to hit Let's Encrypt staging

echo "----> Creating dummy certificate for ${DOMAINS[*]} ..."
path="/etc/letsencrypt/live/$CERTBOT_DOMAIN"

# mkdir -p target path inside certbot container
sugar compose run --service certbot --cmd "/bin/sh -lc 'mkdir -p \"$path\"'" -- --rm

# Create a 1-day dummy cert so nginx can boot with TLS paths present
sugar compose run --service certbot --cmd "/bin/sh -lc '\
  openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1 \
    -keyout \"$path/privkey.pem\" \
    -out \"$path/fullchain.pem\" \
    -subj \"/CN=localhost\"'" -- --rm

echo "----> Starting nginx ..."
sugar compose up --services literev-nginx -- --force-recreate -d

echo "----> Deleting dummy certificate for ${DOMAINS[*]} ..."
sugar compose run --service certbot --entrypoint "\
  rm -rf /etc/letsencrypt/live/$CERTBOT_DOMAIN \
         /etc/letsencrypt/archive/$CERTBOT_DOMAIN \
         /etc/letsencrypt/renewal/$CERTBOT_DOMAIN.conf" -- --rm

echo "----> Requesting Let's Encrypt certificate for $DOMAINS ..."
domain_args=""
for domain in "${DOMAINS[@]}"; do
    domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$EMAIL" in
    "") email_arg="--register-unsafely-without-email" ;;
    *) email_arg="--email $EMAIL" ;;
esac

# Enable staging mode if needed
staging_arg=""
if [ "${STAGING:-0}" != "0" ]; then
    staging_arg="--dry-run"
fi

echo "----> certbot certonly..."
# Run certbot to get real certificates
sugar compose run --service certbot --cmd "/bin/sh -lc '\
  certbot certonly --webroot -w /var/www/certbot \
    ${staging_arg:-} \
    ${email_arg:-} \
    ${domain_args} \
    --rsa-key-size $RSA_KEY_SIZE \
    --agree-tos \
    --no-eff-email \
    --force-renewal'" -- --rm

echo "----> Reloading nginx ..."
sugar compose exec --service literev-nginx --cmd "nginx -s reload"
