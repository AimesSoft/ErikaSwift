import Erika
import XCTest

final class ErikaTests: XCTestCase {
    func testDefaultConfiguration() {
        let configuration = ErikaPlayer.Configuration()
        XCTAssertEqual(configuration.outputMode, .automatic)
        XCTAssertEqual(configuration.edrHeadroom, 1)
        XCTAssertEqual(configuration.upscaler, .off)
    }

    func testHeadroomIsClamped() {
        let configuration = ErikaPlayer.Configuration(edrHeadroom: 0.5)
        XCTAssertEqual(configuration.edrHeadroom, 1)
    }

    func testPublicEnumValuesMatchABI() {
        XCTAssertEqual(ErikaPlaybackState.playing.rawValue, 3)
        XCTAssertEqual(ErikaEventKind.error.rawValue, 9)
        XCTAssertEqual(ErikaUpscaler.artCNNC4F16DS.rawValue, 3)
    }
}
