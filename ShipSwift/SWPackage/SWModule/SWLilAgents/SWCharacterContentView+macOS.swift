// SWCharacterContentView+macOS.swift
// Pixel-accurate hit testing for character clicks via CGWindowListCreateImage.

import AppKit

final class SWCharacterContentView: NSView {
    var onClicked: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isOpaquePixel(at: point) {
            onClicked?()
        } else {
            // Pass through to whatever is behind
            super.mouseDown(with: event)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if isOpaquePixel(at: point) {
            return self
        }
        return nil
    }

    /// Checks if the pixel at the given local point is non-transparent
    /// by capturing a 1x1 image from the window's backing.
    private func isOpaquePixel(at localPoint: NSPoint) -> Bool {
        guard let windowNumber = window?.windowNumber else {
            return fallbackHitTest(at: localPoint)
        }

        // Convert local point to screen coordinates
        let windowPoint = convert(localPoint, to: nil)
        guard let screenPoint = window?.convertPoint(toScreen: windowPoint) else {
            return fallbackHitTest(at: localPoint)
        }

        // CGWindowListCreateImage uses top-left origin
        let screenHeight = window?.screen?.frame.height ?? NSScreen.main?.frame.height ?? 1080
        let flippedY = screenHeight - screenPoint.y

        let captureRect = CGRect(x: screenPoint.x, y: flippedY, width: 1, height: 1)

        guard let image = CGWindowListCreateImage(
            captureRect,
            .optionIncludingWindow,
            CGWindowID(windowNumber),
            [.boundsIgnoreFraming, .nominalResolution]
        ) else {
            return fallbackHitTest(at: localPoint)
        }

        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              CFDataGetLength(data) >= 4 else {
            return fallbackHitTest(at: localPoint)
        }

        let ptr = CFDataGetBytePtr(data)!
        // BGRA format — alpha is at index 3
        let alpha = ptr[3]
        return alpha > 30
    }

    /// Fallback: treat the center 60% as clickable
    private func fallbackHitTest(at point: NSPoint) -> Bool {
        let insetX = bounds.width * 0.2
        let insetY = bounds.height * 0.2
        let hitRect = bounds.insetBy(dx: insetX, dy: insetY)
        return hitRect.contains(point)
    }
}
