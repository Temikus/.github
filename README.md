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
- Indirect Go modules tracked, so vulnerability fixes reach them. Routine bumps to them wait for dashboard approval.

## Shared justfile recipes

`template/` is a [Copier](https://copier.readthedocs.io) template. It renders `just/common.just`, which holds the shared `release` and `sync-common` recipes. Adopt it once from a repo's root:

```bash
uvx copier copy gh:Temikus/.github .
```

Then import it at the top of the repo's `justfile`. A recipe of the same name in the `justfile` overrides the imported one.

```just
set allow-duplicate-recipes

import 'just/common.just'
```

To change a recipe, edit `template/just/common.just` here and tag a release. Renovate's [Copier manager](https://docs.renovatebot.com/modules/manager/copier/) then opens an update PR in each repo. Use a major tag for a breaking change.

## Development

Tools are pinned in `mise.toml`; run `mise install` first.

```bash
just lint             # validate both Renovate configs, actionlint, justfile format
just test             # check the preset on tests/fixture and the template in a scratch repo
just check            # lint + test, as CI runs it
just dry-run ../repo  # show what the preset finds in another checkout
```

`just test` and `just dry-run` look up versions on GitHub, so they need network and a token (`GITHUB_COM_TOKEN`, or `gh auth login`).

## License

[Apache 2.0](LICENSE)
