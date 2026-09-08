import Foundation

internal enum SettingsVersion {
    internal static var current: String {
        let fallbackBundle = Bundle(identifier: "com.productsway.oak.app")
            ?? Bundle(for: FocusSessionViewModel.self)

        if let version = version(in: Bundle.main) ?? version(in: fallbackBundle) {
            return "v\(version.short) (\(version.build))"
        }

        return "v0.0.0 (0)"
    }

    private static func version(in bundle: Bundle) -> (short: String, build: String)? {
        guard let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = bundle.infoDictionary?["CFBundleVersion"] as? String
        else {
            return nil
        }
        return (short, build)
    }
}
