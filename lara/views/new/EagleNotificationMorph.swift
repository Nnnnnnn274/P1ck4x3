import SwiftUI
import UIKit
import CoreImage

// Port of rit3zh/expo-dynamic-notifications: get-notification-layout.ts,
// build-notification-geometry.ts, neck-profile.ts and gooey.tsx.
// Same constants, geometry and alpha matrix. Core Image reproduces Skia's
// render order (blur first, alpha gain/cutoff second) without bundling Skia.
// MIT attribution: NOTICE_Dynamic_Notifications.txt.
struct EagleNotificationLayout {
    let width: CGFloat
    let insetTop: CGFloat
    var cardHeight: CGFloat = 74
    var centerX: CGFloat { width / 2 }
    var islandWidth: CGFloat { 126 }
    var islandHeight: CGFloat { 37.33 }
    var islandTop: CGFloat { max(insetTop - islandHeight - 11, 12) }
    var islandBottom: CGFloat { islandTop + islandHeight }
    var islandRadius: CGFloat { islandHeight / 2 }
    var islandRect: CGRect {
        CGRect(x: centerX - islandWidth / 2, y: islandTop,
               width: islandWidth, height: islandHeight)
    }
    var cardWidth: CGFloat { max(1, min(width - 32, 396)) }
    var cardRadius: CGFloat { cardHeight / 2 }
    var cardTop: CGFloat { islandBottom + 34 }
    var cardCenterY: CGFloat { cardTop + cardHeight / 2 }
    var cardRect: CGRect {
        CGRect(x: centerX - cardWidth / 2, y: cardTop,
               width: cardWidth, height: cardHeight)
    }
    var canvasHeight: CGFloat { cardTop + cardHeight + 96 }
}

struct EagleNotificationGeometry {
    let rect: CGRect
    let radius: CGFloat
    let neck: CGRect
    let shadowOpacity: CGFloat
    let offsetY: CGFloat
    let widthRatio: CGFloat

    static func clamp(_ value: CGFloat, _ low: CGFloat = 0, _ high: CGFloat = 1) -> CGFloat {
        min(high, max(low, value))
    }

    init(drop: CGFloat, expand: CGFloat, layout l: EagleNotificationLayout) {
        let grow = 1 - pow(1 - Self.clamp(drop / 0.7), 1.25)
        let t = Self.clamp(drop / 0.82)
        let peak: CGFloat = 1.6 / 3
        let normal = pow(peak, 1.6) * pow(1 - peak, 1.4)
        let profile = t <= 0 || t >= 1 ? 0 : pow(t, 1.6) * pow(1 - t, 1.4) / normal
        let stretch = 1 + 0.38 * profile
        let droplet = 52 * grow
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + expand * (b - a) }
        let w = max(0, min(mix(droplet / stretch, l.cardWidth), l.width - 20))
        let h = max(0, mix(droplet * stretch, l.cardHeight))
        radius = max(0, min(mix(droplet * 0.5, l.cardRadius), min(w, h) / 2))
        let origin = l.islandBottom - l.islandHeight * 0.34
        let cy = origin + drop * (l.cardCenterY - origin)
        let nw = min(60, w) * profile
        let ny = l.islandBottom - l.islandHeight * 0.5
        rect = CGRect(x: l.centerX - w / 2, y: cy - h / 2, width: w, height: h)
        neck = CGRect(x: l.centerX - nw / 2, y: ny, width: nw, height: max(cy - ny, 0))
        shadowOpacity = Self.clamp(expand)
        offsetY = cy - l.cardCenterY
        widthRatio = w / l.cardWidth
    }
}

/// Reanimated 4.5's duration-based spring translated to SwiftUI's physical
/// spring. The source computes stiffness by bisection so that the spring's
/// energy reaches 6e-9 at 1.5x its perceptual duration; duplicating that step
/// avoids the visibly different timing produced by SwiftUI `response:`.
enum EagleReferenceSpring {
    private static let mass = 4.0
    private static let energyThreshold = 6e-9

    static func animation(milliseconds: Double, dampingRatio: Double) -> Animation {
        let stiffness = matchingStiffness(milliseconds: milliseconds,
                                          dampingRatio: dampingRatio)
        let damping = 2 * dampingRatio * sqrt(stiffness * mass)
        return .interpolatingSpring(mass: mass, stiffness: stiffness,
                                    damping: damping, initialVelocity: 0)
    }

