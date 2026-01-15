import Foundation
import AppKit

/// Handles checking for and installing updates from GitHub releases
@MainActor
final class UpdateService {
    static let shared = UpdateService()

    private let repoOwner = "essamgouda97"
    private let repoName = "macbook-tools"

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private init() {}

    /// Check for updates and show appropriate dialog
    func checkForUpdates(silent: Bool = false) async {
        do {
            guard let release = try await fetchLatestRelease() else {
                if !silent {
                    showNoUpdatesDialog()
                }
                return
            }

            let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")

            if isNewerVersion(latestVersion, than: currentVersion) {
                showUpdateAvailableDialog(release: release)
            } else if !silent {
                showNoUpdatesDialog()
            }
        } catch {
            if !silent {
                showErrorDialog(error: error)
            }
        }
    }

    // MARK: - GitHub API

    private struct GitHubRelease: Codable {
        let tagName: String
        let name: String
        let body: String
        let htmlUrl: String
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case body
            case htmlUrl = "html_url"
            case assets
        }

        struct Asset: Codable {
            let name: String
            let browserDownloadUrl: String

            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadUrl = "browser_download_url"
            }
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease? {
        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    // MARK: - Version Comparison

    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(newParts.count, currentParts.count) {
            let newPart = i < newParts.count ? newParts[i] : 0
            let currentPart = i < currentParts.count ? currentParts[i] : 0

            if newPart > currentPart { return true }
            if newPart < currentPart { return false }
        }
        return false
    }

    // MARK: - Dialogs

    private func showUpdateAvailableDialog(release: GitHubRelease) {
        let version = release.tagName.replacingOccurrences(of: "v", with: "")

        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Version \(version) is available (you have \(currentVersion)).\n\nWould you like to download it?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "View Release")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            // Download zip directly
            if let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }) {
                downloadAndInstall(from: asset.browserDownloadUrl)
            } else if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        case .alertSecondButtonReturn:
            // View release page
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        default:
            break
        }
    }

    private func showNoUpdatesDialog() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "AI Mac Tools \(currentVersion) is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showErrorDialog(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not check for updates. Please try again later.\n\n\(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Download & Install

    private func downloadAndInstall(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        // Show progress
        let alert = NSAlert()
        alert.messageText = "Downloading Update..."
        alert.informativeText = "Please wait while the update is downloaded and installed."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Cancel")

        let progressIndicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 250, height: 20))
        progressIndicator.isIndeterminate = true
        progressIndicator.startAnimation(nil)
        alert.accessoryView = progressIndicator

        var downloadTask: Task<Void, Never>?

        // Start download in background
        downloadTask = Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)

                // Close progress dialog
                NSApp.stopModal()

                // Auto-install the update
                try await autoInstall(zipURL: tempURL)

            } catch {
                NSApp.stopModal()
                if !Task.isCancelled {
                    showErrorDialog(error: error)
                }
            }
        }

        // Run modal (will be stopped when download completes)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // User cancelled
            downloadTask?.cancel()
        }
    }

    private func autoInstall(zipURL: URL) async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create temp directory
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Unzip using ditto (preserves permissions and code signing)
        let unzipProcess = Process()
        unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzipProcess.arguments = ["-xk", zipURL.path, tempDir.path]
        try unzipProcess.run()
        unzipProcess.waitUntilExit()

        guard unzipProcess.terminationStatus == 0 else {
            throw NSError(domain: "UpdateService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to unzip update"])
        }

        // Find the .app in the extracted contents
        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        guard let appURL = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "UpdateService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No app found in update"])
        }

        // Get current app location
        let currentAppURL = Bundle.main.bundleURL
        let appName = currentAppURL.lastPathComponent
        let installDir = currentAppURL.deletingLastPathComponent()
        let targetURL = installDir.appendingPathComponent(appName)

        // Create install script that runs after we quit
        let scriptContent = """
        #!/bin/bash
        sleep 1
        rm -rf "\(targetURL.path)"
        cp -R "\(appURL.path)" "\(targetURL.path)"
        open "\(targetURL.path)"
        rm -rf "\(tempDir.path)"
        """

        let scriptURL = tempDir.appendingPathComponent("install.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)

        // Make script executable
        let chmodProcess = Process()
        chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProcess.arguments = ["+x", scriptURL.path]
        try chmodProcess.run()
        chmodProcess.waitUntilExit()

        // Run install script in background and quit
        let installProcess = Process()
        installProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        installProcess.arguments = [scriptURL.path]
        try installProcess.run()

        // Quit the app to allow replacement
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
