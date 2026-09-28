#!/usr/bin/env bash
# Relink repository-owned skills into Prime Agent without updating checkouts.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
if have prime-agent; then
    log "linking local skills into $(prime_dir)/skills"
    link_local_skills "$(prime_dir)/skills"
else
    warn "prime-agent not on PATH; nothing to do"
fi
