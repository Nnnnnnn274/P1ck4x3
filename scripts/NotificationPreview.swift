// Isolated simulator harness: never loads Eagle's access/runtime engines.
import SwiftUI
import UIKit

enum LaraL10n {
    static func text(en: String, es: String) -> String { es }
}

@main
struct NotificationPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            if let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--phase=") }),
               let phase = Double(argument.dropFirst(8)) {
                FrozenMorphScreen(phase: phase)
            } else {
                PreviewScreen()
                    .background(EagleNotificationInstaller().frame(width: 0, height: 0))
                    .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("--light") ? .light : .dark)
            }
        }
    }
}

struct PreviewScreen: View {
    @State private var taps = 0
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles").font(.system(size: 46))
                Text("EAGLE").font(.largeTitle.weight(.bold))
                Text("Notificaciones dinámicas").foregroundStyle(.secondary)
                Button("Island aplicada") {
                    EagleNotifications.shared.result(true, title: "Island Gallery", message: "Tema aplicado correctamente")
                }.buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                Button("Mostrar error") {
                    EagleNotifications.shared.result(false, title: "No se pudo aplicar", message: "El tema anterior se conservó. Toca para leer los detalles completos del resultado sin perder el estado de la pantalla.")
                }
                Button("Control de fondo: \(taps)") { taps += 1 }
                Spacer()
            }
            .padding(.top, 120)
            .frame(maxWidth: .infinity)
            .navigationTitle("Eagle")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await verifyNotifications() }
    }

    @MainActor
    private func verifyNotifications() async {
        verifyGeometry()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let center = EagleNotifications.shared
        for _ in 0..<100 {
            if UIApplication.shared.applicationState == .active { break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        if ProcessInfo.processInfo.arguments.contains("--demo") {
            center.result(true, title: "Island Gallery", message: "Tema aplicado correctamente")
            try? await Task.sleep(nanoseconds: 400_000_000)
            center.hold()
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--demo-error") {
            center.result(false, title: "Dock Gallery", message: "El tema no se aplicó. Se conservó el anterior.")
            try? await Task.sleep(nanoseconds: 400_000_000)
            center.hold()
            return
        }
        center.show(title: "First", message: "First")
        try? await Task.sleep(nanoseconds: 400_000_000)
        let first = center.current?.id
        assert(first != nil, "preview is not active")
        center.result(false, title: "Second", message: "Failed")
        assert(center.current?.id != first && center.visible, "replacement must appear immediately")
        for index in 0..<12 {
            center.result(index.isMultiple(of: 2), title: "Repeat \(index)", message: "Updated")
            assert(center.current?.title == "Repeat \(index)" && center.visible,
                   "repeated result waited for the previous animation")
        }
        center.result(false, title: "Second", message: "Failed")
        print("Instant replacement: \(center.current?.title ?? "nil"), visible: \(center.visible)")
        fflush(stdout)
        assert(center.current?.kind == .error)
        center.dismiss()
        center.result(true, title: "Third", message: "Applied")
        try? await Task.sleep(nanoseconds: 500_000_000)
        assert(center.current?.title == "Third", "stale dismiss removed replacement")
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let overlay = scene.windows.first(where: { String(describing: type(of: $0)).contains("EagleNoticeWindow") }) else {
            fatalError("notification window missing")
        }
        assert(!overlay.isKeyWindow, "notification stole key-window focus")
        assert(overlay.hitTest(CGPoint(x: 5, y: overlay.bounds.height - 100), with: nil) == nil,
               "notification blocks controls outside card")
        assert(overlay.hitTest(CGPoint(x: overlay.bounds.midX, y: overlay.safeAreaInsets.top + 44), with: nil) != nil,
               "notification card cannot be tapped")
        center.hold()
        try? await Task.sleep(nanoseconds: 4_500_000_000)
        assert(center.current?.title == "Third", "reading details did not cancel expiry")
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
        assert(center.current == nil && !center.visible, "background notification retained")
        assert(!scene.windows.contains(where: { String(describing: type(of: $0)).contains("EagleNoticeWindow") && !$0.isHidden }),
               "background overlay remained visible")
        center.result(true, title: "Expires", message: "Auto dismiss")
        try? await Task.sleep(nanoseconds: 7_500_000_000)
        print("Expiry: \(center.current?.title ?? "nil"), visible: \(center.visible)")
        fflush(stdout)
        assert(center.current == nil, "notification failed to expire")
        print("PASS: notification replacement, cancellation, hold, expiry, background teardown and touch passthrough")
        fflush(stdout)
        center.result(true, title: "Island Gallery", message: "Tema aplicado correctamente")
        try? await Task.sleep(nanoseconds: 400_000_000)
        center.hold()
    }

    private func verifyGeometry() {
        let l = EagleNotificationLayout(width: 402, insetTop: 62)
        assert(l.cardRect == CGRect(x: 16, y: 85, width: 370, height: 74))
        // Independently evaluated from the TypeScript reference equations.
        let samples: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.35, 0, 189.87778617264144, 47.185512895325175, 22.244427654717146, 40.82911420934965, 20.76911986496389),
            (0.7, 0.2, 146.05433388485477, 65.38401227206606, 109.89133223029044, 63.01665545586788, 25.113823845652377),
            (1, 1, 16, 85, 370, 74, 0)
        ]
        for (d, e, x, y, w, h, n) in samples {
            let g = EagleNotificationGeometry(drop: d, expand: e, layout: l)
            for (actual, expected) in zip([g.rect.minX, g.rect.minY, g.rect.width, g.rect.height, g.neck.width], [x,y,w,h,n]) {
                assert(abs(actual - expected) < 0.000001, "reference geometry diverged")
            }
        }
        for width: CGFloat in [320, 375, 393, 402, 430, 440, 1024] {
            for inset: CGFloat in [0, 20, 44, 59, 62] {
                let layout = EagleNotificationLayout(width: width, insetTop: inset)
                for step in 0...105 {
                    let p = CGFloat(step) / 100
                    let g = EagleNotificationGeometry(drop: p, expand: p, layout: layout)
                    assert(g.rect.minX.isFinite && g.rect.minY.isFinite && g.radius.isFinite)
                    assert(g.rect.width >= 0 && g.rect.width <= width - 20)
                    assert(g.radius >= 0 && g.radius <= min(g.rect.width, g.rect.height) / 2)
                }
            }
        }
        print("PASS: TypeScript geometry parity and 3,710 width/inset/spring samples")
        fflush(stdout)
    }
}

