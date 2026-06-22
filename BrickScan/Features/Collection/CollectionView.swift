import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CollectionViewModel?

    var body: some View {
        Group {
            if let cachedSets = viewModel?.cachedSets, !cachedSets.isEmpty {
                List(cachedSets, id: \.setNum) { cached in
                    HStack(spacing: 14) {
                        SetThumbnailView(imageUrl: cached.setImgUrl)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(cached.setNum).font(.headline)
                            Text(cached.name).font(.subheadline).foregroundStyle(.secondary)
                            if let listName = cached.currentListName {
                                Text(listName).font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
