import CErika
import Foundation

public enum ErikaOutputMode: Int32, Sendable, CaseIterable {
    case sdr = 0
    case appleEDR = 1
    case extendedLinear = 2
    case automatic = 3
}

public enum ErikaUpscaler: Int32, Sendable, CaseIterable {
    case off = 0
    case artCNNC4F16 = 1
    case artCNNC4F32 = 2
    case artCNNC4F16DS = 3
}

public enum ErikaPlaybackState: Int32, Sendable, Codable {
    case idle = 0
    case opening = 1
    case ready = 2
    case playing = 3
    case paused = 4
    case stopped = 5
    case closed = 6
    case error = 7
}

public enum ErikaEventKind: Int32, Sendable, Codable {
    case none = 0
    case stateChanged = 1
    case durationChanged = 2
    case positionChanged = 3
    case tracksChanged = 4
    case bufferingChanged = 5
    case videoParamsChanged = 6
    case surfaceAttached = 7
    case surfaceDetached = 8
    case error = 9
    case trackSelectionChanged = 10
    case videoDecoderChanged = 11
    case audioOutputChanged = 12
}

public enum ErikaTrackKind: Int32, Sendable, Codable {
    case video = 0
    case audio = 1
    case subtitle = 2
}

public enum ErikaTrackSource: Int32, Sendable, Codable {
    case embedded = 0
    case external = 1
}

public struct ErikaVideoParameters: Codable, Sendable, Equatable {
    public let width: UInt32
    public let height: UInt32
    public let primaries: UInt32
    public let transfer: UInt32

    public init(width: UInt32, height: UInt32, primaries: UInt32, transfer: UInt32) {
        self.width = width
        self.height = height
        self.primaries = primaries
        self.transfer = transfer
    }
}

public struct ErikaTrackCounts: Codable, Sendable, Equatable {
    public let video: UInt32
    public let audio: UInt32
    public let subtitle: UInt32

    public init(video: UInt32, audio: UInt32, subtitle: UInt32) {
        self.video = video
        self.audio = audio
        self.subtitle = subtitle
    }
}

public struct ErikaPlaybackEvent: Codable, Sendable, Equatable {
    public let kind: ErikaEventKind
    public let status: Int32
    public let state: ErikaPlaybackState
    public let durationMicros: Int64
    public let positionMicros: UInt64
    public let buffering: Bool
    public let video: ErikaVideoParameters
    public let tracks: ErikaTrackCounts
    public let error: String?
    public let message: String?
    public let decoder: ErikaVideoDecoderInfo?
    public let audio: ErikaAudioOutputInfo?

    private enum CodingKeys: String, CodingKey {
        case kind, status, state, durationMicros, positionMicros, buffering, video, tracks, error, message, decoder, audio
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        kind = try values.decode(ErikaEventKind.self, forKey: .kind)
        status = try values.decodeIfPresent(Int32.self, forKey: .status) ?? 0
        state = try values.decodeIfPresent(ErikaPlaybackState.self, forKey: .state) ?? .idle
        durationMicros = try values.decodeIfPresent(Int64.self, forKey: .durationMicros) ?? 0
        positionMicros = try values.decodeIfPresent(UInt64.self, forKey: .positionMicros) ?? 0
        buffering = try values.decodeIfPresent(Bool.self, forKey: .buffering) ?? false
        video = try values.decodeIfPresent(ErikaVideoParameters.self, forKey: .video) ?? .init(width: 0, height: 0, primaries: 0, transfer: 0)
        tracks = try values.decodeIfPresent(ErikaTrackCounts.self, forKey: .tracks) ?? .init(video: 0, audio: 0, subtitle: 0)
        error = try values.decodeIfPresent(String.self, forKey: .error)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        self.decoder = try values.decodeIfPresent(ErikaVideoDecoderInfo.self, forKey: .decoder)
        audio = try values.decodeIfPresent(ErikaAudioOutputInfo.self, forKey: .audio)
    }
}

