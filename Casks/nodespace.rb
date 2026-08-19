cask "nodespace" do
  version "0.2.0"
  sha256 "b19edf954ae06c6c5845b148748c104750871179285ba352265844f98cffd638"

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
  # actual latest published release -- see NodeSpaceAI/nodespace-core#2114.
  livecheck do
    url :url
    strategy :github_latest
  end

  # release.yml builds with MACOSX_DEPLOYMENT_TARGET=14.0 (Metal GPU
  # embeddings require Sonoma+ -- see #990).
  depends_on macos: :sonoma
  # arm64-only by design -- see the platform-support note above the `url` line.
  depends_on arch:  :arm64

  app "NodeSpace.app"
  binary "#{appdir}/NodeSpace.app/Contents/MacOS/nodespace"

  zap trash: [
    "~/.nodespace/bin",
    "~/.nodespace/logs",
    "~/Library/LaunchAgents/app.nodespace.daemon.plist",
  ]
end
