#!/bin/bash

# Check if sugar is avaiable
if ! [ -x "$(command -v sugar)" ]; then
    echo 'Error: sugar is not installed.' >&2
    exit 1
fi

# get script directory
# Use the script_dir variable to construct paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# project directory (root of the literev project)
project_dir="$script_dir/.."

# Check .env exists for environment variabes
if [ -f "$project_dir/.env" ]; then
    # Load Environment Variables
    echo "Loading .env file..."
    source "$project_dir/.env"
else
    echo 'Error: .env file not found.' >&2
    exit 1
fi

## Check if ENV is set to prod or staging
if [[ "$ENV" != "prod" ]] && [[ "$ENV" != "staging" ]]; then
    echo 'Error: ENV should be set to prod or staging.' >&2
    echo 'This script should be run in a production or staging environment.' >&2
    exit 1
fi

# Check if CERTBOT_DOMAIN is set and not empty
if [ -z "$CERTBOT_DOMAIN" ]; then
    echo 'Error: CERTBOT_DOMAIN is not set or empty.' >&2
    exit 1
fi

# Check if CERTBOT_EMAIL is set and not empty
if [ -z "$CERTBOT_EMAIL" ]; then
    echo 'Error: CERTBOT_EMAIL is not set or empty.' >&2
    exit 1
fi

#
DOMAINS=($CERTBOT_DOMAIN)
RSA_KEY_SIZE=4096
EMAIL=${CERTBOT_EMAIL}

echo "----> Creating dummy certificate for $DOMAINS ..."
path="/etc/letsencrypt/live/$DOMAINS"

sugar run --service certbot --options --rm --entrypoint "mkdir -p $path"

sugar run --service certbot --options --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
-subj '/CN=localhost'"
echo

echo "----> Starting nginx ..."
    sugar up --services nginx --options --force-recreate -d
echo

echo "----> Deleting dummy certificate for $DOMAINS ..."
sugar run --service certbot --options --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$DOMAINS && \
    rm -Rf /etc/letsencrypt/archive/$DOMAINS && \
    rm -Rf /etc/letsencrypt/renewal/$DOMAINS.conf"
echo


echo "----> Requesting Let's Encrypt certificate for $DOMAINS ..."
#Join $DOMAINS to -d args (this is useful for cases where multiple DOMAINS certificates are necessary)
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
if [ $staging != "0" ]; then staging_arg="--staging"; fi

sugar run --service certbot --options --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $RSA_KEY_SIZE \
    --agree-tos \
    --no-eff-email \
    --force-renewal"
echo

echo "----> Reloading nginx ..."
sugar exec --service nginx --cmd nginx -s reload
