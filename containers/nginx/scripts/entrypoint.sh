#!/bin/bash

certbot certonly --nginx -n --agree-tos -d ${CERTBOT_DOMAIN} -d www.${CERTBOT_DOMAIN} -m ${CERTBOT_EMAIL}

# Update the Nginx configuration to use the newly generated SSL certificates
sed -i "s/\/tmp\/nginx-selfsigned.crt/\/etc\/letsencrypt\/live\/${CERTBOT_DOMAIN}\/fullchain.pem/" /etc/nginx/sites-available/*
sed -i "s/\/tmp\/nginx-selfsigned.key/\/etc\/letsencrypt\/live\/${CERTBOT_DOMAIN}\/privkey.pem/" /etc/nginx/sites-available/*