    private static func matchingStiffness(milliseconds: Double,
                                          dampingRatio: Double) -> Double {
        let settlingDuration = milliseconds * 1.5 / 1_000
        func energyDifference(_ stiffness: Double) -> Double {
            let x0 = 1.0
            let v0 = 0.0
            let omega = sqrt(stiffness / mass) * dampingRatio
            let envelope = exp(-omega * settlingDuration)
            let common = x0 + (v0 + x0 * omega) * settlingDuration
            let x = common * envelope
            let v = common * envelope * -omega + (v0 + x0 * omega) * envelope
            let initial = 0.5 * stiffness * x0 * x0 + 0.5 * mass * v0 * v0
            let current = 0.5 * stiffness * x * x + 0.5 * mass * v * v
            return current / initial - energyThreshold
        }

        var low = Double.ulpOfOne
        var high = 8_000.0
        let direction = energyDifference(high) >= energyDifference(low) ? 1.0 : -1.0
        var value = (low + high) / 2
        let precision = energyThreshold * 1e-3
        for _ in 0..<100 {
            if abs(energyDifference(value)) <= precision { break }
            if energyDifference(value) * direction < 0 {
                low = value
            } else {
                high = value
            }
            value = (low + high) / 2
        }
        return value
    }
}

struct EagleNotificationMorph<Content: View>: View, Animatable {
    let layout: EagleNotificationLayout
    var drop: CGFloat
    var expand: CGFloat
    var reveal: CGFloat
    var tint: CGFloat
    var dragY: CGFloat
    @ViewBuilder let content: () -> Content

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(drop, expand), AnimatablePair(reveal, tint)) }
        set {
            drop = newValue.first.first; expand = newValue.first.second
            reveal = newValue.second.first; tint = newValue.second.second
        }
    }

    var body: some View {
        let g = EagleNotificationGeometry(drop: drop, expand: expand, layout: layout)
        let progress = EagleNotificationGeometry.clamp(reveal)
        let overshoot = EagleNotificationGeometry.clamp(g.widthRatio - 1, 0, 0.2)
        let scale = 0.88 + 0.12 * progress + overshoot * progress
        ZStack(alignment: .topLeading) {
            EagleNotificationGooSurface(layout: layout, geometry: g, tint: tint)
            .frame(width: layout.width, height: layout.canvasHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            content()
                // expo-blur on iOS is a UIVisualEffectView. Keeping the same
                // material instead of applying a Gaussian blur to the text is
                // essential to the reference reveal.
                .overlay(EagleNotificationRevealBlur(progress: progress))
                .clipShape(RoundedRectangle(cornerRadius: layout.cardRadius, style: .continuous))
                .opacity(Double(progress))
                .scaleEffect(scale)
                .offset(x: layout.cardRect.minX, y: layout.cardTop + g.offsetY + dragY)
        }
    }
}

private struct EagleNotificationGooSurface: UIViewRepresentable {
    let layout: EagleNotificationLayout
    let geometry: EagleNotificationGeometry
    let tint: CGFloat

    func makeUIView(context: Context) -> EagleNotificationGooView {
        let view = EagleNotificationGooView()
        view.isOpaque = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: EagleNotificationGooView, context: Context) {
        view.update(layout: layout, geometry: geometry, tint: tint)
    }
}

/// Native equivalent of the reference's Skia layer:
/// RoundedRect sources -> Gaussian blur -> alpha matrix -> sharp island.
/// The filters are event-driven and only redraw while SwiftUI advances the
/// short notification transition; there is no permanent display link.
private final class EagleNotificationGooView: UIView {
    private static let ciContext = CIContext(options: [
        .cacheIntermediates: false,
        .workingColorSpace: NSNull()
    ])

