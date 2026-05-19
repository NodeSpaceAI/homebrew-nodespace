cask "nodespace" do
  version "0.1.6"

  on_arm do
    sha256 "2bab43d75bcdad766f20811d334defecbb8b7a54b09f8b8c8407c4b6d2f0fcc3"
    url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{version}/NodeSpace_#{version}_aarch64.dmg"
  end
  on_intel do
    sha256 "f3a69ad4a3777f06698b1a78763ee2fca7949abb27eb71e00d7ee751359b99b8"
    url "https://github.com/NodeSpaceAI/nodespace-core/releases/download/v#{version}/NodeSpace_#{version}_x64.dmg"
  end

  name "NodeSpace"
  desc "AI-native local-first knowledge management"
  homepage "https://nodespace.app"

  app "NodeSpace.app"

  binary "#{appdir}/NodeSpace.app/Contents/Resources/bin/nodespace"

  zap trash: [
    "~/Library/LaunchAgents/app.nodespace.daemon.plist",
    "~/.nodespace/bin",
    "~/.nodespace/logs",
  ]
end
