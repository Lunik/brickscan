import Foundation
import SwiftData

@Model
final class CachedSet {
    @Attribute(.unique) var setNum: String
    var name: String
    var year: Int
    var numParts: Int
    var setImgUrl: String?
    var lastScannedAt: Date
    var isInCollection: Bool
    var currentListId: Int?
    var currentListName: String?
    /// True when this entry is an individual CMF minifigure (identified via
    /// its box's Data Matrix code) rather than a directly-scanned set.
    var isMinifig: Bool = false
    /// The raw decoded box code, kept for minifig entries only.
    var boxCode: String?

    init(
        from legoSet: LegoSet,
        isInCollection: Bool = false,
        currentListId: Int? = nil,
        currentListName: String? = nil,
        isMinifig: Bool = false,
        boxCode: String? = nil
    ) {
        self.setNum = legoSet.setNum
        self.name = legoSet.name
        self.year = legoSet.year
        self.numParts = legoSet.numParts
        self.setImgUrl = legoSet.setImgUrl
        self.lastScannedAt = Date()
        self.isInCollection = isInCollection
        self.currentListId = currentListId
        self.currentListName = currentListName
        self.isMinifig = isMinifig
        self.boxCode = boxCode
    }

    var isExpired: Bool {
        Date().timeIntervalSince(lastScannedAt) > 24 * 60 * 60
    }
}

/// A CMF box Data Matrix code that was scanned but didn't match any known
/// entry in the bundled `MinifigBoxCodes.json` table. Kept so the scan isn't
/// lost: if a future app update ships an updated table that covers this
/// code, it gets promoted into a `CachedSet` automatically (see
/// `LocalRepository.resolvePendingMinifigBoxCodes`).
@Model
final class CachedUnresolvedBoxCode {
    @Attribute(.unique) var boxCode: String
    var firstScannedAt: Date
    var lastScannedAt: Date

    init(boxCode: String) {
        self.boxCode = boxCode
        self.firstScannedAt = Date()
        self.lastScannedAt = Date()
    }
}

/// A price quote scraped from an external source (BrickLink, Amazon),
/// cached per set+source so the price section doesn't re-scrape on every
/// screen visit. Prices move slowly, so the TTL is much longer than
/// `CachedSet`'s.
@Model
final class CachedSetPrice {
    var setNum: String
    var source: String
    var amount: Decimal
    var currency: String
    var sourceURLString: String?
    var fetchedAt: Date

    init(setNum: String, quote: PriceQuote) {
        self.setNum = setNum
        self.source = quote.source.rawValue
        self.amount = quote.amount
        self.currency = quote.currency
        self.sourceURLString = quote.sourceURL?.absoluteString
        self.fetchedAt = quote.fetchedAt
    }

    var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > 7 * 24 * 60 * 60
    }

    var quote: PriceQuote? {
        guard let priceSource = PriceSource(rawValue: source) else { return nil }
        return PriceQuote(
            source: priceSource,
            amount: amount,
            currency: currency,
            sourceURL: sourceURLString.flatMap(URL.init),
            fetchedAt: fetchedAt
        )
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
