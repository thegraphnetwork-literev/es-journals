#!/usr/bin/env bash

CERT_PATH=/etc/letsencrypt/archive/${CERTBOT_DOMAIN}

sugar exec --service nginx --cmd ls -1 ${CERT_PATH} | grep 'privkey' | sort -V | tail -n 1
sugar exec --service nginx --cmd ls -1 ${CERT_PATH} | grep 'cert' | sort -V | tail -n 1
