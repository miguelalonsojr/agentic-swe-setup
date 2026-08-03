#!/usr/bin/env python3
"""Create a Jira epic, stories and sub-tasks from a structured markdown backlog.

Commands
  parse [FILE]    Parse only. Prints the hierarchy. No network, no credentials.
  wiki  WHAT      Print one converted description: `epic`, `3` (story), `3.2` (task).
  probe           Show the project's issue types and whether it is team- or
                  company-managed. Read-only.
  fields          Show required fields per issue type. Read-only. Run this before
                  a first create against an unfamiliar project.
  create          Create the issues. Honours JIRA_EPIC_KEY and --epic-only.
  verify          Re-read what was created and check every parent link.

Environment
  JIRA_SITE      required, e.g. https://acme.atlassian.net
  JIRA_PROJECT   required, e.g. CORE
  JIRA_EMAIL     required, Atlassian account email
  JIRA_TOKEN     required, API token. Read it from a file; never paste it into
                 a prompt or a shell history:
                     JIRA_TOKEN="$(cat ~/.jira-token)"
  JIRA_BACKLOG_MD  path to the markdown backlog (or pass it as an argument)
  JIRA_EPIC_KEY    reuse an existing epic instead of creating one
  JIRA_CREATED_JSON  where to write the key mapping (default ./jira-created.json)

Expected markdown shape
  ## EPIC: <summary>          one per file
  ## Ticket <n>: <summary>    becomes a Story
  ### Task <n>.<m>: <summary> becomes a Sub-task of that Story
  Body text under each heading becomes the description. A `---` line or a
  `## Summary` heading ends the current body.

Creation uses REST API v2 so descriptions are plain wiki markup rather than ADF.
Verification uses /rest/api/3/search/jql; the v2 search endpoint was removed by
Atlassian in 2025.
"""
from __future__ import annotations

import base64
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request


def env(name: str) -> str:
    v = os.environ.get(name, "").strip()
    if not v:
        raise SystemExit(f"{name} is not set. See --help at the top of this file.")
    return v


def backlog_path(argv: list[str]) -> str:
    for a in argv:
        if not a.startswith("-") and a.endswith(".md"):
            return a
    p = os.environ.get("JIRA_BACKLOG_MD", "")
    if not p:
        raise SystemExit("pass the backlog path as an argument or set JIRA_BACKLOG_MD")
    return p


# ── parsing ────────────────────────────────────────────────────────────────


def parse(path: str) -> dict:
    """Read the backlog into {epic, stories[{tasks[]}]}."""
    lines = open(path, encoding="utf-8").read().splitlines()

    epic: dict | None = None
    stories: list[dict] = []
    current_story: dict | None = None
    current: dict | None = None
    buf: list[str] = []

    def flush() -> None:
        """Assign the buffered body to whichever issue is currently open.

        Clearing `current` matters: without it a later flush with an empty
        buffer overwrites a description that was already captured.
        """
        nonlocal buf, current
        if current is not None:
            current["description"] = "\n".join(buf).strip()
        buf = []
        current = None

    for line in lines:
        m_epic = re.match(r"^## EPIC:\s*(.+?)\s*$", line)
        m_story = re.match(r"^## Ticket \d+:\s*(.+?)\s*$", line)
        m_task = re.match(r"^### Task (\d+)\.(\d+):\s*(.+?)\s*$", line)

        if m_epic:
            flush()
            epic = {"summary": m_epic.group(1), "description": ""}
            current, current_story = epic, None
            continue
        if m_story:
            flush()
            current_story = {"summary": m_story.group(1), "description": "", "tasks": []}
            stories.append(current_story)
            current = current_story
            continue
        if m_task:
            flush()
            if current_story is None:
                raise SystemExit(f"task {m_task.group(1)}.{m_task.group(2)} appears before any Ticket")
            task = {
                "summary": m_task.group(3),
                "description": "",
                "n": f"{m_task.group(1)}.{m_task.group(2)}",
            }
            current_story["tasks"].append(task)
            current = task
            continue
        if line.strip() == "---":
            flush()
            continue
        if current is not None:
            buf.append(line)

    flush()

    def strip_trailer(d: dict) -> None:
        d["description"] = re.split(r"^## \w", d["description"], flags=re.M)[0].strip()

    if epic is None:
        raise SystemExit(f"no '## EPIC: ...' heading found in {path}")
    strip_trailer(epic)
    for s in stories:
        strip_trailer(s)
        for t in s["tasks"]:
            strip_trailer(t)
    return {"epic": epic, "stories": stories}


# ── markdown -> Jira wiki markup ───────────────────────────────────────────


