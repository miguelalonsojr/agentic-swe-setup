# agentic-swe-setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `just`-driven installer that reproduces a Superpowers + swe-skills + tiered-subagent environment into Claude Code, OpenCode, or both, on a machine where those harnesses are already installed.

**Architecture:** The `justfile` is a thin dispatcher; all logic lives in `scripts/*.sh` so it is testable without invoking `just`. `scripts/lib.sh` holds shared helpers and constants and sets no shell options. Claude Code is configured by symlinking repo files into `~/.claude`; OpenCode is configured by a `jq` deep-merge of a fixed set of managed keys into `~/.config/opencode/opencode.jsonc`. Everything derives paths from `$HOME`, which is what lets the test suite sandbox every install into a temp directory.

**Tech Stack:** Bash 5, `jq`, `just`, `git`. No test framework dependency — `tests/run.sh` is a self-contained runner, since `bats` and `shellcheck` are not installed on the target machine.

## Global Constraints

- Every script derives paths from `$HOME` / `$XDG_CONFIG_HOME` / `$SWE_SKILLS_DIR`. Never hardcode `/home/...` or use a literal `~` inside a quoted string. The test suite overrides all three.
- `scripts/lib.sh` sets **no** shell options (`set -e` etc.). Each entry-point script sets its own, because `doctor.sh` must continue past failing checks.
- The skills repository is `https://github.com/mhihasan/swe-skills`, cloned to `$SWE_SKILLS_DIR` (default `$HOME/.swe-skills`).
- The OpenCode Superpowers plugin string is exactly `superpowers@git+https://github.com/obra/superpowers.git`.
- The Claude Code plugin is `superpowers@claude-plugins-official` from marketplace `anthropics/claude-plugins-official`.
- The eight swe-skills are: `clean-architecture`, `clean-coding`, `ddd-expert`, `design-patterns-expert`, `de-slop`, `generating-design-doc`, `pragmatic-engineer`, `system-designing`.
- The seven OpenCode managed agents are: `general`, `explore`, `implementer-light`, `implementer`, `implementer-strong`, `reviewer`, `reviewer-lite`.
- The five Claude Code agents are: `implementer-light`, `implementer`, `implementer-strong`, `reviewer`, `reviewer-lite`. (`general` and `explore` are built in to Claude Code and are not installed.)
- Missing `claude` → warn, skip, exit 0. Missing `opencode` → warn, skip, exit 0. Missing `jq` → warn, skip the OpenCode half, exit 0. Missing `git` → fatal.
- Every recipe is idempotent and safe to re-run.
- Commit after every task.

**Deviation from the spec's file listing:** the spec's `scripts/` listing named only `lib.sh`, `doctor.sh`, and `merge-opencode.sh`. This plan adds `install-claude.sh`, `install-opencode.sh`, `update.sh`, and `uninstall.sh` so that the `justfile` stays a dispatcher and every code path is reachable from the test suite. No behavior in the spec changes.

---

## File Structure

| File | Responsibility |
|---|---|
| `justfile` | Recipe dispatch and the `provider` variable. No logic. |
| `scripts/lib.sh` | Constants, path resolvers, `log`/`warn`/`die`/`have`, `link_into`, `links_into_repo`, swe-skills helpers. Sets no shell options. |
| `scripts/install-claude.sh` | Claude Code half of install. |
| `scripts/install-opencode.sh` | OpenCode half of install, delegating the config write to `merge-opencode.sh`. |
| `scripts/merge-opencode.sh` | The jq merge: comment guard, backup, merge, manifest. The only writer of `opencode.jsonc`. |
| `scripts/doctor.sh` | Read-only reporting. Always exits 0. |
| `scripts/update.sh` | Refresh skills/plugin/links in place using the recorded provider. |
| `scripts/uninstall.sh` | Remove this repo's symlinks and managed keys. |
| `agents/*.md` | The five canonical Claude Code subagent definitions. |
| `opencode/anthropic.json`, `opencode/openai.json` | Managed OpenCode keys, one file per provider. |
| `tests/run.sh` | Test discovery and reporting. |
| `tests/lib/assert.sh` | Assertion helpers. |
| `tests/lib/sandbox.sh` | Per-test temp `$HOME`, PATH stubs, swe-skills fixture. |
| `tests/test_*.sh` | One file per unit under test. |
| `README.md` | Usage. |

---

### Task 1: Test harness and shared library

**Files:**
- Create: `tests/run.sh`
- Create: `tests/lib/assert.sh`
- Create: `tests/lib/sandbox.sh`
- Create: `scripts/lib.sh`
- Test: `tests/test_lib.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/lib.sh` exporting `REPO_ROOT`; constants `SUPERPOWERS_PLUGIN`, `SUPERPOWERS_MARKETPLACE`, `SUPERPOWERS_CLAUDE_PLUGIN`, `SWE_SKILLS_REPO`; arrays `MANAGED_AGENTS`, `CLAUDE_AGENTS`, `SKILL_NAMES`; functions `log`, `warn`, `die`, `have`, `claude_dir`, `opencode_dir`, `swe_skills_dir`, `link_into SRC DEST`, `links_into_repo PATH`, `ensure_swe_skills`, `run_swe_skills_install TOOL`. Tests consume `tests/lib/sandbox.sh` providing `$SANDBOX`, a sandboxed `$HOME`, `stub_cmd NAME`, `stub_swe_skills`, and `tests/lib/assert.sh` providing `fail`, `assert_eq`, `assert_contains`, `assert_not_contains`, `assert_file`, `assert_symlink_to`, `assert_status`, and the counter `ASSERT_FAILURES`.

- [ ] **Step 1: Write the test runner**

Create `tests/run.sh`:

```bash
#!/usr/bin/env bash
# Discover and run every tests/test_*.sh. Exits non-zero if any file fails.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

total=0
failed=0

for t in "$REPO_ROOT"/tests/test_*.sh; do
    [ -e "$t" ] || continue
    total=$((total + 1))
    printf '%s\n' "$(basename "$t")"
    if bash "$t"; then
        printf '  ok\n'
    else
        printf '  FAILED\n'
        failed=$((failed + 1))
    fi
done

printf '\n%d/%d test files passed\n' "$((total - failed))" "$total"
[ "$failed" -eq 0 ]
```

Then `chmod +x tests/run.sh`.

- [ ] **Step 2: Write the assertion helpers**

Create `tests/lib/assert.sh`:

```bash
# Assertion helpers. Source after tests/lib/sandbox.sh has set up the sandbox.
# Each failure increments ASSERT_FAILURES; the test file exits with that count.

ASSERT_FAILURES=0

fail() {
    printf '  FAIL: %s\n' "$*" >&2
    ASSERT_FAILURES=$((ASSERT_FAILURES + 1))
}

assert_eq() {
    [ "$1" = "$2" ] || fail "${3:-values differ}: expected [$2], got [$1]"
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) fail "${3:-substring missing}: [$2] not found in [$1]" ;;
    esac
}

assert_not_contains() {
    case "$1" in
        *"$2"*) fail "${3:-unexpected substring}: [$2] found in [$1]" ;;
    esac
}

assert_file() {
    [ -f "$1" ] || fail "${2:-expected a file}: $1"
}

assert_symlink_to() {
    if [ ! -L "$1" ]; then
        fail "${3:-not a symlink}: $1"
        return
    fi
    local got want
    got=$(readlink -f "$1")
    want=$(readlink -f "$2")
    [ "$got" = "$want" ] || fail "${3:-wrong symlink target}: $1 -> $got, expected $want"
}

# assert_status EXPECTED CMD... — run CMD, compare its exit status.
assert_status() {
    local expected=$1
    shift
    local got=0
    "$@" >/dev/null 2>&1 || got=$?
    [ "$got" -eq "$expected" ] || fail "exit status: expected $expected, got $got from: $*"
}
```

- [ ] **Step 3: Write the sandbox helper**

Create `tests/lib/sandbox.sh`:

```bash
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
    local skip=$1 dir="$SANDBOX/without-$skip/bin" p base
    mkdir -p "$dir"
    for p in /usr/bin/* /bin/*; do
        [ -x "$p" ] || continue
        base=$(basename "$p")
        [ "$base" = "$skip" ] && continue
        ln -sfn "$p" "$dir/$base" 2>/dev/null || true
    done
    printf '%s\n' "$SANDBOX/bin:$dir"
}
```

