import AppKit

/// Plays short audio cues during spa sessions. Uses the built-in macOS system
/// sounds (in /System/Library/Sounds) so no audio assets need bundling.
/// Each cleaning stage gets a distinct timbre; completion has its own chime.
@MainActor
enum SoundService {
    /// System-sound names assigned to each cue.
    enum Cue: String {
        case keyboard   = "Tink"   // light, tappy - matches key caps
        case trackpad   = "Pop"    // soft round pop - matches a glass pad
        case display    = "Purr"   // smooth sweep - matches a wiped screen
        case completion = "Glass"  // bright finish chime
    }

    static func play(_ cue: Cue) {
        NSSound(named: NSSound.Name(cue.rawValue))?.play()
    }

    /// The "ace" finale: the three device timbres fire in quick succession and
    /// resolve into the bright completion chime - a small crescendo reward.
    static func playFinale() {
        let steps: [(Cue, Double)] = [
            (.keyboard, 0.00),
            (.trackpad, 0.14),
            (.display,  0.28),
            (.completion, 0.46),
        ]
        for (cue, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { play(cue) }
        }
    }
}
