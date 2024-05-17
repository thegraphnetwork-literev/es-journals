#!/usr/bin/env bash

ES_CERT_PATH=/usr/share/elasticsearch/config/certs

set -ex

mkdir -p "${HOST_ELASTIC_CERTS}"

# sugar ext stop --all
# sugar ext start --services es01-fake --options -d
# sleep 1
# sugar ext start --services nginx --options -d
# sleep 5

# note: not sure if this method would be robust for numbers more than 9
# note: using sugar, not necessary when the docker volume points to a specific path
# ORIGINAL_PRIVKEY_FILENAME=$(sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep 'privkey' | sort -V | tail -n 1)
# ORIGINAL_CERT_FILENAME=$(sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep 'cert' | sort -V | tail -n 1)
# ORIGINAL_CHAIN_FILENAME=$(sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep '^chain' | sort -V | tail -n 1)
# ORIGINAL_FULLCHAIN_FILENAME=$(sugar exec --service nginx --cmd ls -1 ${NGINX_CERT_PATH} | grep 'fullchain' | sort -V | tail -n 1)

# Determine the latest version of the folder
NGINX_CERT_PATH=${HOST_CERTBOT_PATH_CONF}/archive/${CERTBOT_DOMAIN}

ORIGINAL_PRIVKEY_FILENAME=$(ls -1 ${NGINX_CERT_PATH} | grep 'privkey' | sort -V | tail -n 1)
ORIGINAL_CERT_FILENAME=$(ls -1 ${NGINX_CERT_PATH} | grep 'cert' | sort -V | tail -n 1)
ORIGINAL_CHAIN_FILENAME=$(ls -1 ${NGINX_CERT_PATH} | grep '^chain' | sort -V | tail -n 1)
ORIGINAL_FULLCHAIN_FILENAME=$(ls -1 ${NGINX_CERT_PATH} | grep 'fullchain' | sort -V | tail -n 1)

# Check if all variables are not empty
if [[ -n "$ORIGINAL_PRIVKEY_FILENAME" && -n "$ORIGINAL_CERT_FILENAME" && -n "$ORIGINAL_CHAIN_FILENAME" && -n "$ORIGINAL_FULLCHAIN_FILENAME" ]]; then
  echo "All variables are not empty."
else
  echo "One or more variables are empty."
fi

# note: using sugar, not necessary when the docker volume points to a specific path
# sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_PRIVKEY_FILENAME} "${HOST_ELASTIC_CERTS}/"
# sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_CERT_FILENAME} "${HOST_ELASTIC_CERTS}/"
# sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_CHAIN_FILENAME} "${HOST_ELASTIC_CERTS}/"
# sugar cp --options nginx:${NGINX_CERT_PATH}/${ORIGINAL_FULLCHAIN_FILENAME} "${HOST_ELASTIC_CERTS}/"

sudo cp ${NGINX_CERT_PATH}/${ORIGINAL_PRIVKEY_FILENAME} "${HOST_ELASTIC_CERTS}/"
sudo cp ${NGINX_CERT_PATH}/${ORIGINAL_CERT_FILENAME} "${HOST_ELASTIC_CERTS}/"
sudo cp ${NGINX_CERT_PATH}/${ORIGINAL_CHAIN_FILENAME} "${HOST_ELASTIC_CERTS}/"
sudo cp ${NGINX_CERT_PATH}/${ORIGINAL_FULLCHAIN_FILENAME} "${HOST_ELASTIC_CERTS}/"

pushd "$HOST_ELASTIC_CERTS"
sudo mv ${ORIGINAL_PRIVKEY_FILENAME} privkey.pem
sudo mv ${ORIGINAL_CERT_FILENAME} cert.pem
sudo mv ${ORIGINAL_CHAIN_FILENAME} chain.pem
sudo mv ${ORIGINAL_FULLCHAIN_FILENAME} fullchain.pem
sudo chown ${ELASTICSEARCH_UID}:${ELASTICSEARCH_GID} privkey.pem cert.pem chain.pem fullchain.pem
sudo chmod 644 privkey.pem cert.pem chain.pem fullchain.pem
popd

# sugar ext stop --all

set +ex

echo "Files copied and permissions set successfully."
