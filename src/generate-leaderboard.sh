#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status

# Define variables
CREDS_FILE=".creds"
PLAYERS_CSV="data/players.csv"
DOWNLOAD_FILE="data/smshistory.csv"
TEMP_JSON_FILE="data/output.txt"
FILTERED_FILE="data/filtered.csv"
LEADERBOARD_FILE="data/leaderboard.csv"
EXPORT_FILE="export.csv"
FILTER_HISTORY_SQL="src/filterhistory.sql"
LEADERBOARD_SQL="src/leaderboard.sql"
HTML_OUTPUT_FILE="_site/index.html"

# Step 1: Verify CREDS and Download Export URL
echo "Step 1: Verifying credentials and retrieving export URL..."

CREDS=$(cat "$CREDS_FILE")
if [ -z "$CREDS" ]; then
  echo "Error: CREDS file not found or empty." >&2
  echo "Please set the CREDS file with your base64 encoded credentials by running the script generate-credentials-file.sh." >&2
  exit 1
fi

echo "Credentials file loaded successfully."

curl -s --header "Authorization: Basic ${CREDS}" "https://rest.clicksend.com/v3/sms/history/export?filename=${EXPORT_FILE}" > "$TEMP_JSON_FILE"
echo "Curl command executed."

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

echo "Extracted export URL successfully."

# Step 2: Download SMS History
echo "Step 2: Downloading SMS history..."

curl -s -o "$DOWNLOAD_FILE" "$URL"
echo "Successfully downloaded data to $DOWNLOAD_FILE"

# Step 3: Filter SMS History
echo "Step 3: Filtering SMS history..."

csvsql --query "$(cat "$FILTER_HISTORY_SQL")" "$DOWNLOAD_FILE" > "$FILTERED_FILE"
echo "Successfully filtered the SMS history"

# Step 4: Generate Leaderboard
echo "Step 4: Generating leaderboard..."

csvsql --query "$(cat "$LEADERBOARD_SQL")" "$FILTERED_FILE" "$PLAYERS_CSV" > "$LEADERBOARD_FILE"
echo "Generated the leaderboard"

# Step 5: Generate HTML
echo "Step 5: Generating HTML..."

cat <<EOF > "$HTML_OUTPUT_FILE"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leaderboard</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
<table>
EOF

# Read the header row
header=$(head -n 1 "$LEADERBOARD_FILE")
header=$(echo "$header" | sed 's/,/<\/th><th>/g')
echo "<tr><th>$header</th></tr>" >> "$HTML_OUTPUT_FILE"

# Process the data rows
tail -n +2 "$LEADERBOARD_FILE" | while IFS=, read -r player total; do
  echo "<tr><td>$player</td><td>$total</td></tr>" >> "$HTML_OUTPUT_FILE"
done

echo "</table></body></html>" >> "$HTML_OUTPUT_FILE"

echo "HTML file generated successfully."

echo "All steps completed successfully!"

exit 0

