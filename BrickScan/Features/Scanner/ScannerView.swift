import SwiftUI

struct ScannerView: View {
    @State private var viewModel = ScannerViewModel()
    @State private var showHistory = false
    @State private var showAccountSheet = false
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreviewView(controller: viewModel.cameraController)
                    .ignoresSafeArea()

                ScanOverlayView(state: viewModel.state)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            viewModel.toggleTorch()
                        } label: {
                            Image(systemName: viewModel.torchOn ? "bolt.fill" : "bolt.slash")
                        }
                        Menu {
                            Button("Compte & Confidentialité") {
                                showAccountSheet = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                Text("Historique")
            }
            .sheet(isPresented: $showAccountSheet) {
                PrivacyDetailView(isAuthenticated: $isAuthenticated)
            }
            .sheet(isPresented: setDetailBinding) {
                if case .found(let legoSet, let userSet) = viewModel.state {
                    SetDetailView(legoSet: legoSet, userSet: userSet) {
                        viewModel.resumeScanning()
                    }
                }
            }
            .sheet(isPresented: ambiguousBinding) {
                if case .ambiguous(let sets) = viewModel.state {
                    AmbiguousSetPickerView(sets: sets) { selected in
                        viewModel.state = .processing
                        Task {
                            // Re-trigger detail resolution for the chosen set.
                            viewModel.state = .found(selected, nil)
                        }
                    } onCancel: {
                        viewModel.resumeScanning()
                    }
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var setDetailBinding: Binding<Bool> {
        Binding(
            get: {
                if case .found = viewModel.state { return true }
                return false
            },
            set: { newValue in
                if !newValue { viewModel.resumeScanning() }
            }
        )
    }

    private var ambiguousBinding: Binding<Bool> {
        Binding(
            get: {
                if case .ambiguous = viewModel.state { return true }
                return false
            },
            set: { newValue in
                if !newValue { viewModel.resumeScanning() }
            }
        )
    }
}

private struct AmbiguousSetPickerView: View {
    let sets: [LegoSet]
    let onSelect: (LegoSet) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List(sets) { set in
                Button {
                    onSelect(set)
                } label: {
                    VStack(alignment: .leading) {
                        Text(set.setNum).font(.headline)
                        Text(set.name).font(.subheadline)
                    }
                }
            }
            .navigationTitle("Choisir un set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: onCancel)
                }
            }
        }
    }
}
