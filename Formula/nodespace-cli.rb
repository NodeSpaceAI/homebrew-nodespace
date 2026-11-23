class NodespaceCli < Formula
  desc "Headless CLI and daemon for NodeSpace, a local-first knowledge graph"
  homepage "https://nodespace.ai"
  # Kept explicit (rather than letting `brew audit` infer it from the url
  # below) so a future version bump is a single-line diff that every
  # `#{version}`-interpolated url picks up -- same reasoning
  # scripts/update-homebrew-cask.ts documents for the sibling cask.
  # `brew audit --strict` flags this as "redundant with version scanned
  # from URL"; that's a known, accepted trade-off, not an oversight.
  version "0.3.12"
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
  # v0.3.12 has no macOS Intel build (see the on_intel odie below). Every
  # digest below was computed locally from bytes actually downloaded from
  # the release.
  on_macos do
    on_arm do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-aarch64-apple-darwin"
      sha256 "1f47c283053e97824f01b8dd9495d4eae3e526ed6de7207b14ce9962f5ec94cf"
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
      sha256 "2edb1cde65e19ac5cebdfcfd4a94993541d50e59916af7dae7e34f3c53f58d21"
    end
    on_intel do
      url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespace-x86_64-unknown-linux-gnu"
      sha256 "2ebe64b5f6f6afff9b5618541175a5bd4cc06de8ec5dab5ada5651bad0b71a08"
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
        sha256 "d2156393448f3636912f0bcca92758f84fed5e9723275bf566e921d8e7753558"
      end
    end
    on_linux do
      on_arm do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-aarch64-unknown-linux-gnu"
        sha256 "d111fc29ffb14eb14cda84b9a77ee5e1a2069df8c4f27db9a19722deb6cc9f1f"
      end
      on_intel do
        url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{release_version}/nodespaced-x86_64-unknown-linux-gnu"
        sha256 "33f2486e35b46f43345441de69fe718847021eb9e51c5414860b37f9f8433274"
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
    # Homebrew's `keep_alive?` is only true when this is set, so omitting it
    # leaves nothing to relaunch nodespaced after a crash, which is the whole
    # point of `brew services start` over running the binary directly (see
    # the caveats above). `successful_exit: false` is the same condition the
    # launchd plist and systemd unit the installer writes use: relaunch after
    # a failure, but not after a deliberate clean exit (for example an
    # unusable databases.toml). `brew services stop` still works normally --
    # it unloads the service definition rather than fighting KeepAlive.
    keep_alive successful_exit: false
    log_path var/"log/nodespace/nodespaced.log"
    error_log_path var/"log/nodespace/nodespaced.log"
  end

  def caveats
    <<~EOS
      nodespaced (the daemon) must be running before `nodespace` commands work:
        nodespaced &                        # run directly, or
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
