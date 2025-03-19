#!/bin/sh

# Check if the CREDS environment variable is set
if [ -z "$CREDS" ]; then
  echo "Error: CREDS environment variable must be set." >&2
  echo "Please set the CREDS environment variable with your base64 encoded credentials." >&2
  exit 1
fi

EXPORT_FILE="export.csv" # The filename given in the export URL
DOWNLOAD_FILE="sms-history-download.csv" # The filename to save

# curl command to get json
CURL_COMMAND="curl -s --header \"Authorization: Basic ${CREDS}\" https://rest.clicksend.com/v3/sms/history/export?filename=${EXPORT_FILE}"

# Set the json from the following curl script above
echo "Executing curl command: $CURL_COMMAND"
JSON_STRING=$($CURL_COMMAND)
echo "JSON_STRING:"
echo $JSON_STRING

if command -v jq >/dev/null 2>&1; then
  URL=$(echo "$JSON_STRING" | jq -r '.data.url')
  echo "URL (using jq): $URL"
else
  #If jq is not installed then fall back to sed, which is less reliable.
  URL=$(echo "$JSON_STRING" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
  echo "URL (using sed): $URL"
fi

if [ -z "$URL" ]; then
    echo "Error: Unable to extract URL from JSON string." >&2
    exit 1
fi

# Download the file using curl
echo "Downloading file to: $DOWNLOAD_FILE"
if curl -s -o "$DOWNLOAD_FILE" "$URL"; then
  echo "File downloaded successfully."
else
  echo "Error: Failed to download file." >&2
  exit 1
fi

exit 0
