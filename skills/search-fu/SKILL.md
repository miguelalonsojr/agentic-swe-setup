---
name: search-fu
description: Use when a task needs information from the open web and the harness has no configured search tool, or its search returns "no API key configured". Also use when a search result needs to be read at its source before a claim is made from it.
---

# search-fu

## Overview

Search the web with no API key, from a script that runs anywhere, and read the
page behind a result before quoting it.

**Core principle: the engine that works is not the one you would guess.** Two of
the obvious choices answer HTTP 200 and return nothing usable, and DuckDuckGo
works only if the request is made the right way. Check what works from here
before concluding the web is unreachable.

## When to Use

- The harness's own search tool is unconfigured, and a key is unavailable
  or unwanted
- A fact, version number, error message or upstream doc has to come from the web
- A search result looks right and is about to be used as evidence

**Do not use** when the harness's search tool works — use it. This is
the fallback, not a replacement. It also does not judge whether a source is
good enough to act on; `cross-checking-claims` owns that.

## The Trap This Avoids

Reaching for a search engine over plain HTTP fails quietly, in ways a status
check does not catch:

| What you do | What comes back |
|---|---|
| POST to DuckDuckGo's HTML endpoint cold | HTTP 202 and a bot challenge page holding zero results |
| GET the same endpoint instead of POST | the same challenge |
| Query Bing | 200 with an empty result list, no error and no results |
| Query Brave | 429, first request, no history |
| Query a public SearXNG instance | 429 or 403 from nearly all of them |
| Query DuckDuckGo's Instant Answer API | 200 and empty abstracts; it disambiguates, it does not search |
| Quote the snippet a search returned | a claim sourced from 30 words a search engine chose |

The first row is the expensive one. The challenge page is HTTP 200 or 202 with a
full HTML body, so code that checks the status and counts results reports "no
results found" and the search looks like it worked.

## The Two Mechanics

**Warm the session.** GET `https://duckduckgo.com/` first, on an opener that
keeps cookies, then POST the query to `https://html.duckduckgo.com/html/` on
that same opener. The warm-up puts the cookies DuckDuckGo wants in the jar, and
gets a cold session in.

It is not immunity. Around eight queries in a few minutes gets the session
walled anyway, warm-up or not, and it stays walled for ten minutes or so. That
is what Mojeek is for. A challenge after a run of successful searches means you
are rate-limited, not that the warm-up or the parser is broken: pin
`--engine mojeek` and carry on rather than debugging.

**Detect the challenge, do not count it.** Treat a challenge as an error to
retry or fall back from — never as an empty result set. The two look identical
to a parser that only counts results and mean opposite things.

Detect it from the challenge form, not from the words in the page. A results
page for a query about bot walls contains `anomaly.js` in its snippets, and the
HTML endpoint echoes your query back into its own search box, so a substring
scan flags a working search as a wall.

## Quick Reference

`websearch.py` in this directory does all of it. Standard library only, no
install.

| Step | Command | Network |
|---|---|---|
| Search | `websearch.py search "QUERY"` | yes |
| Search, machine-readable | `websearch.py search "QUERY" --json` | yes |
| Pin one engine | `websearch.py search "QUERY" --engine mojeek` | yes |
| Read the page behind a result | `websearch.py fetch URL` | yes |
| Check which engines still work | `websearch.py selftest` | yes |
| Check the parser against saved markup | `websearch.py parse < saved.html` | no |

`search` tries DuckDuckGo and falls back to Mojeek on any failure — a wall, a
dead connection, an empty page — so the usual case is one command. It retries
three times before falling back, which costs six or seven seconds against a
walling DuckDuckGo and can reach minutes if the connection hangs instead of
refusing; a search that takes that long is working, not hung. Mojeek needs no
warm-up and runs its own index, which makes it a real second opinion rather than
another window onto the same results.

## Snippets Are Not Evidence

A snippet is not a source. It is a fragment the engine chose, often from a
page's marketing copy, sometimes from a comment thread quoting the thing it
appears to assert. Search to find the page; `fetch` it to find out what it says.

Anything that will change a decision — a version number, a licence, an API's
behaviour, whether a project exists — gets read at the source. This is where
`cross-checking-claims` starts.

`fetch` does no bot detection. A consent wall, a login page or a Cloudflare
interstitial comes back as page text like anything else, so read what it
returned before quoting it. Text that never mentions your subject is the tell.

## When It Stops Working

Every claim above is a claim about someone else's bot detection, and those
change without notice. `websearch.py selftest` asks each engine one known query
and reports which ones answered:

```
$ websearch.py selftest
[fail] ddg: duckduckgo served a bot challenge, not results; retry later or pin the other engine with --engine
[ok]   mojeek: 3 results, first is https://www.informit.com/...
```

That pair is the ordinary walled-session case, and `selftest` exits 0 for it:
one working engine is enough. It exits non-zero only when every engine fails,
which is the signal to go looking for a new one.

Run it before concluding that search is broken, and again before editing this
skill's engine table. If both engines fail, the fix is usually markup drift
rather than a new wall: save the response body and run `websearch.py parse`
over it to see whether the parser or the engine moved.

## Red Flags

- About to report "web search is unavailable" without having run `selftest`
- About to quote a snippet in a claim, without having fetched the page
- About to treat an empty result set as an answer, without checking for a
  challenge
- About to add an engine to the table because its docs say it allows scraping,
  rather than because `selftest` says it answered

## Real-World Impact

Six engines and eight public SearXNG instances were tried before one working
path was found, and every failure looked like a network problem from the
outside. That survey is what the table above is worth, and why `selftest`
exists to redo it in five seconds rather than an afternoon.
