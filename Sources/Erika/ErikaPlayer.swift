import CErika
import Foundation
import QuartzCore

@MainActor
public final class ErikaPlayer {
    public struct Configuration: Sendable, Equatable {
        public var outputMode: ErikaOutputMode
        public var edrHeadroom: Float
        public var upscaler: ErikaUpscaler
        public var videoAlphaMode: ErikaVideoAlphaMode

        public init(
            outputMode: ErikaOutputMode = .automatic,
            edrHeadroom: Float = 1,
            upscaler: ErikaUpscaler = .off,
            videoAlphaMode: ErikaVideoAlphaMode = .opaque
        ) {
            self.outputMode = outputMode
            self.edrHeadroom = max(1, edrHeadroom)
            self.upscaler = upscaler
            self.videoAlphaMode = videoAlphaMode
        }
    }

    private var handle: OpaquePointer?

    public init(configuration: Configuration = .init()) throws {
        let nativeConfiguration = ErikaPresenterConfig(
            output_mode: configuration.outputMode.rawValue,
            edr_headroom: configuration.edrHeadroom,
            luma_upscaler: configuration.upscaler.rawValue,
            video_alpha_mode: configuration.videoAlphaMode.rawValue
        )
        guard let handle = erika_presenter_create_with_config(nativeConfiguration) else {
            var message = "Erika could not create a presenter."
            if let pointer = erika_last_error_message() {
                message = String(cString: pointer)
                erika_string_free(pointer)
            }
            throw ErikaError(statusCode: -1, message: message)
        }
        self.handle = handle
    }

    deinit {
        if let handle {
            erika_presenter_destroy(handle)
        }
    }

    public func open(
        _ url: URL,
        httpHeaders: [String: String] = [:],
        httpReadAheadBytes: UInt64 = 0,
        httpBackBufferBytes: UInt64 = 0
    ) throws {
        let source = url.isFileURL ? url.path : url.absoluteString
        try open(
            source,
            options: ErikaOpenOptions(
                httpHeaders: httpHeaders,
                httpReadAheadBytes: httpReadAheadBytes,
                httpBackBufferBytes: httpBackBufferBytes
            )
        )
    }

    public func open(
        _ source: String,
        httpHeaders: [String: String] = [:],
        httpReadAheadBytes: UInt64 = 0,
        httpBackBufferBytes: UInt64 = 0
    ) throws {
        try open(
            source,
            options: ErikaOpenOptions(
                httpHeaders: httpHeaders,
                httpReadAheadBytes: httpReadAheadBytes,
                httpBackBufferBytes: httpBackBufferBytes
            )
        )
    }

    public func open(_ source: String, options: ErikaOpenOptions) throws {
        guard let handle else { throw closedError }
        try openNative(handle, source: source, options: options)
    }

    public func play() throws { try withHandle { try erikaCheck(erika_presenter_play($0)) } }
    public func pause() throws { try withHandle { try erikaCheck(erika_presenter_pause($0)) } }
    public func stop() throws { try withHandle { try erikaCheck(erika_presenter_stop($0)) } }

    public func close() throws {
        try withHandle { try erikaCheck(erika_presenter_close($0)) }
    }

    public func seek(to seconds: TimeInterval) throws {
        let position = try positionMicroseconds(seconds)
        try withHandle { try erikaCheck(erika_presenter_seek($0, position)) }
    }

    public func setPlaybackRate(_ rate: Double) throws {
        try withHandle { try erikaCheck(erika_presenter_set_playback_rate($0, rate)) }
    }

    public func setVolume(_ volume: Double) throws {
        try withHandle { try erikaCheck(erika_presenter_set_volume($0, min(1, max(0, volume)))) }
    }

    public func setUpscaler(_ upscaler: ErikaUpscaler) throws {
        try withHandle { try erikaCheck(erika_presenter_set_upscaler($0, upscaler.rawValue)) }
    }

    public func setSubtitleScale(_ scale: Double) throws {
        try withHandle { try erikaCheck(erika_presenter_set_subtitle_scale($0, scale)) }
    }

    public func setSubtitleStyle(_ style: ErikaSubtitleStyle) throws {
        guard let handle else { throw closedError }
        try style.withNative { native in
            try erikaCheck(erika_presenter_set_subtitle_style(handle, native))
        }
    }

    public func setSubtitleFont(family: String? = nil, filePath: String? = nil) throws {
        guard let handle else { throw closedError }
        try withOptionalCString(family) { family in
            try withOptionalCString(filePath) { path in
                try erikaCheck(erika_presenter_set_subtitle_font(handle, family, path))
            }
        }
    }

