# search-fu

Web search with no API key, and a way to read the page behind a result.

`SKILL.md` is the agent-facing guide. This file is for humans running the script
by hand.

## Install

Drop the directory where your agent looks for skills, or symlink it so edits
take effect without copying again:

```bash
# Claude Code
ln -sfn "$PWD/search-fu" ~/.claude/skills/search-fu

# OpenCode
ln -sfn "$PWD/search-fu" ~/.config/opencode/skills/search-fu
```

`~/.agents/skills/` also works as a cross-runtime location on Codex, Copilot CLI
and Gemini CLI.

The script stands on its own. If you only want the tooling and not the skill,
run `websearch.py` directly from wherever you cloned it.

## Run it

```bash
S=path/to/search-fu/websearch.py

python3 $S search "sqlite wal mode limitations"     # DuckDuckGo, Mojeek on fallback
python3 $S search "..." -n 3 --json                 # machine-readable
python3 $S search "..." --engine mojeek             # pin one engine
python3 $S fetch https://example.org/doc --chars 4000
python3 $S selftest                                 # which engines work today
python3 $S parse < saved.html                       # parser check, no network
```

## Why a script rather than curl

DuckDuckGo's HTML endpoint answers a cold request with a bot challenge: HTTP 202
and a page whose forms post to `anomaly.js`, carrying no results. A GET to
`https://duckduckgo.com/` on a cookie-keeping session first, then a POST to
`https://html.duckduckgo.com/html/` on that same session, returns real results.

The challenge page arrives as a normal-looking HTML response, so anything that
checks the status code and counts results will report an empty search instead of
a blocked one. The script tells them apart by looking for the challenge form
itself — searching the body for the word `anomaly.js` flags any results page
about bot walls, including one for a query DuckDuckGo echoes back into its own
search box.

The warm-up gets a cold session in and buys nothing after that. Around eight
queries in a few minutes gets you walled for ten minutes or so regardless, which
is what the fallback is for. If you are working through a list of searches, pin
`--engine mojeek` and skip the retries.

## Engines

| Engine | State when last checked | Notes |
|---|---|---|
| DuckDuckGo | works | needs the warm-up; walls a busy session for ~10 minutes |
| Mojeek | works | no warm-up, independent index, no wall seen yet |
| Bing | unusable | HTTP 200 with an empty result list |
| Brave | unusable | HTTP 429 on a first request |
| SearXNG (public instances) | unusable | 429 or 403 across the instances tried |
| DuckDuckGo Instant Answer API | not a search engine | disambiguation only, empty abstracts |

This table dates from the day it was written and depends on third-party bot
detection. `selftest` is the current answer:

```bash
python3 $S selftest
[ok]   ddg: 3 results, first is https://...
[ok]   mojeek: 3 results, first is https://...
```

It exits non-zero only when *no* engine works, which is the signal to go looking
for a new one rather than to conclude the network is down. A `[fail]` line for
DuckDuckGo alongside an `[ok]` for Mojeek usually means nothing worse than a
walled session.

## When the parser breaks

Engines change their markup. `parse` reads saved HTML on stdin and prints what
it extracted, so you can tell markup drift from a bot wall without hitting the
network again:

```bash
curl -s ... > saved.html
python3 $S parse --engine ddg < saved.html
```

## Requirements

Python 3.9+, standard library only. No `pip install`.
