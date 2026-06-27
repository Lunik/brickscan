import Foundation

/// Drives a one-set-at-a-time price refresh across the user's whole collection, started
/// explicitly from Settings — never automatically. A singleton (like
/// `OfflineCatalogStore.shared`/`HeadlessWebScraper.shared`) so the run's state survives
/// `SettingsView` being dismissed and reopened, and so a second `start()` call while one
/// is already running just observes the same job instead of racing it.
///
/// Sets are processed strictly sequentially with a delay between each — `PriceRepository`
/// and `LegoStoreRepository` already drive hidden `WKWebView`s that solve Cloudflare
/// challenges; running dozens of those concurrently across a whole collection risks getting
/// flagged as abusive traffic, so this deliberately trades speed for being polite to the
/// scraped sites.
///
/// Mirrors `OfflineCatalogStore`'s pause/resume pattern: there is no background execution
/// here (see AGENTS.md / issue #5 on why this app avoids `BGAppRefreshTask`-style background
/// work) — `SettingsViewModel.handleScenePhaseChange` calls `cancelPreservingProgress()` when
/// the app backgrounds, and the next `start()` call (after the user reopens the app and taps
/// the button again) resumes from the persisted queue instead of restarting from zero.
@MainActor
@Observable
final class CollectionPriceUpdater {
    static let shared = CollectionPriceUpdater()

    private(set) var isRunning = false
    private(set) var done = 0
    private(set) var total = 0

    private let queueURL: URL
    private var cancelRequested = false

    private struct Queue: Codable {
        var remaining: [LegoSet]
        var total: Int
    }

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.queueURL = directory.appendingPathComponent("CollectionPriceUpdateQueue.json")
        if let queue = Self.loadQueue(at: queueURL) {
            self.total = queue.total
            self.done = queue.total - queue.remaining.count
        }
    }

    var hasResumableUpdate: Bool {
        FileManager.default.fileExists(atPath: queueURL.path)
    }

    /// Runs (or resumes) the batch. `allSets` seeds a fresh run — ignored if a resumable
    /// queue already exists on disk, in which case that queue's own sets/total are used
    /// instead. `persist` is the caller's hook to actually write each set's fetched prices
    /// into SwiftData (this class has no `ModelContext` of its own).
    ///
    /// Returns `true` if the whole queue drained (caller should fire the completion
    /// notification), `false` if the run was cancelled (paused) mid-way.
    func start(
        allSets: [LegoSet],
        priceRepository: PriceRepositoryProtocol,
        legoStoreRepository: LegoStoreRepositoryProtocol,
        persist: @escaping @MainActor (LegoSet, [PriceQuote], StorePrice?) async -> Void
    ) async -> Bool {
        guard !isRunning else { return false }

        var queue = Self.loadQueue(at: queueURL) ?? Queue(remaining: allSets, total: allSets.count)
        total = queue.total
        done = queue.total - queue.remaining.count
        isRunning = true
        cancelRequested = false
        defer { isRunning = false }

        while !queue.remaining.isEmpty {
            if cancelRequested {
                saveQueue(queue)
                return false
            }

            let legoSet = queue.remaining.removeFirst()
            let quotes = await priceRepository.fetchPrices(for: legoSet)
            let storePrice = try? await legoStoreRepository.fetchStorePrice(setNum: legoSet.setNum)
            await persist(legoSet, quotes, storePrice)

            saveQueue(queue)
            done = queue.total - queue.remaining.count

            if !queue.remaining.isEmpty {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }

        clearQueue()
        return true
    }

    /// Stops the run after the set currently in flight finishes — the queue file is
    /// already up to date after every set, so there's nothing extra to persist here, just
    /// the cooperative flag the loop checks between sets.
    func cancelPreservingProgress() {
        guard isRunning else { return }
        cancelRequested = true
    }

    private func saveQueue(_ queue: Queue) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        try? data.write(to: queueURL, options: .atomic)
    }

    private func clearQueue() {
        try? FileManager.default.removeItem(at: queueURL)
        total = 0
        done = 0
    }

    private static func loadQueue(at url: URL) -> Queue? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Queue.self, from: data)
    }
}
