cask "oak" do
  version "0.5.17"
  sha256 "0855c8622baa3325ca51a4a1c75e5bc743e43a6d6bf055e3dbbeb7f3b50a7ecd"

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
