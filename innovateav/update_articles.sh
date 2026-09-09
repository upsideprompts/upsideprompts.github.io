#!/usr/bin/env bash
#
# OpenClaw Site Verification Cron Script
# Executes a prompt via OpenClaw, extracts searched URLs, validates HTTP reachability,
# checks content legitimacy, and logs the results.

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
LOG_FILE="/var/log/openclaw_verification.log"
WORK_DIR="/tmp/openclaw_verify_$(date +%Y%m%d_%H%M%S)"
OPENCLAW_PROMPT="Search for recent research papers on multi-agent LLM architectures and list key findings."

RUN_JSON="${WORK_DIR}/run_output.json"
TARGET_URLS="${WORK_DIR}/target_urls.txt"
REAL_SITES="${WORK_DIR}/real_sites.txt"
VERIFIED_SITES="${WORK_DIR}/verified_sites.txt"

mkdir -p "${WORK_DIR}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "=== Starting OpenClaw Site Verification Job ==="

# ------------------------------------------------------------------------------
# Step 1: Execute OpenClaw & Extract Searched URLs
# ------------------------------------------------------------------------------
log "Step 1: Running OpenClaw prompt and extracting searched URLs..."

openclaw run "${OPENCLAW_PROMPT}" --output-format json > "${RUN_JSON}" 2>&1

# Parse URLs from search results (handles primary URL field or nested web_search logs)
jq -r '(.search_results[]?.url // .tool_calls[]? | select(.name=="web_search") | .response[]?.url) // empty' "${RUN_JSON}" \
 | sort -u \
 | grep -E '^https?://' > "${TARGET_URLS}" || true

URL_COUNT=$(wc -l < "${TARGET_URLS}" | tr -d ' ')
log "Extracted ${URL_COUNT} unique URL(s) to test."

if [ "${URL_COUNT}" -eq 0 ]; then
  log "No URLs extracted from execution output. Exiting."
  rm -rf "${WORK_DIR}"
  exit 0
fi

# ------------------------------------------------------------------------------
# Step 2: Validate HTTP Status Code & Network Connectivity
# ------------------------------------------------------------------------------
log "Step 2: Checking network reachability and HTTP status codes..."

> "${REAL_SITES}"
while IFS= read -r url; do
  [ -z "$url" ] && continue

  # Follow redirects up to 3 times, set timeout to 5 seconds, capture status code
  HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" -L --max-redirs 3 --max-time 5 "$url" || echo "000")

  if [[ "$HTTP_CODE" =~ ^(200|301|302)$ ]]; then
    echo "$url" >> "${REAL_SITES}"
    log "  [PASS] ${HTTP_CODE} -> ${url}"
  else
    log "  [FAIL] ${HTTP_CODE} -> ${url}"
  fi
done < "${TARGET_URLS}"

REACHABLE_COUNT=$(wc -l < "${REAL_SITES}" | tr -d ' ')
log "${REACHABLE_COUNT}/${URL_COUNT} URLs returned accessible HTTP status codes."

if [ "${REACHABLE_COUNT}" -eq 0 ]; then
  log "No reachable sites found. Exiting."
  rm -rf "${WORK_DIR}"
  exit 0
fi

# ------------------------------------------------------------------------------
# Step 3: Verify Site Legitimacy and Content Integrity
# ------------------------------------------------------------------------------
log "Step 3: Verifying page content legitimacy with OpenClaw web-scraper skill..."

# Formulate verification prompt using the list of reachable sites
VERIFY_PROMPT="Inspect the content of the following URLs. Confirm which ones are active, genuine websites rather than domain parking pages, captcha blocks, or soft 404 errors: $(cat "${REAL_SITES}" | tr '\n' ' ')"

openclaw run --skill web-scraper "${VERIFY_PROMPT}" --output-format text > "${VERIFIED_SITES}" 2>&1

log "Verification summary generated:"
cat "${VERIFIED_SITES}" >> "${LOG_FILE}"

# Cleanup temporary run directory
rm -rf "${WORK_DIR}"

log "=== OpenClaw Site Verification Job Complete ==="