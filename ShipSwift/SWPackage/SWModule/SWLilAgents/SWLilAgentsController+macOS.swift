// SWLilAgentsController+macOS.swift
// Main controller: CVDisplayLink tick loop, dock geometry calculation, character orchestration.

import AppKit
import CoreVideo

final class SWLilAgentsController {
    private var displayLink: CVDisplayLink?
    private var characters: [SWWalkerCharacter] = []
    private var pinnedDisplayIndex: Int = -1
    private var isFirstRun = true

    var soundEnabled: Bool = true {
        didSet { characters.forEach { $0.soundEnabled = soundEnabled } }
    }

    var currentThemeName: String {
        characters.first?.theme.name ?? SWPopoverTheme.peach.name
    }

    // MARK: - Lifecycle

    func start() {
        let bruce = SWWalkerCharacter(
            name: "bruce",
            videoName: "walk-bruce-01",
            accelStart: 0.12,
            accelStop: 0.88,
            walkAmountRange: 200...325,
            pauseDurationRange: 5.0...12.0,
            yOffset: 4,
            characterColor: NSColor(red: 0.44, green: 0.72, blue: 0.53, alpha: 1.0)
        )

        let jazz = SWWalkerCharacter(
            name: "jazz",
            videoName: "walk-jazz-01",
            accelStart: 0.15,
            accelStop: 0.85,
            walkAmountRange: 200...300,
            pauseDurationRange: 6.0...14.0,
            yOffset: 0,
            characterColor: NSColor(red: 0.93, green: 0.60, blue: 0.33, alpha: 1.0)
        )

        characters = [bruce, jazz]

        createDisplayLink()

        if isFirstRun {
            isFirstRun = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.characters.first?.showOnboardingBubble()
            }
        }
    }

    func stop() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
        displayLink = nil
        characters.forEach { $0.tearDown() }
    }

    // MARK: - Display Link

    private func createDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)

        guard let link = displayLink else { return }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo = userInfo else { return kCVReturnSuccess }
            let controller = Unmanaged<SWLilAgentsController>.fromOpaque(userInfo).takeUnretainedValue()
            DispatchQueue.main.async {
                controller.tick()
            }
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(link, callback, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(link)
    }

    private func tick() {
        let dockRect = computeDockRect()
        guard dockRect.width > 0 else { return }

        let positions = characters.map { $0.currentX }
        for (index, character) in characters.enumerated() {
            let otherPositions = positions.enumerated().compactMap { $0.offset != index ? $0.element : nil }
            character.update(dockRect: dockRect, otherPositions: otherPositions)
        }
    }

    // MARK: - Dock Geometry

    private func computeDockRect() -> NSRect {
        let screen = targetScreen()
        let visibleFrame = screen.visibleFrame
        let screenFrame = screen.frame

        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")
        let tileSize = dockDefaults?.double(forKey: "tilesize") ?? 48.0
        let showRecents = dockDefaults?.bool(forKey: "show-recents") ?? true

        let persistentApps = (dockDefaults?.array(forKey: "persistent-apps") as? [[String: Any]])?.count ?? 0
        let persistentOthers = (dockDefaults?.array(forKey: "persistent-others") as? [[String: Any]])?.count ?? 0

        let iconCount = persistentApps + persistentOthers
        let dividerCount = 1 + (showRecents ? 1 : 0)
        let dividerWidth = 12.0

        let dockWidth = Double(iconCount) * (tileSize + 4) + Double(dividerCount) * dividerWidth
        let dockHeight = tileSize + 16

        let dockY = screenFrame.minY
        let dockX = screenFrame.midX - dockWidth / 2

        return NSRect(x: dockX, y: dockY, width: dockWidth, height: dockHeight)
    }

    private func targetScreen() -> NSScreen {
        if pinnedDisplayIndex >= 0, pinnedDisplayIndex < NSScreen.screens.count {
            return NSScreen.screens[pinnedDisplayIndex]
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }

    // MARK: - Public Controls

    func setCharacterVisible(name: String, visible: Bool) {
        characters.first(where: { $0.name == name })?.isVisible = visible
    }

    func setTheme(named name: String) {
        guard let theme = SWPopoverTheme.allThemes.first(where: { $0.name == name }) else { return }
        characters.forEach { $0.theme = theme }
    }

    func setPinnedDisplay(index: Int) {
        pinnedDisplayIndex = index
    }
}
