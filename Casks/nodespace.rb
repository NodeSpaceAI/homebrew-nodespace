cask "nodespace" do
  version "0.3.4"
  sha256 "de713bcf29c0010391f26a62d5b8200d469ef83a499e595af85f7940827d8ba4"

  # Apple Silicon (arm64) is the only supported macOS target. This is an
  # intentional decision, not a leftover workaround: there is no way to
  # verify x86_64 (Intel) macOS builds, and shipping a build nobody can
  # test is worse than not shipping it at all. It's reversible if that
  # changes -- Intel Mac users can build nodespace-core from source in
  # the meantime.
  url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{version}/NodeSpace_#{version}_aarch64.dmg"
  name "NodeSpace"
  desc "AI-native local-first knowledge management"
  homepage "https://nodespace.app/"

  # Explicit github_latest strategy: without this, brew's default livecheck
  # falls back to scanning ALL repo tags, which picks up unrelated
  # `review-*` tooling tags (e.g. review-20260813-095222) instead of the
  # actual latest published release.
  livecheck do
    url :url
    strategy :github_latest
  end

  # arm64-only by design -- see the platform-support note above the `url` line.
  depends_on arch:  :arm64
  # release.yml builds with MACOSX_DEPLOYMENT_TARGET=14.0 (Metal GPU
  # embeddings require Sonoma+).
  depends_on macos: :sonoma

  app "NodeSpace.app"
  binary "#{appdir}/NodeSpace.app/Contents/MacOS/nodespace"

  # Refuses to install over another NodeSpace product, reading only static
  # data from the app already in place.
  preflight_steps do
    if_path_exists "NodeSpace.app", base: :appdir do
      run "/bin/sh", args: ["-c", <<~SH, "sh", "{{appdir}}/NodeSpace.app"], print_stderr: false
        product=$(/usr/bin/plutil -extract NodeSpaceProduct raw -o - "$1/Contents/Info.plist" 2>/dev/null)
        if [ "$product" != community ]; then
          msg="The NodeSpace app on this Mac is a different NodeSpace product, or an older"
          msg="$msg NodeSpace that does not say which product it is. To replace it, move"
          msg="$msg /Applications/NodeSpace.app to the Trash, then run the install again."
          msg="$msg Your databases stay on this Mac."
          echo "$msg" >&2
          exit 1
        fi
      SH
    end
  end

  # The same check before an uninstall, which is how a reinstall or upgrade
  # sees the app: Homebrew moves the old app aside before the new version's
  # preflight_steps run.
  uninstall_preflight_steps do
    if_path_exists "NodeSpace.app", base: :appdir do
      run "/bin/sh", args: ["-c", <<~SH, "sh", "{{appdir}}/NodeSpace.app"], print_stderr: false
        product=$(/usr/bin/plutil -extract NodeSpaceProduct raw -o - "$1/Contents/Info.plist" 2>/dev/null)
        if [ "$product" != community ]; then
          msg="The NodeSpace app on this Mac is a different NodeSpace product, or an older"
          msg="$msg NodeSpace that does not say which product it is. To replace it, move"
          msg="$msg /Applications/NodeSpace.app to the Trash, then run the install again."
          msg="$msg Your databases stay on this Mac."
          echo "$msg" >&2
          exit 1
        fi
      SH
    end
  end

  # Neither `~/.nodespace/database` nor `~/.nodespace/models` is listed
  # here: a zap never deletes the user's databases, and models can hold
  # 100GB+ of downloaded weights the user may expect to survive an
  # uninstall/reinstall cycle.
  zap trash: [
    "~/.nodespace/bin",
    "~/.nodespace/logs",
    "~/Library/LaunchAgents/app.nodespace.daemon.dev.plist",
    "~/Library/LaunchAgents/app.nodespace.daemon.plist",
  ]
end
