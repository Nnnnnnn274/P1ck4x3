import SwiftUI
import UIKit
import Combine

// Native adaptation of the capsule/drop interaction in rit3zh's
// expo-dynamic-notifications. See NOTICE_Dynamic_Notifications.txt.
enum EagleNoticeKind: Sendable {
    case success, error, information

    var symbol: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .information: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return Color(red: 0.33, green: 0.88, blue: 0.58)
        case .error: return Color(red: 1, green: 0.38, blue: 0.39)
        case .information: return Color(red: 0.43, green: 0.71, blue: 1)
        }
    }
}

struct EagleDynamicNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let kind: EagleNoticeKind
    let actionTitle: String?
    let action: (() -> Void)?
    var immediate = false

    var sourceSymbol: String {
        let source = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if source.contains("island") || source.contains("isla") { return "capsule" }
        if source.contains("dock") { return "dock.rectangle" }
        if source.contains("prepare") || source.contains("prepar") || source == "eagle" { return "lock.shield.fill" }
        if source.contains("battery") || source.contains("bateria") { return "battery.100percent" }
        if source.contains("font") || source.contains("fuente") { return "textformat" }
        if source.contains("wallpaper") || source.contains("fondo") { return "photo.fill" }
        if source.contains("icon") || source.contains("icono") { return "square.grid.2x2.fill" }
        if source.contains("scene") || source.contains("escena") { return "square.stack.3d.up.fill" }
        if source.contains("aura") { return "sparkles" }
        return "sparkles"
    }
}

/// One visible notification and one cancellable expiry. No polling, network,
/// background work or permanent animation. Only the card intercepts touches.
@MainActor
final class EagleNotifications: ObservableObject {
    static let shared = EagleNotifications()
    @Published private(set) var current: EagleDynamicNotice?
    @Published private(set) var visible = false
    private weak var scene: UIWindowScene?
    private var window: EagleNoticeWindow?
    private var expiry: Task<Void, Never>?
    private var retirement: Task<Void, Never>?
    private var presentation: Task<Void, Never>?
    private var pending: EagleDynamicNotice?
    private var observers: [NSObjectProtocol] = []

    private init() {
        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { _ in
            Task { @MainActor in EagleNotifications.shared.clear() }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                let center = EagleNotifications.shared
                guard let next = center.pending else { return }
                center.pending = nil
                center.schedule(next)
            }
        })
    }

    func attach(to scene: UIWindowScene) {
        self.scene = scene
        if let next = pending, UIApplication.shared.applicationState == .active {
            pending = nil
            schedule(next)
        }
    }

    func show(title: String, message: String, kind: EagleNoticeKind = .information,
              actionTitle: String? = nil, action: (() -> Void)? = nil) {
        let next = EagleDynamicNotice(title: title, message: message, kind: kind,
                                     actionTitle: actionTitle, action: action)
        guard UIApplication.shared.applicationState == .active, scene != nil else {
            pending = next // bounded: retain only the most recent completion
            return
        }
        if visible {
            // Repeated actions replace the current notice without queuing a
            // second entrance animation or delaying the new result.
            presentation?.cancel()
            presentation = nil
            present(next)
        } else {
            schedule(next)
        }
    }

    func result(_ succeeded: Bool, title: String, message: String) {
        show(title: title, message: message, kind: succeeded ? .success : .error)
    }

    private func schedule(_ next: EagleDynamicNotice) {
        presentation?.cancel()
        presentation = Task { [weak self] in
            // Let the triggering control finish its own state transition
            // before the separate Island overlay begins to expand.
            do { try await Task.sleep(nanoseconds: 320_000_000) }
            catch { return }
            guard let self, !Task.isCancelled else { return }
            self.presentation = nil
            guard UIApplication.shared.applicationState == .active else {
                self.pending = next
                return
            }
            self.present(next)
        }
    }

    private func present(_ next: EagleDynamicNotice) {
        guard let scene else { pending = next; return }
        expiry?.cancel()
        retirement?.cancel()
        var incoming = next
        incoming.immediate = current != nil
        if window == nil {
            let overlay = EagleNoticeWindow(windowScene: scene)
            overlay.windowLevel = .normal + 1
            overlay.backgroundColor = .clear
            let controller = UIHostingController(rootView: EagleNoticeOverlay(center: self))
            controller.view.backgroundColor = .clear
            overlay.rootViewController = controller
            window = overlay
        }
        current = incoming
        visible = true
        window?.isHidden = false // deliberately never becomes key window
        let lifetime: UInt64 = UIAccessibility.isVoiceOverRunning ? 12 : (incoming.action != nil ? 9 : (incoming.kind == .error ? 7 : 4))
        expiry = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: (lifetime * 1_000_000_000) + (incoming.immediate ? 0 : 560_000_000)) }
            catch { return }
            guard let self, self.current?.id == incoming.id else { return }
            self.dismiss()
        }
    }

    func hold() { expiry?.cancel(); expiry = nil }

    func dismiss() {
        beginExit()
    }

    private func beginExit() {
        hold()
        guard let id = current?.id, visible else { return }
        visible = false
        window?.hitRegion = .zero
        retirement?.cancel()
        retirement = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 650_000_000) }
            catch { return }
            guard let self, self.current?.id == id else { return }
            self.clear()
        }
    }

    func setHitRegion(_ rect: CGRect) { window?.hitRegion = visible ? rect : .zero }

    private func clear() {
        presentation?.cancel(); presentation = nil
        expiry?.cancel(); expiry = nil
        retirement?.cancel(); retirement = nil
        visible = false
        current = nil
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        pending = nil
    }
}

