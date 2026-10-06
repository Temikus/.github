# Temikus/.github

[![CI](https://github.com/Temikus/.github/actions/workflows/ci.yml/badge.svg)](https://github.com/Temikus/.github/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Shared CI and dependency configuration for Temikus repositories, plus the default `SECURITY.md` GitHub shows for repos without their own.

## Renovate preset

`default.json` is a Renovate preset. Use it from a repo's `renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Temikus/.github"]
}
```

It adds, on top of `config:recommended`:

- Monday-morning batches, with vulnerability fixes at any time.
- Pins in workflows, `justfile` and `just/*.just` marked with a comment:

  ```bash
  # renovate: datasource=github-releases depName=betterleaks/betterleaks
  VERSION="v1.9.0"
  ```

- One PR for all action digest bumps.
- One PR per tool pinned in both `mise.toml` and a workflow (betterleaks, golangci-lint).

## Development

Tools are pinned in `mise.toml`; run `mise install` first.

```bash
just lint             # validate both Renovate configs, actionlint, justfile format
just test             # run Renovate on tests/fixture and check what the preset finds
just check            # lint + test, as CI runs it
just dry-run ../repo  # show what the preset finds in another checkout
```

`just test` and `just dry-run` look up versions on GitHub, so they need network and a token (`GITHUB_COM_TOKEN`, or `gh auth login`).

## License

[Apache 2.0](LICENSE)
