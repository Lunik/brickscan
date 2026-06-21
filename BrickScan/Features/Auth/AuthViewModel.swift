import Foundation
import Observation

@Observable
final class AuthViewModel {
    var apiKey = ""
    var username = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private let repository: RebrickableRepositoryProtocol

    init(repository: RebrickableRepositoryProtocol = RebrickableRepository()) {
        self.repository = repository
    }

    var canSubmit: Bool {
        !apiKey.isEmpty && !username.isEmpty && !password.isEmpty
    }

    @MainActor
    func login() async -> Bool {
        guard canSubmit else { return false }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let userToken = try await repository.authenticate(
                apiKey: apiKey,
                username: username,
                password: password
            )
            KeychainService.shared.save(key: .userToken, value: userToken)

            // The password must never be retained, even transiently.
            password = ""

            return true
        } catch let error as APIError {
            errorMessage = mapError(error)
            password = ""
            return false
        } catch {
            errorMessage = "Connexion impossible. Vérifiez votre réseau."
            password = ""
            return false
        }
    }

    private func mapError(_ error: APIError) -> String {
        switch error {
        case .unauthorized:
            return "API Key invalide"
        case .forbidden:
            return "Nom d'utilisateur ou mot de passe incorrect"
        case .networkUnavailable:
            return "Connexion impossible. Vérifiez votre réseau."
        default:
            return error.errorDescription ?? "Une erreur est survenue"
        }
    }
}
