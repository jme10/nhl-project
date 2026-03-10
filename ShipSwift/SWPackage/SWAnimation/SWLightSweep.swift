//
//  SWLightSweep.swift
//  ShipSwift
//
//  Animated scan-line overlay View wrapper that sweeps a gradient light band
//  across any content. The content is clipped to a rounded rectangle and the
//  light band loops indefinitely.
//
//  Usage:
//    SWLightSweep {
//        Image("photo")
//            .resizable()
//            .frame(width: 300, height: 200)
//    }
//
//    SWLightSweep(
//        lineWidth: 120,
//        duration: 2.0,
//        lineColor: .blue.opacity(0.4),
//        cornerRadius: 20
//    ) {
//        Rectangle()
//            .fill(.gray)
//            .frame(width: 300, height: 200)
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWLightSweep<Content: View>: View {
    @State private var animate = false

    var lineWidth: CGFloat = 80
    var duration: Double = 1.5
    var lineColor: Color = .white.opacity(0.6)
    var cornerRadius: CGFloat = 16

    @ViewBuilder let content: () -> Content

    init(
        lineWidth: CGFloat = 80,
        duration: Double = 1.5,
        lineColor: Color = .white.opacity(0.6),
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.lineWidth = lineWidth
        self.duration = duration
        self.lineColor = lineColor
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, lineColor, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: lineWidth)
                    .offset(x: animate ? geo.size.width : -lineWidth)
                    .animation(
                        .linear(duration: duration).repeatForever(autoreverses: false),
                        value: animate
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .onAppear {
                animate = true
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 26) {
        SWLightSweep {
            Rectangle()
                .fill(.gray)
                .frame(width: 180, height: 180)
        }

        SWLightSweep(lineWidth: 120, duration: 0.5, cornerRadius: 20) {
            Rectangle()
                .fill(.blue)
                .frame(width: 200, height: 200)
        }
    }
}
