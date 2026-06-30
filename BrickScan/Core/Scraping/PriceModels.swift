import Foundation

/// Per-list annotation that drives which price source is used when valuing the collection.
/// Stored as a raw `String` in SwiftData (via `CachedSetList.conditionRaw`) so that adding
/// new cases later doesn't require a schema migration.
enum ListCondition: String, Codable, CaseIterable, Identifiable {
    /// Official lego.com retail price — the default, preserves existing behaviour.
    case retail
    /// BrickLink "last 6 months new" average — for sealed / MISB sets.
    case newSet
    /// BrickLink "last 6 months used" average — for open / occasion sets.
    case used

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .retail: return "Retail (lego.com)"
        case .newSet: return "Neuf (BrickLink)"
        case .used: return "Occasion (BrickLink)"
        }
    }
}

enum PriceSource: String, Codable, CaseIterable {
    case bricklinkUsed
    case bricklinkNew
    case amazon

    var displayName: String {
        switch self {
        case .bricklinkUsed: return "BrickLink (occasion)"
        case .bricklinkNew: return "BrickLink (neuf)"
        case .amazon: return "Amazon (neuf)"
        }
    }
}

extension String {
    /// Display name for a `PriceHistoryEntry.source` raw value, covering both `PriceSource` cases
    /// and `LocalRepository.legoStoreHistorySource` (lego.com has no `PriceSource` case of its own).
    var priceHistorySourceDisplayName: String {
        if self == legoStoreHistorySource { return "lego.com (officiel)" }
        return PriceSource(rawValue: self)?.displayName ?? self
    }
}

struct PriceQuote: Codable, Hashable {
    let source: PriceSource
    let amount: Decimal
    let currency: String
    let sourceURL: URL?
    let fetchedAt: Date
}
