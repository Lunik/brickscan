import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    let onStartScanning: () -> Void

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("BrickScan")
                            .font(.largeTitle.bold())
                            .padding(.top, 16)

                        if let viewModel {
                            appStatsSection(viewModel)
                            rebrickableStatsSection(viewModel)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 140)
                }

                scanButton
            }
            .task {
                let vm = HomeViewModel(localRepository: LocalRepository(modelContext: modelContext))
                viewModel = vm
                vm.loadAppStats()
                await vm.loadRebrickableStats()
            }
        }
    }

    private func appStatsSection(_ viewModel: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activité")
                .font(.headline)
            HStack(spacing: 12) {
                statCard(title: "Sets scannés", value: "\(viewModel.scannedSetsCount)", icon: "number.square")
                statCard(title: "Scans effectués", value: "\(viewModel.totalScans)", icon: "barcode.viewfinder")
            }
        }
    }

    private func rebrickableStatsSection(_ viewModel: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rebrickable")
                .font(.headline)

            if !viewModel.isAccountLinked {
                Text("Compte non lié — ouvrez Réglages pour lier votre compte Rebrickable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if viewModel.isLoadingRebrickableStats {
                ProgressView()
            } else if let errorMessage = viewModel.rebrickableErrorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 12) {
                    statCard(title: "Sets possédés", value: "\(viewModel.ownedSetsCount ?? 0)", icon: "shippingbox")
                    statCard(title: "Listes", value: "\(viewModel.listsCount ?? 0)", icon: "list.bullet")
                }
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scanButton: some View {
        Button(action: onStartScanning) {
            Image(systemName: "camera.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(radius: 8)
        }
        .padding(.bottom, 32)
    }
}
