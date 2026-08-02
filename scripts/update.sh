#!/usr/bin/env bash
# Refresh skills, plugins, and links in place. Reuses the provider recorded
# at install time, so update never silently switches providers.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

manifest="$(opencode_dir)/.agentic-swe-setup.json"
provider="anthropic"
if have jq && [ -f "$manifest" ]; then
    provider=$(jq -r '.provider // "anthropic"' "$manifest")
fi

if have claude; then
    log "updating the superpowers plugin"
    claude plugin update superpowers \
        || warn "plugin update reported an error"
fi

# ensure_swe_skills fast-forwards the shared checkout; the per-harness
# install then relinks, picking up any newly added skills.
if have git; then
    ensure_swe_skills
else
    warn "git not on PATH; skipping the swe-skills refresh"
fi

bash "$REPO_ROOT/scripts/install-claude.sh"
bash "$REPO_ROOT/scripts/install-opencode.sh" "$provider"

log "update complete (provider: $provider)"
