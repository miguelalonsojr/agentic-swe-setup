#!/usr/bin/env bash
# The skills this repo ships itself, as opposed to the shared swe-skills
# checkout: they must be linked on install, reported by doctor, and removed on
# uninstall, in both harnesses.
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# --- every declared skill exists in the repo, with the two required files ---
for s in "${LOCAL_SKILLS[@]}"; do
    assert_file "$REPO_ROOT/skills/$s/SKILL.md" "skills/$s has a SKILL.md"
    assert_file "$REPO_ROOT/skills/$s/README.md" "skills/$s has a README.md"
    body=$(cat "$REPO_ROOT/skills/$s/SKILL.md")
    assert_contains "$body" "name: $s" "skills/$s declares its own name"
    assert_contains "$body" "description:" "skills/$s has a description"
done

# The dispatch-policy skills are only correct if they carry the specific
# facts that make them correct. A skill that says "pick a good model" is
# the advice that already failed.
#
# Each needle is anchored on the whole claim, not on a distinctive token.
# A bare "clamped" would stay green if the thinking-level sentence were
# deleted and "capped at 20" reworded to "clamped to 20"; a bare
# "rlm.find_models" would stay green on a passing mention with the call
# itself gone.
routing=$(cat "$REPO_ROOT/skills/routing-model-tiers/SKILL.md")
assert_contains "$routing" 'rlm.find_models("", limit=20)' \
    "routing skill gives the model-menu call, with its capped limit"
assert_contains "$routing" 'accepts `name` and `model` and nothing else' \
    "routing skill names the rlm keywords and excludes the rest"
assert_contains "$routing" "clamped to the child model" \
    "routing skill states how thinking level is set"
# The list-vs-verdict table is what the skill exists to install. Deleting the
# whole `## The Routing Test` section left every needle above green, so this
# one is the light-tier row's own wording: one matching site, inside the table.
assert_contains "$routing" "A list. Cataloguing licences" \
    "routing skill keeps the list-vs-verdict routing table"

# The needles here are whole clauses for the reason stated above, and this
# skill makes the point sharply: a bare "primary source" matches the mandated
# frontmatter, a bare "verification-before-completion" matches the section
# heading, and a bare "cross-checker" matches a later aside. Gutting Step 2,
# replacing the boundary section's body and deleting the dispatch sentence left
# all three green. Each needle below has exactly one matching site, inside the
# section that owns the rule.
crosscheck=$(cat "$REPO_ROOT/skills/cross-checking-claims/SKILL.md")
assert_contains "$crosscheck" 'to the `cross-checker`' \
    "cross-check skill names its dispatch target"
assert_contains "$crosscheck" "check it against a primary source" \
    "cross-check skill requires a primary source"
assert_contains "$crosscheck" "your own claims about your own work" \
    "cross-check skill draws its boundary with the verification skill"
assert_contains "$crosscheck" "change what gets built, bought or skipped" \
    "cross-check skill gives the load-bearing gate routing-model-tiers leans on"
assert_contains "$crosscheck" "the question, not the" \
    "cross-check skill states the anchoring rule"
assert_contains "$crosscheck" "dual-licensed" \
    "cross-check skill keeps the licence error that primary sources caught"
assert_contains "$crosscheck" "flagged as unconfirmed" \
    "cross-check skill says what happens to a claim that survives neither step"
# Deleting the whole `## Disagreement Is The Signal` section left every needle
# above green, and that section is the other half of the skill's point: the
# two-verdicts case is the outcome the second dispatch was paid for. This
# needle is the rule that section owns, with one matching site.
assert_contains "$crosscheck" "Do not average the two answers" \
    "cross-check skill says how to settle two verdicts that differ"

# search-fu's claims are about a third party's bot detection, so the needles are
# the specific mechanics that make the skill work. "use DuckDuckGo" is the
# advice that already failed: a cold request to the HTML endpoint gets a
# challenge page, and a skill that omits the warm-up teaches the failing call.
search=$(cat "$REPO_ROOT/skills/search-fu/SKILL.md")
assert_contains "$search" 'GET `https://duckduckgo.com/` first' \
    "search skill gives the session warm-up that avoids the challenge"
assert_contains "$search" "anomaly.js" \
    "search skill names the marker that identifies a challenge page"
assert_contains "$search" "never as an empty result set" \
    "search skill says a challenge is not zero results"
