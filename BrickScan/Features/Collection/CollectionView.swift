import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CollectionViewModel?

    var body: some View {
        Group {
            if let cachedSets = viewModel?.cachedSets, !cachedSets.isEmpty {
                List(cachedSets, id: \.setNum) { cached in
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: cached.setImgUrl ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                            default:
                                Image(systemName: "shippingbox")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                            }
                        }
                        .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cached.setNum).font(.headline)
                            Text(cached.name).font(.subheadline).foregroundStyle(.secondary)
                            if let listName = cached.currentListName {
                                Text(listName).font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Aucun set possédé",
                    systemImage: "shippingbox",
                    description: Text("Liez votre compte Rebrickable et synchronisez depuis l'accueil.")
                )
            }
        }
        .navigationTitle("Ma collection")
        .onAppear {
            if viewModel == nil {
                viewModel = CollectionViewModel(localRepository: LocalRepository(modelContext: modelContext))
            }
            viewModel?.load()
        }
    }
}
