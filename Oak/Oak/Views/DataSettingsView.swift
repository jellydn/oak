import AppKit
import SwiftUI

internal struct DataSettingsView: View {
    internal let progressManager: ProgressManager?
    internal let theme: AppTheme

    private var palette: ThemePalette { theme.palette }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Back up or restore your progress data.")
                .font(.caption)
                .foregroundColor(palette.secondaryForeground)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    dataButtons
                }

                VStack(alignment: .leading, spacing: 8) {
                    dataButtons
                }
            }
        }
    }

    @ViewBuilder
    private var dataButtons: some View {
        Button("Export JSON") {
            exportJSON()
        }
        .buttonStyle(.bordered)
        .disabled(progressManager == nil)

        Button("Export CSV") {
            exportCSV()
        }
        .buttonStyle(.bordered)
        .disabled(progressManager == nil)

        Button("Import Backup…") {
            importData()
        }
        .buttonStyle(.borderedProminent)
        .disabled(progressManager == nil)
    }

    private func exportJSON() {
        guard let manager = progressManager,
              let data = manager.exportJSON()
        else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "oak-progress-\(dateStamp()).json"
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
    }

    private func exportCSV() {
        guard let manager = progressManager else { return }
        let csv = manager.exportCSV()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "oak-progress-\(dateStamp()).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? csv.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func importData() {
        guard let manager = progressManager else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            if response == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
                let count = manager.importRecords(from: data)
                if count > 0 {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Import complete"
                        alert.informativeText = "Imported \(count) day(s) of progress data."
                        alert.runModal()
                    }
                }
            }
        }
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
