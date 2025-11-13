import XCTest
@testable import Live_Box

final class Live_BoxTests: XCTestCase {
    func testChannelDecodingParsesBooleanWebCheck() throws {
        let json = """
        [
            {
                "name": "Sample",
                "webcheck": "true",
                "streamurl": "https://example.com/stream.m3u8"
            },
            {
                "name": "Internal",
                "webcheck": "false",
                "streamurl": "https://example.com/stream2.m3u8"
            }
        ]
        """.data(using: .utf8)!

        let channels = try JSONDecoder().decode([Channel].self, from: json)
        XCTAssertEqual(channels.count, 2)
        XCTAssertTrue(channels[0].opensExternally)
        XCTAssertFalse(channels[1].opensExternally)
        XCTAssertEqual(channels[0].streamURL, URL(string: "https://example.com/stream.m3u8"))
    }
}
