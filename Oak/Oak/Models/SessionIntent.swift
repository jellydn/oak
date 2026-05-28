import Foundation

/// Side-effect command emitted by `SessionEngine` for the shell to execute.
///
/// The engine itself never performs side effects; the shell switches over
/// intents to drive `AudioManager`, `NotificationService`, `ProgressManager`,
/// and view-layer animation state.
internal enum SessionIntent: Equatable {
    /// Persist a completed session to the progress history.
    case recordCompletion(SessionRecord)

    /// Stop ambient audio entirely (e.g. on session completion or reset).
    case stopAudio

    /// Pause audio without forgetting the current track (on session pause).
    case pauseAudio

    /// Resume audio that was previously paused (on session resume).
    case resumePausedAudio

    /// Start the remembered track when a new work session begins after a break.
    case startRememberedAudio(track: AudioTrack)

    /// Tell the user a session just ended.
    case notifyCompleted(kind: SessionType)

    /// Play the completion sound (subject to the engine's config flags).
    case playCompletionSound

    /// Flash the "session complete" visual state for the shell's UX cooldown.
    case flashCompletion

    /// Begin the auto-start countdown that leads into the next session.
    case scheduleAutoStartCountdown
}
