import SwiftUI
import AppKit

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    let tapToClickEnabled: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(systemName: "hand.tap")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Quick Setup")
                .font(.title.bold())

            // Main trigger explanation
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    KeyboardKey("⌘")
                    Text("+")
                        .foregroundColor(.secondary)
                    Text("tap")
                        .font(.system(.body, design: .rounded).bold())
                }
                .font(.title2)

                Text("Opens the tool panel at your cursor")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))

            // Tap to click warning
            if !tapToClickEnabled {
                VStack(spacing: 12) {
                    Label("Tap to click is disabled", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.headline)

                    Text("Enable it for the best experience, or use the keyboard shortcut instead.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Open Trackpad Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Trackpad-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
            }

            // Keyboard shortcut fallback
            VStack(spacing: 8) {
                Text("Keyboard shortcut")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    KeyboardKey("⌃")
                    KeyboardKey("⌥")
                    KeyboardKey("T")
                }

                Text("Customizable in Settings")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Got it") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(30)
        .frame(width: 340, height: tapToClickEnabled ? 380 : 480)
    }
}

struct KeyboardKey: View {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .frame(minWidth: 28, minHeight: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Tap to Click Detection

enum TrackpadSettings {
    static var isTapToClickEnabled: Bool {
        // Check built-in trackpad
        let builtIn = UserDefaults.standard.persistentDomain(forName: "com.apple.AppleMultitouchTrackpad")?["Clicking"] as? Int
        // Check bluetooth trackpad
        let bluetooth = UserDefaults.standard.persistentDomain(forName: "com.apple.driver.AppleBluetoothMultitouch.trackpad")?["Clicking"] as? Int

        // If either is enabled, we're good
        return builtIn == 1 || bluetooth == 1
    }
}

// MARK: - Onboarding Manager

final class OnboardingManager {
    static let shared = OnboardingManager()
    private let hasSeenOnboardingKey = "hasSeenOnboarding_v1"

    var shouldShowOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }

    func markOnboardingSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: hasSeenOnboardingKey)
    }
}
