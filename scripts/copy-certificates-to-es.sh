#!/usr/bin/env bash

CERT_PATH=/etc/letsencrypt/archives/${CERTBOT_DOMAIN}

sugar exec nginx ls -1 ${CERT_PATH} | grep 'privkey' | sort -V | tail -n 1
sugar exec nginx ls -1 ${CERT_PATH} | grep 'cert' | sort -V | tail -n 1
