cask "oak" do
  version "0.3.4"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/jellydn/oak/releases/download/v#{version}/Oak-#{version}.dmg"
  name "Oak"
  desc "Lightweight macOS focus companion for deep work"
  homepage "https://github.com/jellydn/oak"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "Oak.app"

  zap trash: [
    "~/Library/Preferences/com.jellydn.Oak.plist",
    "~/Library/Saved Application State/com.jellydn.Oak.savedState",
  ]
end