- [ ] **Step 4: Write the failing test for lib.sh**

Create `tests/test_lib.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# --- path resolvers honour the sandbox ---
assert_eq "$(claude_dir)" "$HOME/.claude" "claude_dir"
assert_eq "$(opencode_dir)" "$XDG_CONFIG_HOME/opencode" "opencode_dir"
assert_eq "$(swe_skills_dir)" "$SWE_SKILLS_DIR" "swe_skills_dir"

# --- constants ---
assert_eq "$SUPERPOWERS_PLUGIN" \
    "superpowers@git+https://github.com/obra/superpowers.git" "plugin string"
assert_eq "${#MANAGED_AGENTS[@]}" 7 "managed agent count"
assert_eq "${#CLAUDE_AGENTS[@]}" 5 "claude agent count"
assert_eq "${#SKILL_NAMES[@]}" 8 "skill count"

# --- have ---
assert_status 0 have bash
assert_status 1 have definitely-not-a-real-command-xyz

# --- link_into creates a symlink ---
src="$SANDBOX/src.txt"
echo hello > "$src"
link_into "$src" "$HOME/nested/dest.txt"
assert_symlink_to "$HOME/nested/dest.txt" "$src" "link_into creates symlink"

# --- link_into backs up a real file it would clobber ---
real="$HOME/real.txt"
echo original > "$real"
link_into "$src" "$real" 2>/dev/null
assert_symlink_to "$real" "$src" "link_into replaced real file"
backups=$(find "$HOME" -maxdepth 1 -name 'real.txt.bak.*' | wc -l)
assert_eq "$backups" 1 "link_into wrote exactly one backup"
assert_eq "$(cat "$HOME"/real.txt.bak.*)" "original" "backup kept contents"

# --- link_into is idempotent ---
link_into "$src" "$real"
assert_symlink_to "$real" "$src" "link_into idempotent"
backups=$(find "$HOME" -maxdepth 1 -name 'real.txt.bak.*' | wc -l)
assert_eq "$backups" 1 "no second backup for an existing symlink"

# --- links_into_repo ---
ln -sfn "$REPO_ROOT/AGENTS.md" "$HOME/inrepo.md"
assert_status 0 links_into_repo "$HOME/inrepo.md"
assert_status 1 links_into_repo "$HOME/nested/dest.txt"
assert_status 1 links_into_repo "$HOME/does-not-exist"

# --- run_swe_skills_install drives the checkout's install.sh ---
stub_swe_skills
run_swe_skills_install claude
assert_symlink_to "$HOME/.claude/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "swe-skills claude link"
run_swe_skills_install opencode
assert_symlink_to "$XDG_CONFIG_HOME/opencode/skills/clean-coding" \
    "$SWE_SKILLS_DIR/book-skills/clean-coding" "swe-skills opencode link"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 5: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `tests/test_lib.sh` errors because `scripts/lib.sh` does not exist.

- [ ] **Step 6: Write scripts/lib.sh**

Create `scripts/lib.sh`:

```bash
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
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS — `1/1 test files passed`.

- [ ] **Step 8: Commit**

```bash
git add tests scripts/lib.sh
git commit -m "test: add sandboxed shell test harness and shared script library

Every path resolves through \$HOME so tests can install into a temp
directory instead of the real home."
```

---

### Task 2: Canonical subagent definitions

**Files:**
- Create: `agents/implementer-light.md`
- Create: `agents/implementer.md`
- Create: `agents/implementer-strong.md`
- Create: `agents/reviewer.md`
- Create: `agents/reviewer-lite.md`
- Test: `tests/test_agents.sh`

**Interfaces:**
- Consumes: `CLAUDE_AGENTS` from `scripts/lib.sh`.
- Produces: five files whose YAML frontmatter `name` equals the filename stem. Task 7 symlinks these into `$(claude_dir)/agents/`.

These carry the Anthropic ladder fixed: `haiku`/`sonnet`/`fable` with `low`/`medium`/`high` effort. The `reviewer` pair keeps the read-only `tools` restriction, which is what enforces that review dispatches cannot write files.

- [ ] **Step 1: Write the failing test**

