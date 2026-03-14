cask "oak" do
  version "0.5.23"
  sha256 "0ec775a99fa10d152023027ae556d0c264226c3281cfafc188c936d59bf06194"

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
