#!/usr/bin/env bash

NGINX_CERT_PATH=/etc/letsencrypt/archive/${CERTBOT_DOMAIN}
ES_CERT_PATH=/usr/share/elasticsearch/config/certs

OWNER_UID=$(id -u)
OWNER_GID=$(id -g)

mkdir -p "${HOST_CERT_PATH}"

set -ex

sugar ext start --service nginx

sleep 5

# note: not sure if this method would be robust for numbers more than 9
ORIGINAL_PRIVKEY_FILENAME=sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep 'privkey' | sort -V | tail -n 1
ORIGINAL_CERT_FILENAME=sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep 'cert' | sort -V | tail -n 1
ORIGINAL_CHAIN_FILENAME=sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep 'chain' | sort -V | tail -n 1

sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_PRIVKEY_FILENAME} "${HOST_CERT_PATH}/privkey.pem"
sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_CERT_FILENAME} "${HOST_CERT_PATH}/cert.pem"
sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_CHAIN_FILENAME} "${HOST_CERT_PATH}/chain.pem"

pushd "$HOST_CERT_PATH"
chown ${OWNER_UID}:${OWNER_GID} privkey.pem cert.pem chain.pem
chmod 644 privkey.pem cert.pem chain.pem
popd

# sugar cp --options ${HOST_CERT_PATH}/privkey.pem es01:${ES_CERT_PATH}/privkey.pem
# sugar cp --options ${HOST_CERT_PATH}/cert.pem    es01:${ES_CERT_PATH}/cert.pem
# sugar cp --options ${HOST_CERT_PATH}/chain.pem   es01:${ES_CERT_PATH}/chain.pem

sugar ext stop --all

set +ex

echo "Files copied and permissions set successfully."
