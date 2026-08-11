#!/usr/bin/env bash
# Install Superpowers, swe-skills, subagents, and global instructions for
# OpenCode. Exits 0 without doing anything when opencode or jq is absent.
#
# Usage: install-opencode.sh [provider]   (default: anthropic)
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

provider=${1:-anthropic}

if ! have opencode; then
    warn "opencode not on PATH; skipping OpenCode setup"
    exit 0
fi
if ! have jq; then
    warn "jq not on PATH; skipping OpenCode setup"
    exit 0
fi

# Merge first: a tripped comment guard must abort before anything else is
# touched, so a refused install leaves no half-configured state.
"$REPO_ROOT/scripts/merge-opencode.sh" "$provider"

ensure_swe_skills
run_swe_skills_install opencode

log "linking local skills into $(opencode_dir)/skills"
link_local_skills "$(opencode_dir)/skills"

instructions=$(render_agents_md opencode) || die "could not render AGENTS.md for OpenCode"
log "linking global instructions to $(opencode_dir)/AGENTS.md"
link_into "$instructions" "$(opencode_dir)/AGENTS.md"

log "OpenCode setup complete (provider: $provider)"
