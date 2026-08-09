#!/usr/bin/env python3
"""Keyless web search: query DuckDuckGo or Mojeek and read the pages behind the results.

Commands
  search QUERY    Search and print ranked results. Tries DuckDuckGo, falls back
                  to Mojeek. `--engine` pins one engine instead.
  fetch URL       Fetch a page and print it as text, so a claim can be read at
                  its source rather than inferred from a snippet.
  parse           Parse saved result HTML on stdin. No network. Use it to check
                  the parser after an engine changes its markup.
  selftest        Ask every engine one known query and report which ones work.
                  Run this before trusting anything this script or its SKILL.md
                  says about a particular engine.

Standard library only, so it runs under any harness with no install.

Three mechanics matter, and they are the difference between working and not:

DuckDuckGo's HTML endpoint answers a cold request with a bot challenge: HTTP 202
and a page whose forms post to `anomaly.js`, carrying no results. A GET to
https://duckduckgo.com/ first puts the cookies it wants in the jar, and the POST
that follows on the same opener returns real results. The warm-up gets a cold
session in; it is not immunity, and sustained querying gets walled anyway.

A challenge page is not an empty result set, and the two are indistinguishable
to a parser that only counts results. It is detected from the challenge form
itself rather than from the presence of the word `anomaly.js` in the document,
because that word is ordinary text on any results page about bot walls.

Mojeek is the fallback for when DuckDuckGo is walling. It needs no warm-up and
indexes independently, so it is a genuine second opinion rather than another
window onto the same index.
"""
from __future__ import annotations

import argparse
import http.cookiejar
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from html import unescape
from html.parser import HTMLParser

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
HEADERS = {
    "User-Agent": UA,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}
DDG_HOME = "https://duckduckgo.com/"
DDG_HTML = "https://html.duckduckgo.com/html/"
MOJEEK = "https://www.mojeek.com/search"
TIMEOUT = 25
ATTEMPTS = 3


class SearchError(RuntimeError):
    """A search could not be completed. The message says which engine and why."""


class ChallengeError(SearchError):
    """The engine served a bot challenge instead of results."""


# --- fetching ---------------------------------------------------------------

def _opener() -> urllib.request.OpenerDirector:
    """An opener with its own cookie jar. One jar per search: the warm-up GET
    and the result POST have to share it, and nothing else should."""
    jar = http.cookiejar.CookieJar()
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))


def _read(opener, url: str, data: bytes | None = None) -> tuple[int, str]:
    """GET or POST one URL, returning (status, body).

    Every transport failure becomes a SearchError. A timeout during the read,
    a reset connection and a malformed URL all arrive here as plain OSError or
    ValueError rather than as urllib's own exception types, and letting one
    through means a traceback where the caller expects one error line, and a
    dead search where the caller expects a fallback.
    """
    try:
        req = urllib.request.Request(url, data=data, headers=dict(HEADERS))
        with opener.open(req, timeout=TIMEOUT) as resp:
            charset = resp.headers.get_content_charset() or "utf-8"
            return resp.status, resp.read().decode(charset, "replace")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8", "replace")
    except urllib.error.URLError as exc:
        raise SearchError(f"{url}: {exc.reason}") from exc
    except (OSError, ValueError) as exc:
        raise SearchError(f"{url}: {exc}") from exc


# --- parsing ----------------------------------------------------------------

class _ChallengeDetector(HTMLParser):
    """Spots a bot wall by its form, not by its vocabulary.

    DuckDuckGo serves the wall as `<form id="challenge-form" action=".../anomaly.js">`.
    Searching the whole document for those two strings instead flags any results
    page that merely talks about bot walls — including one for a query the HTML
    endpoint echoes back into its own search box.
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.found = False

    def handle_starttag(self, tag, attrs):
        if tag != "form":
            return
        attrs = dict(attrs)
        action = attrs.get("action") or ""
        if attrs.get("id") == "challenge-form" or "anomaly.js" in action:
            self.found = True


def is_challenge(html: str) -> bool:
    """True when a body is a bot wall rather than results. The wall arrives as a
    normal-looking 200 or 202 page, so a status check alone reports it as an
    empty result set."""
    detector = _ChallengeDetector()
    detector.feed(html)
    detector.close()
    return detector.found


class _ResultParser(HTMLParser):
    """Shared machinery for the per-engine result parsers.

    A subclass implements `start_tag`, deciding where a result begins and which
    field the text now arriving belongs to, by calling `start_result` and
    `collect`. Everything else — tracking where a field ends, accumulating
    text, whitespace, dropping unusable results, flushing the last one at EOF —
    is the same for every engine and lives here once.
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.results: list[dict] = []
        self._current: dict | None = None
        self._field: str | None = None
        self._field_tag: str | None = None
        self._depth = 0

    def start_tag(self, tag: str, attrs: dict) -> None:
        """Called for every opening tag. Subclasses override."""

    def start_result(self, url: str) -> None:
        self._flush()
        self._current = {"title": "", "url": url, "snippet": ""}

    def collect(self, field: str, tag: str) -> None:
        """Collect text into `field` until `tag` closes at this nesting level.

        Not until any tag closes: both engines bold the query terms inside
        titles and snippets, so ending the field at the first closing tag keeps
        the words before the first highlight and drops the rest of the sentence.
        Not at the first closing tag of that name either: a nested element of
        the same name ends the field early, which is the same silent
        truncation one level down.
        """
        self._field = field
        self._field_tag = tag
        self._depth = 0

    def handle_starttag(self, tag, attrs):
        if tag == self._field_tag:
            self._depth += 1
        self.start_tag(tag, dict(attrs))

    def handle_endtag(self, tag):
        if tag != self._field_tag:
            return
        if self._depth:
            self._depth -= 1
        else:
            self._field = self._field_tag = None

    def handle_data(self, data):
        if self._field and self._current is not None:
            self._current[self._field] += data

    def _flush(self):
        current, self._current = self._current, None
        self._field = self._field_tag = None
        self._depth = 0
        if current and is_fetchable(current["url"]):
            self.results.append({k: " ".join(v.split()) for k, v in current.items()})

    def close(self):
        super().close()
        self._flush()


