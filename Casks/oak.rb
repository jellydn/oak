cask "oak" do
  version "0.4.22"
  sha256 "2f2906d19cf4e30f594a588a0d9e9c82037e8379c27f9ccfd52f1e5dd71e6575"

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
