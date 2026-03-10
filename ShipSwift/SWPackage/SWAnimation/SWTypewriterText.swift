//
//  SWTypewriterText.swift
//  ShipSwift
//
//  Typewriter text animation that cycles through an array of strings,
//  typing and deleting characters one by one with configurable animation
//  styles. Ideal for landing page headlines, onboarding prompts, and
//  AI chat UIs.
//
//  Usage:
//    SWTypewriterText(texts: ["Hello World", "Welcome Back", "Let's Go"])
//    SWTypewriterText(texts: ["Line 1", "Line 2"], animationStyle: .blur)
//    SWTypewriterText.spring(texts: ["A", "B"])
//    SWTypewriterText.blur(texts: ["A", "B"])
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - SWTypewriterStyle

enum SWTypewriterStyle: Sendable {
    case none
    case spring
    case blur
    case fade
    case scale
    case wave
}

// MARK: - SWTypewriterText

struct SWTypewriterText: View {
    let texts: [String]
    var typingSpeed: Double = 0.04
    var deletingSpeed: Double = 0.03
    var pauseDuration: Double = 2.5
    var animationStyle: SWTypewriterStyle = .spring
    var gradient: LinearGradient = LinearGradient(
        colors: [.cyan, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var isDeleting = false
    @State private var charStates: [SWTypewriterTextCharState] = []
    @State private var isActive = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(charStates) { state in
                    Text(state.character)
                        .foregroundStyle(gradient)
                        .transition(transitionForStyle)
                }
            }
            .animation(animationForCurrentAction, value: charStates.count)

            Text("|")
                .foregroundStyle(.clear)
        }
        .onAppear {
            isActive = true
            displayedText = ""
            charStates = []
            currentIndex = 0
            isDeleting = false
            startTyping()
        }
        .onDisappear {
            isActive = false
        }
    }

    // MARK: - Transition Configuration

    private var transitionForStyle: AnyTransition {
        switch animationStyle {
        case .none:
            return .identity
        case .spring:
            return .asymmetric(
                insertion: .scale(scale: 0.3).combined(with: .opacity),
                removal: .scale(scale: 0.3).combined(with: .opacity)
            )
        case .blur:
            return .asymmetric(
                insertion: .opacity.combined(with: .typewriterBlur),
                removal: .opacity.combined(with: .typewriterBlur)
            )
        case .fade:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .scale:
            return .asymmetric(
                insertion: .scale(scale: 1.5).combined(with: .opacity),
                removal: .scale(scale: 1.5).combined(with: .opacity)
            )
        case .wave:
            return .asymmetric(
                insertion: .offset(y: -8).combined(with: .opacity),
                removal: .offset(y: 8).combined(with: .opacity)
            )
        }
    }

    private var animationForCurrentAction: Animation {
        if isDeleting {
            switch animationStyle {
            case .none: return .linear(duration: 0)
            case .spring: return .easeOut(duration: 0.15)
            case .blur: return .easeOut(duration: 0.12)
            case .fade: return .easeOut(duration: 0.12)
            case .scale: return .easeOut(duration: 0.12)
            case .wave: return .easeOut(duration: 0.12)
            }
        } else {
            switch animationStyle {
            case .none: return .linear(duration: 0)
            case .spring: return .spring(response: 0.3, dampingFraction: 0.6)
            case .blur: return .easeOut(duration: 0.2)
            case .fade: return .easeOut(duration: 0.2)
            case .scale: return .spring(response: 0.25, dampingFraction: 0.7)
            case .wave: return .easeInOut(duration: 0.15)
            }
        }
    }

    // MARK: - Typing Logic

    private func startTyping() {
        guard !texts.isEmpty, isActive else { return }
        typeNextCharacter()
    }

    private func typeNextCharacter() {
        guard isActive else { return }

        let currentText = texts[currentIndex]

        if isDeleting {
            if charStates.isEmpty {
                isDeleting = false
                displayedText = ""
                currentIndex = (currentIndex + 1) % texts.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                    guard isActive else { return }
                    typeNextCharacter()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + deletingSpeed) { [self] in
                    guard isActive else { return }
                    if !charStates.isEmpty {
                        _ = charStates.removeLast()
                        displayedText = String(displayedText.dropLast())
                    }
                    typeNextCharacter()
                }
            }
        } else {
            if displayedText.count < currentText.count {
                let charIndex = currentText.index(currentText.startIndex, offsetBy: displayedText.count)
                let newChar = currentText[charIndex]

                DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) { [self] in
                    guard isActive else { return }
                    displayedText.append(newChar)
                    charStates.append(SWTypewriterTextCharState(character: String(newChar)))
                    typeNextCharacter()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) { [self] in
                    guard isActive else { return }
                    isDeleting = true
                    typeNextCharacter()
                }
            }
        }
    }
}

// MARK: - Character State

private struct SWTypewriterTextCharState: Identifiable, Equatable {
    let id = UUID()
    var character: String
}

// MARK: - Custom Blur Transition

fileprivate extension AnyTransition {
    static var typewriterBlur: AnyTransition {
        .modifier(
            active: SWBlurModifier(radius: 10, opacity: 0),
            identity: SWBlurModifier(radius: 0, opacity: 1)
        )
    }
}

private struct SWBlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

// MARK: - Convenience Initializers

extension SWTypewriterText {
    static func spring(texts: [String]) -> SWTypewriterText {
        SWTypewriterText(texts: texts, animationStyle: .spring)
    }

    static func blur(texts: [String]) -> SWTypewriterText {
        SWTypewriterText(texts: texts, animationStyle: .blur)
    }

    static func scale(texts: [String]) -> SWTypewriterText {
        SWTypewriterText(texts: texts, animationStyle: .scale)
    }

    static func fade(texts: [String]) -> SWTypewriterText {
        SWTypewriterText(texts: texts, animationStyle: .fade)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 26) {
        SWTypewriterText(
            texts: [
                "Level up your smile game",
                "AI-powered smile analysis",
                "Join the glow up era"
            ],
            animationStyle: .spring
        )
        .font(.title3.weight(.semibold))

        SWTypewriterText(
            texts: [
                "Level up your smile game",
                "AI-powered smile analysis",
                "Join the glow up era"
            ],
            animationStyle: .blur
        )
        .font(.title3.weight(.semibold))

        SWTypewriterText(
            texts: [
                "Hello World",
                "Welcome Back",
                "Let's Go"
            ],
            animationStyle: .spring,
            gradient: LinearGradient(
                colors: [.pink, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .font(.title.weight(.bold))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
