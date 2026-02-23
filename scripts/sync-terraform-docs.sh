#!/usr/bin/env bash
# sync-terraform-docs.sh - Download latest Terraform provider docs from GitHub
#
# Downloads source archives for each provider, extracts docs + CHANGELOG,
# and stores them in terraform-providers/{provider}/ for local reference.
#
# Usage:
#   ./scripts/sync-terraform-docs.sh              # Sync all providers to latest
#   ./scripts/sync-terraform-docs.sh google 7.20.0 # Sync one provider to specific version
#
# After sync, update check-references.sh with new version numbers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_ROOT="$(dirname "$SCRIPT_DIR")"
TF_DOCS_DIR="${DOCS_ROOT}/terraform-providers"
TMP_DIR="${TMPDIR:-/tmp}/tf-docs-sync-$$"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Provider registry: name | github_repo | docs_path_in_archive
# docs_path: "website/docs" or "docs" depending on provider convention
declare -A PROVIDERS=(
  [google]="hashicorp/terraform-provider-google|website/docs"
  [google-beta]="hashicorp/terraform-provider-google-beta|website/docs"
  [aws]="hashicorp/terraform-provider-aws|website/docs"
  [azurerm]="hashicorp/terraform-provider-azurerm|website/docs"
  [sakuracloud]="sacloud/terraform-provider-sakuracloud|website/docs"
  [cloudflare]="cloudflare/terraform-provider-cloudflare|docs"
  [vultr]="vultr/terraform-provider-vultr|website/docs"
)

# Display names for output
declare -A DISPLAY_NAMES=(
  [google]="Google"
  [google-beta]="Google Beta"
  [aws]="AWS"
  [azurerm]="Azure"
  [sakuracloud]="SakuraCloud"
  [cloudflare]="Cloudflare"
  [vultr]="Vultr"
)