class _DDGParser(_ResultParser):
    """html.duckduckgo.com markup: `div.result`, title `a.result__a`, snippet
    `a.result__snippet`. The title href is sometimes a `/l/?uddg=` redirect
    wrapper around the real URL and sometimes the URL itself."""

    def start_tag(self, tag, attrs):
        classes = (attrs.get("class") or "").split()
        if tag == "div" and "result" in classes:
            self.start_result("")
        elif tag == "a" and self._current is not None:
            if "result__a" in classes:
                self._current["url"] = unwrap_redirect(attrs.get("href", ""))
                self.collect("title", "a")
            elif "result__snippet" in classes:
                self.collect("snippet", "a")


class _MojeekParser(_ResultParser):
    """mojeek.com markup: each result opens at `h2 > a.title`, snippet is `p.s`."""

    def start_tag(self, tag, attrs):
        classes = (attrs.get("class") or "").split()
        if tag == "a" and "title" in classes:
            self.start_result(unescape(attrs.get("href", "")))
            self.collect("title", "a")
        elif tag == "p" and "s" in classes and self._current is not None:
            self.collect("snippet", "p")


def is_fetchable(url: str) -> bool:
    """A result is only useful if the agent can go and read it. Scheme-relative
    and empty hrefs turn into `ValueError: unknown url type` at fetch time."""
    return urllib.parse.urlsplit(url).scheme in ("http", "https")


def unwrap_redirect(href: str) -> str:
    """Turn `//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.org%2Fdoc` into the
    real URL. Results are wrapped inconsistently, so both forms must work.

    Keyed on the wrapper's own host and path rather than on the presence of
    `uddg=` anywhere, so a result URL that happens to carry a `uddg` parameter
    of its own is passed through instead of mangled.
    """
    href = unescape(href)
    parts = urllib.parse.urlsplit(href)
    if not parts.netloc.endswith("duckduckgo.com") or parts.path != "/l/":
        return href
    return urllib.parse.parse_qs(parts.query).get("uddg", [""])[0]


# --- engines ----------------------------------------------------------------

def _ddg_html(query: str) -> str:
    """One warmed DuckDuckGo query. The GET seeds the cookie jar that the POST
    then needs; both must happen on the same opener."""
    opener = _opener()
    _read(opener, DDG_HOME)
    _, html = _read(opener, DDG_HTML, urllib.parse.urlencode({"q": query}).encode())
    return html


def _mojeek_html(query: str) -> str:
    _, html = _read(_opener(), MOJEEK + "?" + urllib.parse.urlencode({"q": query}))
    return html


class Engine:
    """One search engine: how to ask it, and how to read what comes back."""

    def __init__(self, name: str, request, parser: type[_ResultParser]) -> None:
        self.name = name
        self.request = request
        self.parser = parser

    def search(self, query: str, limit: int, attempts: int = ATTEMPTS) -> list[dict]:
        """Query until something useful comes back.

        Retries cover every transient failure, not just the challenge: a reset
        connection on attempt one is the same kind of problem as a wall. A
        challenge outranks a later empty page when reporting what went wrong,
        because it is the one the caller can do something about.
        """
        last: SearchError | None = None
        for attempt in range(attempts):
            try:
                results = parse_results(self.request(query), self.name, limit)
                if results:
                    return results
                raise SearchError(f"{self.name} returned no results")
            except SearchError as exc:
                if last is None or isinstance(exc, ChallengeError):
                    last = exc
            if attempt < attempts - 1:
                time.sleep(1.5 * (attempt + 1))
        raise last or SearchError(f"{self.name} returned no results")


ENGINES = {
    "ddg": Engine("duckduckgo", _ddg_html, _DDGParser),
    "mojeek": Engine("mojeek", _mojeek_html, _MojeekParser),
}
ENGINE_CHOICES = list(ENGINES)


