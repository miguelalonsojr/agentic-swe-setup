# Shared helpers and constants for agentic-swe-setup.
#
# Deliberately sets no shell options: doctor.sh must survive failing checks.
# Every path derives from $HOME so the test suite can sandbox installs.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SUPERPOWERS_PLUGIN="superpowers@git+https://github.com/obra/superpowers.git"
SUPERPOWERS_MARKETPLACE="anthropics/claude-plugins-official"
SUPERPOWERS_CLAUDE_PLUGIN="superpowers@claude-plugins-official"
SWE_SKILLS_REPO="https://github.com/mhihasan/swe-skills"

MANAGED_AGENTS=(general explore implementer-light implementer implementer-strong reviewer reviewer-lite)
CLAUDE_AGENTS=(implementer-light implementer implementer-strong reviewer reviewer-lite)
SKILL_NAMES=(clean-architecture clean-coding ddd-expert design-patterns-expert
             de-slop generating-design-doc pragmatic-engineer system-designing)

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

claude_dir()     { printf '%s\n' "$HOME/.claude"; }
opencode_dir()   { printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"; }
swe_skills_dir() { printf '%s\n' "${SWE_SKILLS_DIR:-$HOME/.swe-skills}"; }

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

# ensure_swe_skills — clone or fast-forward the shared skills checkout.
ensure_swe_skills() {
    local dir
    dir=$(swe_skills_dir)
    have git || die "git is required to install swe-skills"
    if [ -d "$dir/.git" ]; then
        log "updating swe-skills in $dir"
        git -C "$dir" pull --ff-only
    elif [ -e "$dir" ]; then
        die "$dir exists but is not a git checkout; remove it and retry"
    else
        log "cloning swe-skills to $dir"
        git clone --depth 1 "$SWE_SKILLS_REPO" "$dir"
    fi
}

# run_swe_skills_install TOOL — TOOL is claude or opencode.
run_swe_skills_install() {
    local tool=$1 dir
    dir=$(swe_skills_dir)
    [ -f "$dir/install.sh" ] || die "swe-skills install.sh missing in $dir"
    log "installing swe-skills for $tool"
    bash "$dir/install.sh" --scope=user --tool="$tool"
}
