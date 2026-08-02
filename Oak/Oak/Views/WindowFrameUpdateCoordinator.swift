import AppKit

internal struct WindowFrameUpdateRequest: Equatable {
    let expanded: Bool
    let forceReposition: Bool
    let targetOverride: DisplayTarget?
}

@MainActor
internal final class WindowFrameUpdateCoordinator {
    private var pendingRequest: WindowFrameUpdateRequest?
    private var pendingApply: ((WindowFrameUpdateRequest) -> Void)?
    private var isUpdateScheduled = false

    internal func request(
        expanded: Bool,
        forceReposition: Bool = false,
        targetOverride: DisplayTarget? = nil,
        apply: @escaping (WindowFrameUpdateRequest) -> Void
    ) {
        let existingRequest = pendingRequest
        pendingRequest = WindowFrameUpdateRequest(
            expanded: expanded,
            forceReposition: forceReposition || existingRequest?.forceReposition == true,
            targetOverride: targetOverride ?? existingRequest?.targetOverride
        )
        pendingApply = apply

        guard !isUpdateScheduled else { return }
        isUpdateScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self, let request = pendingRequest, let apply = pendingApply else { return }
            pendingRequest = nil
            pendingApply = nil
            isUpdateScheduled = false
            apply(request)
        }
    }
}
