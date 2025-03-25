#!/bin/zsh

set -e

# Define variables - important to set these consistently with part 1
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
NETLIFY_ENV_FILE="$BASE_DIR/.netlify_env"
HTML_OUTPUT_DIR="$BASE_DIR/_site"
LOG_FILE="$BASE_DIR/deploy-leaderboard.log"


# A function to log and echo messages
log_and_echo() {
  echo "$@" | tee -a "$LOG_FILE"
}

log_and_echo "$(date) - Starting script part 2..."


log_and_echo "$(date) - Step 6: Deploy site"
source "$NETLIFY_ENV_FILE"
cd "$HTML_OUTPUT_DIR"
timeout 60 ntl deploy --prod -d . --silent 2>&1
deploy_status=$?
cd "$BASE_DIR"
if [ $deploy_status -ne 0 ]; then
  log_and_echo "$(date) - ERROR: Netlify deployment failed with exit code $deploy_status."
  exit 1
fi

log_and_echo "$(date) - All steps completed!"

exit 0