private final class EagleNoticeWindow: UIWindow {
    var hitRegion = CGRect.zero
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard hitRegion.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

struct EagleNotificationInstaller: UIViewRepresentable {
    final class Probe: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let scene = window?.windowScene {
                EagleNotifications.shared.attach(to: scene)
            }
        }
    }
    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ uiView: Probe, context: Context) {}
}

private struct EagleNoticeOverlay: View {
    @ObservedObject var center: EagleNotifications
    var body: some View {
        GeometryReader { geometry in
            if let notice = center.current {
                EagleNoticeCard(notice: notice, visible: center.visible,
                    layout: EagleNotificationLayout(width: geometry.size.width,
                                                    insetTop: geometry.safeAreaInsets.top),
                    center: center)
                    .id(notice.id)
                    // The source overlay begins at the SCREEN top, not the safe
                    // area. This is what makes the droplet join the actual cutout.
                    .offset(y: -geometry.safeAreaInsets.top)
            }
        }
    }
}

private struct EagleNoticeCard: View {
    let notice: EagleDynamicNotice
    let visible: Bool
    let layout: EagleNotificationLayout
    @ObservedObject var center: EagleNotifications
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var drop: CGFloat = 0
    @State private var expand: CGFloat = 0
    @State private var reveal: CGFloat = 0
    @State private var tint: CGFloat = 0
    @State private var dragY: CGFloat = 0
    @ScaledMetric(relativeTo: .subheadline) private var titleSize: CGFloat = 17
    @ScaledMetric(relativeTo: .footnote) private var messageSize: CGFloat = 14

    private var resolvedLayout: EagleNotificationLayout {
        // Normal type uses the reference's exact 74-point card. Larger type
        // retains readable text rather than clipping accessibility settings.
        EagleNotificationLayout(width: layout.width, insetTop: layout.insetTop,
                                cardHeight: typeSize.isAccessibilitySize ? 132 : 74)
    }

