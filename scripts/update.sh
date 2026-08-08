#!/usr/bin/env bash
# Refresh skills, plugins, and links in place. Reuses the provider recorded
# at install time, so update never silently switches providers.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Each harness records the provider it was installed with, so update never
# silently switches one of them to the other's provider.
read_provider() {
    local manifest=$1
    if have jq && [ -f "$manifest" ]; then
        jq -r '.provider // "anthropic"' "$manifest"
    else
        printf 'anthropic\n'
    fi
}
provider=$(read_provider "$(opencode_dir)/.agentic-swe-setup.json")
prime_provider=$(read_provider "$(prime_dir)/.agentic-swe-setup.json")

if have claude; then
    log "updating the superpowers plugin"
    claude plugin update superpowers \
        || warn "plugin update reported an error"
fi

# ensure_swe_skills fast-forwards the shared checkout; the per-harness
# install then relinks, picking up any newly added skills.
if have git; then
    ensure_swe_skills
    # Superpowers is a plugin for the other two harnesses but a plain checkout
    # for Prime Agent, so it only needs refreshing when Prime Agent is present.
    if have prime-agent; then
        ensure_superpowers
    fi
else
    warn "git not on PATH; skipping the swe-skills refresh"
fi

bash "$REPO_ROOT/scripts/install-claude.sh"
bash "$REPO_ROOT/scripts/install-opencode.sh" "$provider"
bash "$REPO_ROOT/scripts/install-prime.sh" "$prime_provider"

log "update complete (opencode: $provider, prime: $prime_provider)"
