#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status

# Define variables
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)" # Where the script *is*
BASE_DIR="$(dirname "$SCRIPT_DIR")"  # The parent directory where the script should be run from
CREDS_FILE="$BASE_DIR/.creds"
PLAYERS_CSV="$BASE_DIR/data/players.csv"
DOWNLOAD_FILE="$BASE_DIR/data/smshistory.csv"
TEMP_JSON_FILE="$BASE_DIR/data/output.txt"
FILTERED_FILE="$BASE_DIR/data/filtered.csv"
LEADERBOARD_FILE="$BASE_DIR/data/leaderboard.csv"
EXPORT_FILE="export.csv"
FILTER_HISTORY_SQL="$BASE_DIR/src/filterhistory.sql"
LEADERBOARD_SQL="$BASE_DIR/src/leaderboard.sql"
HTML_OUTPUT_DIR="$BASE_DIR/_site"
HTML_OUTPUT_FILE="$HTML_OUTPUT_DIR/index.html"
STYLES_CSS="$HTML_OUTPUT_DIR/styles.css"

# Log file for debugging (in the parent dir)
LOG_FILE="$BASE_DIR/generate-leaderboard.log"

# A function to log and echo messages
log_and_echo() {
  echo "$@" | tee -a "$LOG_FILE"
}

log_and_echo "$(date) - Starting script..."

# Step 0: We're ASSUMING the script is run from the parent directory,
# so no need to change dir.
log_and_echo "$(date) - Assuming script is run from base directory: $(pwd)"

# DEBUG: Print the values of SCRIPT_DIR, BASE_DIR, and CREDS_FILE
log_and_echo "$(date) - DEBUG: SCRIPT_DIR = $SCRIPT_DIR"
log_and_echo "$(date) - DEBUG: BASE_DIR = $BASE_DIR"
log_and_echo "$(date) - DEBUG: CREDS_FILE = $CREDS_FILE"

# Check that .creds file exists
if [ ! -f "$CREDS_FILE" ]; then
   log_and_echo "$(date) - ERROR: .creds file NOT FOUND at $CREDS_FILE" >&2
   exit 1
fi


log_and_echo "$(date) - Step 1: Verifying credentials and retrieving export URL..."

CREDS=$(cat "$CREDS_FILE")
if [ -z "$CREDS" ]; then
    log_and_echo "$(date) - Error: CREDS file not found or empty." >&2
    log_and_echo "$(date) - Please set the CREDS file with your base64 encoded credentials by running the script generate-credentials-file.sh." >&2
    exit 1
fi

log_and_echo "$(date) - Credentials file loaded successfully."

curl -s --header "Authorization: Basic ${CREDS}" "https://rest.clicksend.com/v3/sms/history/export?filename=${EXPORT_FILE}" > "$TEMP_JSON_FILE"
log_and_echo "$(date) - Curl command executed."

JSON_STRING=$(cat "$TEMP_JSON_FILE")
rm -f "$TEMP_JSON_FILE"

if [ -z "$JSON_STRING" ]; then
    log_and_echo "$(date) - Error: Unable to set JSON_STRING (file was empty)." >&2
    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    URL=$(echo "$JSON_STRING" | jq -r '.data.url')
else
    #If jq is not installed then fall back to sed, which is less reliable.
    URL=$(echo "$JSON_STRING" | sed -n 's/.*"url":"\([^\"]*\)".*/\1/p')
fi

if [ -z "$URL" ]; then
    log_and_echo "$(date) - Error: Unable to extract URL from JSON string." >&2
    exit 1
fi

log_and_echo "$(date) - Extracted export URL successfully."

log_and_echo "$(date) - Step 2: Downloading SMS history..."

if [ -f "$DOWNLOAD_FILE" ]; then
    rm -f "$DOWNLOAD_FILE"
fi

curl -s -o "$DOWNLOAD_FILE" "$URL"
log_and_echo "$(date) - Successfully downloaded data to $DOWNLOAD_FILE"

log_and_echo "$(date) - Step 3: Filtering SMS history..."

if [ -f "$FILTERED_FILE" ]; then
    rm -f "$FILTERED_FILE"
fi

csvsql --query "$(cat "$FILTER_HISTORY_SQL")" "$DOWNLOAD_FILE" > "$FILTERED_FILE"

if [ ! -s "$FILTERED_FILE" ] || [ $(wc -l < "$FILTERED_FILE") -eq 1 ]; then
    log_and_echo "$(date) - No matching SMS history records found. Check the competition is today (the filtering is by date)." >&2
    exit 0
fi
log_and_echo "$(date) - Successfully filtered the SMS history"

log_and_echo "$(date) - Step 4: Generating leaderboard..."

if [ -f "$LEADERBOARD_FILE" ]; then
    rm -f "$LEADERBOARD_FILE"
fi

csvsql --query "$(cat "$LEADERBOARD_SQL")" "$FILTERED_FILE" "$PLAYERS_CSV" > "$LEADERBOARD_FILE"

if [ ! -s "$LEADERBOARD_FILE" ] || [ $(wc -l < "$LEADERBOARD_FILE") -eq 1 ]; then
    log_and_echo "$(date) - No leaderboard data! Check for players and sms history data for today." >&2
    exit 0
fi

log_and_echo "$(date) - Generated the leaderboard"

log_and_echo "$(date) - Step 5: Generating HTML..."

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
tail -n +2 "$LEADERBOARD_FILE" | while IFS=, read -r player total thru; do
echo "<tr><td>$player</td><td>$total</td><td>$thru</td></tr>" >> "$HTML_OUTPUT_FILE"
done

echo "</table></body></html>" >> "$HTML_OUTPUT_FILE"

log_and_echo "$(date) - HTML file generated."

log_and_echo "$(date) - Step 6: Deploy site"
cd "$HTML_OUTPUT_DIR"
ntl deploy --json --prod -d .
cd "$BASE_DIR"

log_and_echo "$(date) - All steps completed!"

exit 0