struct FrozenMorphScreen: View {
    let phase: CGFloat
    var body: some View {
        GeometryReader { geometry in
            let l = EagleNotificationLayout(width: geometry.size.width,
                                             insetTop: geometry.safeAreaInsets.top)
            ZStack(alignment: .topLeading) {
                Color(red: 0.76, green: 0.82, blue: 0.90).ignoresSafeArea()
                Text("Eagle · original morph geometry").padding(.top, 260).padding(.horizontal)
                EagleNotificationMorph(layout: l, drop: phase,
                    expand: max(0, (phase - 0.4) / 0.6),
                    reveal: max(0, (phase - 0.6) / 0.4), tint: phase, dragY: 0) {
                    HStack {
                        Circle().fill(.gray.opacity(0.2)).frame(width: 46, height: 46)
                        VStack(alignment: .leading) {
                            Text("Island Gallery").foregroundStyle(.blue).bold()
                            Text("Tema aplicado correctamente").font(.caption).foregroundStyle(.gray)
                        }
                        Spacer()
                        Image(systemName: "checkmark").foregroundStyle(.blue)
                    }.padding(.horizontal, 16).frame(width: l.cardWidth, height: 74)
                }
                .offset(y: -geometry.safeAreaInsets.top)
            }
        }
    }
}
