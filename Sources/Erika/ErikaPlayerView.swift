#if canImport(SwiftUI)
import SwiftUI

#if os(iOS) || os(tvOS)
public struct ErikaPlayerView: UIViewRepresentable {
    public let player: ErikaPlayer

    public init(player: ErikaPlayer) {
        self.player = player
    }

    public func makeUIView(context: Context) -> ErikaVideoView {
        let view = ErikaVideoView()
        view.player = player
        return view
    }

    public func updateUIView(_ view: ErikaVideoView, context: Context) {
        view.player = player
    }
}
#elseif os(macOS)
public struct ErikaPlayerView: NSViewRepresentable {
    public let player: ErikaPlayer

    public init(player: ErikaPlayer) {
        self.player = player
    }

    public func makeNSView(context: Context) -> ErikaVideoView {
        let view = ErikaVideoView()
        view.player = player
        return view
    }

    public func updateNSView(_ view: ErikaVideoView, context: Context) {
        view.player = player
    }
}
#endif
#endif
