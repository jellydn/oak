cask "oak" do
  version "0.5.20"
  sha256 "5a3717c61f7d027c3e39e3f861d309c587f7020ffe672c2fe805ed4f813ac2bf"

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
    "~/Library/Preferences/com.productsway.oak.app.plist",
    "~/Library/Saved Application State/com.productsway.oak.app.savedState",
  ]
end
