import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showPrivacyDetail = false
    @State private var isAPIKeyVisible = false
    @State private var showClearCacheConfirmation = false
    @State private var isClearingCache = false
    @State private var cacheCleared = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Group {
                            if isAPIKeyVisible {
                                TextField("API Key", text: $viewModel.apiKey)
                            } else {
                                SecureField("API Key", text: $viewModel.apiKey)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button {
                            isAPIKeyVisible.toggle()
                        } label: {
                            Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("API Key Rebrickable")
                } footer: {
                    Text("Génère ta clé sur rebrickable.com/profile, dans la section API Key.")
                }

                Section {
                    if viewModel.isAccountLinked {
                        Label("Compte Rebrickable lié", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Button("Délier mon compte", role: .destructive) {
                            viewModel.unlinkAccount()
                        }
                    } else {
                        TextField("Nom d'utilisateur ou email", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Mot de passe", text: $viewModel.password)

                        if let errorMessage = viewModel.linkAccountErrorMessage {
                            Text(errorMessage)
                                .foregroundStyle(Color(hex: "E3000B"))
                                .font(.footnote)
                        }

                        if !viewModel.username.isEmpty && !viewModel.password.isEmpty {
                            Button {
                                Task { _ = await viewModel.linkAccount() }
                            } label: {
                                if viewModel.isLinkingAccount {
                                    ProgressView()
                                } else {
                                    Text("Lier mon compte")
                                }
                            }
                            .disabled(viewModel.apiKey.isEmpty || viewModel.isLinkingAccount)
                        }
                    }
                } header: {
                    Text("Compte Rebrickable")
                } footer: {
                    Text("Nécessaire pour voir et gérer votre collection. Votre mot de passe n'est jamais stocké : il sert une seule fois à obtenir un token de session.")
                }

                Section {
                    PrivacyNoticeView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    Button(role: .destructive) {
                        showClearCacheConfirmation = true
                    } label: {
                        HStack {
                            Text("Vider le cache")
                            Spacer()
                            if isClearingCache {
                                ProgressView()
                            } else if cacheCleared {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(isClearingCache)
                } footer: {
                    Text("Supprime les images, prix et listes mis en cache. Ne touche pas à votre clé API ni à votre compte ; les données seront re-téléchargées au besoin.")
                }

                Section {
                    Button("Confidentialité & données") {
                        showPrivacyDetail = true
                    }
                }
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(viewModel.apiKey.isEmpty)
                }
            }
            .sheet(isPresented: $showPrivacyDetail) {
                PrivacyDetailView()
            }
            .confirmationDialog(
                "Vider le cache ?",
                isPresented: $showClearCacheConfirmation,
                titleVisibility: .visible
            ) {
                Button("Vider le cache", role: .destructive) {
                    Task { await clearCache() }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Supprime les images, prix et listes mis en cache. Votre clé API et votre compte sont conservés.")
            }
        }
    }

    private func clearCache() async {
        isClearingCache = true
        cacheCleared = false
        LocalRepository(modelContext: modelContext).clearAll()
        await ImageCache.shared.clearAll()
        isClearingCache = false
        cacheCleared = true
    }
}
