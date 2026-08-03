#!/usr/bin/env bash
# Link this repo's own skills into every harness that is present.
#
# Both installers already call link_local_skills; this exists so the skills can
# be refreshed on their own, without reinstalling plugins or re-cloning
# swe-skills.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

installed=0

if have claude; then
    log "linking local skills into $(claude_dir)/skills"
    link_local_skills "$(claude_dir)/skills"
    installed=1
fi

if have opencode; then
    log "linking local skills into $(opencode_dir)/skills"
    link_local_skills "$(opencode_dir)/skills"
    installed=1
fi

if [ "$installed" -eq 0 ]; then
    warn "neither claude nor opencode on PATH; nothing to do"
fi
