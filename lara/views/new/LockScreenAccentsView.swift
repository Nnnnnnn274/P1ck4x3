import SwiftUI

private enum LockScreenAccent: Int, CaseIterable, Identifiable {
    case mint = 1
    case ocean = 2
    case rose = 3
    case amber = 4
    case violet = 5
    case cyan = 6
    case sunset = 7

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .mint: return LaraL10n.text(en: "Mint", es: "Menta")
        case .ocean: return LaraL10n.text(en: "Ocean", es: "Océano")
        case .rose: return LaraL10n.text(en: "Rose", es: "Rosa")
        case .amber: return LaraL10n.text(en: "Amber", es: "Ámbar")
        case .violet: return LaraL10n.text(en: "Violet", es: "Violeta")
        case .cyan: return LaraL10n.text(en: "Cyan", es: "Cian")
        case .sunset: return LaraL10n.text(en: "Sunset", es: "Atardecer")
        }
    }

    var color: Color {
        switch self {
        case .mint: return .green
        case .ocean: return .blue
        case .rose: return .pink
        case .amber: return .yellow
        case .violet: return .purple
        case .cyan: return .cyan
        case .sunset: return .orange
        }
    }
}

private final class LockScreenRemoteBox: @unchecked Sendable {
    let value: RemoteCall
    init(_ value: RemoteCall) { self.value = value }
}

private struct LockScreenNativeResult: @unchecked Sendable {
    let count: Int32
    let targetPID: Int32
    let springBoardPID: Int32
    let healthy: Bool
    let timedOut: Bool
    let error: String?
}

private struct LockScreenAccentResult {
    let succeeded: Bool
    let message: String
}

@MainActor
private final class LockScreenAccentExecutor {
    static let shared = LockScreenAccentExecutor()
    private let manager = laramgr.shared

    private init() {}

    func run(_ accent: LockScreenAccent?) async -> LockScreenAccentResult {
        guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 18 else {
            return failure(
                en: "Lock Screen accents currently require iOS 18.",
                es: "Los acentos de pantalla bloqueada requieren iOS 18 por ahora."
            )
        }
        guard EagleFeaturePolicy.allows(.lockScreenAccents) else {
            return failure(
                en: "Select the Laboratory channel in Compatibility first.",
                es: "Primero elige el canal Laboratorio en Compatibilidad."
            )
        }
        guard manager.dsready, !manager.rcSafetyLocked, !isdebugged() else {
            return failure(
                en: "Prepare access and open P1ck4x3 from the Home Screen before applying a Lock Screen accent.",
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
                en: "SpringBoard changed before the Lock Screen accent could be applied.",
                es: "SpringBoard cambió antes de aplicar el acento."
            )
        }

        let label = "Lock Screen accent \(UUID().uuidString.prefix(8))"
        guard manager.beginExclusiveRemoteCall(
            label: label,
            expectedSession: process
        ) else {
            return failure(
                en: "Another protected SpringBoard operation is active. Wait for it to finish and try again.",
                es: "Otra operación protegida de SpringBoard está activa. Espera a que termine y vuelve a intentarlo."
            )
        }

        let box = LockScreenRemoteBox(process)
        let mode = Int32(accent?.rawValue ?? 0)
        let response: LockScreenNativeResult = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let count = autoreleasepool {
                    eagle_set_lock_screen_accent(box.value, mode)
                }
                continuation.resume(returning: LockScreenNativeResult(
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
                reason: response.error ?? "Lock Screen accent transport became unhealthy"
            )
            clearActive()
            return failure(
                en: "The SpringBoard session changed or became unhealthy. Close and reopen P1ck4x3 before retrying.",
                es: "La sesión de SpringBoard cambió o falló. Cierra y reabre P1ck4x3 antes de reintentar."
            )
        }

        if accent == nil, response.count == -5 {
            clearActive()
            return success(
                en: "No P1ck4x3 Lock Screen accent layers remained.",
                es: "No quedaban capas de acento de P1ck4x3 en la pantalla bloqueada."
            )
        }
        guard response.count > 0 else {
            return failure(
                en: "No verified Lock Screen clock or quick-action views were ready (code \(response.count)). Lock and wake the iPhone once, unlock it, then retry. Nothing was changed.",
                es: "No había vistas verificadas del reloj o los accesos rápidos (código \(response.count)). Bloquea y activa el iPhone una vez, desbloquéalo y vuelve a intentarlo. Nada cambió."
            )
        }

        if let accent {
            UserDefaults.standard.set(accent.rawValue, forKey: "eagle.lockAccent.activeTheme")
            UserDefaults.standard.set(Int(response.springBoardPID), forKey: "eagle.lockAccent.activePID")
            return success(
                en: "\(accent.title) was attached to \(response.count) verified Lock Screen surface(s). Lock the iPhone to inspect it; Restore or a respring clears it.",
                es: "\(accent.title) se añadió a \(response.count) superficie(s) verificadas. Bloquea el iPhone para verlo; Restaurar o un respring lo elimina."
            )
        }

        clearActive()
        return success(
            en: "P1ck4x3 Lock Screen accent layers were removed.",
            es: "Se eliminaron las capas de acento de P1ck4x3."
        )
    }

