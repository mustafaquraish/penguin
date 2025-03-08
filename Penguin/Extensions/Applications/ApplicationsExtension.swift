

public class ApplicationsExtension: PenguinExtension {
    public let identifier = "com.penguin.applications"
    public let name = "Applications"

    let am = ApplicationManager.shared

    public func getCommands() -> [Command] {
        am.getApplications().map { app in
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: app.name,
                subtitle: app.url.path,
                icon: app.icon,
                action: {
                    Penguin.shared.hideMainWindow()
                    print("Launching application: \(app.name)")
                    self.am.launch(application: app)
                    return nil
                }
            )
        }
    }
}
