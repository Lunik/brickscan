import SwiftUI
import SwiftData

@main
struct BrickScanApp: App {
    @State private var isAuthenticated = KeychainService.shared.hasCredentials

    var modelContainer: ModelContainer = {
        let schema = Schema([CachedSet.self, CachedSetList.self])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            RootView(isAuthenticated: $isAuthenticated)
                .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
                    let context = modelContainer.mainContext
                    LocalRepository(modelContext: context).clearAll()
                }
        }
        .modelContainer(modelContainer)
    }
}

private struct RootView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        if isAuthenticated {
            ScannerView(isAuthenticated: $isAuthenticated)
        } else {
            AuthView(isAuthenticated: $isAuthenticated)
        }
    }
}
