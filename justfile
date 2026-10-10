set shell := ["bash", "-euo", "pipefail", "-c"]

# Model provider for the Prime Agent ladder: anthropic or openai.
provider := "anthropic"

_scripts := justfile_directory() / "scripts"

# Show available recipes
default:
    @just --list

# Install into Prime Agent
install: install-prime
    @echo
    @{{ _scripts }}/doctor.sh

# Install Superpowers, repository-owned skills, subagent specs, and instructions for Prime Agent
install-prime:
    @{{ _scripts }}/install-prime.sh {{ provider }}

# Link this repo's own skills into Prime Agent
install-skills:
    @{{ _scripts }}/install-skills.sh

# Report what is and is not installed; changes nothing
doctor:
    @{{ _scripts }}/doctor.sh

# Refresh skills and links in place
update:
    @{{ _scripts }}/update.sh

# Remove what this repo installed
uninstall:
    @{{ _scripts }}/uninstall.sh

# Run the test suite
test:
    @bash tests/run.sh
