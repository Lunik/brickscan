import SwiftUI
import SwiftData

struct ListConditionsView: View {
    @Query(sort: \CachedSetList.name) private var setLists: [CachedSetList]

    var body: some View {
        Group {
            if setLists.isEmpty {
                ContentUnavailableView(
                    "Aucune liste",
                    systemImage: "list.bullet",
                    description: Text("Synchronisez votre collection depuis l'accueil pour voir vos listes Rebrickable ici.")
                )
            } else {
                List(setLists) { list in
                    ListConditionRow(list: list)
                }
            }
        }
        .navigationTitle("Listes")
    }
}

struct ListConditionRow: View {
    let list: CachedSetList
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Picker(list.name, selection: Binding(
            get: { list.condition },
            set: {
                list.condition = $0
                try? modelContext.save()
            }
        )) {
            ForEach(ListCondition.allCases) { condition in
                Text(condition.displayName).tag(condition)
            }
        }
    }
}
