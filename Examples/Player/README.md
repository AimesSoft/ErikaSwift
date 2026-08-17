# Minimal Player

Add the `Erika` package product to an iOS, tvOS, or macOS application target.
Keep the player alive for the lifetime of the screen and attach it to an
`ErikaVideoView` or `ErikaPlayerView`.

```swift
@MainActor
final class PlayerController {
    let player = try! ErikaPlayer(
        configuration: .init(outputMode: .automatic)
    )

    func start() throws {
        try player.open(
            "https://example.com/video.m3u8",
            httpHeaders: ["User-Agent": "ErikaSwift/0.1.7"]
        )
        try player.play()
    }
}
```
