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
}

public struct ErikaTrackCounts: Codable, Sendable, Equatable {
    public let video: UInt32
    public let audio: UInt32
    public let subtitle: UInt32
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
}

public struct ErikaDanmakuTrack: Codable, Sendable, Identifiable, Equatable {
    public let id: UInt64
    public let enabled: Bool
    public let offsetMicros: Int64
    public let itemCount: UInt64
    public let name: String?
    public let source: String?
}

public struct ErikaPresenterStats: Codable, Sendable, Equatable {
    public let decodedVideoFrames: UInt64
    public let renderedVideoFrames: UInt64
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
    public let hdrSourceFrames: UInt64
    public let hdr10OutputFrames: UInt64
    public let sdrTonemapFrames: UInt64
    public let videoFrameBackpressureDrops: UInt64
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
}

public struct ErikaFrame: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let rgba: Data
}
