import Foundation
import Observation

@Observable
final class SetDetailViewModel {
    let legoSet: LegoSet
    var userSet: UserSet?
    var isLoading = false
    var errorMessage: String?
    var toastMessage: String?

    private let repository: RebrickableRepositoryProtocol

    init(legoSet: LegoSet, userSet: UserSet?, repository: RebrickableRepositoryProtocol = RebrickableRepository()) {
        self.legoSet = legoSet
        self.userSet = userSet
        self.repository = repository
    }

    var isInCollection: Bool { userSet != nil }

    @MainActor
    func addToList(listId: Int, listName: String) async {
        await perform {
            self.userSet = try await self.repository.addSetToList(setNum: self.legoSet.setNum, listId: listId)
            self.toastMessage = "Set ajouté à \(listName)"
        }
    }

    @MainActor
    func moveToList(listId: Int, listName: String) async {
        await perform {
            self.userSet = try await self.repository.moveSetToList(setNum: self.legoSet.setNum, listId: listId)
            self.toastMessage = "Set déplacé vers \(listName)"
        }
    }

    @MainActor
    func removeFromCollection() async {
        await perform {
            try await self.repository.removeSetFromCollection(setNum: self.legoSet.setNum)
            self.userSet = nil
            self.toastMessage = "Set retiré de la collection"
        }
    }

    @MainActor
    private func perform(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Une erreur est survenue"
        }
    }
}
