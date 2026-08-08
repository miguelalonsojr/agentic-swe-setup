# Shared helpers and constants for agentic-swe-setup.
#
# Deliberately sets no shell options: doctor.sh must survive failing checks.
# Every path derives from $HOME so the test suite can sandbox installs.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SUPERPOWERS_PLUGIN="superpowers@git+https://github.com/obra/superpowers.git"
SUPERPOWERS_MARKETPLACE="anthropics/claude-plugins-official"
SUPERPOWERS_CLAUDE_PLUGIN="superpowers@claude-plugins-official"
SUPERPOWERS_REPO="https://github.com/obra/superpowers"
SWE_SKILLS_REPO="https://github.com/mhihasan/swe-skills"

MANAGED_AGENTS=(general explore implementer-light implementer implementer-strong reviewer reviewer-final reviewer-lite)
CLAUDE_AGENTS=(implementer-light implementer implementer-strong reviewer reviewer-final reviewer-lite)
# Prime Agent has no agent-definition files. The same eight roles are installed
# as continual-harness subagent specs, so PRIME_AGENTS mirrors MANAGED_AGENTS.
PRIME_AGENTS=("${MANAGED_AGENTS[@]}")
# Filenames this project shipped under before, which must be retired on install.
# reviewer-light.md declared `name: reviewer-lite`, so leaving it next to the
# current reviewer-lite.md would mean two files claiming one agent name.
LEGACY_CLAUDE_AGENTS=(reviewer-light)
SKILL_NAMES=(clean-architecture clean-coding ddd-expert design-patterns-expert
             de-slop generating-design-doc pragmatic-engineer system-designing)
# Skills that live in this repo rather than the shared swe-skills checkout.
LOCAL_SKILLS=(jira-fu)

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

claude_dir()     { printf '%s\n' "$HOME/.claude"; }
opencode_dir()   { printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"; }
swe_skills_dir() { printf '%s\n' "${SWE_SKILLS_DIR:-$HOME/.swe-skills}"; }
# PRIME_AGENT_CODING_AGENT_DIR is Prime Agent's own override for its config
# root; honouring it keeps installs and the test sandbox on the same path.
prime_dir()      { printf '%s\n' "${PRIME_AGENT_CODING_AGENT_DIR:-$HOME/.prime/agent}"; }
# Superpowers ships as a Claude plugin, which Prime Agent has no equivalent of.
# Prime consumes the same skills straight from a checkout instead.
superpowers_dir() { printf '%s\n' "${SUPERPOWERS_DIR:-$HOME/.superpowers}"; }

# link_into SRC DEST — symlink SRC at DEST. A DEST that already exists and is
# not a symlink is moved aside first, so we never destroy a real file.
link_into() {
    local src=$1 dest=$2 backup
    [ -e "$src" ] || die "link source missing: $src"
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        backup="$dest.bak.$(date +%s)"
        mv "$dest" "$backup"
        warn "backed up existing $dest to $backup"
    fi
    ln -sfn "$src" "$dest"
}

# links_into_repo PATH — true when PATH is a symlink resolving inside this repo.
links_into_repo() {
    local p=$1 target
    [ -L "$p" ] || return 1
    target=$(readlink -f "$p") || return 1
    case "$target" in
        "$REPO_ROOT"/*) return 0 ;;
        *) return 1 ;;
    esac
}

# retire_legacy_agent NAME — clear out an agent file this project used to
# install under an older filename. A symlink into this repo is ours, so it goes
# outright; anything else is a file the user may care about and is moved aside.
retire_legacy_agent() {
    local name=$1 p backup
    p="$(claude_dir)/agents/$name.md"
    if links_into_repo "$p"; then
        rm -f "$p"
        log "removed stale agent link $p"
    elif [ -e "$p" ] || [ -L "$p" ]; then
        backup="$p.bak.$(date +%s)"
        mv "$p" "$backup"
        warn "retired legacy agent $p to $backup"
    fi
}

# ensure_checkout NAME URL DIR — clone or fast-forward a shared checkout.
ensure_checkout() {
    local name=$1 url=$2 dir=$3
    have git || die "git is required to install $name"
    if [ -d "$dir/.git" ]; then
        log "updating $name in $dir"
        git -C "$dir" pull --ff-only
    elif [ -e "$dir" ]; then
        die "$dir exists but is not a git checkout; remove it and retry"
    else
        log "cloning $name to $dir"
        git clone --depth 1 "$url" "$dir"
    fi
}

# ensure_swe_skills — clone or fast-forward the shared skills checkout.
ensure_swe_skills() {
    ensure_checkout swe-skills "$SWE_SKILLS_REPO" "$(swe_skills_dir)"
}

# ensure_superpowers — clone or fast-forward the Superpowers checkout. Only
# Prime Agent needs it; Claude Code and OpenCode load it as a plugin instead.
ensure_superpowers() {
    ensure_checkout superpowers "$SUPERPOWERS_REPO" "$(superpowers_dir)"
}

# link_skill_tree SRC_DIR DEST_ROOT — symlink every SKILL.md-bearing directory
# directly under SRC_DIR into DEST_ROOT. Used for harnesses that have no
# installer of their own to call.
link_skill_tree() {
    local src=$1 dest_root=$2 d
    [ -d "$src" ] || return 0
    mkdir -p "$dest_root"
    for d in "$src"/*/; do
        [ -f "$d/SKILL.md" ] || continue
        link_into "${d%/}" "$dest_root/$(basename "$d")"
    done
}

# link_local_skills DIR — symlink this repo's own skills into a harness's
# skills directory. Separate from swe-skills, which install.sh there manages.
link_local_skills() {
    local dest_root=$1 s
    for s in "${LOCAL_SKILLS[@]}"; do
        link_into "$REPO_ROOT/skills/$s" "$dest_root/$s"
    done
}

# run_swe_skills_install TOOL — TOOL is claude or opencode.
run_swe_skills_install() {
    local tool=$1 dir
    dir=$(swe_skills_dir)
    [ -f "$dir/install.sh" ] || die "swe-skills install.sh missing in $dir"
    log "installing swe-skills for $tool"
    bash "$dir/install.sh" --scope=user --tool="$tool"
}
