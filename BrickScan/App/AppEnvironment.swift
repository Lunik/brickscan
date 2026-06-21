import Foundation

@Observable
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    private init() {}

    var hasCredentials: Bool {
        KeychainService.shared.hasCredentials
    }
}