    private func clearActive() {
        UserDefaults.standard.set(0, forKey: "eagle.lockAccent.activeTheme")
        UserDefaults.standard.set(0, forKey: "eagle.lockAccent.activePID")
    }

    private func success(en: String, es: String) -> LockScreenAccentResult {
        LockScreenAccentResult(succeeded: true, message: LaraL10n.text(en: en, es: es))
    }

    private func failure(en: String, es: String) -> LockScreenAccentResult {
        LockScreenAccentResult(succeeded: false, message: LaraL10n.text(en: en, es: es))
    }

    nonisolated private static func springBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }
}

struct LockScreenAccentsView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @AppStorage("eagle.lockAccent.activeTheme") private var activeTheme = 0
    @AppStorage("eagle.lockAccent.activePID") private var activePID = 0
    @State private var isApplying = false
    @State private var notice: String?

    private var unlocked: Bool {
        EagleFeaturePolicy.allows(
            .lockScreenAccents,
            channel: EagleFeaturePolicy.channel(from: channelRaw)
        )
    }

    var body: some View {
        List {
            Section {
                Text(LaraL10n.text(
                    en: "Add a temporary colored frame to verified Lock Screen clock and quick-action surfaces. P1ck4x3 never edits Lock Screen files.",
                    es: "Añade un marco de color temporal al reloj y los accesos rápidos verificados. P1ck4x3 nunca edita archivos de la pantalla bloqueada."
                ))
                .font(.subheadline)
                Text(LaraL10n.text(
                    en: "Lock and wake the iPhone once before applying. Restore removes only P1ck4x3 layers, and a respring clears them automatically.",
                    es: "Bloquea y activa el iPhone una vez antes de aplicar. Restaurar elimina solo las capas de P1ck4x3 y un respring las borra automáticamente."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if !manager.dsready {
                LaraAccessView(compact: true)
            }

            Section {
                lockPreview
            } header: {
                Text(LaraL10n.text(en: "Preview", es: "Vista previa"))
            }

            Section {
                ForEach(LockScreenAccent.allCases) { accent in
                    Button {
                        apply(accent)
                    } label: {
                        HStack {
                            Circle()
                                .fill(accent.color)
                                .frame(width: 22, height: 22)
                            Text(accent.title)
                            Spacer()
                            if activePID == Int(Self.springBoardPID()),
                               activeTheme == accent.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(accent.color)
                            }
                        }
                    }
                    .disabled(isApplying || !manager.dsready || !unlocked)
                }
            } header: {
                Text(LaraL10n.text(en: "Accent color", es: "Color del acento"))
            }

            Section {
                Button(role: .destructive) {
                    apply(nil)
                } label: {
                    Text(LaraL10n.text(en: "Restore Lock Screen", es: "Restaurar pantalla bloqueada"))
                }
                .disabled(isApplying || !manager.dsready || !unlocked)
            } footer: {
                Text(LaraL10n.text(
                    en: "Restore removes only layers named and owned by P1ck4x3.",
                    es: "Restaurar elimina solo las capas identificadas y propiedad de P1ck4x3."
                ))
            }
        }
        .navigationTitle(LaraL10n.text(en: "Lock Screen", es: "Pantalla bloqueada"))
        .alert(LaraL10n.text(en: "Lock Screen", es: "Pantalla bloqueada"),
               isPresented: Binding(
                   get: { notice != nil },
                   set: { if !$0 { notice = nil } }
               )) {
            Button("OK", role: .cancel) { notice = nil }
        } message: {
            Text(notice ?? "")
        }
    }

    private var lockPreview: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .indigo.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 14) {
                Text("9:41")
                    .font(.system(size: 44, weight: .thin, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(previewColor, lineWidth: 2.5)
                    }
                Spacer()
                HStack {
                    previewAction("flashlight.on.fill")
                    Spacer()
                    previewAction("camera.fill")
                }
            }
            .padding(18)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityHidden(true)
    }

    private var previewColor: Color {
        LockScreenAccent(rawValue: activeTheme)?.color ?? .green
    }

    private func previewAction(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(.black.opacity(0.55), in: Circle())
            .overlay { Circle().stroke(previewColor, lineWidth: 2.5) }
    }

    private func apply(_ accent: LockScreenAccent?) {
        guard !isApplying else { return }
        isApplying = true
        Task { @MainActor in
            let result = await LockScreenAccentExecutor.shared.run(accent)
            isApplying = false
            notice = result.message
        }
    }

    private static func springBoardPID() -> Int32 {
        "SpringBoard".withCString { find_process_pid($0) }
    }
}
