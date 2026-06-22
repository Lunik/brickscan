import Foundation
import SwiftData

@Model
final class CachedSet {
    @Attribute(.unique) var setNum: String
    var name: String
    var year: Int
    var themeId: Int = 0
    var numParts: Int
    var setImgUrl: String?
    var setUrl: String?
    var quantity: Int = 1
    var lastScannedAt: Date
    /// True if this row exists because the user scanned it; false if it only exists from a
    /// collection sync. Distinguishes History (scanned sets) from Collection (owned sets).
    var wasScanned: Bool = true
    var lastSyncedAt: Date?
    var isInCollection: Bool
    var currentListId: Int?
    var currentListName: String?
    var storePriceEUR: Double?
    var storeAvailability: String?
    var storePriceFetchedAt: Date?

    init(from legoSet: LegoSet, isInCollection: Bool = false, currentListId: Int? = nil, currentListName: String? = nil) {
        self.setNum = legoSet.setNum
        self.name = legoSet.name
        self.year = legoSet.year
        self.themeId = legoSet.themeId
        self.numParts = legoSet.numParts
        self.setImgUrl = legoSet.setImgUrl
        self.setUrl = legoSet.setUrl
        self.lastScannedAt = Date()
        self.isInCollection = isInCollection
        self.currentListId = currentListId
        self.currentListName = currentListName
    }

    var isExpired: Bool {
        Date().timeIntervalSince(lastScannedAt) > 24 * 60 * 60
    }

    func asLegoSet() -> LegoSet {
        LegoSet(setNum: setNum, name: name, year: year, themeId: themeId, numParts: numParts, setImgUrl: setImgUrl, setUrl: setUrl)
    }

    func asCollectionStatus() -> CollectionStatus {
        guard isInCollection else { return .notInCollection }
        let userSet = UserSet(legoSet: asLegoSet(), quantity: quantity, includeSpares: false, listId: currentListId)
        return .inCollection(userSet)
    }
}

@Model
final class CollectionSyncState {
    var lastFullSyncAt: Date?

    init(lastFullSyncAt: Date? = nil) {
        self.lastFullSyncAt = lastFullSyncAt
    }
}

@Model
final class CachedSetList {
    @Attribute(.unique) var listId: Int
    var name: String
    var numSets: Int
    var lastFetchedAt: Date

    init(from setList: SetList) {
        self.listId = setList.id
        self.name = setList.name
        self.numSets = setList.numSets
        self.lastFetchedAt = Date()
    }

    var isExpired: Bool {
        Date().timeIntervalSince(lastFetchedAt) > 5 * 60
    }
}
