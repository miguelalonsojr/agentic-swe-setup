#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# --- path resolvers honour the sandbox ---
assert_eq "$(swe_skills_dir)" "$SWE_SKILLS_DIR" "swe_skills_dir"

# --- constants ---
assert_eq "${#PRIME_AGENTS[@]}" 9 "managed agent count"
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

# --- Prime-only provider paths and headings ---
assert_eq "${HARNESSES[*]}" prime "only Prime harness rendered"
assert_eq "$(harness_heading prime)" '#### When running under Prime Agent'     "Prime heading"
assert_status 1 harness_heading opencode
assert_eq "$(rendered_agents_md prime openai)"     "$REPO_ROOT/build/prime/openai/AGENTS.md" "Prime provider render path"
# --- shared updates refuse every dirty state before fetching ---
upstream="$SANDBOX/upstream"
git init -q "$upstream"
printf 'original\n' > "$upstream/tracked.txt"
git -C "$upstream" add tracked.txt
git -C "$upstream" -c user.name=Test -c user.email=test@example.invalid commit -qm initial
for state in tracked staged untracked clean; do
    git clone -q "$upstream" "$SANDBOX/checkout-$state"
done
printf 'incoming\n' > "$upstream/incoming.txt"
git -C "$upstream" add incoming.txt
git -C "$upstream" -c user.name=Test -c user.email=test@example.invalid commit -qm incoming
for state in tracked staged untracked; do
    checkout="$SANDBOX/checkout-$state"
    if [ "$state" = untracked ]; then
        printf 'local\n' > "$checkout/local.txt"
    else
        printf 'local\n' > "$checkout/tracked.txt"
        [ "$state" != staged ] || git -C "$checkout" add tracked.txt
    fi
    before_head=$(git -C "$checkout" rev-parse HEAD)
    before_status=$(git -C "$checkout" status --porcelain --untracked-files=all)
    output=$(ensure_checkout test "$upstream" "$checkout" 2>&1); status=$?
    [ "$status" -ne 0 ] || fail "$state checkout update succeeded"
    assert_contains "$output" 'local changes' "$state refusal explains dirty state"
    assert_eq "$(git -C "$checkout" rev-parse HEAD)" "$before_head" "$state HEAD unchanged"
    assert_eq "$(git -C "$checkout" status --porcelain --untracked-files=all)" "$before_status" "$state changes preserved"
    [ ! -e "$checkout/.git/FETCH_HEAD" ] || fail "$state checkout fetched before refusal"
done
output=$(ensure_checkout test "$upstream" "$SANDBOX/checkout-clean" 2>&1); status=$?
assert_eq "$status" 0 'clean checkout fast-forwards'
assert_eq "$(git -C "$SANDBOX/checkout-clean" rev-parse HEAD)" "$(git -C "$upstream" rev-parse HEAD)" 'clean checkout reaches upstream HEAD'
assert_eq "$(cat "$SANDBOX/checkout-clean/incoming.txt")" incoming 'clean checkout receives incoming file'

exit "$ASSERT_FAILURES"
