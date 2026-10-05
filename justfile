set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Validate the Renovate configs, lint workflows and justfile formatting
lint:
    mise x -- renovate-config-validator --strict --no-global default.json renovate.json
    mise x -- actionlint
    just --fmt --check

# Check the preset against tests/fixture: what it extracts and how it groups bumps
test:
    tests/preset_test.sh

# Every gate CI runs
check: lint test

# List the dependencies and pending bumps the preset finds in a local checkout
dry-run dir:
    #!/usr/bin/env bash
    set -euo pipefail
    eval "$(mise env -s bash)"
    export GITHUB_COM_TOKEN="${GITHUB_COM_TOKEN:-$(gh auth token)}"
    export RENOVATE_CONFIG_FILE="$PWD/default.json"
    cd "{{ invocation_directory() }}" && cd "{{ dir }}"
    LOG_LEVEL=info renovate --platform=local --dry-run=lookup --require-config=ignored --onboarding=false
