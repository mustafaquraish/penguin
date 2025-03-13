

public class ApplicationsExtension: PenguinExtension {
    public let identifier = "com.penguin.applications"
    public let name = "Applications"

    let am = ApplicationManager.shared

    public func getCommands() -> [Command] {
        am.getApplications().map { app in
            makeCommand(
                title: app.name,
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
