import Foundation
import Observation

@Observable
final class SetDetailViewModel {
    let legoSet: LegoSet
    var collectionStatus: CollectionStatus
    var isLoading = false
    var errorMessage: String?
    var toastMessage: String?

    private let repository: RebrickableRepositoryProtocol

    init(legoSet: LegoSet, collectionStatus: CollectionStatus, repository: RebrickableRepositoryProtocol = RebrickableRepository()) {
        self.legoSet = legoSet
        self.collectionStatus = collectionStatus
        self.repository = repository
    }

    var isInCollection: Bool {
        if case .inCollection = collectionStatus { return true }
        return false
    }

    var statusIsUnknown: Bool {
        if case .unknown = collectionStatus { return true }
        return false
    }

    @MainActor
    func removeFromCollection() async {
        await perform {
            try await self.repository.removeSetFromCollection(setNum: self.legoSet.setNum)
            self.collectionStatus = .notInCollection
            self.toastMessage = "Set retiré de la collection"
        }
    }

    @MainActor
    func retryCollectionStatus() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await refreshCollectionStatus()
    }

    @MainActor
    private func refreshCollectionStatus() async {
        do {
            let userSet = try await repository.fetchUserSet(setNum: legoSet.setNum)
            collectionStatus = userSet.map(CollectionStatus.inCollection) ?? .notInCollection
        } catch let error as APIError {
            collectionStatus = .unknown(error.errorDescription ?? "Statut de collection inconnu")
        } catch {
            collectionStatus = .unknown("Statut de collection inconnu")
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