def to_wiki(md: str) -> str:
    """Convert the markdown subset used in backlogs to Jira wiki markup.

    Jira renders a single newline as a hard line break, so wrapped paragraphs
    and wrapped list items are rejoined onto one line first; skip that and every
    description arrives as a column of short ragged lines.

    Checkboxes become plain bullets. Wiki markup has no checkbox, and the (/)
    emoticon reads as "done" rather than "to do".
    """
    out: list[str] = []
    for block in re.split(r"\n\s*\n", md.strip()):
        lines = block.splitlines()
        if any(re.match(r"^\s*- ", ln) for ln in lines):
            items: list[str] = []
            for ln in lines:
                m = re.match(r"^\s*- (?:\[[ xX]\] )?(.*)$", ln)
                if m:
                    items.append(m.group(1).strip())
                elif items:
                    items[-1] += " " + ln.strip()
                else:
                    items.append(ln.strip())
            out.append("\n".join("* " + i for i in items))
        else:
            out.append(" ".join(ln.strip() for ln in lines if ln.strip()))

    text = "\n\n".join(out)
    text = re.sub(r"`([^`]+)`", r"{{\1}}", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"*\1*", text)
    return text


# ── http ───────────────────────────────────────────────────────────────────


def call(method: str, path: str, payload: dict | None = None) -> dict:
    raw = f"{env('JIRA_EMAIL')}:{env('JIRA_TOKEN')}".encode()
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(env("JIRA_SITE").rstrip("/") + path, data=data, method=method)
    req.add_header("Authorization", "Basic " + base64.b64encode(raw).decode())
    req.add_header("Accept", "application/json")
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            body = r.read().decode()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> HTTP {e.code}\n{e.read().decode()[:800]}") from None


def out_path() -> str:
    return os.environ.get("JIRA_CREATED_JSON", "jira-created.json")


# ── commands ───────────────────────────────────────────────────────────────


def cmd_parse(path: str) -> None:
    data = parse(path)
    print(f"EPIC: {data['epic']['summary']}  ({len(data['epic']['description'])} chars)")
    n = 0
    for i, s in enumerate(data["stories"], 1):
        print(f"\nSTORY {i}: {s['summary']}  ({len(s['description'])} chars)")
        for t in s["tasks"]:
            n += 1
            print(f"    SUB-TASK {t['n']}: {t['summary']}  ({len(t['description'])} chars)")
    print(f"\n{len(data['stories'])} stories, {n} sub-tasks")
    empty = [data["epic"]["summary"]] if not data["epic"]["description"] else []
    empty += [s["summary"] for s in data["stories"] if not s["description"]]
    empty += [t["summary"] for s in data["stories"] for t in s["tasks"] if not t["description"]]
    if empty:
        print("\nWARNING - no description parsed for:")
        for e in empty:
            print(f"  {e}")


def cmd_wiki(path: str, which: str) -> None:
    d = parse(path)
    if which == "epic":
        print(to_wiki(d["epic"]["description"]))
    elif "." in which:
        a, b = which.split(".")
        print(to_wiki(d["stories"][int(a) - 1]["tasks"][int(b) - 1]["description"]))
    else:
        print(to_wiki(d["stories"][int(which) - 1]["description"]))


def project() -> dict:
    return call("GET", f"/rest/api/2/project/{env('JIRA_PROJECT')}")


def cmd_probe() -> None:
    p = project()
    print(f"project : {p['key']} - {p['name']}")
    print(f"style   : {p.get('style', '?')}  simplified={p.get('simplified')}")
    print("issue types:")
    for it in p.get("issueTypes", []):
        print(f"  {it['name']:<20} id={it['id']:<8} subtask={it.get('subtask')} level={it.get('hierarchyLevel')}")


def cmd_fields() -> None:
    """Show required fields per type. Classic projects sometimes demand an Epic
    Name, or link stories to epics through a custom field rather than `parent`."""
    q = urllib.parse.urlencode({"projectKeys": env("JIRA_PROJECT"), "expand": "projects.issuetypes.fields"})
    meta = call("GET", f"/rest/api/2/issue/createmeta?{q}")
    projects = meta.get("projects", [])
    if not projects:
        raise SystemExit(f"no createmeta for {env('JIRA_PROJECT')}; check the key and your permissions")
    for it in projects[0]["issuetypes"]:
        print(f"=== {it['name']} (id {it['id']}) ===")
        for fid, f in it["fields"].items():
            if f.get("required") or fid == "parent" or "epic" in f["name"].lower():
                print(f"  {'REQ ' if f.get('required') else '    '} {fid:<24} {f['name']}")
        print()


