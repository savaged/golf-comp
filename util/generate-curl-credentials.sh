#!/bin/sh

# Usage: $ util/generate-curl-credentials.sh username api-key | clip && CREDS=<C-v>

if [ $# -ne 2 ]; then
  echo "Usage: $0 <username> <api_key>"
  exit 1
fi

username=$1
api_key=$2

combined_string="${username}:${api_key}"

encoded_string=$(echo -n "$combined_string" | base64)

newline_stripped_string="${encoded_string%$'\n'}"

space_stripped_string=$(echo "$newline_stripped_string" | tr -d '[:space:]')

#export CREDS=$space_stripped_string

echo $space_stripped_string

