import AppKit

struct ApplicationItem {
    let name: String
    let url: URL
    let icon: NSImage
}

/// Manages the list of all applications on this system, along with icons, names, etc.
/// These are not just the running applications, but all applications that can be launched.
class ApplicationManager {
    static let shared = ApplicationManager()

    private var applications: [ApplicationItem] = []

    private init() {
        // Fetch all applications from the system, in the background
        // DispatchQueue.global(qos: .background).async { [weak self] in
        //     self?.fetchApplications()
        // }

        /// TODO: This is blocking the app from launching. Ideally, we should launch some background
        //       task to collect all applications like above, but we need to make sure the rest of
        //       the app knows how to deal with the async nature of this.
        fetchApplications()
    }

    /// Iteratively collects all applications from common directories.
    private func fetchApplications() {
        let fileManager = FileManager.default
        // Common directories where applications are stored.
        let directories: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        var foundApps: [ApplicationItem] = []

        for directory in directories {
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                // Check if the URL represents an application bundle
                if fileURL.pathExtension == "app" {
                    let name = fileURL.deletingPathExtension().lastPathComponent
                    let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
                    // Set a standard size for icons (you can change this as needed)
                    icon.size = NSSize(width: 64, height: 64)

                    let appItem = ApplicationItem(name: name, url: fileURL, icon: icon)
                    foundApps.append(appItem)

                    // Do not search deeper inside an app bundle
                    enumerator.skipDescendants()
                }
            }
        }
        print("Found \(foundApps.count) applications")

        self.applications = foundApps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    /// Reloads the applications by clearing the current list and re-fetching from disk.
    func reloadApplications() {
        // DispatchQueue.global(qos: .background).async { [weak self] in
        //     self?.fetchApplications()
        // }
        fetchApplications()
    }

    /// Returns the list of fetched applications, sorted alphabetically.
    func getApplications() -> [ApplicationItem] {
        return applications
    }

    /// Returns the list of applications that match the search query (case insensitive).
    func searchApplications(query: String) -> [ApplicationItem] {
        guard !query.isEmpty else { return getApplications() }
        let lowerQuery = query.lowercased()
        return applications.filter { $0.name.lowercased().contains(lowerQuery) }
    }

    /// Launches the specified application.
    func launch(application: ApplicationItem) {
        DispatchQueue.global().async {
            NSWorkspace.shared.open(application.url)
        }
    }
}
