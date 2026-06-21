import SwiftUI

struct AuthView: View {
    @State private var viewModel = AuthViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("BrickScan")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(hex: "E3000B"))
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    TextField("Rebrickable API Key", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    TextField("Nom d'utilisateur Rebrickable", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Mot de passe Rebrickable", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 16)

                PrivacyNoticeView()
                    .padding(.horizontal, 16)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(hex: "E3000B"))
                }

                Button {
                    Task {
                        if await viewModel.login() {
                            isAuthenticated = true
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Se connecter")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "E3000B"))
                .disabled(!viewModel.canSubmit || viewModel.isLoading)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }
}
