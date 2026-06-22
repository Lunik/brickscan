import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<CachedSet> { $0.wasScanned }, sort: \CachedSet.lastScannedAt, order: .reverse)
    private var cachedSets: [CachedSet]
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if cachedSets.isEmpty {
                    ContentUnavailableView(
                        "Aucun set scanné",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Les sets que tu scannes apparaîtront ici.")
                    )
                } else {
                    List(cachedSets) { cached in
                        Button {
                            onSelect(cached.setNum)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                SetThumbnailView(imageUrl: cached.setImgUrl)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(cached.setNum)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(cached.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if cached.isInCollection {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Historique")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
