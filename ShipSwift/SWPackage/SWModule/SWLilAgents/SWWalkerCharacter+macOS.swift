// SWWalkerCharacter+macOS.swift
// Core character class: video playback, walking physics, popover management, thinking/completion bubbles, sounds.

import AppKit
import AVFoundation

final class SWWalkerCharacter {
    let name: String
    private let videoName: String
    private let accelStart: Double
    private let accelStop: Double
    private let walkAmountRange: ClosedRange<Double>
    private let pauseDurationRange: ClosedRange<Double>
    private let yOffset: CGFloat
    let characterColor: NSColor

    var theme: SWPopoverTheme = .peach {
        didSet { popoverController?.updateTheme(theme) }
    }
    var soundEnabled: Bool = true

    var isVisible: Bool = true {
        didSet {
            window?.isVisible = isVisible
            bubbleWindow?.isVisible = false
            if !isVisible { popoverController?.close() }
        }
    }

    private(set) var currentX: CGFloat = 0
    private var window: NSWindow?
    private var playerView: AVPlayerView?
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    private var popoverController: SWPopoverController?
    private var bubbleWindow: NSWindow?
    private var bubbleLabel: NSTextField?

    // Walk state
    private enum WalkState { case idle, walking }
    private var walkState: WalkState = .idle
    private var walkStartTime: CFTimeInterval = 0
    private var walkDuration: Double = 10.0
    private var walkStartX: CGFloat = 0
    private var walkDistance: CGFloat = 0
    private var walkDirection: CGFloat = 1
    private var pauseEndTime: CFTimeInterval = 0
    private var dockRect: NSRect = .zero

    // Bubbles
    private var thinkingTimer: Timer?
    private var session: SWClaudeSession?

    private static let thinkingPhrases = [
        "hmm...", "thinking...", "one sec...", "ok hold on", "let me check",
        "working on it", "almost...", "bear with me", "on it!", "gimme a sec",
        "brb", "processing...", "hang tight", "just a moment", "figuring it out",
        "crunching...", "reading...", "looking..."
    ]

    private static let completionPhrases = [
        "done!", "all set!", "ready!", "here you go", "got it!", "finished!", "ta-da!", "voila!"
    ]

    private static let soundNames = [
        "ping-aa", "ping-bb", "ping-cc", "ping-dd",
        "ping-ee", "ping-ff", "ping-gg", "ping-hh", "ping-jj"
    ]

    // MARK: - Init

    init(
        name: String,
        videoName: String,
        accelStart: Double,
        accelStop: Double,
        walkAmountRange: ClosedRange<Double>,
        pauseDurationRange: ClosedRange<Double>,
        yOffset: CGFloat,
        characterColor: NSColor
    ) {
        self.name = name
        self.videoName = videoName
        self.accelStart = accelStart
        self.accelStop = accelStop
        self.walkAmountRange = walkAmountRange
        self.pauseDurationRange = pauseDurationRange
        self.yOffset = yOffset
        self.characterColor = characterColor

        setupWindow()
        setupVideo()
        scheduleNextPause()
    }

    // MARK: - Window Setup

    private func setupWindow() {
        let size = NSSize(width: 80, height: 80)
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.hasShadow = false
        window?.ignoresMouseEvents = false
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let contentView = SWCharacterContentView(frame: NSRect(origin: .zero, size: size))
        contentView.onClicked = { [weak self] in self?.handleClick() }
        window?.contentView = contentView
        window?.orderFront(nil)
    }

    private func setupVideo() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov") else { return }

        let item = AVPlayerItem(url: url)
        player = AVQueuePlayer(playerItem: item)
        player?.isMuted = true
        playerLooper = AVPlayerLooper(player: player!, templateItem: item)

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.frame = window?.contentView?.bounds ?? .zero
        layer.backgroundColor = NSColor.clear.cgColor

        window?.contentView?.wantsLayer = true
        window?.contentView?.layer?.addSublayer(layer)