# The warm-up gets a cold session in; it does not buy immunity. Sustained
# querying gets walled anyway, and a skill that promises otherwise sends the
# agent to debug its own parser instead of pinning the fallback engine.
assert_contains "$search" "walled anyway" \
    "search skill says the warm-up does not make the wall go away"
assert_contains "$search" "200 with an empty result list" \
    "search skill records how Bing fails, which a status check misses"
assert_contains "$search" "A snippet is not a source" \
    "search skill requires fetching the page behind a result"
# `fetch` reads whatever came back. An interstitial is page text to it, and the
# skill's central instruction is to fetch before quoting, so the one caveat
# that instruction carries has to be in the file.
assert_contains "$search" "no bot detection" \
    "search skill says fetch does not detect an interstitial"
# The engine table rots without warning, and a skill asserting a dead engine
# still works is worse than no skill. This needle is the sentence that sends
# the reader to selftest before believing the table.
assert_contains "$search" 'selftest` asks each engine one known query' \
    "search skill points at the command that rechecks its own claims"
assert_contains "$search" 'About to report "web search is unavailable"' \
    "search skill requires that check before declaring search broken"
# Quick Reference is the whole command surface, and When to Use carries the
# boundary against the harness's own search. Deleting either left the suite
# green, which is what the anchoring convention above exists to prevent.
assert_contains "$search" '| Search | `websearch.py search "QUERY"` | yes |' \
    "search skill gives the command that runs a search"
assert_contains "$search" "the fallback, not a replacement" \
    "search skill defers to the harness's own search when it works"
# The fallback engine walls too, and its walls are the two the challenge-form
# rule does not cover. A skill that describes only DuckDuckGo's wall sends the
# agent to debug a parser over a rate limit it should have waited out.
assert_contains "$search" "A wall has three shapes" \
    "search skill names every shape a wall arrives in"
assert_contains "$search" "Mojeek rate-limits too" \
    "search skill says the fallback engine has its own wall"

# --- search-fu's parser, offline, against saved markup ---
# The parser is the load-bearing part and the part that breaks when an engine
# changes its markup. Testing it through the network would make the suite
# depend on a third party, so `parse` reads saved HTML on stdin instead.
ws="$REPO_ROOT/skills/search-fu/websearch.py"
assert_file "$ws" "search-fu ships its script"
[ -x "$ws" ] || fail "websearch.py is executable"

