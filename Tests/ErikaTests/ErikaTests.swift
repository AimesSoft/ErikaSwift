import Erika
import XCTest

final class ErikaTests: XCTestCase {
    func testDefaultConfiguration() {
        let configuration = ErikaPlayer.Configuration()
        XCTAssertEqual(configuration.outputMode, .automatic)
        XCTAssertEqual(configuration.edrHeadroom, 1)
        XCTAssertEqual(configuration.upscaler, .off)
        XCTAssertEqual(configuration.videoAlphaMode, .opaque)
    }

    func testHeadroomIsClamped() {
        let configuration = ErikaPlayer.Configuration(edrHeadroom: 0.5)
        XCTAssertEqual(configuration.edrHeadroom, 1)
    }

    func testPublicEnumValuesMatchABI() {
        XCTAssertEqual(ErikaPlaybackState.playing.rawValue, 3)
        XCTAssertEqual(ErikaEventKind.error.rawValue, 9)
        XCTAssertEqual(ErikaUpscaler.artCNNC4F16DS.rawValue, 3)
        XCTAssertEqual(ErikaVideoAlphaMode.opaque.rawValue, 0)
        XCTAssertEqual(ErikaVideoAlphaMode.packedAlphaRight.rawValue, 1)
        XCTAssertEqual(ErikaSubtitleOverride.all.rawValue, 0x9FC)
    }

    func testOpenOptionsDefaultsAndHeaders() {
        let options = ErikaOpenOptions(httpHeaders: ["X-Test": "ok"], httpReadAheadBytes: 2 * 1024 * 1024)
        XCTAssertEqual(options.httpHeaders["X-Test"], "ok")
        XCTAssertEqual(options.httpReadAheadBytes, 2 * 1024 * 1024)
    }

    func testLegacyPlaybackEventJSONRemainsDecodable() throws {
        let data = Data(#"{"kind":1}"#.utf8)
        let event = try JSONDecoder().decode(ErikaPlaybackEvent.self, from: data)
        XCTAssertEqual(event.kind, .stateChanged)
        XCTAssertEqual(event.state, .idle)
        XCTAssertNil(event.decoder)
        XCTAssertNil(event.audio)
    }

    func testLegacyTrackJSONRemainsDecodable() throws {
        let data = Data(#"{"id":7,"kind":2,"source":0}"#.utf8)
        let track = try JSONDecoder().decode(ErikaTrack.self, from: data)
        XCTAssertEqual(track.id, 7)
        XCTAssertEqual(track.kind, .subtitle)
        XCTAssertEqual(track.bitRate, 0)
        XCTAssertNil(track.framesPerSecond)
    }
}