        player?.play()
    }

    // MARK: - Update (called every frame)

    func update(dockRect: NSRect, otherPositions: [CGFloat]) {
        self.dockRect = dockRect
        guard isVisible else { return }

        let now = CACurrentMediaTime()

        switch walkState {
        case .idle:
            if now >= pauseEndTime {
                startWalk(otherPositions: otherPositions)
            }

        case .walking:
            let elapsed = now - walkStartTime
            let progress = min(elapsed / walkDuration, 1.0)
            let normalizedPos = movementPosition(at: progress)

            currentX = walkStartX + walkDistance * walkDirection * CGFloat(normalizedPos)

            // Clamp to dock bounds
            let margin: CGFloat = 20
            currentX = max(dockRect.minX + margin, min(currentX, dockRect.maxX - margin - 80))

            if progress >= 1.0 {
                walkState = .idle
                scheduleNextPause()
                player?.rate = 0
            }
        }

        let windowY = dockRect.maxY + yOffset
        window?.setFrameOrigin(NSPoint(x: currentX, y: windowY))

        updateBubblePosition()
    }

    // MARK: - Walking Physics (trapezoidal velocity profile)

    private func movementPosition(at t: Double) -> Double {
        if t <= accelStart {
            // Ease in (quadratic)
            let normalized = t / accelStart
            return 0.5 * accelStart * normalized * normalized
        } else if t <= accelStop {
            // Constant speed
            let accelDistance = 0.5 * accelStart
            return accelDistance + (t - accelStart)
        } else {
            // Ease out (quadratic)
            let accelDistance = 0.5 * accelStart
            let linearDistance = accelStop - accelStart
            let decelDuration = 1.0 - accelStop
            let normalized = (t - accelStop) / decelDuration
            let decelDistance = decelDuration * (normalized - 0.5 * normalized * normalized)
            return accelDistance + linearDistance + decelDistance
        }
    }

    private func startWalk(otherPositions: [CGFloat]) {
        walkState = .walking
        walkStartTime = CACurrentMediaTime()
        walkStartX = currentX

        let amount = Double.random(in: walkAmountRange)
        walkDistance = CGFloat(amount)

        // Choose direction: bias away from edges, avoid other characters
        let leftSpace = currentX - dockRect.minX
        let rightSpace = dockRect.maxX - currentX
        let bias = rightSpace > leftSpace ? 0.6 : 0.4
        walkDirection = Double.random(in: 0...1) < bias ? 1 : -1

        // Avoid other characters
        let minSeparation = dockRect.width * 0.12
        for other in otherPositions {
            let projected = currentX + walkDistance * walkDirection
            if abs(projected - other) < minSeparation {
                walkDirection *= -1
                break
            }
        }

        // Flip video for direction
        if let layer = window?.contentView?.layer?.sublayers?.first {
            if walkDirection < 0 {
                layer.transform = CATransform3DMakeScale(-1, 1, 1)
            } else {
                layer.transform = CATransform3DIdentity
            }
        }

        player?.rate = 1
    }

    private func scheduleNextPause() {
        let duration = Double.random(in: pauseDurationRange)
        pauseEndTime = CACurrentMediaTime() + duration
    }

    // MARK: - Click / Popover

    private func handleClick() {
        if popoverController != nil {
            popoverController?.toggle()
        } else {
            let session = SWClaudeSession()
            self.session = session

            session.onBusyChanged = { [weak self] isBusy in
                DispatchQueue.main.async {
                    if isBusy {
                        self?.startThinkingBubble()
                    } else {
                        self?.showCompletionBubble()
                    }
                }
            }

            popoverController = SWPopoverController(
                theme: theme,
                characterColor: characterColor,
                session: session,
                anchorProvider: { [weak self] in
                    guard let self = self, let window = self.window else { return .zero }
                    return NSRect(
                        x: window.frame.midX - 175,
                        y: window.frame.maxY + 8,
                        width: 350,
                        height: 450
                    )
                }
            )
            popoverController?.show()
        }
    }

    // MARK: - Thinking Bubbles

    private func startThinkingBubble() {
        guard popoverController?.isShown != true else { return }

        showBubble(text: Self.thinkingPhrases.randomElement()!)

        thinkingTimer?.invalidate()
        thinkingTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...5), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.showBubble(text: Self.thinkingPhrases.randomElement()!)
        }
    }

    private func showCompletionBubble() {
        thinkingTimer?.invalidate()
        thinkingTimer = nil

        guard popoverController?.isShown != true else { return }

        let phrase = Self.completionPhrases.randomElement()!
        showBubble(text: phrase)

        if soundEnabled {
            playCompletionSound()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.hideBubble()
        }
    }

    func showOnboardingBubble() {
        showBubble(text: "hi!")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.hideBubble()
        }
    }

    private func showBubble(text: String) {
        if bubbleWindow == nil {
            createBubbleWindow()
        }

        bubbleLabel?.stringValue = text
        bubbleLabel?.sizeToFit()

        let padding: CGFloat = 24
        let width = max((bubbleLabel?.frame.width ?? 40) + padding, 60)
        let height: CGFloat = 32

        bubbleWindow?.setContentSize(NSSize(width: width, height: height))
        updateBubblePosition()

        bubbleWindow?.alphaValue = 0
        bubbleWindow?.isVisible = true

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            bubbleWindow?.animator().alphaValue = 1.0
        }
    }

    private func hideBubble() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            bubbleWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.bubbleWindow?.isVisible = false
        })
    }

    private func createBubbleWindow() {
        bubbleWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 80, height: 32),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        bubbleWindow?.isOpaque = false
        bubbleWindow?.backgroundColor = .clear
        bubbleWindow?.level = .floating
        bubbleWindow?.hasShadow = true
        bubbleWindow?.ignoresMouseEvents = true

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 80, height: 32))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.cgColor
        container.layer?.cornerRadius = 12
        container.layer?.borderColor = NSColor(white: 0.85, alpha: 1).cgColor
        container.layer?.borderWidth = 1

        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        bubbleWindow?.contentView = container
        bubbleLabel = label
    }

    private func updateBubblePosition() {
        guard let window = window, let bubble = bubbleWindow, bubble.isVisible else { return }
        let x = window.frame.midX - bubble.frame.width / 2
        let y = window.frame.maxY + 4
        bubble.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Sound

    private func playCompletionSound() {
        guard let soundName = Self.soundNames.randomElement() else { return }
        let ext = soundName == "ping-jj" ? "m4a" : "mp3"
        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else { return }
        NSSound(contentsOf: url, byReference: true)?.play()
    }

    // MARK: - Teardown

    func tearDown() {
        thinkingTimer?.invalidate()
        player?.pause()
        popoverController?.close()
        session?.terminate()
        window?.close()
        bubbleWindow?.close()
    }
}

