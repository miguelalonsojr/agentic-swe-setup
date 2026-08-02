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
