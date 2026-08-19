# homebrew-nodespace

Homebrew tap for [NodeSpace](https://nodespace.app) — AI-native local-first knowledge management.

Two install paths, for two different things:

|  | `nodespace` (cask) | `nodespace-cli` (formula) |
|---|---|---|
| Installs | The full GUI app (`NodeSpace.app`) | Headless `nodespace` CLI + `nodespaced` daemon only |
| Use when | You want the desktop app | You want a scriptable/server/CI install with no GUI |

The two can coexist on the same machine — see the Detection section of
[NodeSpaceAI/nodespace-core#2146](https://github.com/NodeSpaceAI/nodespace-core/issues/2146).

## Install the GUI app

```bash
brew tap nodespaceai/nodespace
brew install --cask nodespace
```

## Upgrade

```bash
brew upgrade --cask nodespace
```

## Uninstall

```bash
# Remove app only (preserves data in ~/.nodespace/database)
brew uninstall --cask nodespace

# Remove app and all NodeSpace data
brew uninstall --zap --cask nodespace
```

## Install the headless CLI

```bash
brew install nodespaceai/nodespace/nodespace-cli
```

Installs both `nodespace` (the CLI) and `nodespaced` (the daemon it talks
to over a Unix socket — `nodespace` commands fail until it's running).
Start it directly (`nodespaced &`) or as a managed background service:

```bash
brew services start nodespace-cli
```

Upgrade/uninstall follow the usual formula commands (`brew upgrade
nodespace-cli`, `brew uninstall nodespace-cli`). macOS Intel isn't built
yet for this formula — see the `on_intel` note in
`Formula/nodespace-cli.rb`.

## Official cask

Once NodeSpace has two stable releases, it will be submitted to [homebrew/homebrew-cask](https://github.com/Homebrew/homebrew-cask) for `brew install --cask nodespace` without the tap step.
