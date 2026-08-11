#!/usr/bin/env bash
# Install Superpowers, swe-skills, subagent specs, and global instructions for
# Prime Agent. Exits 0 without doing anything when prime-agent or jq is absent.
#
# Prime Agent differs from the other two harnesses in three ways:
#   - no plugin system, so Superpowers is consumed as a plain skills checkout;
#   - swe-skills' install.sh has no --tool=prime, so we link its skills here;
#   - no agent-definition files, so roles become harness subagent specs.
#
# Usage: install-prime.sh [provider]   (default: anthropic)
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

provider=${1:-anthropic}

if ! have prime-agent; then
    warn "prime-agent not on PATH; skipping Prime Agent setup"
    exit 0
fi
if ! have jq; then
    warn "jq not on PATH; skipping Prime Agent setup"
    exit 0
fi

# Merge first: a tripped comment guard must abort before anything else is
# touched, so a refused install leaves no half-configured state.
"$REPO_ROOT/scripts/merge-prime.sh" "$provider"

skills_dir="$(prime_dir)/skills"

ensure_superpowers
log "linking superpowers skills into $skills_dir"
link_skill_tree "$(superpowers_dir)/skills" "$skills_dir"

ensure_swe_skills
log "linking swe-skills into $skills_dir"
link_skill_tree "$(swe_skills_dir)/skills" "$skills_dir"
link_skill_tree "$(swe_skills_dir)/book-skills" "$skills_dir"

log "linking local skills into $skills_dir"
link_local_skills "$skills_dir"

instructions=$(render_agents_md prime "$provider") || die "could not render AGENTS.md for Prime Agent"
log "linking global instructions to $(prime_dir)/AGENTS.md"
link_into "$instructions" "$(prime_dir)/AGENTS.md"

log "Prime Agent setup complete (provider: $provider)"
