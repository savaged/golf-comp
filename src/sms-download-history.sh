#!/bin/sh

CREDS=$(cat .creds)
if [ -z "$CREDS" ]; then
  echo "Error: CREDS file not found or empty." >&2
  echo "Please set the CREDS file with your base64 encoded credentials by running the script generate-credentials-file.sh." >&2
  exit 1
fi

EXPORT_FILE="export.csv"
DOWNLOAD_FILE="smshistory.csv"
TEMP_JSON_FILE="output.txt"

curl -s --header "Authorization: Basic ${CREDS}" "https://rest.clicksend.com/v3/sms/history/export?filename=${EXPORT_FILE}" > "$TEMP_JSON_FILE"

if [ $? -ne 0 ]; then
  echo "Error: curl command failed. Check the output or the server." >&2
  rm -f "$TEMP_JSON_FILE"
  exit 1
fi

JSON_STRING=$(cat "$TEMP_JSON_FILE")

rm -f "$TEMP_JSON_FILE"

if [ -z "$JSON_STRING" ]; then
    echo "Error: Unable to set JSON_STRING (file was empty)." >&2
    exit 1
fi

if command -v jq >/dev/null 2>&1; then
  URL=$(echo "$JSON_STRING" | jq -r '.data.url')
else
  #If jq is not installed then fall back to sed, which is less reliable.
  URL=$(echo "$JSON_STRING" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
fi

if [ -z "$URL" ]; then
    echo "Error: Unable to extract URL from JSON string." >&2
    exit 1
fi

if curl -s -o "$DOWNLOAD_FILE" "$URL"; then
  echo "File downloaded to $DOWNLOAD_FILE."
else
  echo "Error: Failed to download file." >&2
  exit 1
fi

exit 0
