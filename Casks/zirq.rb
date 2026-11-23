# SPDX-FileCopyrightText: 2026 Mohamed Elashri <kwi@elashri.com>
# SPDX-License-Identifier: CC0-1.0

cask "zirq" do
  version "0.3.2"
  sha256 "cd17c08d3cdc0b68edd3ffdd7a11f28655d44a1648414c13ef08b732056cfdc8"

  url "https://github.com/MohamedElashri/zirq/releases/download/v#{version}/Zirq-arm64.zip"
  name "Zirq"
  desc "Terminal with bidirectional Arabic, Persian and Hebrew support"
  homepage "https://github.com/MohamedElashri/zirq"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Zirq.app"

  caveats <<~EOS
    Requires macOS 14.4 or later. Quit Zirq or Kwi before upgrading.
    This app is ad-hoc signed and is not notarized.
  EOS
end
