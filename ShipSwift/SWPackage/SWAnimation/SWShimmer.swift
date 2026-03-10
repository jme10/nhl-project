//
//  SWShimmer.swift
//  ShipSwift
//
//  Shimmer highlight View wrapper that sweeps a translucent light band across
//  the content in a continuous loop. Commonly used on buttons, skeleton loaders,
//  or cards to draw attention or indicate a loading state.
//
//  Usage:
//    SWShimmer {
//        Text("Upgrade Now")
//            .padding()
//            .background(.blue)
//            .clipShape(.capsule)
//    }
//
//    SWShimmer(duration: 1.5, delay: 2.0) {
//        myView
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - SWShimmer

struct SWShimmer<Content: View>: View {
    @State private var animate = false

    var duration: Double = 2.0
    var delay: Double = 1.0

    @ViewBuilder let content: () -> Content

    init(
        duration: Double = 2.0,
        delay: Double = 1.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.duration = duration
        self.delay = delay
        self.content = content
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                .clear,
                .white.opacity(0.2),
                .clear,
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        content()
            .overlay {
                GeometryReader { geo in
                    let bandWidth = geo.size.width * 0.5
                    gradient
                        .frame(width: bandWidth)
                        .offset(x: animate ? geo.size.width + bandWidth : -bandWidth * 1.5)
                        .animation(
                            .linear(duration: duration)
                            .delay(delay)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
                .clipped()
            }
            .task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                animate = true
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        SWShimmer {
            Button {

            } label: {
                Text("Upgrade Now")
                    .font(.largeTitle)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        }

        SWShimmer {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.3))
                .frame(width: 280, height: 120)
        }
    }
    .padding()
}
