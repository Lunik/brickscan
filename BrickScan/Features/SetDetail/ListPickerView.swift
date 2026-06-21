import SwiftUI

// Manages which custom Rebrickable lists (e.g. a wishlist) a set belongs to.
// A set can be in several custom lists at once, independent of true collection
// ownership, so each row is an immediate toggle rather than a single selection.
struct ListPickerView: View {
    let setNum: String
    @State private var setLists: [SetList] = []
    @State private var membership: [Int: Bool] = [:]
    @State private var isLoading = true
    @State private var newListName = ""
    @State private var showNewListField = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let repository: RebrickableRepositoryProtocol
    let onToggle: (String, Bool) -> Void

    init(setNum: String, repository: RebrickableRepositoryProtocol = RebrickableRepository(), onToggle: @escaping (String, Bool) -> Void) {
        self.setNum = setNum
        self.repository = repository
        self.onToggle = onToggle
    }

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(setLists) { list in
                        Button {
                            Task { await toggle(list) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(list.name)
                                    Text("\(list.numSets) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if membership[list.id] == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "E3000B"))
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(Color(hex: "E3000B"))
                            .font(.footnote)
                    }
                    if showNewListField {
                        HStack {
                            TextField("Nom de la nouvelle liste", text: $newListName)
                            Button("Créer") {
                                Task { await createAndAdd() }
                            }
                            .disabled(newListName.isEmpty)
                        }
                    } else {
                        Button("Créer une nouvelle liste") {
                            showNewListField = true
                        }
                    }
                }
            }
            .navigationTitle("Mes listes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task { await loadLists() }
        }
    }

    private func loadLists() async {
        isLoading = true
        setLists = (try? await repository.fetchUserSetLists()) ?? []
        await withTaskGroup(of: (Int, Bool).self) { group in
            for list in setLists {
                group.addTask {
                    let inList = (try? await repository.isSetInList(setNum: setNum, listId: list.id)) ?? false
                    return (list.id, inList)
                }
            }
            for await (listId, inList) in group {
                membership[listId] = inList
            }
        }
        isLoading = false
    }

    private func toggle(_ list: SetList) async {
        errorMessage = nil
        let currentlyIn = membership[list.id] == true
        do {
            if currentlyIn {
                try await repository.removeSetFromList(setNum: setNum, listId: list.id)
                membership[list.id] = false
                onToggle(list.name, false)
            } else {
                _ = try await repository.addSetToList(setNum: setNum, listId: list.id)
                membership[list.id] = true
                onToggle(list.name, true)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Une erreur est survenue"
        }
    }

    private func createAndAdd() async {
        errorMessage = nil
        guard !newListName.isEmpty else { return }
        do {
            let created = try await repository.createSetList(name: newListName)
            setLists.append(created)
            _ = try await repository.addSetToList(setNum: setNum, listId: created.id)
            membership[created.id] = true
            onToggle(created.name, true)
            newListName = ""
            showNewListField = false
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Une erreur est survenue"
        }
    }
}
