import Foundation
import QuartzCore

#if os(iOS) || os(tvOS)
import UIKit

@MainActor
public final class ErikaVideoView: UIView {
    public override class var layerClass: AnyClass { CAMetalLayer.self }

    public weak var player: ErikaPlayer? {
        didSet {
            if oldValue !== player, isAttached {
                try? oldValue?.detachSurface()
                isAttached = false
            }
            updateDisplayLink()
            setNeedsLayout()
        }
    }

    public var onError: ((Error) -> Void)?
    public var metalLayer: CAMetalLayer { layer as! CAMetalLayer }

    private var displayLink: CADisplayLink?
    private var isAttached = false
    private var lastDrawableSize = CGSize.zero

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    deinit {
        displayLink?.invalidate()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateSurface()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        updateDisplayLink()
        updateSurface()
    }

    private func configure() {
        isOpaque = true
        backgroundColor = .black
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.isOpaque = true
        metalLayer.backgroundColor = UIColor.black.cgColor
    }

    private func updateSurface() {
        guard let player else { return }
        let scale = max(1, window?.screen.scale ?? UIScreen.main.scale)
        let size = CGSize(
            width: max(1, bounds.width * scale),
            height: max(1, bounds.height * scale)
        )
        metalLayer.contentsScale = scale
        metalLayer.drawableSize = size
        guard size != lastDrawableSize || !isAttached else { return }
        lastDrawableSize = size
        do {
            if isAttached {
                try player.resizeSurface(
                    width: UInt32(size.width),
                    height: UInt32(size.height),
                    scale: Double(scale)
                )
            } else {
                try player.attach(
                    to: metalLayer,
                    width: UInt32(size.width),
                    height: UInt32(size.height),
                    scale: Double(scale)
                )
                isAttached = true
            }
        } catch {
            onError?(error)
        }
    }

    private func updateDisplayLink() {
        guard window != nil, player != nil else {
            displayLink?.invalidate()
            displayLink = nil
            return
        }
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(displayFrame(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func displayFrame(_ link: CADisplayLink) {
        do {
            try player?.render(at: link.timestamp)
        } catch {
            onError?(error)
        }
    }
}

#elseif os(macOS)
import AppKit

@MainActor
public final class ErikaVideoView: NSView {
    public weak var player: ErikaPlayer? {
        didSet {
            if oldValue !== player, isAttached {
                try? oldValue?.detachSurface()
                isAttached = false
            }
            updateTimer()
            needsLayout = true
        }
    }

    public var onError: ((Error) -> Void)?
    public let metalLayer = CAMetalLayer()

    private var timer: Timer?
    private var isAttached = false
    private var lastDrawableSize = CGSize.zero

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    deinit {
        timer?.invalidate()
    }

    public override func layout() {
        super.layout()
        metalLayer.frame = bounds
        updateSurface()
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateTimer()
        updateSurface()
    }

    private func configure() {
        wantsLayer = true
        layer = metalLayer
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.isOpaque = true
        metalLayer.backgroundColor = NSColor.black.cgColor
    }

    private func updateSurface() {
        guard let player else { return }
        let scale = max(1, window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1)
        let size = CGSize(
            width: max(1, bounds.width * scale),
            height: max(1, bounds.height * scale)
        )
        metalLayer.contentsScale = scale
        metalLayer.drawableSize = size
        guard size != lastDrawableSize || !isAttached else { return }
        lastDrawableSize = size
        do {
            if isAttached {
                try player.resizeSurface(
                    width: UInt32(size.width),
                    height: UInt32(size.height),
                    scale: Double(scale)
                )
            } else {
                try player.attach(
                    to: metalLayer,
                    width: UInt32(size.width),
                    height: UInt32(size.height),
                    scale: Double(scale)
                )
                isAttached = true
            }
        } catch {
            onError?(error)
        }
    }

    private func updateTimer() {
        guard window != nil, player != nil else {
            timer?.invalidate()
            timer = nil
            return
        }
        guard timer == nil else { return }
        let timer = Timer(
            timeInterval: 1.0 / 60.0,
            target: self,
            selector: #selector(displayFrame),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func displayFrame() {
        do {
            try player?.render(at: ProcessInfo.processInfo.systemUptime)
        } catch {
            onError?(error)
        }
    }
}
#endif
