import XCTest
import WebKit
@testable import BrickScan

/// Exercises the JS extraction logic against static HTML fixtures, rather
/// than the real network/Cloudflare flow (which isn't deterministic to test
/// against). If BrickLink or Amazon change their markup, update the fixture
/// here to match and see whether the extraction script still finds the
/// price — that's the contract these tests protect.
@MainActor
final class PriceScraperTests: XCTestCase {
    private struct BrickLinkResult: Decodable {
        let used: String?
        let new: String?
    }

    private struct AmazonResult: Decodable {
        let price: String
        let url: String?
    }

    private func evaluate(html: String, script: String) async throws -> String {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        webView.loadHTMLString(html, baseURL: URL(string: "https://example.com/"))

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let ready = try? await webView.evaluateJavaScript("document.readyState === 'complete'")
            if ready as? Bool == true { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        guard let result = try await webView.evaluateJavaScript(script) as? String else {
            XCTFail("Script did not return a string")
            return ""
        }
        return result
    }

    func testBrickLinkExtractScriptReadsUsedAndNewAveragePrices() async throws {
        let html = """
        <html><body>
        <table>
          <tr><td>Used</td></tr>
          <tr><td>Times Sold</td><td>12</td></tr>
          <tr><td>Avg Price</td><td>EUR 22.50</td></tr>
          <tr><td>New</td></tr>
          <tr><td>Times Sold</td><td>4</td></tr>
          <tr><td>Avg Price</td><td>EUR 39.99</td></tr>
        </table>
        </body></html>
        """

        let json = try await evaluate(html: html, script: BrickLinkPriceScraper.extractScript)
        let decoded = try JSONDecoder().decode(BrickLinkResult.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.used, "EUR 22.50")
        XCTAssertEqual(decoded.new, "EUR 39.99")
    }

    func testBrickLinkReadinessScriptWaitsForAvgPrice() async throws {
        let notReady = try await evaluate(
            html: "<html><body>Just a moment...</body></html>",
            script: "JSON.stringify(\(BrickLinkPriceScraper.readinessScript))"
        )
        XCTAssertEqual(notReady, "false")

        let ready = try await evaluate(
            html: "<html><body><table><tr><td>Avg Price</td><td>EUR 22.50</td></tr></table></body></html>",
            script: "JSON.stringify(\(BrickLinkPriceScraper.readinessScript))"
        )
        XCTAssertEqual(ready, "true")
    }

    func testAmazonExtractScriptPicksCardMatchingSetNumber() async throws {
        let html = """
        <html><body>
        <div data-component-type="s-search-result">
          <h2><a href="/dp/B000IRRELEVANT">LEGO Generic Set 99999</a></h2>
          <span class="a-price"><span class="a-offscreen">19,99 €</span></span>
        </div>
        <div data-component-type="s-search-result">
          <h2><a href="https://www.amazon.fr/dp/B0EXAMPLE">LEGO Creator 75257 Faucon Millenium</a></h2>
          <span class="a-price"><span class="a-offscreen">169,99 €</span></span>
        </div>
        </body></html>
        """

        let json = try await evaluate(html: html, script: AmazonPriceScraper.extractScript(setDigits: "75257"))
        let decoded = try JSONDecoder().decode(AmazonResult.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.price, "169,99 €")
        XCTAssertEqual(decoded.url, "https://www.amazon.fr/dp/B0EXAMPLE")
    }

    func testAmazonExtractScriptDetectsCaptchaAndReturnsNoMatch() async throws {
        let html = "<html><body>Saisissez les caractères que vous voyez ci-dessous</body></html>"
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        webView.loadHTMLString(html, baseURL: nil)

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let ready = try? await webView.evaluateJavaScript("document.readyState === 'complete'")
            if ready as? Bool == true { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        let result = try await webView.evaluateJavaScript(AmazonPriceScraper.extractScript(setDigits: "75257"))
        XCTAssertNil(result)
    }

    func testPriceParsingHandlesEuroCommaDecimal() {
        XCTAssertEqual(PriceParsing.amount(from: "22,50 €"), Decimal(string: "22.50"))
        XCTAssertEqual(PriceParsing.currency(from: "22,50 €"), "EUR")
    }

    func testPriceParsingHandlesDollarDotDecimal() {
        XCTAssertEqual(PriceParsing.amount(from: "$22.50"), Decimal(string: "22.50"))
        XCTAssertEqual(PriceParsing.currency(from: "$22.50"), "USD")
    }

    func testPriceParsingHandlesCurrencyCode() {
        XCTAssertEqual(PriceParsing.amount(from: "EUR 22.50"), Decimal(string: "22.50"))
        XCTAssertEqual(PriceParsing.currency(from: "EUR 22.50"), "EUR")
    }
}
