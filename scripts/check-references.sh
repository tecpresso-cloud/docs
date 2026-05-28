#!/usr/bin/env bash
# check-references.sh - Check vendor doc freshness
# Run weekly via cron/launchd or GitHub Actions to detect stale references
#
# Usage: ./scripts/check-references.sh
# Output: Prints STALE/OK status for each tracked vendor
# Exit code: 1 if any provider is stale, 0 if all current

set -euo pipefail

# Script directory for resolving paths to provider .synced-version files.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

STALE_COUNT=0
STALE_DETAILS=""

echo "=== Vendor Reference Freshness Check ==="
echo "Date: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo ""

# Check GitHub releases for Terraform providers
check_github_release() {
  local repo="$1"
  local display_name="$2"
  local local_version="$3"

  latest=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')

  if [[ -z "$latest" ]]; then
    printf "${YELLOW}UNKNOWN${NC}: %-35s (API error)\n" "$display_name"
    return
  fi

  if [[ "$local_version" == "$latest" ]]; then
    printf "${GREEN}OK${NC}:      %-35s (local: %s, latest: %s)\n" "$display_name" "$local_version" "$latest"
  else
    printf "${RED}STALE${NC}:   %-35s (local: %s, latest: %s)\n" "$display_name" "$local_version" "$latest"
    STALE_COUNT=$((STALE_COUNT + 1))
    STALE_DETAILS="${STALE_DETAILS}\n- **${display_name}**: ${local_version} → ${latest} ([${repo}](https://github.com/${repo}/releases))"
  fi
}

# Check if a URL returns llms.txt (Mintlify-powered docs)
check_llmstxt() {
  local url="$1"
  local display_name="$2"

  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}/llms.txt" 2>/dev/null || echo "000")

  if [[ "$status" == "200" ]]; then
    printf "${GREEN}AVAILABLE${NC}: %-30s llms.txt at %s/llms.txt\n" "$display_name" "$url"
  else
    printf "${YELLOW}NONE${NC}:      %-30s (HTTP %s)\n" "$display_name" "$status"
  fi
}

# Read locally-synced provider version from its .synced-version marker file
# (auto-written by sync-terraform-docs.sh on each run). Returns "NOT_SYNCED"
# if the marker is missing, which causes the comparison against upstream to
# report STALE.
get_local_version() {
  local provider="$1"
  local sync_version_file="${SCRIPT_DIR}/../terraform-providers/${provider}/.synced-version"
  if [[ -f "$sync_version_file" ]]; then
    tr -d ' \t\n\r' < "$sync_version_file"
  else
    echo "NOT_SYNCED"
  fi
}

echo "--- Terraform Providers ---"
# Local versions are read dynamically from each provider's .synced-version
# file (written by sync-terraform-docs.sh on each sync). No manual edits here.
check_github_release "hashicorp/terraform-provider-google" "Google Provider" "$(get_local_version google)"
check_github_release "hashicorp/terraform-provider-azurerm" "Azure Provider" "$(get_local_version azurerm)"
check_github_release "hashicorp/terraform-provider-aws" "AWS Provider" "$(get_local_version aws)"
check_github_release "sacloud/terraform-provider-sakuracloud" "SakuraCloud Provider" "$(get_local_version sakuracloud)"
check_github_release "cloudflare/terraform-provider-cloudflare" "Cloudflare Provider" "$(get_local_version cloudflare)"
check_github_release "vultr/terraform-provider-vultr" "Vultr Provider" "$(get_local_version vultr)"
echo ""

echo "--- Vendor llms.txt Availability ---"
check_llmstxt "https://docs.whmcs.com" "WHMCS"
check_llmstxt "https://docs.cpanel.net" "cPanel"
check_llmstxt "https://docs.cloudlinux.com" "CloudLinux"
check_llmstxt "https://docs.imunify360.com" "Imunify360"
check_llmstxt "https://developer.hashicorp.com" "HashiCorp"
check_llmstxt "https://docs.crisp.chat" "Crisp"
check_llmstxt "https://docs.cronitor.io" "Cronitor"
check_llmstxt "https://www.vultr.com/docs" "Vultr"
echo ""

echo "=== Check complete ==="

# Output for GitHub Actions
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "stale_count=${STALE_COUNT}" >> "$GITHUB_OUTPUT"
  echo "stale_details<<EOF" >> "$GITHUB_OUTPUT"
  echo -e "$STALE_DETAILS" >> "$GITHUB_OUTPUT"
  echo "EOF" >> "$GITHUB_OUTPUT"
fi

if [[ "$STALE_COUNT" -gt 0 ]]; then
  echo ""
  echo "${STALE_COUNT} provider(s) behind latest release."
  exit 1
else
  echo ""
  echo "All providers up to date."
  exit 0
fi
