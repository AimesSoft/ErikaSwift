# Erika Swift SDK

Erika 的 macOS、iOS 和 tvOS 原生 Swift SDK。Swift Package Manager 会自动下载
预编译运行时，接入应用不需要安装 Rust、FFmpeg、CocoaPods 或 Flutter。

## 要求

- macOS 11+
- iOS 13+
- tvOS 13+
- Xcode 15+

## 安装

在 Xcode 中选择 **File > Add Package Dependencies**，输入：

```text
https://github.com/AimesSoft/ErikaSwift
```

选择 `0.1.7` 或更高版本，并把 `Erika` product 加入应用 target。

## 使用

```swift
import Erika

let player = try ErikaPlayer()
let videoView = ErikaVideoView(frame: container.bounds)
videoView.player = player
container.addSubview(videoView)

try player.open("https://example.com/video.mp4")
try player.play()
```

SwiftUI 使用 `ErikaPlayerView(player:)`。`ErikaVideoView` 会管理
`CAMetalLayer`、drawable size 和逐帧渲染。

SDK 已覆盖播放控制、HTTP headers、音视频与字幕轨道、外挂字幕、弹幕、
HDR/EDR 输出、ArtCNN 放大、资源统计和 RGBA 截图。`ErikaPlayer` 需要在主线程创建和调用。

## 许可证

Swift 封装使用 MPL-2.0。预编译二进制包含 Erika 及静态链接的原生依赖，详情见
`THIRD_PARTY_NOTICES.md` 和 Erika `v0.1.7` Release 内的许可证文件。