def type_ids() -> tuple[str, str, str]:
    by_name = {it["name"].lower(): it for it in project().get("issueTypes", [])}

    def pick(*names: str) -> dict:
        for n in names:
            if n in by_name:
                return by_name[n]
        raise SystemExit(f"none of {names} exist in {env('JIRA_PROJECT')}: {sorted(by_name)}")

    return pick("epic")["id"], pick("story", "task")["id"], pick("sub-task", "subtask", "sub task")["id"]


def create_issue(fields: dict) -> str:
    return call("POST", "/rest/api/2/issue", {"fields": fields})["key"]


def cmd_create(path: str, epic_only: bool) -> None:
    data = parse(path)
    epic_id, story_id, subtask_id = type_ids()
    proj = {"key": env("JIRA_PROJECT")}

    epic_key = os.environ.get("JIRA_EPIC_KEY", "")
    if epic_key:
        print(f"EPIC {epic_key}  (existing, not recreated)")
    else:
        epic_key = create_issue({
            "project": proj,
            "issuetype": {"id": epic_id},
            "summary": data["epic"]["summary"],
            "description": to_wiki(data["epic"]["description"]),
        })
        print(f"EPIC {epic_key}  {data['epic']['summary']}")

    if epic_only:
        print(f"\nStopping after the epic. Check it renders, then re-run with JIRA_EPIC_KEY={epic_key}")
        return

    created = {"epic": epic_key, "stories": []}
    for s in data["stories"]:
        skey = create_issue({
            "project": proj,
            "issuetype": {"id": story_id},
            "summary": s["summary"],
            "description": to_wiki(s["description"]),
            "parent": {"key": epic_key},
        })
        print(f"  STORY {skey}  {s['summary']}")
        subs = []
        for t in s["tasks"]:
            tkey = create_issue({
                "project": proj,
                "issuetype": {"id": subtask_id},
                "summary": t["summary"],
                "description": to_wiki(t["description"]),
                "parent": {"key": skey},
            })
            print(f"    SUB-TASK {tkey}  {t['summary']}")
            subs.append({"key": tkey, "n": t["n"], "summary": t["summary"]})
        created["stories"].append({"key": skey, "summary": s["summary"], "tasks": subs})
        # Written every story, so a failure part way through still leaves a
        # record of what exists. Re-running blind would duplicate issues.
        with open(out_path(), "w") as f:
            json.dump(created, f, indent=2)

    print(f"\nwrote {out_path()}")


def cmd_verify() -> None:
    """Re-read the created issues and check the hierarchy actually landed.

    Creation returning 201 says a row was written, not that it is parented
    where you asked. Verify from the server, not from the create responses.
    """
    try:
        created = json.load(open(out_path()))
    except FileNotFoundError:
        raise SystemExit(f"{out_path()} not found; run create first") from None

    parents = [created["epic"]] + [s["key"] for s in created["stories"]]
    jql = " OR ".join(f"parent = {p}" for p in parents)
    q = urllib.parse.urlencode({"jql": jql, "fields": "summary,issuetype,parent", "maxResults": 200})
    res = call("GET", f"/rest/api/3/search/jql?{q}")

    issues = res.get("issues", [])
    kids: dict[str, int] = {}
    orphans, types = [], {}
    for i in issues:
        t = i["fields"]["issuetype"]["name"]
        types[t] = types.get(t, 0) + 1
        par = (i["fields"].get("parent") or {}).get("key")
        if par:
            kids[par] = kids.get(par, 0) + 1
        else:
            orphans.append(i["key"])

    expected = len(created["stories"]) + sum(len(s["tasks"]) for s in created["stories"])
    print(f"epic     : {created['epic']}")
    print(f"found    : {len(issues)} of {expected} expected")
    for t, c in sorted(types.items()):
        print(f"  {t:<12} {c}")
    print(f"orphans  : {orphans or 'none'}")
    for s in created["stories"]:
        got, want = kids.get(s["key"], 0), len(s["tasks"])
        mark = "ok " if got == want else "BAD"
        print(f"  {mark} {s['key']} {got}/{want}  {s['summary']}")

    bad = orphans or len(issues) != expected or any(
        kids.get(s["key"], 0) != len(s["tasks"]) for s in created["stories"]
    )
    raise SystemExit(1 if bad else 0)


def main() -> None:
    argv = sys.argv[1:]
    cmd = argv[0] if argv else "parse"
    if cmd == "parse":
        cmd_parse(backlog_path(argv[1:]))
    elif cmd == "wiki":
        rest = [a for a in argv[1:] if not a.endswith(".md")]
        cmd_wiki(backlog_path(argv[1:]), rest[0] if rest else "epic")
    elif cmd == "probe":
        cmd_probe()
    elif cmd == "fields":
        cmd_fields()
    elif cmd == "create":
        cmd_create(backlog_path(argv[1:]), "--epic-only" in argv)
    elif cmd == "verify":
        cmd_verify()
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