Create `tests/test_agents.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# frontmatter_field FILE KEY — first-level YAML scalar out of the frontmatter.
frontmatter_field() {
    awk -v key="$2" '
        NR == 1 && $0 == "---" { inside = 1; next }
        inside && $0 == "---"  { exit }
        inside {
            split($0, kv, ": ")
            if (kv[1] == key) { sub("^" key ": ", ""); print; exit }
        }
    ' "$1"
}

for a in "${CLAUDE_AGENTS[@]}"; do
    f="$REPO_ROOT/agents/$a.md"
    assert_file "$f" "agent definition exists"
    [ -f "$f" ] || continue

    assert_eq "$(head -n1 "$f")" "---" "$a starts with frontmatter"
    assert_eq "$(frontmatter_field "$f" name)" "$a" "$a name matches filename"

    desc=$(frontmatter_field "$f" description)
    [ -n "$desc" ] || fail "$a has no description"

    model=$(frontmatter_field "$f" model)
    case "$model" in
        haiku|sonnet|fable) ;;
        *) fail "$a model must be haiku, sonnet, or fable; got [$model]" ;;
    esac

    effort=$(frontmatter_field "$f" effort)
    case "$effort" in
        low|medium|high) ;;
        *) fail "$a effort must be low, medium, or high; got [$effort]" ;;
    esac

    # A body prompt after the closing --- is required.
    # Print every line that follows the second "---" delimiter.
    body=$(awk 'seen >= 2 { print } /^---$/ { seen++ }' "$f")
    [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] \
        || fail "$a has an empty body prompt"
done

# The two reviewers must be read-only.
for a in reviewer reviewer-lite; do
    tools=$(frontmatter_field "$REPO_ROOT/agents/$a.md" tools)
    assert_eq "$tools" "Read, Grep, Glob, Bash" "$a is read-only"
done

# The strong tier must outrank the default tier.
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer-strong.md" model)" \
    fable "implementer-strong uses fable"
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer-light.md" model)" \
    haiku "implementer-light uses haiku"

# The old misnamed file must not come back.
[ -e "$REPO_ROOT/agents/reviewer-light.md" ] && fail "reviewer-light.md should be reviewer-lite.md"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `agents/*.md` do not exist.

- [ ] **Step 3: Write the five agent files**

Create `agents/implementer-light.md`:

```markdown
---
name: implementer-light
description: Implements a single mechanical, fully-specified plan task - isolated functions, clear spec, 1-2 files. Do NOT use for multi-file work, debugging, or judgment.
model: haiku
effort: low
---
Implement the dispatched task exactly as specified. Follow the plan
task's spec and TDD process. Report status per the dispatch prompt's
status protocol. If the task turns out to require judgment or
multi-file changes, report BLOCKED rather than improvising.
```

Create `agents/implementer.md`:

```markdown
---
name: implementer
description: Default implementer for plan tasks - multi-file coordination, integration, debugging, prose-specified tasks. Writes tests per TDD.
model: sonnet
effort: medium
---
Implement the dispatched task per its spec and TDD process. Report
status per the dispatch prompt's status protocol.
```

Create `agents/implementer-strong.md`:

```markdown
---
name: implementer-strong
description: Escalation implementer for BLOCKED tasks, fix rounds 4+, or tasks needing design judgment or broad codebase understanding.
model: fable
effort: high
---
You are dispatched because a prior attempt stalled or the task needs
design judgment. Read the prior attempt's report if provided before
starting. Implement per the dispatch prompt and report status per its
status protocol.
```

Create `agents/reviewer.md`:

```markdown
---
name: reviewer
description: Spec-compliance and code-quality review of diffs, plus final whole-branch review. Read-only - never writes files.
tools: Read, Grep, Glob, Bash
model: fable
effort: high
---
Review strictly per the dispatched review prompt (spec compliance,
code quality, or whole-branch). Never modify files. Bash is for
running the review package script and tests only.
```

Create `agents/reviewer-lite.md`:

```markdown
---
name: reviewer-lite
description: Scoped re-review of small fix diffs only, after a full review has already passed. Read-only. Not for first-pass or final branch reviews.
tools: Read, Grep, Glob, Bash
model: sonnet
effort: medium
---
Re-review only the scoped fix diff against the specific findings it
addresses. Never modify files.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS — `2/2 test files passed`.

- [ ] **Step 5: Commit**

```bash
git add agents tests/test_agents.sh
git commit -m "feat: add canonical subagent role definitions

Fixes the filename/name mismatch in the previous reviewer-light.md,
which declared name: reviewer-lite."
```

---

### Task 3: Verify OpenCode variant behavior

**Files:**
- Create: `docs/verification/opencode-variant.md`

**Interfaces:**
- Consumes: nothing.
- Produces: a recorded verdict — either `variant` is confirmed usable (Task 4 proceeds as designed) or it is not (Task 4 falls back to per-provider raw `options` blocks).

The spec makes this a blocking gate. The design rests on a claim read out of the compiled OpenCode bundle rather than published docs: that OpenCode synthesizes model variants from `models.dev` `reasoning_options` and maps them per provider SDK, so `agent.<name>.variant` is the provider-agnostic effort lever while `agent.<name>.options.reasoningEffort` is OpenAI-only.

**Do not skip this task and do not let a check "pass" by assumption.** If a check cannot be run, record that it could not be run — do not record it as passing.

- [ ] **Step 1: Confirm the CLI exposes a variant flag**

Run: `opencode run --help 2>&1 | grep -i -A1 variant`
Expected: a `--variant` option described as a provider-specific reasoning effort, with examples such as `high`, `max`, `minimal`.

Record the exact output.

- [ ] **Step 2: Confirm the effort levels models.dev advertises**

Run:

```bash
curl -fsSL https://models.dev/api.json \
  | jq '.anthropic.models
        | {"claude-sonnet-5", "claude-fable-5", "claude-haiku-4-5"}
        | map_values(.reasoning_options)'
```

Expected: `claude-sonnet-5` and `claude-fable-5` each carry `{"type":"effort","values":["low","medium","high","xhigh","max"]}`; `claude-haiku-4-5` carries `{"type":"budget_tokens","min":1024}` and **no** effort list.

Record the output. This is the evidence for the Haiku constraint in the spec.

- [ ] **Step 3: Confirm a valid variant is accepted on an Anthropic model**

Requires Anthropic credentials configured in OpenCode. Run:

```bash
opencode run --model anthropic/claude-sonnet-5 --variant medium \
  'Reply with the single word: ok' 2>&1 | tail -20
```

Expected: a normal completion, no error mentioning an unknown or invalid variant.

If OpenCode has no Anthropic credentials, skip to Step 5 and record this check as **not run**.

- [ ] **Step 4: Confirm an unavailable variant is rejected on Haiku**

Run:

```bash
opencode run --model anthropic/claude-haiku-4-5 --variant medium \
  'Reply with the single word: ok' 2>&1 | tail -20
```

Expected: an error or warning naming the variant, because Haiku exposes only `high` and `max`. A silent success here would mean variants are not actually enumerated per model, which weakens the design.

- [ ] **Step 5: Confirm the OpenAI side is equivalent to the current live config**

This check needs no Anthropic credentials and is the fallback evidence path. Run:

```bash
opencode run --model openai/gpt-5.6-terra --variant medium \
  'Reply with the single word: ok' 2>&1 | tail -20
```

Expected: a normal completion, matching the behavior of the existing
`options: { reasoningEffort: "medium" }` configuration.

- [ ] **Step 6: Record the verdict**

Create `docs/verification/opencode-variant.md` containing: the date, the OpenCode version (`opencode --version`), each step's command and actual output, and one of two explicit verdicts.

Use this template, filling in real output — do not leave any bracket unreplaced:

````markdown
# Verification: OpenCode `variant` as a provider-agnostic effort lever

Date: <YYYY-MM-DD>
OpenCode version: <output of `opencode --version`>

## Claim under test

OpenCode synthesizes a model variant per reasoning-effort level from
models.dev metadata and maps each to provider-specific parameters:

| Provider SDK | Generated parameters |
|---|---|
| `@ai-sdk/openai` | `{ reasoningEffort, reasoningSummary: "auto", include: [...] }` |
| `@ai-sdk/anthropic` | `{ thinking: { type: "adaptive" }, effort }` |

If true, `agent.<name>.variant` works across both providers where
`agent.<name>.options.reasoningEffort` works only for OpenAI.

## Checks

### 1. CLI exposes --variant
Command: `opencode run --help 2>&1 | grep -i -A1 variant`
Result: <PASS | FAIL | NOT RUN>
Output:
```
<paste>
```

### 2. models.dev effort levels
Command: <the curl | jq from Step 2>
Result: <PASS | FAIL | NOT RUN>
Output:
```
<paste>
```

### 3. Valid variant accepted on an Anthropic model
Result: <PASS | FAIL | NOT RUN — reason>
Output:
```
<paste>
```

### 4. Unavailable variant rejected on Haiku
Result: <PASS | FAIL | NOT RUN — reason>
Output:
```
<paste>
```

### 5. OpenAI variant equivalent to reasoningEffort
Result: <PASS | FAIL | NOT RUN — reason>
Output:
```
<paste>
```

## Verdict

<CONFIRMED — use `variant` in both provider files, as designed.>
<or>
<NOT CONFIRMED — <what failed>. Fall back to per-provider raw `options`
blocks: `options: { reasoningEffort: <level> }` for OpenAI and
`options: { thinking: { type: "adaptive" }, effort: <level> }` for
Anthropic. The two provider files then differ in shape, not only in values.>
````

- [ ] **Step 7: Commit**

```bash
git add docs/verification/opencode-variant.md
git commit -m "docs: record OpenCode variant verification

Gates the provider config shape. The design's use of agent.<name>.variant
came from the compiled bundle, not published docs."
```

**Gate:** if the verdict is NOT CONFIRMED, stop and report to the human before starting Task 4. The fallback changes the shape of both provider files.

---

### Task 4: Provider config files

**Files:**
- Create: `opencode/anthropic.json`
- Create: `opencode/openai.json`
- Test: `tests/test_provider_configs.sh`

**Interfaces:**
- Consumes: the Task 3 verdict; `MANAGED_AGENTS` and `SUPERPOWERS_PLUGIN` from `scripts/lib.sh`.
- Produces: two JSON files, each with an `agent` object keyed by all seven managed agent names and a `plugin` array containing `SUPERPOWERS_PLUGIN`. `opencode/openai.json` additionally has `provider.openai.options.store = false`. Task 5 merges whichever file is selected.

If Task 3's verdict was NOT CONFIRMED, replace every `"variant": "<level>"` below with the fallback `options` object recorded in the verification doc, and update the test's variant assertions to match. Everything else in this task is unchanged.

- [ ] **Step 1: Write the failing test**

Create `tests/test_provider_configs.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

for p in anthropic openai; do
    f="$REPO_ROOT/opencode/$p.json"
    assert_file "$f" "$p config exists"
    [ -f "$f" ] || continue

    jq -e . "$f" >/dev/null 2>&1 || fail "$p config is not valid JSON"

    # Every managed agent is present with a model.
    for a in "${MANAGED_AGENTS[@]}"; do
        model=$(jq -r --arg a "$a" '.agent[$a].model // ""' "$f")
        [ -n "$model" ] || fail "$p config missing model for agent $a"
        assert_contains "$model" "$p/" "$p agent $a uses the $p provider"
    done

    # No extra agents beyond the managed set.
    count=$(jq '.agent | length' "$f")
    assert_eq "$count" "${#MANAGED_AGENTS[@]}" "$p config agent count"

    # The superpowers plugin is declared.
    assert_eq "$(jq -r --arg p "$SUPERPOWERS_PLUGIN" \
        '(.plugin // []) | index($p) != null' "$f")" \
        "true" "$p config declares the superpowers plugin"

    # Effort is expressed as a variant, never as options.reasoningEffort.
    assert_eq "$(jq '[.agent[] | select(.options.reasoningEffort)] | length' "$f")" \
        0 "$p config uses variant, not options.reasoningEffort"

    # Subagents declare mode and description; primaries do not need to.
    for a in implementer-light implementer implementer-strong reviewer reviewer-lite; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].mode' "$f")" \
            "subagent" "$p agent $a is a subagent"
        desc=$(jq -r --arg a "$a" '.agent[$a].description // ""' "$f")
        [ -n "$desc" ] || fail "$p agent $a has no description"
    done

    # Reviewers are read-only.
    for a in reviewer reviewer-lite; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].permission.edit' "$f")" \
            "deny" "$p agent $a denies edit"
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].permission.bash' "$f")" \
            "ask" "$p agent $a gates bash"
    done
done

# --- Anthropic specifics ---
a="$REPO_ROOT/opencode/anthropic.json"
assert_eq "$(jq -r '.agent["implementer-strong"].model' "$a")" \
    "anthropic/claude-fable-5" "anthropic strong tier"
assert_eq "$(jq -r '.agent.reviewer.model' "$a")" \
    "anthropic/claude-fable-5" "anthropic reviewer tier"
assert_eq "$(jq -r '.agent["implementer-light"].model' "$a")" \
    "anthropic/claude-haiku-4-5" "anthropic light tier"
# Haiku exposes only high/max, so implementer-light carries no variant at all.
assert_eq "$(jq -r '.agent["implementer-light"] | has("variant")' "$a")" \
    "false" "haiku implementer-light has no variant"
assert_eq "$(jq -r '.agent.explore.variant' "$a")" \
    "high" "haiku explore uses the nearest available rung"
# No provider block is needed for Anthropic.
assert_eq "$(jq -r 'has("provider")' "$a")" "false" "anthropic config has no provider block"

# --- OpenAI specifics ---
o="$REPO_ROOT/opencode/openai.json"
assert_eq "$(jq -r '.agent["implementer-strong"].model' "$o")" \
    "openai/gpt-5.6-sol" "openai strong tier"
assert_eq "$(jq -r '.agent["implementer-light"].variant' "$o")" \
    "low" "openai light tier variant"
assert_eq "$(jq -r '.provider.openai.options.store' "$o")" \
    "false" "openai config keeps store: false"
# reasoningSummary and include are covered by the generated variant.
assert_eq "$(jq -r '.provider.openai.options | has("reasoningSummary")' "$o")" \
    "false" "openai config drops reasoningSummary"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `opencode/anthropic.json` and `opencode/openai.json` do not exist.

- [ ] **Step 3: Write the Anthropic config**

Create `opencode/anthropic.json`:

```json
{
  "agent": {
    "general": {
      "model": "anthropic/claude-sonnet-5",
      "variant": "medium"
    },
    "explore": {
      "model": "anthropic/claude-haiku-4-5",
      "variant": "high"
    },
    "implementer-light": {
      "mode": "subagent",
      "description": "Implements a single mechanical, fully-specified plan task: isolated functions, clear spec, 1-2 files. Do NOT use for multi-file work, debugging, or judgment.",
      "model": "anthropic/claude-haiku-4-5"
    },
    "implementer": {
      "mode": "subagent",
      "description": "Default implementer: multi-file coordination, integration, debugging, prose-specified tasks. Writes tests per TDD.",
      "model": "anthropic/claude-sonnet-5",
      "variant": "medium"
    },
    "implementer-strong": {
      "mode": "subagent",
      "description": "Escalation implementer for BLOCKED tasks, fix rounds 4+, or tasks needing design judgment or broad codebase understanding.",
      "model": "anthropic/claude-fable-5",
      "variant": "high"
    },
    "reviewer": {
      "mode": "subagent",
      "description": "Spec-compliance and code-quality review of diffs, plus final whole-branch review. Read-only.",
      "model": "anthropic/claude-fable-5",
      "variant": "high",
      "permission": { "edit": "deny", "bash": "ask" }
    },
    "reviewer-lite": {
      "mode": "subagent",
      "description": "Scoped re-review of small fix diffs only, after a full review passed. Read-only.",
      "model": "anthropic/claude-sonnet-5",
      "variant": "medium",
      "permission": { "edit": "deny", "bash": "ask" }
    }
  },
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

- [ ] **Step 4: Write the OpenAI config**

Create `opencode/openai.json`:

```json
{
  "provider": {
    "openai": {
      "options": {
        "store": false
      }
    }
  },
  "agent": {
    "general": {
      "model": "openai/gpt-5.6-terra",
      "variant": "medium"
    },
    "explore": {
      "model": "openai/gpt-5.6-luna",
      "variant": "medium"
    },
    "implementer-light": {
      "mode": "subagent",
      "description": "Implements a single mechanical, fully-specified plan task: isolated functions, clear spec, 1-2 files. Do NOT use for multi-file work, debugging, or judgment.",
      "model": "openai/gpt-5.6-luna",
      "variant": "low"
    },
    "implementer": {
      "mode": "subagent",
      "description": "Default implementer: multi-file coordination, integration, debugging, prose-specified tasks. Writes tests per TDD.",
      "model": "openai/gpt-5.6-terra",
      "variant": "medium"
    },
    "implementer-strong": {
      "mode": "subagent",
      "description": "Escalation implementer for BLOCKED tasks, fix rounds 4+, or tasks needing design judgment or broad codebase understanding.",
      "model": "openai/gpt-5.6-sol",
      "variant": "high"
    },
    "reviewer": {
      "mode": "subagent",
      "description": "Spec-compliance and code-quality review of diffs, plus final whole-branch review. Read-only.",
      "model": "openai/gpt-5.6-sol",
      "variant": "high",
      "permission": { "edit": "deny", "bash": "ask" }
    },
    "reviewer-lite": {
      "mode": "subagent",
      "description": "Scoped re-review of small fix diffs only, after a full review passed. Read-only.",
      "model": "openai/gpt-5.6-terra",
      "variant": "medium",
      "permission": { "edit": "deny", "bash": "ask" }
    }
  },
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS — `3/3 test files passed`.

- [ ] **Step 6: Commit**

```bash
git add opencode tests/test_provider_configs.sh
git commit -m "feat: add Anthropic and OpenAI OpenCode model ladders

Effort is expressed as agent.<name>.variant, which OpenCode maps to
provider-specific parameters, so one config shape serves both providers."
```

---

### Task 5: The OpenCode merge

**Files:**
- Create: `scripts/merge-opencode.sh`
- Test: `tests/test_merge_opencode.sh`

**Interfaces:**
- Consumes: `opencode/<provider>.json`; `opencode_dir`, `MANAGED_AGENTS`, `SUPERPOWERS_PLUGIN`, `log`, `warn`, `die`, `have` from `scripts/lib.sh`.
- Produces: `scripts/merge-opencode.sh <provider>` — exit 0 merged, 1 error, **2 comment guard tripped with nothing written**. Writes `$(opencode_dir)/opencode.jsonc` and the manifest `$(opencode_dir)/.agentic-swe-setup.json` with shape `{provider, backup, agents: [...], plugin, provider_key}`. Task 7 calls it; Task 8's `uninstall.sh` reads the manifest.

- [ ] **Step 1: Write the failing test**

Create `tests/test_merge_opencode.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

MERGE="$REPO_ROOT/scripts/merge-opencode.sh"
CFG="$(opencode_dir)/opencode.jsonc"
MAN="$(opencode_dir)/.agentic-swe-setup.json"
mkdir -p "$(opencode_dir)"

# --- creates a config from nothing ---
"$MERGE" anthropic >/dev/null 2>&1 || fail "merge failed on a fresh install"
assert_file "$CFG" "merge created the config"
assert_eq "$(jq -r '."$schema"' "$CFG")" \
    "https://opencode.ai/config.json" "schema key present"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "anthropic/claude-fable-5" "anthropic reviewer merged"
assert_eq "$(jq -r --arg p "$SUPERPOWERS_PLUGIN" \
    '(.plugin // []) | index($p) != null' "$CFG")" "true" "plugin merged"
assert_file "$MAN" "manifest written"
assert_eq "$(jq -r .provider "$MAN")" "anthropic" "manifest records provider"

# --- preserves unmanaged keys ---
cat > "$CFG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "tokyonight",
  "agent": { "my-own-agent": { "model": "openai/gpt-5.6-luna" } },
  "plugin": ["some-other-plugin@1.0.0"],
  "mcp": { "fetch": { "type": "local", "command": ["uvx", "mcp-server-fetch"] } }
}
EOF
"$MERGE" anthropic >/dev/null 2>&1 || fail "merge failed over an existing config"
assert_eq "$(jq -r '.theme' "$CFG")" "tokyonight" "unmanaged top-level key kept"
assert_eq "$(jq -r '.agent["my-own-agent"].model' "$CFG")" \
    "openai/gpt-5.6-luna" "unmanaged agent kept"
assert_eq "$(jq -r '.mcp.fetch.type' "$CFG")" "local" "mcp block kept"
assert_eq "$(jq -r '.plugin | index("some-other-plugin@1.0.0") != null' "$CFG")" \
    "true" "other plugin kept"
assert_eq "$(jq -r '.agent | length' "$CFG")" "8" "7 managed + 1 unmanaged agent"

# --- plugin is appended, not duplicated ---
"$MERGE" anthropic >/dev/null 2>&1
assert_eq "$(jq -r --arg p "$SUPERPOWERS_PLUGIN" \
    '[.plugin[] | select(. == $p)] | length' "$CFG")" "1" "plugin not duplicated"

# --- a backup is written for every merge over an existing file ---
before=$(find "$(opencode_dir)" -maxdepth 1 -name 'opencode.jsonc.bak.*' | wc -l)
[ "$before" -ge 1 ] || fail "no backup written"

# --- provider switch: openai adds the provider block ---
"$MERGE" openai >/dev/null 2>&1 || fail "merge failed for openai"
assert_eq "$(jq -r '.provider.openai.options.store' "$CFG")" \
    "false" "openai provider block added"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-sol" "openai reviewer merged"

# --- provider switch back: the openai block is removed, others survive ---
jq '.provider.anthropic = {"options": {"timeout": 60000}}' "$CFG" > "$CFG.tmp" \
    && mv "$CFG.tmp" "$CFG"
"$MERGE" anthropic >/dev/null 2>&1 || fail "merge failed switching back"
assert_eq "$(jq -r '.provider | has("openai")' "$CFG")" \
    "false" "openai provider block removed on switch"
assert_eq "$(jq -r '.provider.anthropic.options.timeout' "$CFG")" \
    "60000" "unmanaged provider entry survived"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "anthropic/claude-fable-5" "agents switched back"
# No stale OpenAI model strings anywhere in the managed agents.
for a in "${MANAGED_AGENTS[@]}"; do
    m=$(jq -r --arg a "$a" '.agent[$a].model' "$CFG")
    assert_not_contains "$m" "openai/" "agent $a has no stale openai model"
done

# --- provider object disappears entirely when nothing is left in it ---
cat > "$CFG" <<'EOF'
{"$schema": "https://opencode.ai/config.json",
 "provider": {"openai": {"options": {"store": false}}}}
EOF
"$MERGE" anthropic >/dev/null 2>&1
assert_eq "$(jq -r 'has("provider")' "$CFG")" \
    "false" "empty provider object deleted"

# --- comment guard: refuse, exit 2, change nothing ---
cat > "$CFG" <<'EOF'
{
  // my carefully annotated config
  "theme": "tokyonight"
}
EOF
sum_before=$(cksum < "$CFG")
assert_status 2 "$MERGE" anthropic
assert_eq "$(cksum < "$CFG")" "$sum_before" "comment guard left the file untouched"

# The guard must print the keys to add by hand.
guard_out=$("$MERGE" anthropic 2>&1)
assert_contains "$guard_out" "implementer-strong" "guard printed the managed keys"

# --- unknown provider is an error, not a silent no-op ---
rm -f "$CFG"
assert_status 1 "$MERGE" not-a-provider

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `scripts/merge-opencode.sh` does not exist.

- [ ] **Step 3: Write the merge script**

Create `scripts/merge-opencode.sh`:

```bash
#!/usr/bin/env bash
# Merge this repo's managed keys into the user's opencode.jsonc.
#
# Usage: merge-opencode.sh <provider>
# Exit:  0 merged
#        1 error
#        2 target is not strict JSON (JSONC comments) — nothing was written

set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

provider=${1:-}
[ -n "$provider" ] || die "usage: merge-opencode.sh <provider>"

src="$REPO_ROOT/opencode/$provider.json"
[ -f "$src" ] || die "unknown provider '$provider' (no $src)"
have jq || die "jq is required to merge opencode.jsonc"

dir=$(opencode_dir)
target="$dir/opencode.jsonc"
manifest="$dir/.agentic-swe-setup.json"
schema="https://opencode.ai/config.json"
mkdir -p "$dir"

backup=""
if [ -f "$target" ]; then
    if ! jq -e . "$target" >/dev/null 2>&1; then
        warn "$target is not strict JSON (JSONC comments?); refusing to rewrite it"
        {
            printf '\nAdd these keys to %s by hand, then re-run:\n\n' "$target"
            jq -S . "$src"
            printf '\n'
        } >&2
        exit 2
    fi
    backup="$target.bak.$(date +%s)"
    cp "$target" "$backup"
    log "backed up $target to $backup"
else
    printf '{"$schema":"%s"}\n' "$schema" > "$target"
fi

tmp=$(mktemp)
jq -n \
    --argjson base "$(cat "$target")" \
    --argjson mgd "$(cat "$src")" \
    --arg schema "$schema" '
      ($mgd.agent    // {}) as $agents
    | ($mgd.provider // {}) as $prov
    | ($mgd.plugin   // []) as $plugins
    | $base
    | .["$schema"] = (.["$schema"] // $schema)
    # Object + is right-biased, so each managed agent key is replaced
    # wholesale while unmanaged agents survive untouched.
    | .agent = ((.agent // {}) + $agents)
    # Append-and-dedupe, preserving any existing plugin order.
    | .plugin = ((.plugin // []) + ($plugins - (.plugin // [])))
    | if ($prov | length) > 0
      then .provider = ((.provider // {}) + $prov)
      else (if has("provider") then .provider |= del(.openai) else . end)
      end
    | if (.provider? == {}) then del(.provider) else . end
    ' > "$tmp"

mv "$tmp" "$target"

printf '%s\n' "${MANAGED_AGENTS[@]}" \
    | jq -R . \
    | jq -s \
        --arg provider "$provider" \
        --arg backup "$backup" \
        --arg plugin "$SUPERPOWERS_PLUGIN" \
        '{provider: $provider,
          backup: $backup,
          agents: .,
          plugin: $plugin,
          provider_key: "provider.openai"}' \
    > "$manifest"

log "merged $provider config into $target"
```

Then `chmod +x scripts/merge-opencode.sh`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS — `4/4 test files passed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/merge-opencode.sh tests/test_merge_opencode.sh
git commit -m "feat: merge managed keys into opencode.jsonc

Owns a fixed key set only. Refuses to rewrite a file with JSONC comments
rather than stripping them, since jq cannot round-trip comments."
```

---

### Task 6: The doctor report

**Files:**
- Create: `scripts/doctor.sh`
- Test: `tests/test_doctor.sh`

**Interfaces:**
- Consumes: everything in `scripts/lib.sh`; the manifest written by `merge-opencode.sh`.
- Produces: `scripts/doctor.sh` — prints one line per check prefixed `[ok]`, `[warn]`, or `[skip]`, and always exits 0. Task 7's `install` recipe calls it as a summary.

- [ ] **Step 1: Write the failing test**

Create `tests/test_doctor.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

DOCTOR="$REPO_ROOT/scripts/doctor.sh"

# --- with neither harness present it still exits 0 and says so ---
out=$("$DOCTOR" 2>&1); status=$?
assert_eq "$status" 0 "doctor exits 0 with nothing installed"
assert_contains "$out" "[skip] claude not installed" "skips absent claude"
assert_contains "$out" "[skip] opencode not installed" "skips absent opencode"
assert_contains "$out" "[warn]" "warns about something"

# --- doctor never writes ---
before=$(find "$HOME" | sort | cksum)
"$DOCTOR" >/dev/null 2>&1
assert_eq "$(find "$HOME" | sort | cksum)" "$before" "doctor changed nothing"

# --- a fully installed sandbox reports green ---
stub_cmd_output claude "superpowers@claude-plugins-official  6.2.0  enabled"
stub_cmd opencode
stub_cmd git
stub_swe_skills

bash "$REPO_ROOT/scripts/install-claude.sh"   >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-opencode.sh" anthropic >/dev/null 2>&1

out=$("$DOCTOR" 2>&1)
assert_contains "$out" "[ok]   superpowers plugin installed" "claude plugin ok"
assert_contains "$out" "[ok]   agent reviewer-lite" "claude agent ok"
assert_contains "$out" "[ok]   global CLAUDE.md linked" "claude memory ok"
assert_contains "$out" "[ok]   provider: anthropic" "opencode provider ok"
assert_contains "$out" "[ok]   global AGENTS.md linked" "opencode instructions ok"
assert_not_contains "$out" "[warn] agent reviewer" "no agent warnings"

# --- a link that points somewhere else is reported, not silently accepted ---
ln -sfn /etc/hostname "$(claude_dir)/CLAUDE.md"
out=$("$DOCTOR" 2>&1)
assert_contains "$out" "[warn] global CLAUDE.md not linked from this repo" \
    "foreign symlink flagged"

exit "$ASSERT_FAILURES"
```

Note this test depends on Task 7's install scripts. Implement Task 6 and Task 7 in order, then run the suite; if executing Task 6 alone, expect `test_doctor.sh` to fail on the "fully installed" block until Task 7 lands.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `scripts/doctor.sh` does not exist.

- [ ] **Step 3: Write the doctor script**

Create `scripts/doctor.sh`:

```bash
#!/usr/bin/env bash
# Report what is and is not installed. Read-only; always exits 0.
#
# Note: no `set -e`. Every check must run even when an earlier one fails.
set -uo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ok()   { printf '[ok]   %s\n' "$*"; }
bad()  { printf '[warn] %s\n' "$*"; }
skip() { printf '[skip] %s\n' "$*"; }

printf 'tooling\n'
for c in claude opencode git jq; do
    if have "$c"; then ok "$c on PATH"; else bad "$c not on PATH"; fi
done

printf '\nshared\n'
if [ -d "$(swe_skills_dir)/.git" ]; then
    ok "swe-skills checkout at $(swe_skills_dir)"
else
    bad "no swe-skills checkout at $(swe_skills_dir)"
fi

printf '\nclaude code\n'
if have claude; then
    if claude plugin list 2>/dev/null | grep -q superpowers; then
        ok "superpowers plugin installed"
    else
        bad "superpowers plugin not installed"
    fi
    for s in "${SKILL_NAMES[@]}"; do
        if [ -e "$(claude_dir)/skills/$s" ]; then ok "skill $s"
        else bad "skill $s missing"; fi
    done
    for a in "${CLAUDE_AGENTS[@]}"; do
        if links_into_repo "$(claude_dir)/agents/$a.md"; then ok "agent $a"
        else bad "agent $a not linked from this repo"; fi
    done
    if links_into_repo "$(claude_dir)/CLAUDE.md"; then
        ok "global CLAUDE.md linked"
    else
        bad "global CLAUDE.md not linked from this repo"
    fi
else
    skip "claude not installed"
fi

printf '\nopencode\n'
if have opencode; then
    cfg="$(opencode_dir)/opencode.jsonc"
    man="$(opencode_dir)/.agentic-swe-setup.json"
    if have jq && [ -f "$man" ]; then
        ok "provider: $(jq -r .provider "$man")"
    else
        bad "no install manifest at $man"
    fi
    if have jq && [ -f "$cfg" ] \
        && jq -e --arg p "$SUPERPOWERS_PLUGIN" \
            '(.plugin // []) | index($p)' "$cfg" >/dev/null 2>&1; then
        ok "superpowers plugin configured"
    else
        bad "superpowers plugin not in $cfg"
    fi
    for a in "${MANAGED_AGENTS[@]}"; do
        if have jq && [ -f "$cfg" ] \
            && jq -e --arg a "$a" '.agent[$a]' "$cfg" >/dev/null 2>&1; then
            ok "agent $a"
        else
            bad "agent $a missing from $cfg"
        fi
    done
    for s in "${SKILL_NAMES[@]}"; do
        if [ -e "$(opencode_dir)/skills/$s" ]; then ok "skill $s"
        else bad "skill $s missing"; fi
    done
    if links_into_repo "$(opencode_dir)/AGENTS.md"; then
        ok "global AGENTS.md linked"
    else
        bad "global AGENTS.md not linked from this repo"
    fi
else
    skip "opencode not installed"
fi

exit 0
```

Then `chmod +x scripts/doctor.sh`.

- [ ] **Step 4: Run the test to verify the first half passes**

Run: `bash tests/test_doctor.sh; echo "failures: $?"`
Expected: the "nothing installed" and "changed nothing" assertions pass; the "fully installed" assertions fail until Task 7 lands.

- [ ] **Step 5: Commit**

```bash
git add scripts/doctor.sh tests/test_doctor.sh
git commit -m "feat: add read-only doctor report"
```

---

### Task 7: Install recipes

**Files:**
- Create: `scripts/install-claude.sh`
- Create: `scripts/install-opencode.sh`
- Create: `justfile`
- Test: `tests/test_install.sh`

**Interfaces:**
- Consumes: `scripts/lib.sh`, `scripts/merge-opencode.sh`, `agents/*.md`, `opencode/*.json`, `AGENTS.md`.
- Produces: `scripts/install-claude.sh` (no arguments) and `scripts/install-opencode.sh <provider>` (default `anthropic`). Both exit 0 when their harness is absent. Task 8's `update.sh` reuses both.

`install-opencode.sh` runs the merge **first** so a tripped comment guard aborts before anything else is touched.

- [ ] **Step 1: Write the failing test**

Create `tests/test_install.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

IC="$REPO_ROOT/scripts/install-claude.sh"
IO="$REPO_ROOT/scripts/install-opencode.sh"

# --- absent harnesses: warn, skip, exit 0 ---
out=$("$IC" 2>&1); assert_eq "$?" 0 "install-claude exits 0 without claude"
assert_contains "$out" "claude not on PATH" "warned about missing claude"
out=$("$IO" 2>&1); assert_eq "$?" 0 "install-opencode exits 0 without opencode"
assert_contains "$out" "opencode not on PATH" "warned about missing opencode"
[ -e "$(claude_dir)/CLAUDE.md" ] && fail "install-claude wrote despite no claude"

# --- missing jq: warn and skip the OpenCode half, still exit 0 ---
stub_cmd opencode
out=$(PATH="$(path_without jq)" "$IO" 2>&1)
assert_eq "$?" 0 "install-opencode exits 0 without jq"
assert_contains "$out" "jq not on PATH" "warned about missing jq"
[ -e "$(opencode_dir)/opencode.jsonc" ] && fail "wrote a config without jq"
rm -f "$SANDBOX/bin/opencode"

# --- missing git: fatal, because the skills install cannot proceed ---
stub_cmd claude
assert_status 1 env "PATH=$(path_without git)" "$IC"
rm -f "$SANDBOX/bin/claude"

# --- claude install ---
stub_cmd claude
stub_cmd git
stub_swe_skills
"$IC" >/dev/null 2>&1 || fail "install-claude failed"

for a in "${CLAUDE_AGENTS[@]}"; do
    assert_symlink_to "$(claude_dir)/agents/$a.md" \
        "$REPO_ROOT/agents/$a.md" "agent $a linked"
done
assert_symlink_to "$(claude_dir)/CLAUDE.md" \
    "$REPO_ROOT/AGENTS.md" "global CLAUDE.md linked"
assert_symlink_to "$(claude_dir)/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "skills installed for claude"

log_out=$(cat "$SANDBOX/claude.log")
assert_contains "$log_out" "plugin marketplace add anthropics/claude-plugins-official" \
    "marketplace added"
assert_contains "$log_out" "plugin install superpowers@claude-plugins-official" \
    "plugin installed"

# `general` and `explore` are built in to Claude Code; do not install them.
[ -e "$(claude_dir)/agents/general.md" ] && fail "general.md should not be installed"
[ -e "$(claude_dir)/agents/explore.md" ] && fail "explore.md should not be installed"

# --- claude install is idempotent ---
"$IC" >/dev/null 2>&1 || fail "second install-claude failed"
assert_symlink_to "$(claude_dir)/agents/reviewer.md" \
    "$REPO_ROOT/agents/reviewer.md" "agent still linked after re-run"
n=$(find "$(claude_dir)" -name 'CLAUDE.md.bak.*' | wc -l)
assert_eq "$n" 0 "no spurious backup on re-run"

# --- opencode install, default provider ---
stub_cmd opencode
"$IO" >/dev/null 2>&1 || fail "install-opencode failed"
CFG="$(opencode_dir)/opencode.jsonc"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "anthropic/claude-fable-5" "default provider is anthropic"
assert_symlink_to "$(opencode_dir)/AGENTS.md" \
    "$REPO_ROOT/AGENTS.md" "global AGENTS.md linked"
assert_symlink_to "$(opencode_dir)/skills/clean-coding" \
    "$SWE_SKILLS_DIR/book-skills/clean-coding" "skills installed for opencode"

# --- opencode install, explicit provider ---
"$IO" openai >/dev/null 2>&1 || fail "install-opencode openai failed"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-sol" "explicit provider honoured"

# --- comment guard aborts the whole opencode install ---
rm -f "$(opencode_dir)/AGENTS.md"
cat > "$CFG" <<'EOF'
{
  // hand-annotated
  "theme": "tokyonight"
}
EOF
assert_status 2 "$IO" anthropic
[ -e "$(opencode_dir)/AGENTS.md" ] && \
    fail "install continued past the comment guard"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — the install scripts do not exist.

- [ ] **Step 3: Write install-claude.sh**

Create `scripts/install-claude.sh`:

```bash
#!/usr/bin/env bash
# Install Superpowers, swe-skills, subagents, and global instructions for
# Claude Code. Exits 0 without doing anything when claude is not on PATH.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if ! have claude; then
    warn "claude not on PATH; skipping Claude Code setup"
    exit 0
fi

log "installing superpowers for Claude Code"
# Both are no-ops when already present; a non-zero status here means
# "already added", not a real failure.
claude plugin marketplace add "$SUPERPOWERS_MARKETPLACE" \
    || warn "marketplace add reported an error (already added?)"
claude plugin install "$SUPERPOWERS_CLAUDE_PLUGIN" \
    || warn "plugin install reported an error (already installed?)"

ensure_swe_skills
run_swe_skills_install claude

log "linking subagents into $(claude_dir)/agents"
for a in "${CLAUDE_AGENTS[@]}"; do
    link_into "$REPO_ROOT/agents/$a.md" "$(claude_dir)/agents/$a.md"
done

log "linking global instructions to $(claude_dir)/CLAUDE.md"
link_into "$REPO_ROOT/AGENTS.md" "$(claude_dir)/CLAUDE.md"

log "Claude Code setup complete"
```

Then `chmod +x scripts/install-claude.sh`.

- [ ] **Step 4: Write install-opencode.sh**

Create `scripts/install-opencode.sh`:

```bash
#!/usr/bin/env bash
# Install Superpowers, swe-skills, subagents, and global instructions for
# OpenCode. Exits 0 without doing anything when opencode or jq is absent.
#
# Usage: install-opencode.sh [provider]   (default: anthropic)
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

provider=${1:-anthropic}

if ! have opencode; then
    warn "opencode not on PATH; skipping OpenCode setup"
    exit 0
fi
if ! have jq; then
    warn "jq not on PATH; skipping OpenCode setup"
    exit 0
fi

# Merge first: a tripped comment guard must abort before anything else is
# touched, so a refused install leaves no half-configured state.
"$REPO_ROOT/scripts/merge-opencode.sh" "$provider"

ensure_swe_skills
run_swe_skills_install opencode

log "linking global instructions to $(opencode_dir)/AGENTS.md"
link_into "$REPO_ROOT/AGENTS.md" "$(opencode_dir)/AGENTS.md"

log "OpenCode setup complete (provider: $provider)"
```

Then `chmod +x scripts/install-opencode.sh`.

- [ ] **Step 5: Write the justfile**

Create `justfile`:

```just
set shell := ["bash", "-euo", "pipefail", "-c"]

# Model provider for the OpenCode agent ladder: anthropic or openai.
provider := "anthropic"

_scripts := justfile_directory() / "scripts"

# Show available recipes
default:
    @just --list

# Install into both harnesses; warns and skips one that is not present
install: install-claude install-opencode
    @echo
    @{{ _scripts }}/doctor.sh

# Install Superpowers, swe-skills, subagents, and instructions for Claude Code
install-claude:
    @{{ _scripts }}/install-claude.sh

# Install Superpowers, swe-skills, agents, and instructions for OpenCode
install-opencode:
    @{{ _scripts }}/install-opencode.sh {{ provider }}

# Report what is and is not installed; changes nothing
doctor:
    @{{ _scripts }}/doctor.sh

# Refresh skills, plugins, and links in place
update:
    @{{ _scripts }}/update.sh

# Remove what this repo installed
uninstall:
    @{{ _scripts }}/uninstall.sh

# Run the test suite
test:
    @bash tests/run.sh
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `bash tests/run.sh`
Expected: PASS — all test files pass, including the previously failing half of `test_doctor.sh`.

- [ ] **Step 7: Verify the just recipes parse**

Run: `just --list`
Expected: the eight recipes above, each with its comment as the description.

- [ ] **Step 8: Commit**

```bash
git add scripts/install-claude.sh scripts/install-opencode.sh justfile \
        tests/test_install.sh
git commit -m "feat: add install recipes for both harnesses

A missing harness warns and skips rather than failing, so a machine with
only one of the two is a valid target. The OpenCode merge runs first so a
refused config leaves no half-configured state."
```

---

### Task 8: Update and uninstall

**Files:**
- Create: `scripts/update.sh`
- Create: `scripts/uninstall.sh`
- Test: `tests/test_uninstall.sh`

**Interfaces:**
- Consumes: the manifest `{provider, backup, agents, plugin, provider_key}` written by `merge-opencode.sh`; the install scripts from Task 7.
- Produces: `scripts/update.sh` and `scripts/uninstall.sh`, both argument-free. Referenced by the `update` and `uninstall` recipes already in the `justfile`.

`update` reuses the provider recorded in the manifest, so it never silently switches providers. `uninstall` deliberately leaves `$SWE_SKILLS_DIR` and the Superpowers plugin in place — both are shared installs other tooling may depend on — and prints how to remove them.

- [ ] **Step 1: Write the failing test**

Create `tests/test_uninstall.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

stub_cmd claude
stub_cmd opencode
stub_cmd git
stub_swe_skills

CFG="$(opencode_dir)/opencode.jsonc"
MAN="$(opencode_dir)/.agentic-swe-setup.json"
mkdir -p "$(opencode_dir)"

# A pre-existing config with keys this repo must never touch.
cat > "$CFG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "tokyonight",
  "agent": { "my-own-agent": { "model": "openai/gpt-5.6-luna" } },
  "plugin": ["some-other-plugin@1.0.0"],
  "provider": { "anthropic": { "options": { "timeout": 60000 } } }
}
EOF
pristine=$(jq -S . "$CFG")

bash "$REPO_ROOT/scripts/install-claude.sh"   >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-opencode.sh" openai >/dev/null 2>&1

# --- update keeps the recorded provider ---
bash "$REPO_ROOT/scripts/update.sh" >/dev/null 2>&1 || fail "update failed"
assert_eq "$(jq -r .provider "$MAN")" "openai" "update kept the provider"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-sol" "update re-merged the same provider"
assert_symlink_to "$(claude_dir)/agents/reviewer.md" \
    "$REPO_ROOT/agents/reviewer.md" "update relinked agents"

# --- uninstall removes only what we added ---
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail "uninstall failed"

for a in "${CLAUDE_AGENTS[@]}"; do
    [ -e "$(claude_dir)/agents/$a.md" ] && fail "agent $a survived uninstall"
done
[ -e "$(claude_dir)/CLAUDE.md" ]   && fail "CLAUDE.md survived uninstall"
[ -e "$(opencode_dir)/AGENTS.md" ] && fail "AGENTS.md survived uninstall"
[ -e "$MAN" ] && fail "manifest survived uninstall"

assert_eq "$(jq -S . "$CFG")" "$pristine" "config restored to its pre-install state"

# --- shared installs are left alone, with instructions printed ---
[ -d "$SWE_SKILLS_DIR" ] || fail "uninstall removed the shared swe-skills checkout"
out=$(bash "$REPO_ROOT/scripts/uninstall.sh" 2>&1)
assert_contains "$out" "$SWE_SKILLS_DIR" "printed how to remove swe-skills"
assert_contains "$out" "claude plugin uninstall" "printed how to remove superpowers"

# --- uninstall is safe to run twice ---
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 \
    || fail "second uninstall failed"

# --- uninstall leaves a foreign symlink alone ---
mkdir -p "$(claude_dir)"
ln -sfn /etc/hostname "$(claude_dir)/CLAUDE.md"
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1
assert_symlink_to "$(claude_dir)/CLAUDE.md" /etc/hostname \
    "foreign CLAUDE.md left in place"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `scripts/update.sh` and `scripts/uninstall.sh` do not exist.

- [ ] **Step 3: Write update.sh**

Create `scripts/update.sh`:

```bash
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
```

Then `chmod +x scripts/update.sh`.

- [ ] **Step 4: Write uninstall.sh**

Create `scripts/uninstall.sh`:

```bash
#!/usr/bin/env bash
# Remove the symlinks and managed config keys this repo installed.
#
# Deliberately leaves the shared swe-skills checkout and the Superpowers
# plugin in place; other tooling may depend on both.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# unlink_ours PATH — remove PATH only when it is a symlink into this repo.
unlink_ours() {
    local p=$1
    if links_into_repo "$p"; then
        rm -f "$p"
        log "removed $p"
    elif [ -e "$p" ] || [ -L "$p" ]; then
        warn "leaving $p alone; it is not a symlink into this repo"
    fi
}

log "removing Claude Code links"
for a in "${CLAUDE_AGENTS[@]}"; do
    unlink_ours "$(claude_dir)/agents/$a.md"
done
unlink_ours "$(claude_dir)/CLAUDE.md"

log "removing OpenCode links"
unlink_ours "$(opencode_dir)/AGENTS.md"

for s in "${SKILL_NAMES[@]}"; do
    for d in "$(claude_dir)/skills/$s" "$(opencode_dir)/skills/$s"; do
        if [ -L "$d" ]; then
            rm -f "$d"
            log "removed $d"
        fi
    done
done

manifest="$(opencode_dir)/.agentic-swe-setup.json"
cfg="$(opencode_dir)/opencode.jsonc"

if have jq && [ -f "$manifest" ] && [ -f "$cfg" ]; then
    if jq -e . "$cfg" >/dev/null 2>&1; then
        log "removing managed keys from $cfg"
        tmp=$(mktemp)
        jq \
            --argjson agents "$(jq -c '.agents' "$manifest")" \
            --arg plugin "$(jq -r '.plugin' "$manifest")" '
              reduce $agents[] as $a (
                  .;
                  if has("agent") then .agent |= del(.[$a]) else . end
              )
            | if has("provider") then .provider |= del(.openai) else . end
            | if (.provider? == {}) then del(.provider) else . end
            | if has("agent") and (.agent == {}) then del(.agent) else . end
            | if has("plugin")
              then .plugin = (.plugin - [$plugin])
              else . end
            | if (.plugin? == []) then del(.plugin) else . end
            ' "$cfg" > "$tmp"
        mv "$tmp" "$cfg"
    else
        warn "$cfg is not strict JSON; remove the managed keys by hand"
    fi
    rm -f "$manifest"
    log "removed $manifest"
fi

printf '\n'
log "left in place on purpose (shared with other tooling):"
printf '  swe-skills checkout : %s\n' "$(swe_skills_dir)"
printf '    remove with       : rm -rf %s\n' "$(swe_skills_dir)"
printf '  superpowers plugin  : claude plugin uninstall superpowers\n'
printf '  opencode.jsonc backups: %s/opencode.jsonc.bak.*\n' "$(opencode_dir)"
```

Then `chmod +x scripts/uninstall.sh`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tests/run.sh`
Expected: PASS — all test files pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/update.sh scripts/uninstall.sh tests/test_uninstall.sh
git commit -m "feat: add update and uninstall recipes

update reuses the recorded provider so it never switches silently.
uninstall removes only symlinks that resolve into this repo, and leaves
the shared skills checkout and plugin alone."
```

---

### Task 9: README

**Files:**
- Modify: `README.md` (currently two lines)
- Test: `tests/test_readme.sh`

**Interfaces:**
- Consumes: the recipe names from the `justfile`.
- Produces: nothing consumed by later tasks.

Load the `de-slop` skill before writing the prose and apply it to the finished text.

- [ ] **Step 1: Write the failing test**

Create `tests/test_readme.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

R="$REPO_ROOT/README.md"
assert_file "$R" "README exists"
body=$(cat "$R")

# Every recipe in the justfile must be documented.
for r in install install-claude install-opencode doctor update uninstall test; do
    assert_contains "$body" "just $r" "README documents 'just $r'"
done

# The provider knob and its default must be stated.
assert_contains "$body" "provider=openai" "README shows the provider override"
assert_contains "$body" "anthropic" "README names the default provider"

# The two prerequisites the repo does not install.
assert_contains "$body" "Claude Code" "README names Claude Code"
assert_contains "$body" "OpenCode" "README names OpenCode"

# What uninstall leaves behind, so nobody is surprised.
assert_contains "$body" "swe-skills" "README mentions the shared skills checkout"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — the current two-line README documents no recipes.

- [ ] **Step 3: Load the de-slop skill**

Invoke the `de-slop` skill. It governs the prose in the next step.

- [ ] **Step 4: Write the README**

Replace `README.md`. It must cover, in this order:

1. **What this is** — one paragraph. A `just`-driven installer for Superpowers, swe-skills, five model-tiered subagents, and a global `AGENTS.md`, targeting Claude Code and OpenCode.
2. **Prerequisites** — Claude Code and/or OpenCode already installed and authenticated; `just`, `git`, and `jq` on `PATH`. State that a missing harness is warned about and skipped, so installing with only one is supported.
3. **Quick start** — a fenced block:
   ```bash
   git clone <this repo>
   cd agentic-swe-setup
   just install                      # both harnesses, provider=anthropic
   just install provider=openai      # both harnesses, OpenAI ladder
   just doctor                       # what is and is not installed
   ```
4. **Recipes** — a table of all seven recipes plus `test`, one line each.
5. **What gets installed where** — reproduce the component matrix from the design spec (four rows: Superpowers, swe-skills, global instructions, subagents; two columns: Claude Code, OpenCode).
6. **The model ladder** — both provider tables from the spec. Note that Haiku exposes only `high`/`max` variants, which is why `implementer-light` carries none and `explore` uses `high`.
7. **Changing models** — edit `opencode/<provider>.json` and `agents/*.md`, then re-run `just install`. Note that agent files are symlinked, so edits to `agents/*.md` take effect with no reinstall, while OpenCode config changes need a re-merge.
8. **What the OpenCode merge touches** — the managed key list, that everything else is preserved, that a backup is written each time, and that a config containing JSONC comments is refused rather than rewritten.
9. **Uninstall** — `just uninstall`, and what it deliberately leaves behind (the `~/.swe-skills` checkout, the Superpowers plugin, and the `opencode.jsonc.bak.*` files) with the commands to remove each.

Every command in the README must be one that actually exists. Do not invent flags.

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/run.sh`
Expected: PASS — all test files pass.

- [ ] **Step 6: Full-suite verification**

Run: `bash tests/run.sh && just --list && just doctor`
Expected: every test file passes; `just --list` shows eight recipes; `just doctor` prints a report and exits 0.

- [ ] **Step 7: Commit**

```bash
git add README.md tests/test_readme.sh
git commit -m "docs: document recipes, model ladders, and uninstall scope"
```

---

## Post-implementation verification

Run on the real machine, outside the test sandbox, after Task 9:

- [ ] `just doctor` before installing — reports the current state without error.
- [ ] `just install` — completes; `just doctor` afterwards shows no `[warn]` lines for skills, agents, or instructions.
- [ ] Confirm `~/.claude/CLAUDE.md` and `~/.config/opencode/AGENTS.md` both resolve to `agents-swe-setup/AGENTS.md`, and that the pre-existing `~/.config/opencode/AGENTS.md` was backed up rather than destroyed.
- [ ] Confirm `~/.config/opencode/opencode.jsonc` retains its `provider.openai` reasoning options if the OpenAI provider was selected, and that no unmanaged key was lost. Diff against the `.bak.*` file.
- [ ] Start Claude Code and confirm the five subagents appear and that `reviewer` is read-only.
- [ ] Start OpenCode and confirm the seven agents resolve and that a subagent dispatch uses the expected model.
- [ ] `just uninstall`, then `just install` — round-trips cleanly.
