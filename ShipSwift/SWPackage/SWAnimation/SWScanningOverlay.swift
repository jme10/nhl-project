//
//  SWScanningOverlay.swift
//  ShipSwift
//
//  Animated scan-line overlay View wrapper that renders a flowing grid, a top-to-bottom
//  sweeping scan band, and a subtle noise layer on top of the provided content.
//  Conveys an "analyzing / processing" visual effect.
//  Uses Canvas for high-performance grid rendering.
//
//  Usage:
//    SWScanningOverlay {
//        Image("myPhoto")
//            .resizable()
//            .scaledToFit()
//    }
//
//    SWScanningOverlay(
//        gridOpacity: 0.3,
//        bandOpacity: 0.5,
//        bandHeightRatio: 0.25,
//        gridSpacing: 20,
//        speed: 3.0
//    ) {
//        Image("myPhoto")
//            .resizable()
//            .scaledToFit()
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWScanningOverlay<Content: View>: View {
    // MARK: - Configurable Parameters

    var gridOpacity: Double = 0.2
    var bandOpacity: Double = 0.3
    var bandHeightRatio: CGFloat = 0.2
    var gridSpacing: CGFloat = 16
    var speed: Double = 2.0

    @ViewBuilder let content: () -> Content

    @State private var startDate = Date.now

    init(
        gridOpacity: Double = 0.2,
        bandOpacity: Double = 0.3,
        bandHeightRatio: CGFloat = 0.2,
        gridSpacing: CGFloat = 16,
        speed: Double = 2.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gridOpacity = gridOpacity
        self.bandOpacity = bandOpacity
        self.bandHeightRatio = bandHeightRatio
        self.gridSpacing = gridSpacing
        self.speed = speed
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        content()
            .overlay {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSince(startDate)
                    GeometryReader { geo in
                        let size = geo.size
                        ZStack {
                            // 1) Dynamic grid with subtle "flowing" motion
                            Canvas { ctx, _ in
                                let phase = CGFloat(t * 0.8)
                                let dx = sin(phase) * 3
                                let dy = cos(phase * 0.9) * 3

                                var path = Path()
                                let step = max(10, gridSpacing)

                                // Vertical lines
                                var x: CGFloat = -step
                                while x <= size.width + step {
                                    let xx = x + dx + sin((x / 80) + phase) * 1.5
                                    path.move(to: CGPoint(x: xx, y: 0))
                                    path.addLine(to: CGPoint(x: xx, y: size.height))
                                    x += step
                                }

                                // Horizontal lines
                                var y: CGFloat = -step
                                while y <= size.height + step {
                                    let yy = y + dy + cos((y / 80) + phase) * 1.5
                                    path.move(to: CGPoint(x: 0, y: yy))
                                    path.addLine(to: CGPoint(x: size.width, y: yy))
                                    y += step
                                }

                                ctx.stroke(
                                    path,
                                    with: .color(.white.opacity(gridOpacity)),
                                    lineWidth: 1
                                )
                            }
                            .blendMode(.screen)

                            // 2) Scan band (top-to-bottom loop)
                            scanBand(size: size, time: t)

                            // 3) Lightweight noise overlay
                            noiseOverlay(time: t)
                                .opacity(0.06)
                                .blendMode(.overlay)
                        }
                        .compositingGroup()
                    }
                }
            }
    }

    // MARK: - Private Views

    private func scanBand(size: CGSize, time t: Double) -> some View {
        let p = CGFloat((t * (0.22 * speed)).truncatingRemainder(dividingBy: 1.0))
        let bandH = size.height * bandHeightRatio
        let y = -bandH + (size.height + bandH * 2) * p

        return ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(bandOpacity * 0.4), location: 0.25),
                            .init(color: .white.opacity(bandOpacity), location: 0.5),
                            .init(color: .white.opacity(bandOpacity * 0.4), location: 0.75),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: bandH)
                .position(x: size.width/2, y: y)
                .blendMode(.screen)

            Rectangle()
                .fill(Color.white.opacity(bandOpacity * 0.65))
                .frame(height: 2)
                .position(x: size.width/2, y: y)
                .blur(radius: 0.6)
                .blendMode(.screen)
        }
    }

    private func noiseOverlay(time t: Double) -> some View {
        LinearGradient(
            colors: [
                .white.opacity(0.0),
                .white.opacity(1.0),
                .white.opacity(0.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(1.6)
        .offset(x: sin(t * 0.9) * 20, y: cos(t * 1.1) * 20)
        .blur(radius: 12)
    }
}

// MARK: - Preview

#Preview("Basic Usage") {
    VStack(spacing: 20) {
        SWScanningOverlay {
            Rectangle()
                .fill(.gray)
                .frame(width: 180, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        SWScanningOverlay(
            gridOpacity: 0.1,
            bandOpacity: 0.1,
            speed: 3.0
        ) {
            Rectangle()
                .fill(.blue)
                .frame(width: 200, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    .padding()
}