def parse_results(html: str, engine: str, limit: int = 10) -> list[dict]:
    """Parse saved result HTML. Raises ChallengeError rather than returning []
    for a bot wall, because the two mean opposite things.

    The challenge check runs for every engine. Exempting all but the one engine
    whose wall we have seen puts the confusion back on the fallback path, which
    is where it does the most damage.
    """
    if is_challenge(html):
        raise ChallengeError(f"{engine} served a bot challenge, not results; "
                             "retry later or pin the other engine with --engine")
    parser = ENGINES[engine].parser()
    parser.feed(html)
    parser.close()
    return parser.results[:limit]


def search(query: str, limit: int = 10, engine: str = "auto") -> tuple[str, list[dict]]:
    """Search, returning the engine that answered along with its results.

    `auto` tries DuckDuckGo and falls back to Mojeek on any failure, because
    DuckDuckGo's wall is intermittent and a blocked search should cost a
    fallback rather than the whole task.
    """
    if engine != "auto":
        return engine, ENGINES[engine].search(query, limit)
    try:
        return "ddg", ENGINES["ddg"].search(query, limit)
    except SearchError as exc:
        print(f"note: {exc}; falling back to mojeek", file=sys.stderr)
        return "mojeek", ENGINES["mojeek"].search(query, limit)


# --- reading a page ---------------------------------------------------------

class _TextParser(HTMLParser):
    """Page text with the furniture removed. Not a renderer: enough to read an
    article and quote it, which is what a claim needs."""

    SKIP = {"script", "style", "nav", "footer", "header", "form", "noscript", "svg"}
    BREAK = {"p", "div", "br", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skipping = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self._skipping += 1
        elif tag in self.BREAK:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in self.SKIP and self._skipping:
            self._skipping -= 1

    def handle_data(self, data):
        if not self._skipping and data.strip():
            self.parts.append(data.strip())

    def text(self) -> str:
        joined = " ".join(self.parts)
        joined = re.sub(r" *\n *", "\n", joined)
        return re.sub(r"\n{3,}", "\n\n", joined).strip()


def fetch(url: str, max_chars: int = 6000) -> str:
    """A page as text. No bot detection: an interstitial or a consent wall comes
    back as page text like anything else, so read what you got before quoting
    it."""
    status, html = _read(_opener(), url)
    if status >= 400:
        raise SearchError(f"{url}: HTTP {status}")
    parser = _TextParser()
    parser.feed(html)
    parser.close()
    return parser.text()[:max_chars]


# --- commands ---------------------------------------------------------------

def cmd_search(args) -> int:
    engine, results = search(args.query, args.n, args.engine)
    if args.json:
        print(json.dumps({"engine": engine, "results": results}, indent=2))
        return 0
    for i, result in enumerate(results, 1):
        print(f"{i}. {result['title']}\n   {result['url']}")
        if result["snippet"]:
            print(f"   {result['snippet']}")
    print(f"\n({len(results)} results from {engine})", file=sys.stderr)
    return 0


def cmd_fetch(args) -> int:
    print(fetch(args.url, args.chars))
    return 0


def cmd_parse(args) -> int:
    if sys.stdin.isatty():
        print("parse reads saved HTML on stdin: websearch.py parse < saved.html",
              file=sys.stderr)
        return 2
    results = parse_results(sys.stdin.read(), args.engine, args.n)
    if not results:
        print("no results parsed", file=sys.stderr)
        return 1
    print(json.dumps(results, indent=2))
    return 0


def cmd_selftest(args) -> int:
    """Every claim this skill makes about an engine is a claim about someone
    else's bot detection, which changes without notice. This rechecks them."""
    query = "clean architecture dependency rule"
    working = 0
    for name, engine in ENGINES.items():
        try:
            results = engine.search(query, 3)
        except SearchError as exc:
            print(f"[fail] {name}: {exc}")
        else:
            working += 1
            print(f"[ok]   {name}: {len(results)} results, first is {results[0]['url']}")
    if not working:
        print("\nno engine works from here; the SKILL.md engine table is out of date",
              file=sys.stderr)
        return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="websearch.py",
        description="Keyless web search, and a way to read the page behind a result.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("search", help="search the web")
    p.add_argument("query")
    p.add_argument("-n", type=int, default=8, help="results to show (default 8)")
    p.add_argument("--engine", choices=["auto"] + ENGINE_CHOICES, default="auto")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_search)

    p = sub.add_parser("fetch", help="print a page as text")
    p.add_argument("url")
    p.add_argument("--chars", type=int, default=6000, help="truncate (default 6000)")
    p.set_defaults(func=cmd_fetch)

    p = sub.add_parser("parse", help="parse saved result HTML from stdin")
    p.add_argument("--engine", choices=ENGINE_CHOICES, default="ddg")
    p.add_argument("-n", type=int, default=10)
    p.set_defaults(func=cmd_parse)

    p = sub.add_parser("selftest", help="check which engines still work")
    p.set_defaults(func=cmd_selftest)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except SearchError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
