# Source this first in every test file. Creates an isolated $HOME so install
# scripts never touch the real one, and provides PATH stubs.

: "${REPO_ROOT:?run tests via tests/run.sh}"

SANDBOX=$(mktemp -d)
export HOME="$SANDBOX/home"
export XDG_CONFIG_HOME="$HOME/.config"
export SWE_SKILLS_DIR="$SANDBOX/swe-skills"

# PATH is deliberately minimal, NOT "$SANDBOX/bin:$PATH". The real machine has
# claude at ~/.local/bin and opencode at ~/.opencode/bin; inheriting the real
# PATH would make every "harness is absent" test silently pass against the real
# binaries, and would let an install script mutate the real config.
# /usr/bin and /bin still supply jq, git, and coreutils.
export PATH="$SANDBOX/bin:/usr/bin:/bin"

mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$SANDBOX/bin"
trap 'rm -rf "$SANDBOX"' EXIT

# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/assert.sh"

# stub_cmd NAME — put a no-op NAME on PATH that appends its argv to
# $SANDBOX/NAME.log, so tests can assert on how it was called.
stub_cmd() {
    local name=$1
    cat >"$SANDBOX/bin/$name" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$SANDBOX/$name.log"
exit 0
EOF
    chmod +x "$SANDBOX/bin/$name"
}

# stub_cmd_output NAME OUTPUT — like stub_cmd but also prints OUTPUT.
stub_cmd_output() {
    local name=$1 out=$2
    cat >"$SANDBOX/bin/$name" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$SANDBOX/$name.log"
printf '%s\n' "$out"
exit 0
EOF
    chmod +x "$SANDBOX/bin/$name"
}

# stub_swe_skills — a fake swe-skills checkout whose install.sh links two
# dummy skills into the right per-tool directory.
stub_swe_skills() {
    mkdir -p "$SWE_SKILLS_DIR/.git" \
             "$SWE_SKILLS_DIR/skills/de-slop" \
             "$SWE_SKILLS_DIR/book-skills/clean-coding"
    touch "$SWE_SKILLS_DIR/skills/de-slop/SKILL.md" \
          "$SWE_SKILLS_DIR/book-skills/clean-coding/SKILL.md"
    cat >"$SWE_SKILLS_DIR/install.sh" <<'EOF'
#!/usr/bin/env bash
set -eu
tool=""
for a in "$@"; do
    case "$a" in --tool=*) tool=${a#--tool=} ;; esac
done
case "$tool" in
    claude)   dest="$HOME/.claude/skills" ;;
    opencode) dest="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
    *) echo "unknown tool" >&2; exit 1 ;;
esac
mkdir -p "$dest"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for d in "$here"/skills/*/ "$here"/book-skills/*/; do
    [ -d "$d" ] || continue
    ln -sfn "$d" "$dest/$(basename "$d")"
done
EOF
    chmod +x "$SWE_SKILLS_DIR/install.sh"
}

# path_without CMD — echo a PATH containing the stub dir plus everything in
# /usr/bin and /bin except CMD. Lets tests exercise "this tool is missing"
# without breaking the coreutils the scripts themselves need.
path_without() {
    # Declare separately: `local` expands every argument before it performs
    # any assignment, so a `dir=...$skip...` on the same line would expand
    # $skip while it is still unbound, which aborts the function under set -u.
    local skip=$1
    local dir="$SANDBOX/without-$skip/bin"
    local p base
    mkdir -p "$dir"
    for p in /usr/bin/* /bin/*; do
        [ -x "$p" ] || continue
        base=$(basename "$p")
        [ "$base" = "$skip" ] && continue
        ln -sfn "$p" "$dir/$base" 2>/dev/null || true
    done
    printf '%s\n' "$SANDBOX/bin:$dir"
}