public struct ErikaTrack: Codable, Sendable, Identifiable, Equatable {
    public let id: Int64
    public let kind: ErikaTrackKind
    public let source: ErikaTrackSource
    public let selected: Bool
    public let canRemove: Bool
    public let title: String?
    public let language: String?
    public let codec: String?
    public let width: UInt32
    public let height: UInt32
    public let sampleRate: UInt32
    public let channels: UInt32
    public let pixelFormat: String?
    public let sampleFormat: String?
    public let profile: String?
    public let level: Int32
    public let bitRate: UInt64
    public let frameRateNumerator: UInt32
    public let frameRateDenominator: UInt32

    public var framesPerSecond: Double? {
        guard frameRateDenominator > 0 else { return nil }
        return Double(frameRateNumerator) / Double(frameRateDenominator)
    }

    public init(
        id: Int64,
        kind: ErikaTrackKind,
        source: ErikaTrackSource,
        selected: Bool,
        canRemove: Bool,
        title: String? = nil,
        language: String? = nil,
        codec: String? = nil,
        width: UInt32 = 0,
        height: UInt32 = 0,
        sampleRate: UInt32 = 0,
        channels: UInt32 = 0,
        pixelFormat: String? = nil,
        sampleFormat: String? = nil,
        profile: String? = nil,
        level: Int32 = 0,
        bitRate: UInt64 = 0,
        frameRateNumerator: UInt32 = 0,
        frameRateDenominator: UInt32 = 0
    ) {
        self.id = id
        self.kind = kind
        self.source = source
        self.selected = selected
        self.canRemove = canRemove
        self.title = title
        self.language = language
        self.codec = codec
        self.width = width
        self.height = height
        self.sampleRate = sampleRate
        self.channels = channels
        self.pixelFormat = pixelFormat
        self.sampleFormat = sampleFormat
        self.profile = profile
        self.level = level
        self.bitRate = bitRate
        self.frameRateNumerator = frameRateNumerator
        self.frameRateDenominator = frameRateDenominator
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, source, selected, canRemove, title, language, codec, width, height, sampleRate, channels, pixelFormat, sampleFormat, profile, level, bitRate, frameRateNumerator, frameRateDenominator
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int64.self, forKey: .id)
        kind = try values.decode(ErikaTrackKind.self, forKey: .kind)
        source = try values.decode(ErikaTrackSource.self, forKey: .source)
        selected = try values.decodeIfPresent(Bool.self, forKey: .selected) ?? false
        canRemove = try values.decodeIfPresent(Bool.self, forKey: .canRemove) ?? false
        title = try values.decodeIfPresent(String.self, forKey: .title)
        language = try values.decodeIfPresent(String.self, forKey: .language)
        codec = try values.decodeIfPresent(String.self, forKey: .codec)
        width = try values.decodeIfPresent(UInt32.self, forKey: .width) ?? 0
        height = try values.decodeIfPresent(UInt32.self, forKey: .height) ?? 0
        sampleRate = try values.decodeIfPresent(UInt32.self, forKey: .sampleRate) ?? 0
        channels = try values.decodeIfPresent(UInt32.self, forKey: .channels) ?? 0
        pixelFormat = try values.decodeIfPresent(String.self, forKey: .pixelFormat)
        sampleFormat = try values.decodeIfPresent(String.self, forKey: .sampleFormat)
        profile = try values.decodeIfPresent(String.self, forKey: .profile)
        level = try values.decodeIfPresent(Int32.self, forKey: .level) ?? 0
        bitRate = try values.decodeIfPresent(UInt64.self, forKey: .bitRate) ?? 0
        frameRateNumerator = try values.decodeIfPresent(UInt32.self, forKey: .frameRateNumerator) ?? 0
        frameRateDenominator = try values.decodeIfPresent(UInt32.self, forKey: .frameRateDenominator) ?? 0
    }
}

public struct ErikaDanmakuTrack: Codable, Sendable, Identifiable, Equatable {
    public let id: UInt64
    public let enabled: Bool
    public let offsetMicros: Int64
    public let itemCount: UInt64
    public let name: String?
    public let source: String?

    public init(id: UInt64, enabled: Bool, offsetMicros: Int64, itemCount: UInt64, name: String?, source: String?) {
        self.id = id
        self.enabled = enabled
        self.offsetMicros = offsetMicros
        self.itemCount = itemCount
        self.name = name
        self.source = source
    }
}

