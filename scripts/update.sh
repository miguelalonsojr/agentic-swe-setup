#!/usr/bin/env bash
# Refresh Prime Agent links and skills without switching the installed provider.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
read_provider() {
    local manifest=$1
    if have jq && [ -f "$manifest" ]; then
        jq -r '.provider // "anthropic"' "$manifest"
    else
        printf 'anthropic\n'
    fi
}
for prerequisite in prime-agent jq; do
    if ! have "$prerequisite"; then
        warn "$prerequisite not on PATH; skipping update"
        exit 0
    fi
done
provider=$(read_provider "$(prime_dir)/.agentic-swe-setup.json")
if have prime-agent && have git; then
    ensure_superpowers
elif ! have git; then
    warn "git not on PATH; skipping shared skills refresh"
fi
bash "$REPO_ROOT/scripts/install-prime.sh" "$provider"
log "update complete (prime: $provider)"
