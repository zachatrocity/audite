import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var latestVersion: String?
    @Published var downloadURL: URL?

    private let currentVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }()

    var updateAvailable: Bool {
        guard let latest = latestVersion else { return false }
        return compare(latest, isNewerThan: currentVersion)
    }

    func check() {
        let url = URL(string: "https://api.github.com/repos/zachatrocity/audite/releases/latest")!
        Task.detached {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String,
                      let htmlURL = json["html_url"] as? String else { return }

                let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                let releaseURL = URL(string: htmlURL)

                await MainActor.run {
                    self.latestVersion = version
                    self.downloadURL = releaseURL
                }
            } catch {
                NSLog("Audite: update check failed: \(error)")
            }
        }
    }

    private func compare(_ a: String, isNewerThan b: String) -> Bool {
        let partsA = a.split(separator: ".").compactMap { Int($0) }
        let partsB = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(partsA.count, partsB.count) {
            let va = i < partsA.count ? partsA[i] : 0
            let vb = i < partsB.count ? partsB[i] : 0
            if va > vb { return true }
            if va < vb { return false }
        }
        return false
    }
}
