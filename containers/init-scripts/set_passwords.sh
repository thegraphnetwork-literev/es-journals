#!/bin/bash

set -e


es_password=$ES_PASSWORD

output_full=$(/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b)

curr_password=$(echo "$output_full" | grep "New value" | awk '{print $3}')

curl -s -k -X POST "https://localhost:9200/_security/user/elastic/_password" \
     -H "Content-Type: application/json" \
     -d "{\"password\":\"$es_password\"}" \
     --cacert /usr/share/elasticsearch/config/certs/chain.pem \
     -u "elastic:$curr_password"
