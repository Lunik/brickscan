import AppIntents

struct BrickScanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckSetPriceIntent(),
            phrases: [
                "Vérifie le prix du set \(.applicationName)",
                "Vérifie le prix du set LEGO \(\.$setNumber) sur \(.applicationName)",
                "Quel est le prix du set \(\.$setNumber) sur \(.applicationName)"
            ],
            shortTitle: "Prix d'un set LEGO",
            systemImageName: "tag"
        )
    }
}
