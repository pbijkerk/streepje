import UIKit

/// Kleine helper voor haptische feedback (licht tikje bij +/− knoppen).
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
