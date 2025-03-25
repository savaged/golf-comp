#!/bin/zsh

set -e

# Define variables - use absolute paths to avoid issues with cron
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
NETLIFY_ENV_FILE="$BASE_DIR/.netlify_env"
HTML_OUTPUT_DIR="$BASE_DIR/_site"
LOG_FILE="$BASE_DIR/deploy-leaderboard.log"

# Ensure PATH includes directories where ntl might be found
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

log_and_echo() {
  echo "$@" | tee -a "$LOG_FILE"
}

log_and_echo "$(date) - Step 6: Deploy site"

# Log environment variables for debugging
env | tee -a "$LOG_FILE"

if [ ! -f "$NETLIFY_ENV_FILE" ]; then
  log_and_echo "$(date) - ERROR: .netlify_env file not found at $NETLIFY_ENV_FILE"
  exit 1
fi

# Log the contents of .netlify_env (remove this after debugging)
log_and_echo "$(date) - NETLIFY_ENV_FILE content:"
cat "$NETLIFY_ENV_FILE" | tee -a "$LOG_FILE"

# Source the Netlify environment variables
source "$NETLIFY_ENV_FILE"

# Ensure the Netlify CLI can be found
if ! command -v ntl &> /dev/null; then
  log_and_echo "$(date) - ERROR: Netlify CLI (ntl) not found in PATH."
  exit 1
fi

# Change to the output directory and deploy
cd "$HTML_OUTPUT_DIR"
timeout 60 ntl deploy --prod -d . --json | tee -a "$LOG_FILE"
deploy_status=$?
cd "$BASE_DIR"

if [ $deploy_status -ne 0 ]; then
  log_and_echo "$(date) - ERROR: Netlify deployment failed with exit code $deploy_status."
  exit 1
fi

log_and_echo "$(date) - All steps completed!"

exit 0