// MARK: - Popover Controller

final class SWPopoverController {
    private var window: NSWindow?
    private var terminalView: SWTerminalView?
    private var theme: SWPopoverTheme
    private let characterColor: NSColor
    private let session: SWClaudeSession
    private let anchorProvider: () -> NSRect

    var isShown: Bool { window?.isVisible ?? false }

    init(
        theme: SWPopoverTheme,
        characterColor: NSColor,
        session: SWClaudeSession,
        anchorProvider: @escaping () -> NSRect
    ) {
        self.theme = theme
        self.characterColor = characterColor
        self.session = session
        self.anchorProvider = anchorProvider
    }

    func show() {
        if window == nil {
            createWindow()
        }

        let rect = anchorProvider()
        window?.setFrame(rect, display: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.orderOut(nil)
    }

    func toggle() {
        if isShown {
            close()
        } else {
            show()
        }
    }

    func updateTheme(_ newTheme: SWPopoverTheme) {
        self.theme = newTheme
        applyTheme()
    }

    private func createWindow() {
        let rect = anchorProvider()

        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.isMovableByWindowBackground = true
        window?.level = .floating
        window?.isOpaque = false

        let terminal = SWTerminalView(frame: rect, theme: theme, characterColor: characterColor)
        terminal.onSubmit = { [weak self] text in
            self?.session.send(message: text)
        }

        session.onOutput = { [weak terminal] text in
            DispatchQueue.main.async {
                terminal?.appendOutput(text)
            }
        }

        session.onToolUse = { [weak terminal] toolName, content in
            DispatchQueue.main.async {
                terminal?.appendToolUse(name: toolName, content: content)
            }
        }

        window?.contentView = terminal
        terminalView = terminal

        applyTheme()
        session.start()
    }

    private func applyTheme() {
        window?.backgroundColor = theme.backgroundColor
        if let layer = window?.contentView?.layer {
            layer.cornerRadius = theme.cornerRadius
        }
        terminalView?.applyTheme(theme)
    }
}
