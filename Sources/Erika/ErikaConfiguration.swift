import CErika
import Foundation

/// Fields correspond to ErikaDanmakuConfig. Zero quantity/line limits mean unlimited.
public struct ErikaDanmakuConfiguration: Sendable, Equatable {
    public var enabled: Bool = true
    public var fontSize: Float = 25
    public var opacity: Float = 1
    public var displayArea: Float = 1
    public var scrollDurationSeconds: Float = 10
    public var scrollSpeedFactor: Float = 1
    public var trackGapRatio: Float = 0.15
    public var outlineWidth: Float = 1
    public var shadowOffsetX: Float = 1
    public var shadowOffsetY: Float = 1
    public var mergeDuplicates: Bool = false
    public var allowStacking: Bool = false
    public var allowScrollOverwrite: Bool = false
    public var maxQuantity: UInt32 = 0
    public var maxLinesPerMode: UInt32 = 0
    public var blockTop: Bool = false
    public var blockBottom: Bool = false
    public var blockScroll: Bool = false
    public var shadowStyle: Int32 = 3

    public init() {}

    init(native: CErika.ErikaDanmakuConfig) {
        enabled = native.enabled
        fontSize = native.font_size
        opacity = native.opacity
        displayArea = native.display_area
        scrollDurationSeconds = native.scroll_duration_seconds
        scrollSpeedFactor = native.scroll_speed_factor
        trackGapRatio = native.track_gap_ratio
        outlineWidth = native.outline_width
        shadowOffsetX = native.shadow_offset_x
        shadowOffsetY = native.shadow_offset_y
        mergeDuplicates = native.merge_duplicates
        allowStacking = native.allow_stacking
        allowScrollOverwrite = native.allow_scroll_overwrite
        maxQuantity = native.max_quantity
        maxLinesPerMode = native.max_lines_per_mode
        blockTop = native.block_top
        blockBottom = native.block_bottom
        blockScroll = native.block_scroll
        shadowStyle = native.shadow_style
    }

    var native: CErika.ErikaDanmakuConfig {
        CErika.ErikaDanmakuConfig(
            enabled: enabled,
            font_size: fontSize,
            opacity: opacity,
            display_area: displayArea,
            scroll_duration_seconds: scrollDurationSeconds,
            scroll_speed_factor: scrollSpeedFactor,
            track_gap_ratio: trackGapRatio,
            outline_width: outlineWidth,
            shadow_offset_x: shadowOffsetX,
            shadow_offset_y: shadowOffsetY,
            merge_duplicates: mergeDuplicates,
            allow_stacking: allowStacking,
            allow_scroll_overwrite: allowScrollOverwrite,
            max_quantity: maxQuantity,
            max_lines_per_mode: maxLinesPerMode,
            block_top: blockTop,
            block_bottom: blockBottom,
            block_scroll: blockScroll,
            shadow_style: shadowStyle
        )
    }
}

/// ASS selective override bits, with the same values as the C ABI.
public struct ErikaSubtitleOverride: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let fontSize = Self(rawValue: 1 << 2)
    public static let fontName = Self(rawValue: 1 << 3)
    public static let colors = Self(rawValue: 1 << 4)
    public static let attributes = Self(rawValue: 1 << 5)
    public static let border = Self(rawValue: 1 << 6)
    public static let alignment = Self(rawValue: 1 << 7)
    public static let margins = Self(rawValue: 1 << 8)
    public static let blur = Self(rawValue: 1 << 11)
    public static let all: Self = [.fontSize, .fontName, .colors, .attributes, .border, .alignment, .margins, .blur]
}

/// Fallback subtitle style; overrides explicitly opt into replacing embedded ASS fields.
public struct ErikaSubtitleStyle: Sendable, Equatable {
    public var fontFamily: String?
    public var fontFilePath: String?
    public var primaryColorRgba: UInt32 = 0xFFFFFFFF
    public var outlineColorRgba: UInt32 = 0x0000007F
    public var fontSize: Double = 48
    public var outlineWidth: Double = 2
    public var bold: Bool = false
    public var italic: Bool = false
    public var underline: Bool = false
    public var strikeOut: Bool = false
    public var spacing: Double = 0
    public var scaleXPercent: Double = 100
    public var scaleYPercent: Double = 100
    public var borderStyle: Int32 = 1
    public var shadowDepth: Double = 0
    public var blur: Double = 0
    public var alignment: Int32 = 2
    public var marginLeft: Int32 = 48
    public var marginRight: Int32 = 48
    public var marginVertical: Int32 = 54
    public var overrides: ErikaSubtitleOverride = []

    public init() {}

    func withNative<T>(_ body: (CErika.ErikaSubtitleStyle) throws -> T) throws -> T {
        try withOptionalCString(fontFamily) { family in
            try withOptionalCString(fontFilePath) { path in
                try body(CErika.ErikaSubtitleStyle(
                    font_family: family,
                    font_file_path: path,
                    primary_color_rgba: primaryColorRgba,
                    outline_color_rgba: outlineColorRgba,
                    font_size: fontSize,
                    outline_width: outlineWidth,
                    bold: bold,
                    italic: italic,
                    underline: underline,
                    strike_out: strikeOut,
                    spacing: spacing,
                    scale_x_percent: scaleXPercent,
                    scale_y_percent: scaleYPercent,
                    border_style: borderStyle,
                    shadow_depth: shadowDepth,
                    blur: blur,
                    alignment: alignment,
                    margin_left: marginLeft,
                    margin_right: marginRight,
                    margin_vertical: marginVertical,
                    override_mask: overrides.rawValue
                ))
            }
        }
    }
}
