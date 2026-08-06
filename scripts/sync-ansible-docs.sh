#!/usr/bin/env bash
# sync-ansible-docs.sh - fetch upstream Ansible changelogs + porting guides
#
# Companion to sync-terraform-docs.sh, with ONE deliberate structural difference:
# it does NOT call the GitHub /releases/latest API. That endpoint returns a single
# non-prerelease answer for the whole project, which cannot describe the FOUR
# branches we track simultaneously (core 2.20 + 2.21, package 13 + 14).
# Instead the newest stable release is read out of each changelog document itself,
# so the recorded version can never disagree with the file it came from.
#
# Usage:  ./scripts/sync-ansible-docs.sh
# Output: rewrites ansible/.synced-versions and prints a diff of what moved.
#         Does NOT rewrite ansible/SYNC-INFO.md - that is hand-maintained.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_ROOT="$(dirname "$SCRIPT_DIR")"
DEST="${DOCS_ROOT}/ansible"

# --- what we track. Edit these when the runner or controller moves. ---
CORE_BRANCHES=(2.20 2.21)
PKG_MAJORS=(13 14)

RAW_CORE="https://raw.githubusercontent.com/ansible/ansible"
RAW_PKG="https://raw.githubusercontent.com/ansible-community/ansible-build-data/main"
RAW_DOC="https://raw.githubusercontent.com/ansible/ansible-documentation/devel/docs/docsite/rst/porting_guides"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "${DEST}/core" "${DEST}/package"
MARKER="${DEST}/.synced-versions"
NEW="${MARKER}.new"
: > "$NEW"

echo "=== Ansible Docs Sync ==="
echo "Date:   $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "Target: ${DEST}"
echo ""

for b in "${CORE_BRANCHES[@]}"; do
  cl="CHANGELOG-v${b}.rst"
  if curl -sfL "${RAW_CORE}/stable-${b}/changelogs/${cl}" -o "${DEST}/core/${cl}"; then
    latest=$(grep -E "^v${b}\.[0-9]+$" "${DEST}/core/${cl}" | head -1 | sed 's/^v//' || true)
    echo "core-${b}=${latest:-unknown}" >> "$NEW"
    printf "${GREEN}core %s${NC}  changelog ok, latest stable %s\n" "$b" "${latest:-unknown}"
  else
    printf "${RED}core %s${NC}  CHANGELOG FETCH FAILED\n" "$b"
    grep "^core-${b}=" "$MARKER" >> "$NEW" 2>/dev/null || true
  fi
  pg="porting_guide_core_${b}.rst"
  if curl -sfL "${RAW_DOC}/${pg}" -o "${DEST}/core/${pg}"; then
    printf "           porting guide ok\n"
  else
    printf "${YELLOW}           no porting guide for core %s${NC}\n" "$b"
  fi
done

for m in "${PKG_MAJORS[@]}"; do
  cl="CHANGELOG-v${m}.md"
  if curl -sfL "${RAW_PKG}/${m}/${cl}" -o "${DEST}/package/${cl}"; then
    # antsibull-generated markdown ESCAPES the dots: headings read "## v13\.8\.0".
    # Match the heading line and strip backslashes rather than fight ERE escaping
    # through two levels of quoting. grep -m1 also avoids SIGPIPE entirely.
    latest=$(grep -m1 "^## v${m}" "${DEST}/package/${cl}" 2>/dev/null | sed 's/^## v//; s/\\//g' || true)
    echo "package-${m}=${latest:-unknown}" >> "$NEW"
    printf "${GREEN}pkg  %s${NC}    changelog ok, newest seen %s\n" "$m" "${latest:-unknown}"
  else
    printf "${RED}pkg  %s${NC}    CHANGELOG FETCH FAILED\n" "$m"
    grep "^package-${m}=" "$MARKER" >> "$NEW" 2>/dev/null || true
  fi
  pg="porting_guide_${m}.rst"
  if curl -sfL "${RAW_DOC}/${pg}" -o "${DEST}/package/${pg}"; then
    printf "           porting guide ok\n"
  else
    printf "${YELLOW}           no porting guide for package %s${NC}\n" "$m"
  fi
done

echo ""
if [[ -f "$MARKER" ]]; then
  if diff -q "$MARKER" "$NEW" >/dev/null 2>&1; then
    printf "${GREEN}No version change since last sync.${NC}\n"
  else
    echo "=== VERSION DELTA (read the changelogs for anything that moved) ==="
    diff "$MARKER" "$NEW" || true
  fi
fi
mv "$NEW" "$MARKER"

echo ""
echo "=== .synced-versions ==="
cat "$MARKER"
echo ""
echo "Reminder: a version delta on core means any local ansible-lint result must be"
echo "re-checked against the changelog gap before it is treated as evidence about production."
