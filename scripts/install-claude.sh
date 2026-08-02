#!/usr/bin/env bash
# Install Superpowers, swe-skills, subagents, and global instructions for
# Claude Code. Exits 0 without doing anything when claude is not on PATH.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if ! have claude; then
    warn "claude not on PATH; skipping Claude Code setup"
    exit 0
fi

log "installing superpowers for Claude Code"
# Both are no-ops when already present; a non-zero status here means
# "already added", not a real failure.
claude plugin marketplace add "$SUPERPOWERS_MARKETPLACE" \
    || warn "marketplace add reported an error (already added?)"
claude plugin install "$SUPERPOWERS_CLAUDE_PLUGIN" \
    || warn "plugin install reported an error (already installed?)"

ensure_swe_skills
run_swe_skills_install claude

for a in "${LEGACY_CLAUDE_AGENTS[@]}"; do
    retire_legacy_agent "$a"
done

log "linking subagents into $(claude_dir)/agents"
for a in "${CLAUDE_AGENTS[@]}"; do
    link_into "$REPO_ROOT/agents/$a.md" "$(claude_dir)/agents/$a.md"
done

log "linking global instructions to $(claude_dir)/CLAUDE.md"
link_into "$REPO_ROOT/AGENTS.md" "$(claude_dir)/CLAUDE.md"

log "Claude Code setup complete"
