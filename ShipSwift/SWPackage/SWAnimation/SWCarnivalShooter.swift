//
//  SWCarnivalShooter.swift
//  ShipSwift
//
//  SpriteKit-powered carnival shooting gallery game. Bullseye targets pop up
//  and slide across the booth — tap to shoot and rack up points. Features a
//  crosshair that tracks your finger, spark particle effects on hits, and
//  animated score popups. Targets come in three tiers: small (100 pts),
//  medium (50 pts), and large (25 pts).
//
//  Usage:
//    SWCarnivalShooter()
//
//    SWCarnivalShooter(roundDuration: 45, spawnInterval: 1.0)
//
//  Created by Claude on 4/8/26.
//

import SwiftUI
import SpriteKit

// MARK: - SWCarnivalShooter

struct SWCarnivalShooter: View {
    var roundDuration: Double = 30
    var spawnInterval: Double = 1.2

    @State private var score = 0
    @State private var timeRemaining: Double = 30
    @State private var gameState: SWCarnivalGameState = .ready
    @State private var shotsHit = 0
    @State private var shotsFired = 0

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height * 1.3)

            ZStack {
                SWCarnivalShooterSpriteView(
                    roundDuration: roundDuration,
                    spawnInterval: spawnInterval,
                    score: $score,
                    timeRemaining: $timeRemaining,
                    gameState: $gameState,
                    shotsHit: $shotsHit,
                    shotsFired: $shotsFired
                )

                VStack {
                    hudOverlay
                    Spacer()
                }

                if gameState == .ready {
                    startOverlay
                }

                if gameState == .ended {
                    endOverlay
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            timeRemaining = roundDuration
        }
    }

    private var hudOverlay: some View {
        HStack {
            Label("\(score)", systemImage: "star.fill")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.yellow)

            Spacer()

            Label("\(Int(ceil(timeRemaining)))s", systemImage: "timer")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(timeRemaining <= 5 ? .red : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.7))
    }

    private var startOverlay: some View {
        VStack(spacing: 16) {
            Text("CARNIVAL SHOOTER")
                .font(.title.weight(.black))
                .foregroundStyle(.yellow)
                .shadow(color: .black, radius: 2, x: 1, y: 1)

            Text("Tap targets to shoot!")
                .font(.headline)
                .foregroundStyle(.white)

            Button {
                gameState = .playing
                score = 0
                shotsHit = 0
                shotsFired = 0
                timeRemaining = roundDuration
            } label: {
                Text("START GAME")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.red, in: Capsule())
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var endOverlay: some View {
        VStack(spacing: 12) {
            Text("GAME OVER")
                .font(.title.weight(.black))
                .foregroundStyle(.red)
                .shadow(color: .black, radius: 2, x: 1, y: 1)

            Text("Score: \(score)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.yellow)

            let accuracy = shotsFired > 0
                ? Int(Double(shotsHit) / Double(shotsFired) * 100)
                : 0

            Text("Accuracy: \(accuracy)%")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                gameState = .playing
                score = 0
                shotsHit = 0
                shotsFired = 0
                timeRemaining = roundDuration
            } label: {
                Text("PLAY AGAIN")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.red, in: Capsule())
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Game State

enum SWCarnivalGameState {
    case ready, playing, ended
}

// MARK: - SpriteKit Bridge

private struct SWCarnivalShooterSpriteView: View {
    let roundDuration: Double
    let spawnInterval: Double
    @Binding var score: Int
    @Binding var timeRemaining: Double
    @Binding var gameState: SWCarnivalGameState
    @Binding var shotsHit: Int
    @Binding var shotsFired: Int

    @State private var scene: SWCarnivalShooterScene?

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
            }
        }
        .onAppear {
            let newScene = SWCarnivalShooterScene()
            newScene.roundDuration = roundDuration
            newScene.spawnInterval = spawnInterval
            newScene.scaleMode = .resizeFill
            newScene.onScoreChanged = { score = $0 }
            newScene.onTimeChanged = { timeRemaining = $0 }
            newScene.onGameStateChanged = { gameState = $0 }
            newScene.onStatsChanged = { hits, fired in
                shotsHit = hits
                shotsFired = fired
            }
            scene = newScene
        }
        .onChange(of: gameState) { _, newState in
            if newState == .playing {
                scene?.startGame()
            }
        }
    }
}

// MARK: - SpriteKit Scene

private class SWCarnivalShooterScene: SKScene {
    var roundDuration: Double = 30
    var spawnInterval: Double = 1.2

    var onScoreChanged: ((Int) -> Void)?
    var onTimeChanged: ((Double) -> Void)?
    var onGameStateChanged: ((SWCarnivalGameState) -> Void)?
    var onStatsChanged: ((Int, Int) -> Void)?

    private var score = 0
    private var shotsHit = 0
    private var shotsFired = 0
    private var timeRemaining: Double = 30
    private var isPlaying = false
    private var lastUpdateTime: TimeInterval = 0
    private var timeSinceLastSpawn: Double = 0

    private let crosshairNode = SKNode()
    private var targets: [SWTarget] = []
    private var touchLocation: CGPoint?

    // Booth layout
    private let shelfCount = 3
    private var shelfYPositions: [CGFloat] = []

    // Colors
    private let boothRed = SKColor(red: 0.75, green: 0.12, blue: 0.15, alpha: 1)
    private let boothYellow = SKColor(red: 0.95, green: 0.78, blue: 0.15, alpha: 1)
    private let boothDarkRed = SKColor(red: 0.55, green: 0.08, blue: 0.1, alpha: 1)
    private let shelfBrown = SKColor(red: 0.45, green: 0.28, blue: 0.15, alpha: 1)
    private let skyBlue = SKColor(red: 0.25, green: 0.35, blue: 0.65, alpha: 1)

    override func didMove(to view: SKView) {
        backgroundColor = skyBlue
        buildBooth()
        buildCrosshair()
    }

    // MARK: - Booth Construction

    private func buildBooth() {
        guard let view = self.view else { return }
        let w = view.bounds.width
        let h = view.bounds.height

        // Sky gradient background
        let bg = SKSpriteNode(color: skyBlue, size: CGSize(width: w, height: h))
        bg.position = CGPoint(x: w / 2, y: h / 2)
        bg.zPosition = -10
        addChild(bg)

        // Booth back wall
        let wall = SKShapeNode(rect: CGRect(x: 0, y: 0, width: w, height: h * 0.78))
        wall.fillColor = boothDarkRed
        wall.strokeColor = .clear
        wall.zPosition = -5
        addChild(wall)

        // Striped awning at top
        let awningHeight: CGFloat = h * 0.15
        let stripeCount = 12
        let stripeWidth = w / CGFloat(stripeCount)
        for i in 0..<stripeCount {
            let stripe = SKShapeNode(rect: CGRect(
                x: CGFloat(i) * stripeWidth,
                y: h - awningHeight,
                width: stripeWidth,
                height: awningHeight
            ))
            stripe.fillColor = i % 2 == 0 ? boothRed : boothYellow
            stripe.strokeColor = .clear
            stripe.zPosition = 5
            addChild(stripe)
        }

        // Awning scalloped bottom edge
        let scallops = SKShapeNode()
        let scallopPath = CGMutablePath()
        let scallopWidth: CGFloat = w / 8
        let scallopY = h - awningHeight
        for i in 0..<8 {
            let sx = CGFloat(i) * scallopWidth
            scallopPath.move(to: CGPoint(x: sx, y: scallopY))
            scallopPath.addQuadCurve(
                to: CGPoint(x: sx + scallopWidth, y: scallopY),
                control: CGPoint(x: sx + scallopWidth / 2, y: scallopY - scallopWidth * 0.4)
            )
        }
        scallops.path = scallopPath
        scallops.fillColor = .clear
        scallops.strokeColor = boothYellow
        scallops.lineWidth = 3
        scallops.zPosition = 6
        addChild(scallops)

        // Shelves
        shelfYPositions = []
        let shelfZone = h * 0.65
        let shelfSpacing = shelfZone / CGFloat(shelfCount + 1)
        for i in 1...shelfCount {
            let y = shelfSpacing * CGFloat(i)
            shelfYPositions.append(y)

            let shelf = SKShapeNode(rect: CGRect(x: 0, y: y - 4, width: w, height: 8))
            shelf.fillColor = shelfBrown
            shelf.strokeColor = SKColor(red: 0.35, green: 0.2, blue: 0.1, alpha: 1)
            shelf.lineWidth = 1
            shelf.zPosition = 2
            addChild(shelf)

            // Shelf front face
            let face = SKShapeNode(rect: CGRect(x: 0, y: y - 12, width: w, height: 10))
            face.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 1)
            face.strokeColor = .clear
            face.zPosition = 3
            addChild(face)
        }

        // Side posts
        for xPos in [CGFloat(8), w - 8] {
            let post = SKShapeNode(rect: CGRect(x: xPos - 6, y: 0, width: 12, height: h - awningHeight))
            post.fillColor = boothRed
            post.strokeColor = boothDarkRed
            post.lineWidth = 1
            post.zPosition = 4
            addChild(post)
        }
    }

    // MARK: - Crosshair

    private func buildCrosshair() {
        let radius: CGFloat = 18
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.strokeColor = .red
        circle.lineWidth = 2.5
        circle.fillColor = .clear
        crosshairNode.addChild(circle)

        let dot = SKShapeNode(circleOfRadius: 2.5)
        dot.fillColor = .red
        dot.strokeColor = .clear
        crosshairNode.addChild(dot)

        let tickLen: CGFloat = 7
        for angle in [CGFloat(0), .pi / 2, .pi, 3 * .pi / 2] {
            let tick = SKShapeNode()
            let path = CGMutablePath()
            let innerX = cos(angle) * (radius - tickLen)
            let innerY = sin(angle) * (radius - tickLen)
            let outerX = cos(angle) * (radius + tickLen)
            let outerY = sin(angle) * (radius + tickLen)
            path.move(to: CGPoint(x: innerX, y: innerY))
            path.addLine(to: CGPoint(x: outerX, y: outerY))
            tick.path = path
            tick.strokeColor = .red
            tick.lineWidth = 2.5
            crosshairNode.addChild(tick)
        }

        crosshairNode.zPosition = 100
        crosshairNode.alpha = 0
        addChild(crosshairNode)
    }

    // MARK: - Game Control

    func startGame() {
        // Clear old targets
        for target in targets {
            target.node.removeFromParent()
        }
        targets.removeAll()

        score = 0
        shotsHit = 0
        shotsFired = 0
        timeRemaining = roundDuration
        lastUpdateTime = 0
        timeSinceLastSpawn = 0
        isPlaying = true

        onScoreChanged?(0)
        onStatsChanged?(0, 0)
    }

    // MARK: - Target Spawning

    private func spawnTarget() {
        guard let view = self.view else { return }
        let w = view.bounds.width
        guard !shelfYPositions.isEmpty else { return }

        let shelfIndex = Int.random(in: 0..<shelfYPositions.count)
        let shelfY = shelfYPositions[shelfIndex]

        // Target tier: small=hard, medium=mid, large=easy
        let tier = SWTargetTier.allCases.randomElement()!
        let radius = tier.radius

        // Spawn position
        let spawnFromLeft = Bool.random()
        let startX: CGFloat = spawnFromLeft ? -radius * 2 : w + radius * 2
        let endX: CGFloat = spawnFromLeft ? w + radius * 2 : -radius * 2
        let y = shelfY + radius + 6

        let targetNode = SKNode()
        targetNode.position = CGPoint(x: startX, y: y)
        targetNode.zPosition = 1

        // Build bullseye rings
        let ringColors: [(SKColor, CGFloat)] = [
            (.white, radius),
            (.red, radius * 0.82),
            (.white, radius * 0.64),
            (.red, radius * 0.46),
            (.white, radius * 0.28),
            (.red, radius * 0.14)
        ]
        for (color, r) in ringColors {
            let ring = SKShapeNode(circleOfRadius: r)
            ring.fillColor = color
            ring.strokeColor = SKColor(white: 0, alpha: 0.15)
            ring.lineWidth = 0.5
            targetNode.addChild(ring)
        }

        // Stick/post under the target
        let stickHeight = radius + 4
        let stick = SKShapeNode(rect: CGRect(x: -2, y: -stickHeight, width: 4, height: stickHeight))
        stick.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.12, alpha: 1)
        stick.strokeColor = .clear
        stick.zPosition = -1
        targetNode.addChild(stick)

        addChild(targetNode)

        // Movement animation
        let speed: CGFloat = tier.speed
        let duration = Double(abs(endX - startX) / speed)

        // Bobbing motion while sliding
        let bobUp = SKAction.moveBy(x: 0, y: 6, duration: 0.4)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.repeatForever(.sequence([bobUp, bobDown]))

        let slide = SKAction.moveTo(x: endX, duration: duration)

        let target = SWTarget(
            node: targetNode,
            tier: tier,
            radius: radius
        )
        targets.append(target)

        targetNode.run(bob)
        targetNode.run(slide) { [weak self] in
            targetNode.removeFromParent()
            self?.targets.removeAll { $0.node === targetNode }
        }

        // Pop-up entrance animation
        targetNode.setScale(0)
        targetNode.run(.scale(to: 1.0, duration: 0.2))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchLocation = location
        crosshairNode.position = location
        crosshairNode.alpha = 1

        if isPlaying {
            shoot(at: location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchLocation = location
        crosshairNode.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = nil
        crosshairNode.run(.fadeAlpha(to: 0.4, duration: 0.3))
    }

    // MARK: - Shooting

    private func shoot(at point: CGPoint) {
        shotsFired += 1
        onStatsChanged?(shotsHit, shotsFired)

        // Muzzle flash at crosshair
        showMuzzleFlash(at: point)

        // Check hits (closest first for overlapping targets)
        var hitTarget: SWTarget?
        var closestDist: CGFloat = .greatestFiniteMagnitude

        for target in targets {
            let targetPos = target.node.position
            let dist = hypot(point.x - targetPos.x, point.y - targetPos.y)
            if dist <= target.radius && dist < closestDist {
                closestDist = dist
                hitTarget = target
            }
        }

        if let hit = hitTarget {
            // Calculate points — closer to center = bonus
            let centerDist = closestDist / hit.radius
            let bonus = centerDist < 0.3 ? 2 : 1
            let points = hit.tier.points * bonus

            score += points
            shotsHit += 1
            onScoreChanged?(score)
            onStatsChanged?(shotsHit, shotsFired)

            // Hit effects
            showHitEffect(at: hit.node.position, points: points, isBullseye: bonus == 2)
            showSparks(at: hit.node.position)

            // Shatter the target
            shatterTarget(hit)
        } else {
            // Miss effect
            showMissEffect(at: point)
        }
    }

    // MARK: - Visual Effects

    private func showMuzzleFlash(at point: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 12)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.position = point
        flash.zPosition = 90
        flash.alpha = 0.8
        addChild(flash)

        flash.run(.sequence([
            .group([
                .scale(to: 2.0, duration: 0.08),
                .fadeAlpha(to: 0, duration: 0.12)
            ]),
            .removeFromParent()
        ]))
    }

    private func showHitEffect(at point: CGPoint, points: Int, isBullseye: Bool) {
        // Score popup
        let label = SKLabelNode(text: isBullseye ? "BULLSEYE! +\(points)" : "+\(points)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isBullseye ? 22 : 18
        label.fontColor = isBullseye ? .yellow : .white
        label.position = CGPoint(x: point.x, y: point.y + 20)
        label.zPosition = 80
        addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 50, duration: 0.8),
                .sequence([
                    .fadeAlpha(to: 1, duration: 0.1),
                    .wait(forDuration: 0.4),
                    .fadeAlpha(to: 0, duration: 0.3)
                ]),
                .scale(to: 1.3, duration: 0.8)
            ]),
            .removeFromParent()
        ]))

        // Impact ring
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.strokeColor = isBullseye ? .yellow : .white
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.position = point
        ring.zPosition = 75
        addChild(ring)

        ring.run(.sequence([
            .group([
                .scale(to: 4.0, duration: 0.3),
                .fadeAlpha(to: 0, duration: 0.3)
            ]),
            .removeFromParent()
        ]))
    }

    private func showSparks(at point: CGPoint) {
        let sparkCount = 10
        for _ in 0..<sparkCount {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            spark.fillColor = [.yellow, .orange, .white, .red].randomElement()!
            spark.strokeColor = .clear
            spark.position = point
            spark.zPosition = 85

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...220)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            addChild(spark)
            spark.run(.sequence([
                .group([
                    .moveBy(x: dx * 0.4, y: dy * 0.4, duration: 0.35),
                    .fadeAlpha(to: 0, duration: 0.35),
                    .scale(to: 0.2, duration: 0.35)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func showMissEffect(at point: CGPoint) {
        let puff = SKShapeNode(circleOfRadius: 4)
        puff.fillColor = SKColor(white: 0.8, alpha: 0.5)
        puff.strokeColor = .clear
        puff.position = point
        puff.zPosition = 75
        addChild(puff)

        puff.run(.sequence([
            .group([
                .scale(to: 3.0, duration: 0.25),
                .fadeAlpha(to: 0, duration: 0.25)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Target Shatter

    private func shatterTarget(_ target: SWTarget) {
        let pos = target.node.position
        let radius = target.radius

        target.node.removeFromParent()
        targets.removeAll { $0.node === target.node }

        // Create shard pieces
        let shardCount = 6
        for _ in 0..<shardCount {
            let shardSize = CGFloat.random(in: radius * 0.25...radius * 0.5)
            let shard = SKShapeNode(rectOf: CGSize(width: shardSize, height: shardSize), cornerRadius: 2)
            shard.fillColor = [.white, .red, .white, .red].randomElement()!
            shard.strokeColor = SKColor(white: 0, alpha: 0.2)
            shard.lineWidth = 0.5
            shard.position = CGPoint(
                x: pos.x + CGFloat.random(in: -radius...radius) * 0.5,
                y: pos.y + CGFloat.random(in: -radius...radius) * 0.5
            )
            shard.zPosition = 70

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 100...260)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed + 80 // slight upward bias

            addChild(shard)
            shard.run(.sequence([
                .group([
                    .moveBy(x: dx * 0.6, y: dy * 0.6 - 120, duration: 0.6),
                    .rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.6),
                    .sequence([
                        .wait(forDuration: 0.3),
                        .fadeAlpha(to: 0, duration: 0.3)
                    ])
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard isPlaying else { return }

        // Update timer
        timeRemaining -= dt
        onTimeChanged?(max(0, timeRemaining))

        if timeRemaining <= 0 {
            isPlaying = false
            onGameStateChanged?(.ended)

            // Clear remaining targets
            for target in targets {
                target.node.run(.sequence([
                    .fadeAlpha(to: 0, duration: 0.3),
                    .removeFromParent()
                ]))
            }
            targets.removeAll()
            return
        }

        // Spawn targets
        timeSinceLastSpawn += dt
        // Speed up spawning as time progresses
        let progress = 1 - (timeRemaining / roundDuration)
        let adjustedInterval = spawnInterval * (1 - progress * 0.4)

        if timeSinceLastSpawn >= adjustedInterval {
            timeSinceLastSpawn = 0
            spawnTarget()
        }
    }
}

// MARK: - Target Model

private struct SWTarget {
    let node: SKNode
    let tier: SWTargetTier
    let radius: CGFloat
}

private enum SWTargetTier: CaseIterable {
    case small, medium, large

    var radius: CGFloat {
        switch self {
        case .small: 16
        case .medium: 24
        case .large: 34
        }
    }

    var points: Int {
        switch self {
        case .small: 100
        case .medium: 50
        case .large: 25
        }
    }

    var speed: CGFloat {
        switch self {
        case .small: 140
        case .medium: 100
        case .large: 70
        }
    }
}

// MARK: - Preview

#Preview {
    SWCarnivalShooter()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
}