extension ErikaPlaybackEvent {
    public init(
        kind: ErikaEventKind,
        status: Int32 = 0,
        state: ErikaPlaybackState = .idle,
        durationMicros: Int64 = 0,
        positionMicros: UInt64 = 0,
        buffering: Bool = false,
        video: ErikaVideoParameters = .init(width: 0, height: 0, primaries: 0, transfer: 0),
        tracks: ErikaTrackCounts = .init(video: 0, audio: 0, subtitle: 0),
        error: String? = nil,
        message: String? = nil,
        decoder: ErikaVideoDecoderInfo? = nil,
        audio: ErikaAudioOutputInfo? = nil
    ) {
        self.kind = kind
        self.status = status
        self.state = state
        self.durationMicros = durationMicros
        self.positionMicros = positionMicros
        self.buffering = buffering
        self.video = video
        self.tracks = tracks
        self.error = error
        self.message = message
        self.decoder = decoder
        self.audio = audio
    }
}

public struct ErikaPresenterStats: Codable, Sendable, Equatable {
    public let decodedVideoFrames: UInt64
    public let renderedVideoFrames: UInt64
    public let renderedTestFrames: UInt64
    public let pushedAudioFrames: UInt64
    public let overlayFrames: UInt64
    public let danmakuFrames: UInt64
    public let danmakuItems: UInt64
    public let importFailures: UInt64
    public let renderFailures: UInt64
    public let audioFailures: UInt64
    public let softwareVideoFrames: UInt64
    public let hardwareVideoFrames: UInt64
    public let zeroCopyVideoFrames: UInt64
    public let cpuVideoFrameFallbacks: UInt64
    public let lastRenderMicros: UInt64
    public let lastRenderCurrentMicros: UInt64
    public let audioClockReadFrames: UInt64
    public let audioClockQueuedFrames: UInt64
    public let audioClockUnderflowFrames: UInt64
    public let audioRecoveryState: Int32
    public let audioLastErrorCode: Int32
    public let audioRecoveryAttempts: UInt64
    public let audioRecoveryCount: UInt64
    public let audioRecoveryFailures: UInt64
    public let directZeroCopyVideoFrames: UInt64
    public let sharedHandleVideoFrames: UInt64
    public let hdrSourceFrames: UInt64
    public let hdr10OutputFrames: UInt64
    public let sdrTonemapFrames: UInt64
    public let hdr10MetadataUpdates: UInt64
    public let hdr10MetadataFailures: UInt64
    public let hdr10OutputFailures: UInt64
    public let hdr10OutputActive: Bool
    public let videoFrameBackpressureDrops: UInt64

    init(native: CErika.ErikaPresenterStats) {
        decodedVideoFrames = UInt64(native.decoded_video_frames)
        renderedVideoFrames = UInt64(native.rendered_video_frames)
        renderedTestFrames = UInt64(native.rendered_test_frames)
        pushedAudioFrames = UInt64(native.pushed_audio_frames)
        overlayFrames = UInt64(native.overlay_frames)
        danmakuFrames = UInt64(native.danmaku_frames)
        danmakuItems = UInt64(native.danmaku_items)
        importFailures = UInt64(native.import_failures)
        renderFailures = UInt64(native.render_failures)
        audioFailures = UInt64(native.audio_failures)
        softwareVideoFrames = UInt64(native.software_video_frames)
        hardwareVideoFrames = UInt64(native.hardware_video_frames)
        zeroCopyVideoFrames = UInt64(native.zero_copy_video_frames)
        cpuVideoFrameFallbacks = UInt64(native.cpu_video_frame_fallbacks)
        lastRenderMicros = UInt64(native.last_render_micros)
        lastRenderCurrentMicros = UInt64(native.last_render_current_micros)
        audioClockReadFrames = UInt64(native.audio_clock_read_frames)
        audioClockQueuedFrames = UInt64(native.audio_clock_queued_frames)
        audioClockUnderflowFrames = UInt64(native.audio_clock_underflow_frames)
        audioRecoveryState = Int32(native.audio_recovery_state)
        audioLastErrorCode = Int32(native.audio_last_error_code)
        audioRecoveryAttempts = UInt64(native.audio_recovery_attempts)
        audioRecoveryCount = UInt64(native.audio_recovery_count)
        audioRecoveryFailures = UInt64(native.audio_recovery_failures)
        directZeroCopyVideoFrames = UInt64(native.direct_zero_copy_video_frames)
        sharedHandleVideoFrames = UInt64(native.shared_handle_video_frames)
        hdrSourceFrames = UInt64(native.hdr_source_frames)
        hdr10OutputFrames = UInt64(native.hdr10_output_frames)
        sdrTonemapFrames = UInt64(native.sdr_tonemap_frames)
        hdr10MetadataUpdates = UInt64(native.hdr10_metadata_updates)
        hdr10MetadataFailures = UInt64(native.hdr10_metadata_failures)
        hdr10OutputFailures = UInt64(native.hdr10_output_failures)
        hdr10OutputActive = Bool(native.hdr10_output_active)
        videoFrameBackpressureDrops = UInt64(native.video_frame_backpressure_drops)
    }
}

