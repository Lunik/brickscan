import SwiftUI

struct SetDetailView: View {
    @State private var viewModel: SetDetailViewModel
    @State private var showListPicker = false
    @State private var showRemoveConfirmation = false
    @Environment(\.dismiss) private var dismiss

    let onScanAgain: () -> Void

    init(legoSet: LegoSet, userSet: UserSet?, onScanAgain: @escaping () -> Void) {
        _viewModel = State(initialValue: SetDetailViewModel(legoSet: legoSet, userSet: userSet))
        self.onScanAgain = onScanAgain
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: viewModel.legoSet.setImgUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        default:
                            Image(systemName: "shippingbox")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .padding(40)
                        }
                    }
                    .frame(height: 220)

                    VStack(spacing: 4) {
                        Text(viewModel.legoSet.setNum)
                            .font(.title2.bold())
                        Text(viewModel.legoSet.name)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                        Text("\(viewModel.legoSet.year) · \(viewModel.legoSet.numParts) pièces")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    statusBadge

                    if viewModel.isLoading {
                        ProgressView()
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(Color(hex: "E3000B"))
                            .font(.footnote)
                    }

                    actionButtons

                    Button("Scanner à nouveau") {
                        dismiss()
                        onScanAgain()
                    }
                    .buttonStyle(.bordered)

                    if let setUrl = viewModel.legoSet.setUrl, let url = URL(string: setUrl) {
                        Link("Voir sur Rebrickable", destination: url)
                            .font(.footnote)
                    }
                }
                .padding(16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                        onScanAgain()
                    }
                }
            }
            .sheet(isPresented: $showListPicker) {
                ListPickerView { listId, listName in
                    Task {
                        if viewModel.isInCollection {
                            await viewModel.moveToList(listId: listId, listName: listName)
                        } else {
                            await viewModel.addToList(listId: listId, listName: listName)
                        }
                    }
                }
            }
            .alert("Retirer de la collection ?", isPresented: $showRemoveConfirmation) {
                Button("Retirer", role: .destructive) {
                    Task { await viewModel.removeFromCollection() }
                }
                Button("Annuler", role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if let toast = viewModel.toastMessage {
                    Text(toast)
                        .padding(12)
                        .background(.black.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 24)
                        .task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            viewModel.toastMessage = nil
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if viewModel.isInCollection {
            Label("Dans votre collection", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Label("Pas dans votre collection", systemImage: "xmark.circle.fill")
                .foregroundStyle(Color(hex: "E3000B"))
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isInCollection {
            VStack(spacing: 8) {
                Button("Changer de liste") {
                    showListPicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "E3000B"))

                Button("Retirer de la collection", role: .destructive) {
                    showRemoveConfirmation = true
                }
            }
        } else {
            Button("Ajouter à une liste") {
                showListPicker = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "E3000B"))
        }
    }
}