out=$(printf '%s' '<div class="result results_links web-result">
<h2 class="result__title"><a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.org%2Fdoc&amp;rut=x">Example Doc</a></h2>
<a class="result__snippet">The snippet text.</a></div>' | python3 "$ws" parse --engine ddg 2>&1)
assert_contains "$out" "https://example.org/doc" \
    "parse decodes the uddg redirect wrapper into the real URL"
assert_contains "$out" "Example Doc" "parse extracts the result title"
assert_contains "$out" "The snippet text." "parse extracts the snippet"

# Only DuckDuckGo's own wrapper is a wrapper. A result URL that happens to
# carry a uddg parameter belongs to the site it points at.
out=$(printf '%s' '<div class="result"><a class="result__a" href="https://example.org/p?uddg=1">Not A Wrapper</a></div>' \
    | python3 "$ws" parse --engine ddg 2>&1)
assert_contains "$out" "https://example.org/p?uddg=1" \
    "parse leaves a non-wrapper URL alone"

# Snippets wrap across source lines. Text that keeps the newlines reads as a
# working search whose output is quietly mangled, which is the failure this
# whole block exists to catch.
out=$(printf '%s' '<div class="result"><a class="result__a" href="https://a.org/x">T</a>
<a class="result__snippet">first line
   second   line</a></div>' | python3 "$ws" parse --engine ddg 2>&1)
assert_contains "$out" "first line second line" \
    "parse collapses whitespace inside a snippet"

# Mojeek is the fallback: the path that runs when things have already gone
# wrong. Leaving it uncovered means the parser that matters most on a bad day
# is the one nothing checks.
out=$(printf '%s' '<ul class="results-standard"><li class="r1">
<h2><a class="title" href="https://example.net/page">Mojeek Result</a></h2>
<p class="s">Mojeek snippet text.</p></li></ul>' | python3 "$ws" parse --engine mojeek 2>&1)
assert_contains "$out" "https://example.net/page" "mojeek parse extracts the URL"
assert_contains "$out" "Mojeek Result" "mojeek parse extracts the title"
assert_contains "$out" "Mojeek snippet text." "mojeek parse extracts the snippet"

# Both engines bold the query terms inside the snippet and the title. A parser
# that stops collecting at the first closing tag keeps the words before the
# first highlight and silently drops the rest of the sentence, which reads as a
# working search returning uselessly short snippets.
out=$(printf '%s' '<div class="result"><a class="result__a" href="https://a.org/x">A <b>Bold</b> Title</a>
<a class="result__snippet">Text before <b>the</b> highlight and after it.</a></div>'     | python3 "$ws" parse --engine ddg 2>&1)
assert_contains "$out" "A Bold Title" "ddg parse keeps title text across inline markup"
assert_contains "$out" "highlight and after it." "ddg parse keeps snippet text after a highlight"

out=$(printf '%s' '<ul class="results-standard"><li><h2><a class="title" href="https://b.org/y">A <strong>Bold</strong> Title</a></h2>
<p class="s">Text before <strong>the</strong> highlight and after it.</p></li></ul>'     | python3 "$ws" parse --engine mojeek 2>&1)
assert_contains "$out" "A Bold Title" "mojeek parse keeps title text across inline markup"
assert_contains "$out" "highlight and after it." "mojeek parse keeps snippet text after a highlight"

# Same failure one level down: closing on the first tag of the right *name*
# ends the field at a nested element of that name instead of at its own
# closing tag. Truncation again, silent again.
out=$(printf '%s' '<div class="result"><a class="result__a" href="https://a.org/x">Title <a>nested</a> tail</a>
<a class="result__snippet">Snippet <a href="https://b/">nested</a> tail.</a></div>' \
    | python3 "$ws" parse --engine ddg 2>&1)
assert_contains "$out" "Title nested tail" "ddg parse survives a same-tag nesting in the title"
assert_contains "$out" "Snippet nested tail." "ddg parse survives a same-tag nesting in the snippet"

out=$(printf '%s' '<ul class="results-standard"><li><h2><a class="title" href="https://b.org/y">T</a></h2>
<p class="s">Snippet <p>nested</p> tail.</p></li></ul>' \
    | python3 "$ws" parse --engine mojeek 2>&1)
assert_contains "$out" "Snippet nested tail." "mojeek parse survives a same-tag nesting in the snippet"

# A challenge page parses to zero results while returning HTTP 200, so the
# script has to name that case rather than report an empty search.
out=$(printf '%s' '<html><form id="challenge-form" action="//duckduckgo.com/anomaly.js?sv=html"></form></html>' \
    | python3 "$ws" parse --engine ddg 2>&1)
rc=$?
assert_eq "$rc" 1 "parse exits non-zero on a challenge page"
assert_contains "$out" "challenge" "parse says the page was a challenge, not an empty result set"

# The same page routed to the other engine must still be called a challenge.
# Exempting every engine but DuckDuckGo from the check reintroduces, on the
# fallback path, the exact confusion this script exists to prevent.
out=$(printf '%s' '<html><form id="challenge-form" action="//duckduckgo.com/anomaly.js?sv=html"></form></html>' \
    | python3 "$ws" parse --engine mojeek 2>&1)
assert_contains "$out" "challenge" "a challenge is a challenge on the fallback engine too"

# `anomaly.js` and `challenge-form` are ordinary document text: they turn up in
# titles, in snippets, and in the query the HTML endpoint echoes back into its
# own search box. Matching them anywhere in the body makes every query about
# bot walls look like a bot wall.
# The fixture carries the search-box form every real results page has: the test
# is worthless without it, since "any form at all" would then pass.
out=$(printf '%s' '<html><form id="search_form" action="/html/">
<input name="q" value="anomaly.js challenge-form"></form>
<div class="result"><a class="result__a" href="https://a.org/doc">What anomaly.js does</a>
<a class="result__snippet">The challenge-form explained.</a></div></html>' \
    | python3 "$ws" parse --engine ddg 2>&1)
rc=$?
assert_eq "$rc" 0 "a results page that merely mentions the wall is not a challenge"
assert_contains "$out" "https://a.org/doc" "that page's result is still parsed"

# An unwrapped href with no scheme cannot be fetched, and the skill tells the
# agent to fetch every URL this prints. The assertion is on the dropped
# result's title, not on the href: an empty `uddg=` unwraps to the empty
# string, so a needle on the wrapper text is absent either way and the test
# stays green with the filter deleted.
out=$(printf '%s' '<div class="result"><a class="result__a" href="//duckduckgo.com/l/?uddg=">Unfetchable</a></div>
<div class="result"><a class="result__a" href="ftp://files.example/x">Wrong scheme</a></div>
<div class="result"><a class="result__a" href="https://real.example/ok">Real</a></div>' \
    | python3 "$ws" parse --engine ddg 2>&1)
assert_contains "$out" "https://real.example/ok" "a fetchable result survives"
assert_not_contains "$out" "Unfetchable" "a result with no scheme is dropped"
assert_not_contains "$out" "Wrong scheme" "a result with a non-http scheme is dropped"

# --- the whole search path, offline ---
# Every parser test above calls `parse`, which takes the engine key the CLI
# already validated. Nothing called Engine.search, and that is the one caller
# that looked its parser up by the engine's display name instead: `ddg` is
# keyed `ddg` but named `duckduckgo`, so every real DuckDuckGo query died with
# KeyError while the suite stayed green. These tests stub the network at
# `_read` and drive `search()` itself, so the request, the status, the wall
# check and the parser are all on the path.
stub_read() {
    # stub_read STATUS — a websearch.py with its one network call replaced by a
    # canned (STATUS, BODY). BODY is defined by the caller's own heredoc, which
    # is appended after this one and read before the lambda ever runs.
    cat <<PY
import importlib.util, sys
spec = importlib.util.spec_from_file_location("websearch", "$ws")
ws = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ws)
ws.time.sleep = lambda _s: None
ws._read = lambda opener, url, data=None: ($1, BODY)
PY
}

results_page='<div class="result"><a class="result__a" href="https://example.org/doc">Doc</a><a class="result__snippet">Snippet.</a></div>'
out=$( { stub_read 200 ; cat <<PY
BODY = '''$results_page'''
engine, results = ws.search("q", 3, "ddg")
print(engine, results[0]["url"])
PY
} | python3 - 2>&1)
assert_contains "$out" "ddg https://example.org/doc" \
    "search() reaches the parser for the engine whose key and name differ"

# Mojeek's wall is an HTTP 403 whose body carries no results, so a caller that
# ignores the status reports the rate limit as an empty web. The status is the
# only thing that tells them apart.
mojeek_403='<html><head><title>403 - Forbidden</title></head><body><h1>403 - Forbidden</h1><h2>Sorry your network appears to be sending automated queries so we cannot process your search at this time.</h2></body></html>'
out=$( { stub_read 403 ; cat <<PY
BODY = '''$mojeek_403'''
try:
    ws.search("q", 3, "mojeek")
except ws.SearchError as exc:
    print(type(exc).__name__, exc)
PY
} | python3 - 2>&1)
assert_contains "$out" "ChallengeError" "an HTTP 403 from an engine is a wall"
assert_contains "$out" "403" "the wall error names the status that caused it"
assert_not_contains "$out" "no results" "a walled engine is not an empty result set"

# Mojeek's other wall is HTTP 200 carrying a JavaScript interstitial. Same
# failure as the 403, one layer up: a results-shaped response with no results.
# The phrase is split by inline markup and a line break, because the real page
# is free to be, and a regex over raw HTML would miss every version that is.
mojeek_js='<html><body><div class="header"></div><noscript>JavaScript is
<b>required</b> to complete this challenge. Please enable it.</noscript></body></html>'
out=$( { stub_read 200 ; cat <<PY
BODY = '''$mojeek_js'''
try:
    ws.search("q", 3, "mojeek")
except ws.SearchError as exc:
    print(type(exc).__name__, exc)
PY
} | python3 - 2>&1)
assert_contains "$out" "ChallengeError" "a JavaScript interstitial is a wall, not an empty page"

# The interstitial is detected only when nothing parsed, for the same reason
# the challenge form is matched structurally: a results page is allowed to
# contain those words, and one about bot walls does.
out=$(printf '%s' '<div class="result"><a class="result__a" href="https://example.org/doc">JavaScript is required to complete this challenge</a>
<a class="result__snippet">Why engines say that.</a></div>' | python3 "$ws" parse --engine ddg 2>&1)
rc=$?
assert_eq "$rc" 0 "a results page quoting the interstitial is not a wall"
assert_contains "$out" "https://example.org/doc" "that page's result is still parsed"

# The fallback is only worth having if a walled first engine hands over to the
# second rather than taking the search down with it.
mojeek_page='<ul class="results-standard"><li class="r1"><h2><a class="title" href="https://example.net/page">Page</a></h2><p class="s">Snippet.</p></li></ul>'
out=$( { stub_read 200 ; cat <<PY
BODY = '''$mojeek_page'''
ws.ENGINES["ddg"].request = lambda q: (403, "")
engine, results = ws.search("q", 3)
print(engine, results[0]["url"])
PY
} | python3 - 2>&1)
assert_contains "$out" "mojeek https://example.net/page" \
    "auto falls back to the second engine when the first is walled"


# Every failure the script can hit has to arrive as one error line. A traceback
# is unreadable to the agent and, worse, is not the `error:` line it is told to
# expect. Connection refused is the cheap offline stand-in for a timeout.
out=$(python3 "$ws" fetch 'example.org' 2>&1)
rc=$?
assert_eq "$rc" 1 "fetch on a URL with no scheme exits 1"
assert_contains "$out" "error:" "fetch reports a bad URL as an error"
[[ "$out" == *"Traceback"* ]] && fail "fetch printed a traceback for a bad URL"

out=$(python3 "$ws" fetch 'http://127.0.0.1:9/' 2>&1)
rc=$?
assert_eq "$rc" 1 "fetch on a refused connection exits 1"
[[ "$out" == *"Traceback"* ]] && fail "fetch printed a traceback for a refused connection"

# --- install-skills alone, with no harness present ---
out=$("$REPO_ROOT/scripts/install-skills.sh" 2>&1)
assert_eq "$?" 0 "install-skills exits 0 with no harness"
assert_contains "$out" "nothing to do" "install-skills said it had nothing to do"

# --- claude: linked by install-claude ---
stub_cmd claude
stub_cmd git
stub_swe_skills
"$REPO_ROOT/scripts/install-claude.sh" >/dev/null 2>&1 || fail "install-claude failed"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_symlink_to "$(claude_dir)/skills/$s" "$REPO_ROOT/skills/$s" \
        "claude skill $s links into the repo"
done

# --- doctor reports them ---
out=$("$REPO_ROOT/scripts/doctor.sh" 2>&1)
for s in "${LOCAL_SKILLS[@]}"; do
    assert_contains "$out" "[ok]   local skill $s" "doctor sees claude skill $s"
done

# --- opencode: linked by install-skills, which is the standalone path ---
stub_cmd opencode
"$REPO_ROOT/scripts/install-skills.sh" >/dev/null 2>&1 || fail "install-skills failed"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_symlink_to "$(opencode_dir)/skills/$s" "$REPO_ROOT/skills/$s" \
        "opencode skill $s links into the repo"
done

# --- relinking is idempotent ---
"$REPO_ROOT/scripts/install-skills.sh" >/dev/null 2>&1 || fail "second install-skills failed"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_symlink_to "$(claude_dir)/skills/$s" "$REPO_ROOT/skills/$s" \
        "claude skill $s still linked after a second run"
done

# --- a real directory the user owns is backed up, never destroyed ---
first=${LOCAL_SKILLS[0]}
rm -f "$(claude_dir)/skills/$first"
mkdir -p "$(claude_dir)/skills/$first"
printf 'mine\n' > "$(claude_dir)/skills/$first/SKILL.md"
"$REPO_ROOT/scripts/install-skills.sh" >/dev/null 2>&1 || fail "install over a real dir failed"
n=$(find "$(claude_dir)/skills" -maxdepth 1 -name "$first.bak.*" | wc -l)
assert_eq "$n" 1 "a user-owned skill directory was backed up, not overwritten"

# --- uninstall removes only our links ---
"$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail "uninstall failed"
for s in "${LOCAL_SKILLS[@]}"; do
    [ -L "$(claude_dir)/skills/$s" ] && fail "uninstall left the claude link for $s"
    [ -L "$(opencode_dir)/skills/$s" ] && fail "uninstall left the opencode link for $s"
done

# --- uninstall leaves a directory it does not own ---
rm -rf "$(claude_dir)/skills/$first"
mkdir -p "$(claude_dir)/skills/$first"
"$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail "second uninstall failed"
[ -d "$(claude_dir)/skills/$first" ] || fail "uninstall removed a directory it did not create"

exit "$ASSERT_FAILURES"
