import CErika
import Foundation
import QuartzCore

@MainActor
public final class ErikaPlayer {
    public struct Configuration: Sendable, Equatable {
        public var outputMode: ErikaOutputMode
        public var edrHeadroom: Float
        public var upscaler: ErikaUpscaler

        public init(
            outputMode: ErikaOutputMode = .automatic,
            edrHeadroom: Float = 1,
            upscaler: ErikaUpscaler = .off
        ) {
            self.outputMode = outputMode
            self.edrHeadroom = max(1, edrHeadroom)
            self.upscaler = upscaler
        }
    }

    private var handle: OpaquePointer?

    public init(configuration: Configuration = .init()) throws {
        let nativeConfiguration = ErikaPresenterConfig(
            output_mode: configuration.outputMode.rawValue,
            edr_headroom: configuration.edrHeadroom,
            luma_upscaler: configuration.upscaler.rawValue
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

    public func open(_ url: URL, httpHeaders: [String: String] = [:]) throws {
        let source = url.isFileURL ? url.path : url.absoluteString
        try invokeVoid("open", arguments: ["uri": source, "httpHeaders": httpHeaders])
    }

    public func open(_ source: String, httpHeaders: [String: String] = [:]) throws {
        try invokeVoid("open", arguments: ["uri": source, "httpHeaders": httpHeaders])
    }

    public func play() throws { try invokeVoid("play") }
    public func pause() throws { try invokeVoid("pause") }
    public func stop() throws { try invokeVoid("stop") }

    public func close() throws {
        try invokeVoid("close")
    }

    public func seek(to seconds: TimeInterval) throws {
        try invokeVoid("seek", arguments: ["positionMicros": UInt64(max(0, seconds) * 1_000_000)])
    }

    public func setPlaybackRate(_ rate: Double) throws {
        try invokeVoid("setPlaybackRate", arguments: ["rate": rate])
    }

    public func setVolume(_ volume: Double) throws {
        try invokeVoid("setVolume", arguments: ["volume": min(1, max(0, volume))])
    }

    public func setUpscaler(_ upscaler: ErikaUpscaler) throws {
        try invokeVoid("setUpscaler", arguments: ["mode": upscaler.rawValue])
    }

    public func setSubtitleScale(_ scale: Double) throws {
        try invokeVoid("setSubtitleScale", arguments: ["scale": scale])
    }

    public func tracks() throws -> [ErikaTrack] {
        try invoke("tracks", as: [ErikaTrack].self)
    }

    @discardableResult
    public func addExternalSubtitle(_ source: String) throws -> Int64 {
        try invoke("addExternalSubtitle", arguments: ["uri": source], as: Int64.self)
    }

    public func removeSubtitleTrack(id: Int64) throws {
        try invokeVoid("removeSubtitleTrack", arguments: ["trackId": id])
    }

    public func selectAudioTrack(id: Int64?) throws {
        try invokeVoid("selectAudioTrack", arguments: ["trackId": id ?? -1])
    }

    public func selectSubtitleTrack(id: Int64?) throws {
        try invokeVoid("selectSubtitleTrack", arguments: ["trackId": id ?? -1])
    }

    public func loadDanmaku(from source: String) throws {
        try invokeVoid("loadDanmakuFile", arguments: ["uri": source])
    }

    public func loadDanmaku(json: String) throws {
        try invokeVoid("loadDanmakuJson", arguments: ["json": json])
    }

    @discardableResult
    public func addDanmakuTrack(
        from source: String,
        name: String? = nil,
        offset: TimeInterval = 0
    ) throws -> UInt64 {
        var arguments: [String: Any] = [
            "uri": source,
            "offsetMicros": Int64(offset * 1_000_000),
        ]
        if let name { arguments["name"] = name }
        return try invoke("addDanmakuTrackFile", arguments: arguments, as: UInt64.self)
    }

    public func danmakuTracks() throws -> [ErikaDanmakuTrack] {
        try invoke("danmakuTracks", as: [ErikaDanmakuTrack].self)
    }

    public func setDanmakuEnabled(_ enabled: Bool) throws {
        try invokeVoid("setDanmakuEnabled", arguments: ["enabled": enabled])
    }

    public func clearDanmaku() throws {
        try invokeVoid("clearDanmaku")
    }

    public func presenterStats() throws -> ErikaPresenterStats {
        try invoke("getPresenterStats", as: ErikaPresenterStats.self)
    }

    public func outputStatus() throws -> ErikaOutputStatus {
        try invoke("getOutputStatus", as: ErikaOutputStatus.self)
    }

    public func resourceStatus() throws -> ErikaResourceStatus {
        try invoke("getResourceStatus", as: ErikaResourceStatus.self)
    }

    public func pollEvent() throws -> ErikaPlaybackEvent? {
        guard let pointer = handle.flatMap({ erika_presenter_poll_event_json($0) }) else {
            return nil
        }
        return try decodeResponse(pointer, as: ErikaPlaybackEvent.self)
    }

    public func captureFrame(width: Int, height: Int) throws -> ErikaFrame {
        guard width > 0, height > 0 else {
            throw ErikaError(statusCode: -1, message: "Frame dimensions must be positive.")
        }
        let (pixels, pixelOverflow) = width.multipliedReportingOverflow(by: height)
        let (count, byteOverflow) = pixels.multipliedReportingOverflow(by: 4)
        guard !pixelOverflow, !byteOverflow else {
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

    func attach(to layer: CAMetalLayer, width: UInt32, height: UInt32, scale: Double) throws {
        guard let handle else { throw closedError }
        let rawLayer = UInt64(UInt(bitPattern: Unmanaged.passUnretained(layer).toOpaque()))
        try erikaCheck(erika_presenter_attach_metal_layer(handle, rawLayer, width, height, scale))
    }

    func resizeSurface(width: UInt32, height: UInt32, scale: Double) throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_resize_surface(handle, width, height, scale))
    }

    func detachSurface() throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_detach_surface(handle))
    }

    func render(at timestamp: TimeInterval) throws {
        guard let handle else { throw closedError }
        try erikaCheck(erika_presenter_render_tick(handle, timestamp, nil))
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
