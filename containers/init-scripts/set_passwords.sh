#!/bin/bash

set -eo pipefail

# Validate ES_PASSWORD environment variable
if [ -z "$ES_PASSWORD" ]; then
  echo "Error: ES_PASSWORD environment variable is not set."
  exit 1
fi

# Elasticsearch reset password command path
RESET_PASSWORD_CMD="/usr/share/elasticsearch/bin/elasticsearch-reset-password"

# Validate that the Elasticsearch reset password command exists
if [ ! -f "$RESET_PASSWORD_CMD" ]; then
  echo "Error: Elasticsearch reset password command not found at $RESET_PASSWORD_CMD."
  exit 1
fi

# Resetting the 'elastic' user password and capturing the new password
echo "Resetting the 'elastic' user password..."
output_full=$("$RESET_PASSWORD_CMD" -u elastic -b 2>&1)

# Extracting the new password from the command output
curr_password=$(echo "$output_full" | grep -oP '(?<=New value: )\S+')

# Validate that we have captured the current password
if [ -z "$curr_password" ]; then
  echo "Error: Failed to reset the 'elastic' user password."
  echo "Command output: $output_full"
  exit 1
fi

echo "Successfully reset the 'elastic' user password."

# Updating the 'elastic' user password to the predefined value
echo "Updating the 'elastic' user password to the predefined value..."

curl_response=$(curl -s -k -X POST "https://localhost:9200/_security/user/elastic/_password" \
     -H "Content-Type: application/json" \
     -d "{\"password\":\"$ES_PASSWORD\"}" \
     --cacert /usr/share/elasticsearch/config/certs/chain.pem \
     -u "elastic:$curr_password")

# Check for errors in curl response
if echo "$curl_response" | grep -q "error"; then
  echo "Error: Failed to update the 'elastic' user password."
  echo "Curl response: $curl_response"
  exit 1
fi

echo "Successfully updated the 'elastic' user password."