    @discardableResult
    public func registerSubtitleMemoryFont(_ data: Data) throws -> UInt64 {
        guard let handle else { throw closedError }
        var id: UInt64 = 0
        let status = data.withUnsafeBytes { bytes in
            erika_presenter_register_subtitle_memory_font(handle, bytes.bindMemory(to: UInt8.self).baseAddress, UInt(data.count), &id)
        }
        try erikaCheck(status)
        return id
    }

    public func selectSubtitleMemoryFonts(_ ids: [UInt64]) throws {
        guard let handle else { throw closedError }
        try ids.withUnsafeBufferPointer { buffer in
            try erikaCheck(erika_presenter_select_subtitle_memory_fonts(handle, buffer.baseAddress, UInt(buffer.count)))
        }
    }

    public func clearSubtitleMemoryFonts() throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_clear_subtitle_memory_fonts(handle))
    }

    public func setOutputHeadroom(_ headroom: Float, known: Bool = true) throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_set_output_headroom(handle, headroom, known))
    }

    public func setDebugHUDEnabled(_ enabled: Bool) throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_set_debug_hud_enabled(handle, enabled))
    }

    public func setDanmakuConfiguration(_ configuration: ErikaDanmakuConfiguration) throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_set_danmaku_config(handle, configuration.native))
    }

    public func danmakuConfiguration() throws -> ErikaDanmakuConfiguration {
        guard let handle else { throw closedError }
        var native = ErikaDanmakuConfig()
        try erikaCheck(erika_presenter_get_danmaku_config(handle, &native))
        return ErikaDanmakuConfiguration(native: native)
    }

    public func tracks() throws -> [ErikaTrack] {
        guard let handle else { throw closedError }
        var count: UInt = 0
        try erikaCheck(erika_presenter_tracks(handle, nil, 0, &count))
        guard count > 0 else { return [] }
        var native = [CErika.ErikaTrackInfo](repeating: CErika.ErikaTrackInfo(), count: Int(count))
        try native.withUnsafeMutableBufferPointer { buffer in
            try erikaCheck(erika_presenter_tracks(handle, buffer.baseAddress, count, &count))
        }
        return native.prefix(Int(count)).map { item in
            let track = ErikaTrack(
                id: item.id,
                kind: ErikaTrackKind(rawValue: Int32(item.kind.rawValue)) ?? .video,
                source: ErikaTrackSource(rawValue: Int32(item.source.rawValue)) ?? .embedded,
                selected: item.selected,
                canRemove: item.can_remove,
                title: nativeString(item.title),
                language: nativeString(item.language),
                codec: nativeString(item.codec),
                width: item.width,
                height: item.height,
                sampleRate: item.sample_rate,
                channels: item.channels,
                pixelFormat: nativeString(item.pixel_format),
                sampleFormat: nativeString(item.sample_format),
                profile: nativeString(item.profile),
                level: item.level,
                bitRate: item.bit_rate,
                frameRateNumerator: item.frame_rate_numerator,
                frameRateDenominator: item.frame_rate_denominator
            )
            var owned = item
            erika_track_info_free(&owned)
            return track
        }
    }

    @discardableResult
    public func addExternalSubtitle(_ source: String) throws -> Int64 {
        var trackID: Int64 = 0
        try withOptionalCString(source) { uri in
            try withHandle { try erikaCheck(erika_presenter_add_external_subtitle($0, uri, &trackID)) }
        }
        return trackID
    }

    public func removeSubtitleTrack(id: Int64) throws {
        try withHandle { try erikaCheck(erika_presenter_remove_subtitle_track($0, id)) }
    }

    public func selectAudioTrack(id: Int64?) throws {
        try withHandle { try erikaCheck(erika_presenter_select_audio_track($0, id ?? -1)) }
    }

    public func selectSubtitleTrack(id: Int64?) throws {
        try withHandle { try erikaCheck(erika_presenter_select_subtitle_track($0, id ?? -1)) }
    }

    public func loadDanmaku(from source: String) throws {
        try withOptionalCString(source) { uri in
            try withHandle { try erikaCheck(erika_presenter_load_danmaku_file($0, uri)) }
        }
    }

    public func loadDanmaku(json: String) throws {
        try withOptionalCString(json) { value in
            try withHandle { try erikaCheck(erika_presenter_load_danmaku_json($0, value)) }
        }
    }

    @discardableResult
    public func addDanmakuTrack(
        from source: String,
        name: String? = nil,
        offset: TimeInterval = 0
    ) throws -> UInt64 {
        var trackID: UInt64 = 0
        let offsetMicros = try signedMicroseconds(offset)
        try withOptionalCString(source) { uri in
            try withOptionalCString(name) { trackName in
                try withHandle {
                    try erikaCheck(erika_presenter_add_danmaku_track_file($0, uri, trackName, offsetMicros, &trackID))
                }
            }
        }
        return trackID
    }

    @discardableResult
    public func addDanmakuTrack(
        json: String,
        name: String? = nil,
        offset: TimeInterval = 0
    ) throws -> UInt64 {
        var trackID: UInt64 = 0
        let offsetMicros = try signedMicroseconds(offset)
        try withOptionalCString(json) { value in
            try withOptionalCString(name) { trackName in
                try withHandle {
                    try erikaCheck(erika_presenter_add_danmaku_track_json($0, value, trackName, offsetMicros, &trackID))
                }
            }
        }
        return trackID
    }

    public func danmakuTracks() throws -> [ErikaDanmakuTrack] {
        guard let handle else { throw closedError }
        var count: UInt = 0
        try erikaCheck(erika_presenter_danmaku_tracks(handle, nil, 0, &count))
        guard count > 0 else { return [] }
        var native = [CErika.ErikaDanmakuTrackInfo](repeating: CErika.ErikaDanmakuTrackInfo(), count: Int(count))
        try native.withUnsafeMutableBufferPointer { buffer in
            try erikaCheck(erika_presenter_danmaku_tracks(handle, buffer.baseAddress, count, &count))
        }
        return native.prefix(Int(count)).map { item in
            let track = ErikaDanmakuTrack(
                id: item.id,
                enabled: item.enabled,
                offsetMicros: item.offset_micros,
                itemCount: UInt64(item.item_count),
                name: nativeString(item.name),
                source: nativeString(item.source)
            )
            var owned = item
            erika_danmaku_track_info_free(&owned)
            return track
        }
    }

    public func setDanmakuEnabled(_ enabled: Bool) throws {
        try withHandle { try erikaCheck(erika_presenter_set_danmaku_enabled($0, enabled)) }
    }

    public func clearDanmaku() throws {
        try withHandle { try erikaCheck(erika_presenter_clear_danmaku($0)) }
    }

    public func removeDanmakuTrack(id: UInt64) throws {
        try withHandle { try erikaCheck(erika_presenter_remove_danmaku_track($0, id)) }
    }

    public func setDanmakuTrackEnabled(id: UInt64, enabled: Bool) throws {
        try withHandle { try erikaCheck(erika_presenter_set_danmaku_track_enabled($0, id, enabled)) }
    }

    public func setDanmakuTrackOffset(id: UInt64, offset: TimeInterval) throws {
        let offsetMicros = try signedMicroseconds(offset)
        try withHandle { try erikaCheck(erika_presenter_set_danmaku_track_offset($0, id, offsetMicros)) }
    }

    public func setDanmakuGlobalOffset(_ offset: TimeInterval) throws {
        let offsetMicros = try signedMicroseconds(offset)
        try withHandle { try erikaCheck(erika_presenter_set_danmaku_global_offset($0, offsetMicros)) }
    }

    public func setDanmakuFont(family: String? = nil, filePath: String? = nil) throws {
        guard let handle else { throw closedError }
        try withOptionalCString(family) { family in
            try withOptionalCString(filePath) { path in
                try erikaCheck(erika_presenter_set_danmaku_font(handle, family, path))
            }
        }
    }

    public func setDanmakuBlockWordsJSON(_ json: String?) throws {
        guard let handle else { throw closedError }
        try withOptionalCString(json) { value in
            try erikaCheck(erika_presenter_set_danmaku_block_words_json(handle, value))
        }
    }

    public func upscalerStatus() throws -> ErikaUpscalerStatus {
        guard let handle else { throw closedError }
        var native = CErika.ErikaUpscalerStatus()
        try erikaCheck(erika_presenter_get_upscaler_status(handle, &native))
        return ErikaUpscalerStatus(native: native)
    }

    public func trackSelection() throws -> ErikaTrackSelection {
        guard let handle else { throw closedError }
        var native = CErika.ErikaTrackSelection()
        try erikaCheck(erika_presenter_track_selection(handle, &native))
        return ErikaTrackSelection(
            video: native.video >= 0 ? native.video : nil,
            audio: native.audio >= 0 ? native.audio : nil,
            subtitle: native.subtitle >= 0 ? native.subtitle : nil
        )
    }

    public func subtitleMemoryFontStatus() throws -> ErikaSubtitleMemoryFontStatus {
        guard let handle else { throw closedError }
        var native = CErika.ErikaSubtitleMemoryFontStatus()
        try erikaCheck(erika_presenter_get_subtitle_memory_font_status(handle, &native))
        defer { erika_subtitle_memory_font_status_free(&native) }
        let selectedIDs: [UInt64]
        if let pointer = native.selected_ids, native.selected_count > 0 {
            selectedIDs = Array(UnsafeBufferPointer(start: pointer, count: Int(native.selected_count)))
        } else {
            selectedIDs = []
        }
        return ErikaSubtitleMemoryFontStatus(
            registeredCount: native.registered_count,
            registeredBytes: native.registered_bytes,
            selectedIDs: selectedIDs,
            generation: native.generation
        )
    }

    public func subtitleMemoryFontInfo(id: UInt64) throws -> ErikaSubtitleMemoryFontInfo {
        guard let handle else { throw closedError }
        var native = CErika.ErikaSubtitleMemoryFontInfo()
        try erikaCheck(erika_presenter_get_subtitle_memory_font_info(handle, id, &native))
        defer { erika_subtitle_memory_font_info_free(&native) }
        let faces: [ErikaSubtitleMemoryFontFace]
        if let pointer = native.faces, native.face_count > 0 {
            faces = (0..<Int(native.face_count)).map { index in
                let face = pointer[index]
                let families: [String]
                if let familiesJSON = nativeString(face.families_json),
                   let data = familiesJSON.data(using: .utf8),
                   let decoded = try? JSONSerialization.jsonObject(with: data) as? [String] {
                    families = decoded
                } else {
                    families = []
                }
                return ErikaSubtitleMemoryFontFace(
                    index: face.index,
                    families: families,
                    postScriptName: nativeString(face.post_script_name),
                    weight: face.weight,
                    italic: face.italic,
                    monospaced: face.monospaced
                )
            }
        } else {
            faces = []
        }
        return ErikaSubtitleMemoryFontInfo(id: native.id, byteLength: native.byte_len, faces: faces)
    }

    public func presenterStats() throws -> ErikaPresenterStats {
        guard let handle else { throw closedError }
        var native = CErika.ErikaPresenterStats()
        try erikaCheck(erika_presenter_get_stats(handle, &native))
        return ErikaPresenterStats(native: native)
    }

    public func outputStatus() throws -> ErikaOutputStatus {
        guard let handle else { throw closedError }
        var native = CErika.ErikaOutputStatus()
        try erikaCheck(erika_presenter_get_output_status(handle, &native))
        return ErikaOutputStatus(native: native)
    }

    public func resourceStatus() throws -> ErikaResourceStatus {
        guard let handle else { throw closedError }
        var native = CErika.ErikaPresenterResourceStatus()
        try erikaCheck(erika_presenter_get_resource_status(handle, &native))
        return ErikaResourceStatus(native: native)
    }

    public func pollEvent() throws -> ErikaPlaybackEvent? {
        guard let pointer = handle.flatMap({ erika_presenter_poll_event_json($0) }) else {
            return nil
        }
        return try decodeResponse(pointer, as: ErikaPlaybackEvent.self)
    }

    /// Polls the native fixed-layout C event. Use `pollEvent()` when decoder,
    /// audio, error, and message details from the JSON bridge are needed.
    public func pollNativeEvent() throws -> ErikaPlaybackEvent? {
        try withHandle { handle in
            var native = CErika.ErikaEvent()
            let status = erika_presenter_poll_event(handle, &native)
            if status == ErikaStatus_NoEvent { return nil }
            try erikaCheck(status)
            return ErikaPlaybackEvent(
                kind: ErikaEventKind(rawValue: Int32(native.kind.rawValue)) ?? .none,
                status: Int32(native.status.rawValue),
                state: ErikaPlaybackState(rawValue: Int32(native.state.rawValue)) ?? .idle,
                durationMicros: native.duration_micros,
                positionMicros: native.position_micros,
                buffering: native.buffering,
                video: ErikaVideoParameters(
                    width: native.video.width,
                    height: native.video.height,
                    primaries: native.video.primaries,
                    transfer: native.video.transfer
                ),
                tracks: ErikaTrackCounts(
                    video: native.tracks.video,
                    audio: native.tracks.audio,
                    subtitle: native.tracks.subtitle
                )
            )
        }
    }

    public func captureFrame(width: Int, height: Int) throws -> ErikaFrame {
        guard let handle else { throw closedError }
        guard width > 0, height > 0 else {
            throw ErikaError(statusCode: -1, message: "Frame dimensions must be positive.")
        }
        let (pixels, pixelOverflow) = width.multipliedReportingOverflow(by: height)
        let (count, byteOverflow) = pixels.multipliedReportingOverflow(by: 4)
        guard !pixelOverflow, !byteOverflow, width <= Int(UInt32.max), height <= Int(UInt32.max) else {
            throw ErikaError(statusCode: -1, message: "Frame dimensions are too large.")
        }
        var rgba = Data(count: count)
        let status = rgba.withUnsafeMutableBytes { bytes in
            erika_presenter_capture_frame_rgba(
                handle,
                UInt32(width),
                UInt32(height),
                bytes.bindMemory(to: UInt8.self).baseAddress,
                UInt(count)
            )
        }
        try erikaCheck(status)
        return ErikaFrame(width: width, height: height, rgba: rgba)
    }

    public func invoke(_ method: String, arguments: [String: Any] = [:]) throws -> Any {
        try invokeValue(method, arguments: arguments)
    }

    public func attach(to layer: CAMetalLayer, width: UInt32, height: UInt32, scale: Double) throws {
        guard let handle else { throw closedError }
        let rawLayer = UInt64(UInt(bitPattern: Unmanaged.passUnretained(layer).toOpaque()))
        try erikaCheck(erika_presenter_attach_metal_layer(handle, rawLayer, width, height, scale))
    }

    public func resizeSurface(width: UInt32, height: UInt32, scale: Double) throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_resize_surface(handle, width, height, scale))
    }

    public func detachSurface() throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_detach_surface(handle))
    }

    @discardableResult
    public func render(at timestamp: TimeInterval) throws -> ErikaPresenterStats {
        try withHandle { handle in
            var native = CErika.ErikaPresenterStats()
            try erikaCheck(erika_presenter_render_tick(handle, timestamp, &native))
            return ErikaPresenterStats(native: native)
        }
    }

    @discardableResult
    public func audioOnlyTick() throws -> ErikaPresenterStats {
        try withHandle { handle in
            var native = CErika.ErikaPresenterStats()
            try erikaCheck(erika_presenter_audio_only_tick(handle, &native))
            return ErikaPresenterStats(native: native)
        }
    }

    private func withHandle<T>(_ body: (OpaquePointer) throws -> T) throws -> T {
        guard let handle else { throw closedError }
        return try body(handle)
    }

    private var closedError: ErikaError {
        ErikaError(statusCode: -1, message: "ErikaPlayer has already been destroyed.")
    }

    private func invokeVoid(_ method: String, arguments: [String: Any] = [:]) throws {
        _ = try invokeValue(method, arguments: arguments)
    }

    private func invoke<T: Decodable>(
        _ method: String,
        arguments: [String: Any] = [:],
        as type: T.Type
    ) throws -> T {
        let value = try invokeValue(method, arguments: arguments)
        let data = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func invokeValue(_ method: String, arguments: [String: Any]) throws -> Any {
        guard let handle else { throw closedError }
        let argumentsData = try JSONSerialization.data(withJSONObject: arguments)
        guard let argumentsJSON = String(data: argumentsData, encoding: .utf8) else {
            throw ErikaError(statusCode: -1, message: "Could not encode Erika arguments as UTF-8.")
        }
        let pointer = method.withCString { methodPointer in
            argumentsJSON.withCString { argumentsPointer in
                erika_presenter_invoke_json(handle, methodPointer, argumentsPointer)
            }
        }
        guard let pointer else {
            throw ErikaError(statusCode: -1, message: "Erika returned no response for \(method).")
        }
        return try responseValue(pointer)
    }

    private func decodeResponse<T: Decodable>(
        _ pointer: UnsafeMutablePointer<CChar>,
        as type: T.Type
    ) throws -> T {
        let value = try responseValue(pointer)
        let data = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func responseValue(_ pointer: UnsafeMutablePointer<CChar>) throws -> Any {
        defer { erika_string_free(pointer) }
        let data = Data(String(cString: pointer).utf8)
        guard
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let ok = response["ok"] as? Bool
        else {
            throw ErikaError(statusCode: -1, message: "Erika returned an invalid JSON response.")
        }
        guard ok else {
            let code = (response["status"] as? NSNumber)?.int32Value ?? -1
            let message = response["error"] as? String ?? "Erika operation failed."
            throw ErikaError(statusCode: code, message: message)
        }
        return response["value"] ?? NSNull()
    }
}
