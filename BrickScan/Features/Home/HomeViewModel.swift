import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var scannedSetsCount = 0
    var totalScans = 0

    var isAccountLinked = false
    var ownedSetsCount: Int?
    var listsCount: Int?
    var rebrickableErrorMessage: String?
    var isLoadingRebrickableStats = false

    private let repository: RebrickableRepositoryProtocol
    private let localRepository: LocalRepository

    init(repository: RebrickableRepositoryProtocol = RebrickableRepository(), localRepository: LocalRepository) {
        self.repository = repository
        self.localRepository = localRepository
    }

    func loadAppStats() {
        scannedSetsCount = localRepository.scannedSetsCount()
        totalScans = ScanStatsStore.shared.totalScans
    }

    func loadRebrickableStats() async {
        isAccountLinked = KeychainService.shared.hasUserToken
        guard isAccountLinked else {
            ownedSetsCount = nil
            listsCount = nil
            rebrickableErrorMessage = nil
            return
        }

        isLoadingRebrickableStats = true
        rebrickableErrorMessage = nil
        defer { isLoadingRebrickableStats = false }
        do {
            async let count = repository.fetchUserSetsCount()
            async let lists = repository.fetchUserSetLists()
            ownedSetsCount = try await count
            listsCount = try await lists.count
        } catch let error as APIError {
            rebrickableErrorMessage = error.errorDescription
        } catch {
            rebrickableErrorMessage = "Une erreur est survenue"
        }
    }
}
