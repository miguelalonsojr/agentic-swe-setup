# plain-technical-prose

A register for prose that should read as a specification: documentation, design
specs, READMEs, commit messages, PR descriptions, issue bodies, code comments.
`SKILL.md` is the agent-facing guide; there is nothing to run by hand.

## Where it came from

Vendored verbatim from philpax's nixos-configuration repo:

    https://github.com/philpax/nixos-configuration/blob/main/common-dev/dotfiles/.agents/skills/plain-technical-prose/SKILL.md

The only local change is the `name:` field added to the frontmatter, which this
repo's tests and Claude Code both expect. The upstream repo declares no license;
the file is carried here as configuration with attribution, not relicensed.
Refresh by re-copying the upstream file and re-adding the `name:` line.

## Related

- `de-slop`, from swe-skills: removes AI writing patterns and rewrites toward a
  specific human voice. This skill instead targets a fixed specification
  register: third person, no emphasis typography, no rhetoric.