    private var notificationLayout = EagleNotificationLayout(width: 1, insetTop: 0)
    private var notificationGeometry = EagleNotificationGeometry(
        drop: 0, expand: 0, layout: EagleNotificationLayout(width: 1, insetTop: 0)
    )
    private var notificationTint: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        layer.drawsAsynchronously = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(layout: EagleNotificationLayout,
                geometry: EagleNotificationGeometry,
                tint: CGFloat) {
        notificationLayout = layout
        notificationGeometry = geometry
        notificationTint = tint
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard bounds.width > 0, bounds.height > 0,
              let target = UIGraphicsGetCurrentContext() else { return }

        let l = notificationLayout
        let g = notificationGeometry
        // Goo is intentionally blurred by 14.3 pt. Two samples per point are
        // visually lossless for that filtered layer and avoid a 3x offscreen
        // texture on Pro/Max phones. Text and the sharp island remain native.
        let scale = min(window?.screen.scale ?? traitCollection.displayScale, 2)

        // Skia draws this shadow outside the filtered group with shadowOnly.
        target.saveGState()
        target.setFillColor(UIColor(red: 0.075, green: 0.084, blue: 0.105, alpha: 1).cgColor)
        target.setShadow(offset: CGSize(width: 0, height: 10), blur: 14,
                         color: UIColor(red: 16/255, green: 19/255, blue: 28/255,
                                        alpha: 0.20 * g.shadowOpacity).cgColor)
        target.addPath(CGPath(roundedRect: g.rect, cornerWidth: g.radius,
                              cornerHeight: g.radius, transform: nil))
        target.fillPath()
        target.setShadow(offset: .zero, blur: 0, color: nil)
        target.setBlendMode(.clear)
        target.addPath(CGPath(roundedRect: g.rect, cornerWidth: g.radius,
                              cornerHeight: g.radius, transform: nil))
        target.fillPath()
        target.restoreGState()

        let blur: CGFloat = 5 + 0.62 * (20 - 5) // 14.3, from the reference.
        let inset = blur * 0.26
        let dropletTone = EagleNotificationGeometry.clamp(
            (notificationTint - 0.06) / (0.88 - 0.06)
        )
        let pixelExtent = CGRect(x: 0, y: 0,
                                 width: bounds.width * scale,
                                 height: bounds.height * scale)
        func ciRect(_ rect: CGRect) -> CGRect {
            // Core Image's origin is bottom-left; Eagle layout is top-left.
            CGRect(x: rect.minX * scale,
                   y: (bounds.height - rect.maxY) * scale,
                   width: rect.width * scale,
                   height: rect.height * scale)
        }
        func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: CIColor) -> CIImage? {
            guard rect.width > 0, rect.height > 0,
                  let filter = CIFilter(name: "CIRoundedRectangleGenerator") else { return nil }
            filter.setValue(CIVector(cgRect: ciRect(rect)), forKey: "inputExtent")
            filter.setValue(radius * scale, forKey: "inputRadius")
            filter.setValue(color, forKey: kCIInputColorKey)
            return filter.outputImage
        }
        let clear = CIImage(color: CIColor.clear).cropped(to: pixelExtent)
        let island = l.islandRect.insetBy(dx: inset, dy: inset)
        var sources = clear
        if let shape = rounded(island, max(0, l.islandRadius - inset), .black) {
            sources = shape.composited(over: sources)
        }
        if let shape = rounded(g.neck, g.neck.width / 2, .black) {
            sources = shape.composited(over: sources)
        }
        if let shape = rounded(g.rect, g.radius,
                               CIColor(red: 0.075 + 0.025 * dropletTone,
                                       green: 0.084 + 0.025 * dropletTone,
                                       blue: 0.105 + 0.025 * dropletTone, alpha: 1)) {
            sources = shape.composited(over: sources)
        }

        let blurred = sources
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [
                    kCIInputRadiusKey: blur * scale
                ])
                .cropped(to: pixelExtent)
            let matrix = blurred.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 22),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: -22 * 0.43)
            ])
        if let result = Self.ciContext.createCGImage(matrix, from: pixelExtent) {
            target.saveGState()
            target.interpolationQuality = .high
            UIImage(cgImage: result, scale: scale, orientation: .up).draw(in: bounds)
            target.restoreGState()
        }

        // The hardware-aligned pill is deliberately sharp and sits above goo.
        target.setFillColor(UIColor.black.cgColor)
        target.addPath(CGPath(roundedRect: l.islandRect,
                              cornerWidth: l.islandRadius,
                              cornerHeight: l.islandRadius,
                              transform: nil))
        target.fillPath()
    }
}

private struct EagleNotificationRevealBlur: UIViewRepresentable {
    let progress: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.alpha = 1 - EagleNotificationGeometry.clamp(progress)
    }
}