cleanup() {
  if [[ -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

get_latest_version() {
  local repo="$1"
  curl -s "https://api.github.com/repos/${repo}/releases/latest" \
    | grep '"tag_name"' \
    | sed -E 's/.*"v?([^"]+)".*/\1/'
}

sync_provider() {
  local name="$1"
  local version="$2"  # empty string = auto-detect latest
  local provider_config="${PROVIDERS[$name]}"
  local repo="${provider_config%%|*}"
  local docs_path="${provider_config##*|}"
  local display="${DISPLAY_NAMES[$name]}"

  # Get version
  if [[ -z "$version" ]]; then
    printf "${CYAN}[%s]${NC} Fetching latest release... " "$display"
    version=$(get_latest_version "$repo")
    if [[ -z "$version" ]]; then
      printf "${RED}FAILED${NC} (API error)\n"
      return 1
    fi
    printf "v%s\n" "$version"
  else
    printf "${CYAN}[%s]${NC} Target version: v%s\n" "$display" "$version"
  fi

  # Check if already synced at this version
  local dest_dir="${TF_DOCS_DIR}/${name}"
  local version_file="${dest_dir}/.synced-version"
  if [[ -f "$version_file" ]] && [[ "$(cat "$version_file")" == "$version" ]]; then
    printf "${GREEN}[%s]${NC} Already synced at v%s — skipping\n" "$display" "$version"
    return 0
  fi

  # Download source archive
  local archive_url="https://github.com/${repo}/archive/refs/tags/v${version}.zip"
  local zip_file="${TMP_DIR}/${name}-${version}.zip"

  printf "${CYAN}[%s]${NC} Downloading v%s source archive... " "$display" "$version"
  mkdir -p "$TMP_DIR"
  if ! curl -sL "$archive_url" -o "$zip_file"; then
    printf "${RED}FAILED${NC}\n"
    return 1
  fi
  local zip_size
  zip_size=$(du -sh "$zip_file" | cut -f1)
  printf "%s\n" "$zip_size"

  # Determine the top-level directory name in the archive
  local repo_name="${repo##*/}"
  local archive_prefix="${repo_name}-${version}"

  # Extract docs and CHANGELOG only
  printf "${CYAN}[%s]${NC} Extracting docs + CHANGELOG... " "$display"

  local extract_dir="${TMP_DIR}/${name}-extract"
  mkdir -p "$extract_dir"

  # Extract docs directory
  unzip -q -o "$zip_file" "${archive_prefix}/${docs_path}/*" -d "$extract_dir" 2>/dev/null || true

  # Extract CHANGELOG files (main version only, not vendor/)
  unzip -q -o "$zip_file" "${archive_prefix}/CHANGELOG.md" -d "$extract_dir" 2>/dev/null || true
  unzip -q -o "$zip_file" "${archive_prefix}/CHANGELOG_v*.md" -d "$extract_dir" 2>/dev/null || true

  # Extract upgrade guides if at top level
  unzip -q -o "$zip_file" "${archive_prefix}/UPGRADE*.md" -d "$extract_dir" 2>/dev/null || true

  # Count extracted docs
  local doc_count
  doc_count=$(find "${extract_dir}/${archive_prefix}/${docs_path}" -type f 2>/dev/null | wc -l | tr -d ' ')
  printf "%s doc files\n" "$doc_count"

  # Prepare destination
  if [[ -d "$dest_dir" ]]; then
    rm -rf "$dest_dir"
  fi
  mkdir -p "$dest_dir"

  # Move docs into place
  if [[ -d "${extract_dir}/${archive_prefix}/${docs_path}" ]]; then
    cp -R "${extract_dir}/${archive_prefix}/${docs_path}/"* "$dest_dir/"
  fi

  # Move CHANGELOGs into a changelog/ subdirectory
  mkdir -p "${dest_dir}/changelog"
  for cl in "${extract_dir}/${archive_prefix}"/CHANGELOG*.md; do
    [[ -f "$cl" ]] && cp "$cl" "${dest_dir}/changelog/"
  done

  # Move upgrade guides if present
  for ug in "${extract_dir}/${archive_prefix}"/UPGRADE*.md; do
    [[ -f "$ug" ]] && cp "$ug" "${dest_dir}/"
  done

  # Write version marker
  echo "$version" > "$version_file"

  # Write metadata
  cat > "${dest_dir}/SYNC-INFO.md" << EOF
# ${display} Terraform Provider - Synced Docs

**Provider:** \`${repo}\`
**Version:** v${version}
**Synced:** $(date -u '+%Y-%m-%d %H:%M UTC')
**Source:** https://github.com/${repo}/releases/tag/v${version}
**Doc files:** ${doc_count}

## Directory Structure

- \`d/\` or \`data-sources/\` — Data source documentation
- \`r/\` or \`resources/\` — Resource documentation
- \`guides/\` — Provider guides and upgrade docs
- \`changelog/\` — Version changelogs

## Usage

These docs are the authoritative reference for this provider version.
Compare CHANGELOG.md entries between our deployed version and this version
before running \`terraform init -upgrade\`.
EOF

  # Clean up zip
  rm -f "$zip_file"
  rm -rf "$extract_dir"

  printf "${GREEN}[%s]${NC} Synced v%s → %s (%s files)\n" "$display" "$version" "${dest_dir##*/Users/headsup/workspace/}" "$doc_count"
}

# --- Main ---

echo "=== Terraform Provider Docs Sync ==="
echo "Date: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "Target: ${TF_DOCS_DIR}"
echo ""

# Single provider mode
if [[ $# -ge 1 ]]; then
  provider_name="$1"
  specific_version="${2:-}"

  if [[ -z "${PROVIDERS[$provider_name]+x}" ]]; then
    echo "Unknown provider: $provider_name"
    echo "Available: ${!PROVIDERS[*]}"
    exit 1
  fi

  sync_provider "$provider_name" "$specific_version"
  echo ""
  echo "=== Done ==="
  exit 0
fi

# All providers mode
SYNC_COUNT=0
FAIL_COUNT=0

for provider in google google-beta aws azurerm sakuracloud cloudflare vultr; do
  if sync_provider "$provider" ""; then
    SYNC_COUNT=$((SYNC_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  echo ""
done

echo "=== Sync complete ==="
echo "Synced: ${SYNC_COUNT} | Failed: ${FAIL_COUNT}"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
