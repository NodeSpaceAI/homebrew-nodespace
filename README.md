# homebrew-nodespace

Homebrew tap for [NodeSpace](https://nodespace.app) — AI-native local-first knowledge management.

## Install

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

## Official cask

Once NodeSpace has two stable releases, it will be submitted to [homebrew/homebrew-cask](https://github.com/Homebrew/homebrew-cask) for `brew install --cask nodespace` without the tap step.
