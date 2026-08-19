class NodespaceCli < Formula
  desc "Headless CLI and daemon for NodeSpace, a local-first knowledge graph"
  homepage "https://nodespace.ai"
  # Kept explicit (rather than letting `brew audit` infer it from the url
  # below) so a future version bump is a single-line diff that every
  # `#{version}`-interpolated url picks up -- same reasoning
  # scripts/update-homebrew-cask.ts documents for the sibling cask.
  # `brew audit --strict` flags this as "redundant with version scanned
  # from URL"; that's a known, accepted trade-off, not an oversight.
  version "0.2.0"
  # nodespace-core's actual LICENSE file is FSL-1.1-Apache-2.0 (Functional
  # Source License), which has no SPDX identifier -- `license
  # :cannot_represent` is Homebrew's documented escape hatch for exactly
  # this case (a real license that isn't in SPDX's list), verified against
  # `brew audit --strict` (a literal SPDX-style string here fails audit:
  # "contains non-standard SPDX licenses").
  license :cannot_represent

  # A plain local var, not the `version` DSL method: inside a nested
  # `resource "nodespaced" do ... end` block below, `self` is the Resource,
  # not the Formula, so `#{version}` there resolves to the RESOURCE's own
  # (unset, empty) version rather than the Formula's -- confirmed the hard
  # way: `brew install` 404'd on ".../releases/download/v/nodespaced-..."
  # (empty version segment) before this was pulled out as a captured local.
  release_version = version

  # Distinct from the `nodespace` cask (installs the full GUI app, which
  # bundles its own nodespaced + nodespace CLI under NodeSpace.app). This
  # formula is the headless-only path: `brew install nodespace-cli`, no
  # GUI, no Applications entry. See NodeSpaceAI/nodespace-core#2146.
  #
  # Ships prebuilt binaries from nodespace-core's GitHub Releases, same as
  # the cask -- there's no source build here, just like the cask's .dmg.
  #
  # v0.2.0 has no macOS Intel build (see the on_intel odie below and
  # NodeSpaceAI/nodespace-core#2154, the same single-arch situation the
  # cask already had to render honestly). NOTE: the release's own
  # SHA256SUMS file lists checksums for nodespace-x86_64-apple-darwin /
  # nodespaced-x86_64-apple-darwin even though neither is an actual
  # uploaded release asset -- verified against `gh release view v0.2.0
  # --json assets`, not just SHA256SUMS. Every digest below was computed
  # locally from bytes actually downloaded from the release, never copied
  # from SHA256SUMS.
  on_macos do
    on_arm do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-aarch64-apple-darwin"
      sha256 "4552580f6e1106c7c1d2f8ab07fd2ecdf758da75e5aeb6cdd1a57fb48890a348"
    end
    on_intel do
      odie "nodespace-cli has no macOS Intel build in v#{release_version}. " \
           "Use the nodespace-cli formula on Apple Silicon or Linux, or " \
           "`cargo install nodespace-cli` in the meantime -- see " \
           "NodeSpaceAI/nodespace-core#2154."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-aarch64-unknown-linux-gnu"
      sha256 "7126df3ec590f3e89dbbecec1263c256b472cb0e342e5750c35f5a694cd4f24e"
    end
    on_intel do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-x86_64-unknown-linux-gnu"
      sha256 "29ac367ccf6f6be5c5ceaf944babf58f386988cf3382e024039cafab85bd65b5"
    end
  end

  # The CLI is useless without the daemon it talks to over a Unix socket
  # (see packages/skill/SKILL.md's Prerequisites section in nodespace-core)
  # -- this formula installs both, matching what the cask's .app bundle
  # already ships (nodespaced alongside the CLI).
  resource "nodespaced" do
    on_macos do
      on_arm do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-aarch64-apple-darwin"
        sha256 "e205379ee1e1c9cc778ff801543fcb9c2d40bb5a461f6ac0e4fffeb5d99687b6"
      end
    end
    on_linux do
      on_arm do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-aarch64-unknown-linux-gnu"
        sha256 "77a355970af7c8ee678ac04b1cfc35d40fa9ee8cddd5cfc49374db12e58b10fd"
      end
      on_intel do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-x86_64-unknown-linux-gnu"
        sha256 "4d427bbec004d4b9c84f7abfcc0f0e9fb80b0acc5d17822ce86c6bff25437da6"
      end
    end
  end

  def install
    # Each on_macos/on_linux branch above resolves to exactly one url, so
    # exactly one nodespace-<triple> file is present in the staging dir --
    # `Dir[...]` sidesteps hardcoding the per-branch filename a second time.
    bin.install Dir["nodespace-*"].first => "nodespace"
    resource("nodespaced").stage do
      bin.install Dir["nodespaced-*"].first => "nodespaced"
    end
  end

  service do
    run [opt_bin/"nodespaced"]
    keep_alive false
    log_path var/"log/nodespace/nodespaced.log"
    error_log_path var/"log/nodespace/nodespaced.log"
  end

  def caveats
    <<~EOS
      nodespaced (the daemon) must be running before `nodespace` commands work:
        nodespaced &            # run directly, or
        brew services start nodespace-cli   # run as a background service

      This is the headless CLI only -- no GUI, no Applications entry. For
      the full app, use `brew install --cask nodespace` instead (the two
      can coexist; see NodeSpaceAI/nodespace-core#2146's Detection section).
    EOS
  end

  test do
    output = shell_output("#{bin}/nodespace --version")
    assert_match version.to_s, output
  end
end
