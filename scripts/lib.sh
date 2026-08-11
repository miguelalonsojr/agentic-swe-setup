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

MANAGED_AGENTS=(general explore implementer-light implementer implementer-strong reviewer reviewer-final reviewer-lite cross-checker)
CLAUDE_AGENTS=(implementer-light implementer implementer-strong reviewer reviewer-final reviewer-lite cross-checker)
# Prime Agent has no agent-definition files. The same roles are installed as
# continual-harness subagent specs, so PRIME_AGENTS mirrors MANAGED_AGENTS.
PRIME_AGENTS=("${MANAGED_AGENTS[@]}")
# Filenames this project shipped under before, which must be retired on install.
# reviewer-light.md declared `name: reviewer-lite`, so leaving it next to the
# current reviewer-lite.md would mean two files claiming one agent name.
LEGACY_CLAUDE_AGENTS=(reviewer-light)
SKILL_NAMES=(clean-architecture clean-coding ddd-expert design-patterns-expert
             de-slop generating-design-doc pragmatic-engineer system-designing)
# Skills that live in this repo rather than the shared swe-skills checkout.
LOCAL_SKILLS=(jira-fu routing-model-tiers cross-checking-claims search-fu)

# Harnesses this repo installs into, and the AGENTS.md section that belongs to
# each. AGENTS.md carries all three so the repo's own agents can read any of
# them; install renders a copy that keeps only the target harness's section,
# because the three sections give conflicting dispatch instructions.
HARNESSES=(claude opencode prime)

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

# harness_heading HARNESS — the AGENTS.md heading owned by HARNESS. Matched
# literally against the file, so a reworded heading fails the render instead
# of quietly producing instructions for the wrong harness.
harness_heading() {
    case $1 in
        claude)   printf '%s\n' '#### When running under Claude Code' ;;
        opencode) printf '%s\n' '#### When running under OpenCode' ;;
        prime)    printf '%s\n' '#### When running under Prime Agent' ;;
        *) return 1 ;;
    esac
}

# rendered_agents_md HARNESS PROVIDER — where the rendered instructions are
# written. Inside the repo, so the installed path stays a symlink into this
# repo and doctor, uninstall, and update keep working unchanged.
rendered_agents_md() { printf '%s\n' "$REPO_ROOT/build/$1/$2/AGENTS.md"; }

# render_agents_md HARNESS PROVIDER — write AGENTS.md minus the other
# harnesses' sections, and print the path. Prime renders its provider's model
# ladder into the markers left in its section. Returns non-zero rather than
# dying, so the caller decides whether a failed render is fatal.
render_agents_md() {
    local harness=${1:-} provider=${2:-} keep out src config filtered table rendered reviewer
    local agent model
    src="$REPO_ROOT/AGENTS.md"
    if [ -z "$harness" ] || [ -z "$provider" ]; then
        warn "render_agents_md requires a harness and provider"
        return 1
    fi
    if ! keep=$(harness_heading "$harness"); then
        warn "unknown harness: $harness"
        return 1
    fi
    config="$REPO_ROOT/prime/$provider.json"
    if [ ! -f "$config" ]; then
        warn "unknown provider: $provider"
        return 1
    fi
    if ! grep -qxF "$keep" "$src"; then
        warn "AGENTS.md has no section titled: $keep"
        return 1
    fi
    out=$(rendered_agents_md "$harness" "$provider")
    mkdir -p "$(dirname "$out")"
    filtered=$(mktemp "${out}.filtered.XXXXXX") || return 1
    # A section runs from its heading to the next heading of any level. The
    # fence toggle keeps a `#` comment inside a code block from ending one.
    if ! awk -v keep="$keep" '
        /^```/ { fence = !fence }
        !fence && /^#### When running under / {
            drop = ($0 != keep)
            if (drop) next
        }
        !fence && /^#/ && !/^#### When running under / { drop = 0 }
        drop { next }
        { print }
    ' "$src" > "$filtered"; then
        rm -f "$filtered"
        return 1
    fi
    if [ "$harness" != prime ]; then
        if [ -d "$out" ]; then
            warn "render output is a directory: $out"
            rm -f "$filtered"
            return 1
        fi
        if ! mv "$filtered" "$out"; then
            rm -f "$filtered"
            return 1
        fi
        printf '%s\n' "$out"
        return 0
    fi

    table=$(mktemp "${out}.table.XXXXXX") || { rm -f "$filtered"; return 1; }
    for agent in "${PRIME_AGENTS[@]}"; do
        if ! model=$(jq -er --arg agent "$agent" \
            '.agent[$agent].model | select(type == "string" and length > 0)' "$config"); then
            warn "provider $provider has no model for Prime agent: $agent"
            rm -f "$filtered" "$table"
            return 1
        fi
        if ! printf '| `%s` | `%s` |\n' "$agent" "$model" >> "$table"; then
            rm -f "$filtered" "$table"
            return 1
        fi
    done
    if ! reviewer=$(jq -er \
        '.agent.reviewer.model | select(type == "string" and length > 0)' "$config"); then
        warn "provider $provider has no model for Prime agent: reviewer"
        rm -f "$filtered" "$table"
        return 1
    fi
    rendered=$(mktemp "${out}.rendered.XXXXXX") || {
        rm -f "$filtered" "$table"
        return 1
    }
    if ! awk -v table="$table" -v reviewer="$reviewer" '
        $0 == "<!-- PRIME_AGENT_MODEL_TABLE -->" {
            print "| Role | Model |"
            print "|---|---|"
            while ((getline row < table) > 0) print row
            close(table)
            next
        }
        {
            gsub(/<!-- PRIME_AGENT_REVIEWER_MODEL -->/, reviewer)
            print
        }
    ' "$filtered" > "$rendered"; then
        rm -f "$filtered" "$table" "$rendered"
        return 1
    fi
    rm -f "$filtered" "$table"
    if [ -d "$out" ]; then
        warn "render output is a directory: $out"
        rm -f "$rendered"
        return 1
    fi
    if ! mv "$rendered" "$out"; then
        rm -f "$rendered"
        return 1
    fi
    printf '%s\n' "$out"
}
