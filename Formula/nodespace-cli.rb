class NodespaceCli < Formula
  desc "Headless CLI and daemon for NodeSpace, a local-first knowledge graph"
  homepage "https://nodespace.ai"
  # Kept explicit (rather than letting `brew audit` infer it from the url
  # below) so a future version bump is a single-line diff that every
  # `#{version}`-interpolated url picks up -- same reasoning
  # scripts/update-homebrew-cask.ts documents for the sibling cask.
  # `brew audit --strict` flags this as "redundant with version scanned
  # from URL"; that's a known, accepted trade-off, not an oversight.
  version "0.2.5"
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
  #
  # Must be assigned BEFORE the on_macos/on_linux blocks below: Ruby
  # decides whether a bare identifier is a local-variable reference or a
  # method call at PARSE time, based on whether an assignment to that name
  # has already been seen earlier in the source -- not at block-execution
  # time. `brew style --fix`'s automatic stanza reordering (which moves
  # on_macos/on_linux up, ahead of conflicts_with, per
  # FormulaAudit/ComponentsOrder) will happily move them above this
  # assignment too if run carelessly, which turns `#{release_version}`
  # into an undefined-local-variable-or-method error the moment the block
  # runs (confirmed by actually running `brew style --fix` and then `brew
  # audit` against the result). Keep this line above both blocks.
  release_version = version

  # Distinct from the `nodespace` cask (installs the full GUI app, which
  # bundles its own nodespaced + nodespace CLI under NodeSpace.app). This
  # formula is the headless-only path: `brew install nodespace-cli`, no
  # GUI, no Applications entry.
  #
  # Ships prebuilt binaries from nodespace-core's GitHub Releases, same as
  # the cask -- there's no source build here, just like the cask's .dmg.
  #
  # v0.2.5 has no macOS Intel build (see the on_intel odie below). NOTE:
  # the release's own SHA256SUMS file lists checksums for
  # nodespace-x86_64-apple-darwin / nodespaced-x86_64-apple-darwin even
  # though neither is an actual uploaded release asset -- verified against
  # `gh release view v0.2.5 --json assets`, not just SHA256SUMS. Every
  # digest below was computed locally from bytes actually downloaded from
  # the release, never copied from SHA256SUMS.
  on_macos do
    on_arm do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-aarch64-apple-darwin"
      sha256 "cee5a4e0fb05f8a75101f2d803b9a6752daee3d440055f2632e8bf6bf8128745"
    end
    on_intel do
      odie "nodespace-cli has no macOS Intel build in v#{release_version}. " \
           "Use the nodespace-cli formula on Apple Silicon or Linux, or " \
           "`cargo install nodespace-cli` in the meantime."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-aarch64-unknown-linux-gnu"
      sha256 "5019b9a202d5eccd18382d989ac3f9b3e16a5fbdcbc7c0efcb679f69f7428501"
    end
    on_intel do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-x86_64-unknown-linux-gnu"
      sha256 "a4dfd9ada90790ca7cd398821f97d528ca33f5628543ae72d38067a4ce25ac89"
    end
  end

  # NOTE: a real, verified path collision. The cask's `binary` stanza and
  # this formula's `bin.install ... => "nodespace"` both resolve to the
  # same symlink path, $(brew --prefix)/bin/nodespace. There is no
  # Homebrew mechanism that actually prevents this across the cask/formula
  # boundary -- verified directly, not assumed: `conflicts_with cask:
  # "..."` is accepted by the formula DSL but has NO enforcement effect
  # (confirmed: installing this formula while the cask's bin/nodespace
  # symlink exists still succeeds); the cask-side mirror,
  # `conflicts_with formula: "..."`, doesn't exist at all in current
  # Homebrew (`Unknown key: :formula. Valid keys are: :cask`). So neither
  # side can declare this.
  #
  # What Homebrew actually does (also verified directly, with a synthetic
  # cask providing a real bin/nodespace symlink and then installing this
  # formula against it): the SECOND of the two to install still installs
  # its files into its own Cellar keg successfully, but `brew link` skips
  # the conflicting bin/nodespace symlink with a clear "already exists"
  # warning rather than either failing outright or silently overwriting
  # it -- and it skips linking bin/nodespaced too (Homebrew links a keg's
  # files as a unit, not file-by-file), even though nodespaced's name
  # doesn't collide with anything. `brew link --overwrite nodespace-cli`
  # (or the equivalent for the cask) resolves it, consciously choosing
  # which copy PATH should resolve to. `brew services start nodespace-cli`
  # still works either way -- see the caveats below.

  # The CLI is useless without the daemon it talks to over a Unix socket
  # -- this formula installs both, matching what the cask's .app bundle
  # already ships (nodespaced alongside the CLI).
  resource "nodespaced" do
    on_macos do
      on_arm do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-aarch64-apple-darwin"
        sha256 "8bbe45cc97c880d7f5cfb999d1a378faf4979a5eeacd44e74e8a30a1abdba47a"
      end
    end
    on_linux do
      on_arm do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-aarch64-unknown-linux-gnu"
        sha256 "8578c5bde376dae22a9f781397acda68abc6283ebe0107d18586c042d9115bce"
      end
      on_intel do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-x86_64-unknown-linux-gnu"
        sha256 "e114474be8c3b424190e9d797f04e5cccdbe52d61357dda379be5cf34e713dd5"
      end
    end
  end

  def install
    # Each on_macos/on_linux branch above resolves to exactly one url, so
    # exactly one nodespace-<triple> file is present in the staging dir --
    # `Dir[...]` sidesteps hardcoding the per-branch filename a second
    # time. Guarded explicitly rather than letting a missing/renamed
    # asset surface as a bare Ruby TypeError on `nil => "nodespace"`.
    #
    # Explicit chmod after each install: verified in an isolated Homebrew
    # prefix that the downloaded binaries already land executable (the
    # release build pipeline chmods them before upload, and Homebrew's own
    # install path preserved that through a real `brew install` -- `ls -la`
    # showed `-r-xr-xr-x` and `brew test` passed without this line). Kept
    # anyway as a zero-cost guarantee that doesn't depend on the upload
    # pipeline or Homebrew's internals continuing to behave that way.
    cli_binary = Dir["nodespace-*"].first
    odie "no nodespace-<triple> binary found in the downloaded archive" if cli_binary.nil?
    bin.install cli_binary => "nodespace"
    (bin/"nodespace").chmod 0755

    resource("nodespaced").stage do
      daemon_binary = Dir["nodespaced-*"].first
      odie "no nodespaced-<triple> binary found in the downloaded archive" if daemon_binary.nil?
      bin.install daemon_binary => "nodespaced"
      (bin/"nodespaced").chmod 0755
    end
  end

  service do
    run [opt_bin/"nodespaced"]
    # `keep_alive false` is a no-op, not "don't restart" -- Homebrew's
    # `keep_alive?` is only true when this is explicitly set truthy, and
    # false/omitted both leave it false either way. `true` here is what
    # actually gets launchd/systemd to relaunch nodespaced if it crashes,
    # which is the whole point of `brew services start` over just running
    # the binary directly (see the caveats above). `brew services stop`
    # still works normally -- it unloads the service definition rather
    # than fighting KeepAlive.
    keep_alive true
    log_path var/"log/nodespace/nodespaced.log"
    error_log_path var/"log/nodespace/nodespaced.log"
  end

  def caveats
    <<~EOS
      nodespaced (the daemon) must be running before `nodespace` commands work:
        nodespaced &            # run directly, or
        brew services start nodespace-cli   # run as a background service

      This is the headless CLI only -- no GUI, no Applications entry. For
      the full app, use `brew install --cask nodespace` instead. Both CAN
      be installed at once, but they claim the same `nodespace` binary
      name on PATH: whichever installs second gets its bin/nodespace link
      skipped with a warning rather than silently overwritten. Run
      `brew link --overwrite nodespace-cli` (or `--overwrite nodespace`
      for the cask) to choose which one PATH resolves to.
      `brew services start nodespace-cli` and running `nodespaced`
      directly both work regardless of link state.
    EOS
  end

  test do
    cli_output = shell_output("#{bin}/nodespace --version")
    assert_match version.to_s, cli_output

    # Also asserts the nested `nodespaced` resource actually installed and
    # runs -- a regression in its Dir-glob/sha256/install-target handling
    # would otherwise pass this test block while leaving the daemon (which
    # every `nodespace` command depends on) silently missing.
    assert_path_exists bin/"nodespaced"
    assert_predicate bin/"nodespaced", :executable?
    daemon_output = shell_output("#{bin}/nodespaced --version")
    assert_match version.to_s, daemon_output
  end
end
