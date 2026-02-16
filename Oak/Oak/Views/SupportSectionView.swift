import SwiftUI

internal struct SupportSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("If Oak helps you focus, consider supporting the project ⭐️")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Link("⭐ Star on GitHub", destination: URL(string: "https://github.com/jellydn/oak")!)
                Link("☕ Buy Me a Coffee", destination: URL(string: "https://www.buymeacoffee.com/dunghd")!)
                Link("❤️ Ko-fi", destination: URL(string: "https://ko-fi.com/dunghd")!)
                Link("💙 PayPal", destination: URL(string: "https://paypal.me/dunghd")!)
            }
            .font(.caption)
        }
    }
}