public struct ErikaOutputStatus: Codable, Sendable, Equatable {
    public let requestedMode: Int32
    public let activeEncoding: Int32
    public let surfaceFormat: Int32
    public let nativeDataSpace: Int32
    public let requestedHeadroom: Float
    public let activeHeadroom: Float
    public let activeHeadroomKnown: Bool
    public let extendedLinearActive: Bool
    public let fallbackReason: Int32
    public let fallbackCount: UInt64
    public let dataSpaceFailures: UInt64
    public let headroomUpdates: UInt64
    public let extendedLinearFrames: UInt64

    init(native: CErika.ErikaOutputStatus) {
        requestedMode = Int32(native.requested_mode)
        activeEncoding = Int32(native.active_encoding)
        surfaceFormat = Int32(native.surface_format)
        nativeDataSpace = Int32(native.native_data_space)
        requestedHeadroom = Float(native.requested_headroom)
        activeHeadroom = Float(native.active_headroom)
        activeHeadroomKnown = Bool(native.active_headroom_known)
        extendedLinearActive = Bool(native.extended_linear_active)
        fallbackReason = Int32(native.fallback_reason)
        fallbackCount = UInt64(native.fallback_count)
        dataSpaceFailures = UInt64(native.data_space_failures)
        headroomUpdates = UInt64(native.headroom_updates)
        extendedLinearFrames = UInt64(native.extended_linear_frames)
    }
}

public struct ErikaResourceStatus: Codable, Sendable, Equatable {
    public let deviceCurrentAllocatedBytes: UInt64
    public let deviceRecommendedWorkingSetBytes: UInt64
    public let drawableEstimatedBytes: UInt64
    public let videoFrameBytes: UInt64
    public let overlayAtlasBytes: UInt64
    public let danmakuAtlasBytes: UInt64
    public let danmakuVertexBufferBytes: UInt64
    public let upscalerBytes: UInt64
    public let rendererTrackedBytes: UInt64
    public let presenterCpuDanmakuAtlasBytes: UInt64
    public let drawableCount: UInt64
    public let outputModeSwitches: UInt64

    init(native: CErika.ErikaPresenterResourceStatus) {
        deviceCurrentAllocatedBytes = UInt64(native.device_current_allocated_bytes)
        deviceRecommendedWorkingSetBytes = UInt64(native.device_recommended_working_set_bytes)
        drawableEstimatedBytes = UInt64(native.drawable_estimated_bytes)
        videoFrameBytes = UInt64(native.video_frame_bytes)
        overlayAtlasBytes = UInt64(native.overlay_atlas_bytes)
        danmakuAtlasBytes = UInt64(native.danmaku_atlas_bytes)
        danmakuVertexBufferBytes = UInt64(native.danmaku_vertex_buffer_bytes)
        upscalerBytes = UInt64(native.upscaler_bytes)
        rendererTrackedBytes = UInt64(native.renderer_tracked_bytes)
        presenterCpuDanmakuAtlasBytes = UInt64(native.presenter_cpu_danmaku_atlas_bytes)
        drawableCount = UInt64(native.drawable_count)
        outputModeSwitches = UInt64(native.output_mode_switches)
    }
}

