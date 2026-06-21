import SwiftUI
import SafariServices

struct PrivacyDetailView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Ce qui est stocké", systemImage: "internaldrive")
                        .font(.headline)
                    Text("API Key Rebrickable : dans le Keychain iOS")
                    Text("Token de session : dans le Keychain iOS")
                    Text("Sets scannés récemment : dans la base SwiftData locale, sur l'appareil uniquement")
                }

                Section {
                    Label("Ce qui n'est jamais stocké", systemImage: "xmark.shield")
                        .font(.headline)
                    Text("Votre mot de passe Rebrickable : effacé immédiatement après connexion")
                    Text("Aucune donnée n'est envoyée à un serveur tiers autre que Rebrickable")
                }

                Section {
                    Label("Vous gardez le contrôle", systemImage: "hand.raised")
                        .font(.headline)
                    Button("Gérer votre API Key sur Rebrickable") {
                        showSafari = true
                    }
                    Button("Se déconnecter", role: .destructive) {
                        showLogoutConfirmation = true
                    }
                }
            }
            .navigationTitle("Comment BrickScan protège vos données")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showSafari) {
                SafariView(url: URL(string: "https://rebrickable.com/settings/")!)
            }
            .confirmationDialog(
                "Se déconnecter ?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Se déconnecter", role: .destructive) {
                    logout()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }

    private func logout() {
        KeychainService.shared.clearAll()
        NotificationCenter.default.post(name: .didLogout, object: nil)
        isAuthenticated = false
        dismiss()
    }
}

extension Notification.Name {
    static let didLogout = Notification.Name("BrickScan.didLogout")
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