    var body: some View {
        let l = resolvedLayout
        EagleNotificationMorph(layout: l, drop: drop, expand: expand,
                               reveal: reveal, tint: tint, dragY: dragY) {
            HStack(spacing: 12) {
                Image(systemName: notice.sourceSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(notice.kind.color)
                    .frame(width: 46, height: 46)
                    .background(notice.kind.color.opacity(0.16), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(notice.title)
                        .font(.system(size: titleSize, weight: .bold))
                        .tracking(-0.35)
                        .foregroundStyle(.white)
                        .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                    Text(notice.message)
                        .font(.system(size: messageSize, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(typeSize.isAccessibilitySize ? 3 : 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: notice.kind.symbol)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(notice.kind.color)
                    .accessibilityHidden(true)
            }
            .padding(.leading, 13).padding(.trailing, 20)
            .frame(width: l.cardWidth, height: l.cardHeight)
            .background(Color(red: 0.075, green: 0.084, blue: 0.105), in: Capsule())
            .overlay {
                Capsule().strokeBorder(notice.kind.color.opacity(0.38), lineWidth: 1)
            }
            .contentShape(Capsule())
            .onTapGesture {
                center.dismiss()
                notice.action?()
            }
            .gesture(DragGesture(minimumDistance: 8)
                .onChanged { value in
                    dragY = min(24, max(-120, value.translation.height))
                }
                .onEnded { value in
                    if value.translation.height < -18 ||
                        value.predictedEndTranslation.height - value.translation.height < -42 {
                        center.dismiss()
                    } else {
                        withAnimation(EagleReferenceSpring.animation(milliseconds: 560, dampingRatio: 0.7)) {
                            dragY = 0
                        }
                    }
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(notice.title + ". " + notice.message)
            .accessibilityHint(notice.actionTitle ?? LaraL10n.text(en: "Tap to dismiss", es: "Toca para cerrar"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { center.dismiss(); notice.action?() }
        }
        .frame(width: l.width, height: l.canvasHeight, alignment: .topLeading)
        .task(id: visible) {
            if reduceMotion || (visible && notice.immediate) {
                drop = visible ? 1 : 0
                expand = visible ? 1 : 0
                reveal = visible ? 1 : 0
                tint = visible ? 1 : 0
                center.setHitRegion(visible ? l.cardRect : .zero)
                return
            }
            if visible {
                // Source timings: tint 110ms, expansion 340ms, reveal 560ms.
                withAnimation(EagleReferenceSpring.animation(milliseconds: 1_150, dampingRatio: 0.82)) {
                    drop = 1
                }
                do { try await Task.sleep(nanoseconds: 110_000_000) } catch { return }
                withAnimation(EagleReferenceSpring.animation(milliseconds: 700, dampingRatio: 1)) {
                    tint = 1
                }
                do { try await Task.sleep(nanoseconds: 230_000_000) } catch { return }
                withAnimation(EagleReferenceSpring.animation(milliseconds: 1_000, dampingRatio: 0.8)) {
                    expand = 1
                }
                do { try await Task.sleep(nanoseconds: 220_000_000) } catch { return }
                withAnimation(EagleReferenceSpring.animation(milliseconds: 700, dampingRatio: 1)) {
                    reveal = 1
                }
                center.setHitRegion(l.cardRect)
                UIAccessibility.post(notification: .announcement,
                                     argument: notice.title + ". " + notice.message)
            } else {
                // Fade, collapse to a droplet, then pull it back into the island.
                withAnimation(EagleReferenceSpring.animation(milliseconds: 360, dampingRatio: 1)) {
                    reveal = 0
                }
                do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }
                withAnimation(EagleReferenceSpring.animation(milliseconds: 660, dampingRatio: 0.92)) {
                    expand = 0
                }
                do { try await Task.sleep(nanoseconds: 180_000_000) } catch { return }
                withAnimation(EagleReferenceSpring.animation(milliseconds: 1_150, dampingRatio: 0.9)) {
                    drop = 0; tint = 0; dragY = 0
                }
            }
        }
        .onChange(of: l.cardRect) { center.setHitRegion($0) }
    }
}

private struct EagleNoticeModifier<Item: Identifiable>: ViewModifier {
    @Binding var item: Item?
    let title: String
    let message: (Item) -> String
    let kind: (Item) -> EagleNoticeKind
    func body(content: Content) -> some View {
        content.onChange(of: item?.id) { _ in deliver() }.onAppear { deliver() }
    }
    private func deliver() {
        guard let value = item else { return }
        EagleNotifications.shared.show(title: title, message: message(value), kind: kind(value))
        item = nil
    }
}

extension View {
    func eagleNotice<Item: Identifiable>(item: Binding<Item?>, title: String,
        kind: @escaping (Item) -> EagleNoticeKind = { _ in .information },
        message: @escaping (Item) -> String) -> some View {
        modifier(EagleNoticeModifier(item: item, title: title, message: message, kind: kind))
    }
    func eagleStatus(_ status: Binding<String?>, title: String) -> some View {
        onChange(of: status.wrappedValue) { value in
            guard let value else { return }
            EagleNotifications.shared.show(title: title, message: value)
            status.wrappedValue = nil
        }
    }
}
