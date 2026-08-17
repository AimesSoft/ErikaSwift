# Erika for Swift

Native Swift SDK for the [Erika](https://github.com/AimesSoft/Erika) media
engine. It provides a Swift API and Metal-backed views for macOS, iOS, and
tvOS. The prebuilt native runtime is downloaded automatically by Swift Package
Manager; applications do not need Rust, FFmpeg, CocoaPods, or Flutter.

## Requirements

- macOS 11 or later
- iOS 13 or later
- tvOS 13 or later
- Xcode 15 or later

## Installation

In Xcode, choose **File > Add Package Dependencies** and enter:

```text
https://github.com/AimesSoft/ErikaSwift
```

Select version `0.1.7` or later and add the `Erika` product to your target.

## UIKit / AppKit

```swift
import Erika

let player = try ErikaPlayer()
let videoView = ErikaVideoView(frame: container.bounds)
videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
videoView.player = player
container.addSubview(videoView)

try player.open("https://example.com/video.mp4")
try player.play()
```

`ErikaVideoView` owns a `CAMetalLayer`, keeps its drawable size synchronized
with the native view, and drives the presenter's render loop.

## SwiftUI

```swift
import Erika
import SwiftUI

struct PlayerScreen: View {
    let player: ErikaPlayer

    var body: some View {
        ErikaPlayerView(player: player)
            .task {
                try? player.open("https://example.com/video.mp4")
                try? player.play()
            }
    }
}
```

Create and use `ErikaPlayer` on the main actor. Poll `pollEvent()` for playback,
position, buffering, track, decoder, and output changes.

## Available APIs

- open local files and HTTP(S) streams with custom headers
- play, pause, stop, seek, playback rate, and volume
- audio and subtitle track discovery and selection
- external subtitles and subtitle scaling
- Bilibili XML / JSON danmaku tracks
- SDR, Apple EDR, extended-linear, and automatic output modes
- ArtCNN luma upscaling modes
- playback, output, and resource statistics
- composited RGBA frame capture
- UIKit, AppKit, and SwiftUI video views

The lower-level `invoke(_:arguments:)` API exposes new Erika presenter commands
without requiring an immediate Swift wrapper update.

## License

The Swift wrapper is available under MPL-2.0. The binary target includes Erika
and statically linked native dependencies; see `THIRD_PARTY_NOTICES.md` and the
Erika release notices for their licenses.
