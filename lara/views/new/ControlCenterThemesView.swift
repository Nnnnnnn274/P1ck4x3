import SwiftUI

private enum ControlCenterAccent: Int, CaseIterable, Identifiable {
    case mint = 1
    case ocean = 2
    case rose = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .mint: return LaraL10n.text(en: "Mint", es: "Menta")
        case .ocean: return LaraL10n.text(en: "Ocean", es: "Océano")
        case .rose: return LaraL10n.text(en: "Rose", es: "Rosa")
        }
    }

    var color: Color {
        switch self {
        case .mint: return .green
        case .ocean: return .blue
        case .rose: return .pink
        }
    }
}

private final class ControlCenterRemoteBox: @unchecked Sendable {
    let value: RemoteCall
    init(_ value: RemoteCall) { self.value = value }
}

private struct ControlCenterNativeResult: @unchecked Sendable {
    let count: Int32
    let targetPID: Int32
    let springBoardPID: Int32
    let healthy: Bool
    let timedOut: Bool
    let error: String?
}

private struct ControlCenterThemeResult {
    let succeeded: Bool
    let message: String
}

@MainActor
private final class ControlCenterThemeExecutor {
    static let shared = ControlCenterThemeExecutor()
    private let manager = laramgr.shared

    private init() {}

    func run(_ theme: ControlCenterAccent?) async -> ControlCenterThemeResult {
        let version = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        guard version == 18 else {
            return failure(
                en: "Live Control Center accents currently require iOS 18.",
                es: "Los acentos del Centro de control requieren iOS 18 por ahora."
            )
        }
        guard EagleFeaturePolicy.allows(.controlCenterThemes) else {
            return failure(
                en: "Select the Laboratory channel in Compatibility first.",
                es: "Primero elige el canal Laboratorio en Compatibilidad."
            )
        }
        guard manager.dsready, !manager.rcSafetyLocked, !isdebugged() else {
            return failure(
                en: "Prepare access and open P1ck4x3 from the Home Screen before applying a live accent.",
                es: "Prepara el acceso y abre P1ck4x3 desde Inicio antes de aplicar el acento."
            )
        }

        let preparation: (RemoteCall?, String?) = await withCheckedContinuation { continuation in
            manager.prepareFreshRemoteCall(process: "SpringBoard", timeout: 20) { process, error in
                continuation.resume(returning: (process, error))
            }
        }
        guard let process = preparation.0 else {
            return failure(
                en: "SpringBoard could not be prepared. Nothing changed. \(preparation.1 ?? "")",
                es: "No se pudo preparar SpringBoard. Nada cambió. \(preparation.1 ?? "")"
            )
        }
        let targetPID = process.pid
        guard targetPID > 0,
              targetPID == Self.springBoardPID(),
              process.creatingExtraThread else {
            return failure(
                en: "SpringBoard changed before the accent could be applied.",
                es: "SpringBoard cambió antes de aplicar el acento."
            )
        }

        let label = "Control Center accent \(UUID().uuidString.prefix(8))"
        var ownsSpringBoard = false
        for attempt in 0..<4 {
            guard UIApplication.shared.applicationState == .active else { break }
            if manager.beginExclusiveRemoteCall(
                label: label,
                expectedSession: process
            ) {
                ownsSpringBoard = true
                break
            }
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
        }
        guard ownsSpringBoard else {
            return failure(
                en: "SpringBoard ownership remained busy after a bounded retry. Close Control Center, wait for the current protected operation to finish, and try again.",
                es: "SpringBoard siguió ocupado después de un reintento limitado. Cierra el Centro de control, espera a que termine la operación protegida actual y vuelve a intentarlo."
            )
        }
        let box = ControlCenterRemoteBox(process)
        let mode = Int32(theme?.rawValue ?? 0)
        let response: ControlCenterNativeResult = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let count = autoreleasepool {
                    eagle_set_control_center_accent(box.value, mode)
                }
                continuation.resume(returning: ControlCenterNativeResult(
                    count: count,
                    targetPID: targetPID,
                    springBoardPID: Self.springBoardPID(),
                    healthy: box.value.isHealthy,
                    timedOut: box.value.lastCallTimedOut,
                    error: box.value.lastError
                ))
            }
        }
        manager.endExclusiveRemoteCall(label: label)

        guard response.targetPID == response.springBoardPID,
              response.healthy,
              !response.timedOut,
              response.error?.isEmpty != false else {
            manager.quarantineRemoteCall(
                reason: response.error ?? "Control Center accent transport became unhealthy"
            )
            clearActive()
            return failure(
                en: "The SpringBoard session changed or became unhealthy. Close and reopen P1ck4x3 before retrying.",
                es: "La sesión de SpringBoard cambió o falló. Cierra y reabre P1ck4x3 antes de reintentar."
            )
        }
        guard response.count > 0 else {
            return failure(
                en: "No recognized Control Center module backgrounds were ready (code \(response.count)). Open Control Center once, close it, and try again. Nothing was written to disk.",
                es: "No se encontraron módulos preparados (código \(response.count)). Abre y cierra el Centro de control y reintenta. No se escribió nada en disco."
            )
        }

        if let theme {
            let defaults = UserDefaults.standard
            defaults.set(theme.rawValue, forKey: "eagle.ccAccent.activeTheme")
            defaults.set(Int(response.springBoardPID), forKey: "eagle.ccAccent.activePID")
            return ControlCenterThemeResult(
                succeeded: true,
                message: LaraL10n.text(
                    en: "\(theme.title) accent attached to \(response.count) Control Center modules. Open Control Center to inspect it; a respring clears it.",
                    es: "Acento \(theme.title) añadido a \(response.count) módulos. Abre el Centro de control para verlo; un respring lo elimina."
                )
            )
        }
        clearActive()
        return ControlCenterThemeResult(
            succeeded: true,
            message: LaraL10n.text(
                en: "The live accent layers were removed.",
                es: "Se eliminaron las capas de acento."
            )
        )
    }

    private func clearActive() {
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: "eagle.ccAccent.activeTheme")
        defaults.set(0, forKey: "eagle.ccAccent.activePID")
    }

    private func failure(en: String, es: String) -> ControlCenterThemeResult {
        ControlCenterThemeResult(succeeded: false, message: LaraL10n.text(en: en, es: es))
    }

    nonisolated private static func springBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }
}

