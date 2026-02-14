import SwiftUI

internal struct NotchBackgroundView: View {
    let isExpanded: Bool
    let isSessionComplete: Bool
    let onTap: () -> Void

    var body: some View {
        Group {
            if isExpanded {
                expandedShape
                    .fill(Color.black.opacity(0.97))
                    .overlay {
                        if isSessionComplete {
                            expandedShape
                                .stroke(Color.green.opacity(0.45), lineWidth: 1.4)
                        }
                    }
            } else {
                collapsedShape
                    .fill(Color.black.opacity(0.98))
                    .overlay {
                        if isSessionComplete {
                            collapsedShape
                                .stroke(Color.green.opacity(0.45), lineWidth: 1.2)
                        }
                    }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var collapsedShape: NotchCapShape {
        NotchCapShape(cornerRadius: 14)
    }

    private var expandedShape: NotchCapShape {
        NotchCapShape(cornerRadius: 15)
    }
}
