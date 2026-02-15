cask "oak" do
  version "0.5.10"
  sha256 "f7de0ceaee2e1810a2a6c72bfdce2371a51cbd12486bafa721df60aad2441f44"

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