public struct ErikaFrame: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let rgba: Data
}

public enum ErikaVideoAlphaMode: Int32, Codable, Sendable, CaseIterable {
    case opaque = 0
    case packedAlphaRight = 1
}

public struct ErikaOpenOptions: Sendable, Equatable {
    public var httpHeaders: [String: String]
    public var httpReadAheadBytes: UInt64
    public var httpBackBufferBytes: UInt64

    public init(
        httpHeaders: [String: String] = [:],
        httpReadAheadBytes: UInt64 = 0,
        httpBackBufferBytes: UInt64 = 0
    ) {
        self.httpHeaders = httpHeaders
        self.httpReadAheadBytes = httpReadAheadBytes
        self.httpBackBufferBytes = httpBackBufferBytes
    }
}

public struct ErikaTrackSelection: Codable, Sendable, Equatable {
    /// A negative native track id is represented as nil.
    public let video: Int64?
    public let audio: Int64?
    public let subtitle: Int64?

    public init(video: Int64? = nil, audio: Int64? = nil, subtitle: Int64? = nil) {
        self.video = video
        self.audio = audio
        self.subtitle = subtitle
    }
}

public struct ErikaVideoDecoderInfo: Codable, Sendable, Equatable {
    public let stage: String
    public let requestedBackend: String
    public let previousBackend: String?
    public let activeBackend: String
    public let fallbackCount: UInt64
    public let codec: String?
    public let pixelFormat: String?
    public let lineSizes: [Int]?
    public let reason: String?
}

public struct ErikaAudioOutputInfo: Codable, Sendable, Equatable {
    public let recoveryState: String
    public let lastErrorCode: Int32
    public let recoveryAttempts: UInt64
    public let recoveryCount: UInt64
    public let recoveryFailures: UInt64
    public let transitionSequence: UInt64
}

public struct ErikaUpscalerStatus: Codable, Sendable, Equatable {
    public let requestedMode: Int32
    public let activeBackend: Int32
    public let fallbackCount: UInt64
    public let upscaledFrames: UInt64
    public let lastEncodeMicros: UInt64
    public let lastGpuMicros: UInt64

    init(native: CErika.ErikaUpscalerStatus) {
        requestedMode = native.requested_mode
        activeBackend = native.active_backend
        fallbackCount = native.fallback_count
        upscaledFrames = native.upscaled_frames
        lastEncodeMicros = native.last_encode_micros
        lastGpuMicros = native.last_gpu_micros
    }
}

public struct ErikaSubtitleMemoryFontStatus: Sendable, Equatable {
    public let registeredCount: UInt
    public let registeredBytes: UInt
    public let selectedIDs: [UInt64]
    public let generation: UInt64
    public var selectedCount: Int { selectedIDs.count }

    public init(registeredCount: UInt, registeredBytes: UInt, selectedIDs: [UInt64], generation: UInt64) {
        self.registeredCount = registeredCount
        self.registeredBytes = registeredBytes
        self.selectedIDs = selectedIDs
        self.generation = generation
    }
}

public struct ErikaSubtitleMemoryFontFace: Sendable, Equatable {
    public let index: UInt32
    public let families: [String]
    public let postScriptName: String?
    public let weight: UInt16
    public let italic: Bool
    public let monospaced: Bool

    public init(index: UInt32, families: [String], postScriptName: String?, weight: UInt16, italic: Bool, monospaced: Bool) {
        self.index = index
        self.families = families
        self.postScriptName = postScriptName
        self.weight = weight
        self.italic = italic
        self.monospaced = monospaced
    }
}

public struct ErikaSubtitleMemoryFontInfo: Sendable, Equatable, Identifiable {
    public let id: UInt64
    public let byteLength: UInt
    public let faces: [ErikaSubtitleMemoryFontFace]

    public init(id: UInt64, byteLength: UInt, faces: [ErikaSubtitleMemoryFontFace]) {
        self.id = id
        self.byteLength = byteLength
        self.faces = faces
    }
}