struct ControlCenterThemesView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var manager = laramgr.shared
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @AppStorage("eagle.ccAccent.activeTheme") private var activeTheme = 0
    @AppStorage("eagle.ccAccent.activePID") private var activePID = 0
    @State private var isApplying = false
    @State private var notice: String?
    @State private var armedThemeRaw: Int?
    @State private var sawControlCenterCycle = false
    @State private var armToken = UUID()

    private var unlocked: Bool {
        EagleFeaturePolicy.allows(
            .controlCenterThemes,
            channel: EagleFeaturePolicy.channel(from: channelRaw)
        )
    }

    var body: some View {
        List {
            Section {
                Text(LaraL10n.text(
                    en: "Choose a live accent for Control Center module frames. It lasts until SpringBoard restarts and does not change system files.",
                    es: "Elige un acento temporal para los marcos de los módulos. Dura hasta que SpringBoard se reinicie y no cambia archivos del sistema."
                ))
                .font(.subheadline)
                Text(LaraL10n.text(
                    en: "Arm an accent, open and close Control Center, then return here. P1ck4x3 applies automatically after SpringBoard settles. This iOS 18 experiment may respring SpringBoard if the live view changes during Apply.",
                    es: "Prepara un acento, abre y cierra el Centro de control y vuelve aquí. P1ck4x3 lo aplica automáticamente cuando SpringBoard se estabiliza. Este experimento de iOS 18 puede reiniciar SpringBoard si la vista cambia durante Aplicar."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if !manager.dsready {
                LaraAccessView(compact: true)
            }

            if let armedThemeRaw {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(armedInstruction(for: armedThemeRaw))
                            .font(.subheadline)
                    }
                    Button(role: .cancel) {
                        cancelArmedApply()
                    } label: {
                        Text(LaraL10n.text(en: "Cancel Armed Apply", es: "Cancelar aplicación preparada"))
                    }
                } header: {
                    Text(LaraL10n.text(en: "Ready for Control Center", es: "Listo para el Centro de control"))
                }
            }

            ForEach(ControlCenterAccent.allCases) { theme in
                Section {
                    HStack(spacing: 14) {
                        preview(theme)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.title).font(.headline)
                            Text(LaraL10n.text(
                                en: "Colored module outlines",
                                es: "Contornos de módulos coloreados"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if activePID == Int(Self.springBoardPID()),
                           activeTheme == theme.rawValue {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.color)
                        }
                    }
                    Button(LaraL10n.text(en: "Arm \(theme.title)", es: "Preparar \(theme.title)")) {
                        arm(theme)
                    }
                    .disabled(isApplying || armedThemeRaw != nil || !manager.dsready || !unlocked)
                }
            }

            if activeTheme != 0 && activePID == Int(Self.springBoardPID()) {
                Section {
                    Button(role: .destructive) {
                        arm(nil)
                    } label: {
                        Text(LaraL10n.text(en: "Arm Accent Removal", es: "Preparar eliminación del acento"))
                    }
                    .disabled(isApplying || armedThemeRaw != nil || !manager.dsready || !unlocked)
                }
            }
        }
        .navigationTitle(LaraL10n.text(en: "Control Center", es: "Centro de control"))
        .alert(LaraL10n.text(en: "Control Center", es: "Centro de control"),
               isPresented: Binding(
                   get: { notice != nil },
                   set: { if !$0 { notice = nil } }
               )) {
            Button("OK", role: .cancel) { notice = nil }
        } message: {
            Text(notice ?? "")
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhase(phase)
        }
        .onDisappear {
            cancelArmedApply()
        }
    }

    private func preview(_ theme: ControlCenterAccent) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .frame(width: 19, height: 23)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(theme.color.opacity(0.9), lineWidth: 2)
                    }
                    .overlay {
                        Image(systemName: ["wifi", "bluetooth", "moon.fill", "sun.max.fill"][index])
                            .font(.system(size: 8))
                            .foregroundStyle(theme.color)
                    }
            }
        }
        .padding(8)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }

    private func arm(_ theme: ControlCenterAccent?) {
        guard !isApplying, armedThemeRaw == nil else { return }
        let rawValue = theme?.rawValue ?? 0
        let token = UUID()
        armToken = token
        armedThemeRaw = rawValue
        sawControlCenterCycle = false

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard armToken == token, armedThemeRaw != nil else { return }
            cancelArmedApply()
            notice = LaraL10n.text(
                en: "The armed Control Center apply expired without a complete open-and-close cycle.",
                es: "La aplicación preparada caducó sin completar un ciclo de abrir y cerrar el Centro de control."
            )
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard armedThemeRaw != nil else { return }
        switch phase {
        case .inactive:
            sawControlCenterCycle = true
        case .active:
            guard sawControlCenterCycle, let rawValue = armedThemeRaw else { return }
            let theme = ControlCenterAccent(rawValue: rawValue)
            cancelArmedApply()
            Task { @MainActor in
                // Let SpringBoard finish dismissing Control Center before a
                // fresh, PID-verified session claims exclusive ownership.
                try? await Task.sleep(nanoseconds: 650_000_000)
                applyNow(theme)
            }
        case .background:
            break
        @unknown default:
            break
        }
    }

    private func cancelArmedApply() {
        armToken = UUID()
        armedThemeRaw = nil
        sawControlCenterCycle = false
    }

    private func armedInstruction(for rawValue: Int) -> String {
        let action = ControlCenterAccent(rawValue: rawValue)?.title ?? LaraL10n.text(
            en: "removal",
            es: "eliminación"
        )
        return LaraL10n.text(
            en: "\(action) is armed. Open Control Center, then close it and return here. P1ck4x3 will apply automatically after SpringBoard settles.",
            es: "\(action) está preparado. Abre el Centro de control, ciérralo y vuelve aquí. P1ck4x3 lo aplicará automáticamente cuando SpringBoard se estabilice."
        )
    }

    private func applyNow(_ theme: ControlCenterAccent?) {
        guard !isApplying else { return }
        isApplying = true
        Task { @MainActor in
            let result = await ControlCenterThemeExecutor.shared.run(theme)
            isApplying = false
            notice = result.message
        }
    }

    private static func springBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }
}
