import SwiftUI

enum P1ckTheme {
    static let neon = Color(red: 0.16, green: 0.91, blue: 0.47)
    static let mint = Color(red: 0.52, green: 1.00, blue: 0.72)
    static let deepGreen = Color(red: 0.02, green: 0.20, blue: 0.10)
    static let canvasTop = Color(red: 0.025, green: 0.105, blue: 0.060)
    static let canvasBottom = Color(red: 0.010, green: 0.040, blue: 0.025)
    static let panel = Color(red: 0.055, green: 0.155, blue: 0.092)
    static let panelRaised = Color(red: 0.075, green: 0.215, blue: 0.125)
    static let outline = Color(red: 0.30, green: 0.92, blue: 0.55).opacity(0.24)
    static let subdued = Color(red: 0.69, green: 0.87, blue: 0.75)

    static var canvas: some View {
        LinearGradient(
            colors: [canvasTop, canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

enum P1ckSection {
    case studio
    case access
}

struct EagleAppShellView: View {
    @ObservedObject private var sceneManager = EagleSceneManager.shared
    @State private var selectedSection: P1ckSection = .studio

    var body: some View {
        NavigationStack {
            ZStack {
                P1ckTheme.canvas

                Group {
                    switch selectedSection {
                    case .studio:
                        LaraHomeView()
                    case .access:
                        P1ckAccessView()
                    }
                }
                .transition(.opacity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                P1ckTabBar(selection: $selectedSection)
            }
            .tint(P1ckTheme.neon)
            .toolbar(.hidden, for: .navigationBar)
            .alert(item: $sceneManager.notice) { notice in
                Alert(
                    title: Text("P1CK4X3"),
                    message: Text(notice.message),
                    dismissButton: .default(Text("Got it"))
                )
            }
            .overlay {
                if sceneManager.isApplying {
                    EagleBlockingProgress(
                        title: LaraL10n.text(
                            en: "Applying scene safely",
                            es: "Aplicando escena de forma segura"
                        ),
                        progress: sceneManager.progress
                    )
                }
            }
        }
    }
}

struct P1ckBrandMark: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [P1ckTheme.mint, P1ckTheme.neon, P1ckTheme.deepGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .strokeBorder(.white.opacity(0.30), lineWidth: 1)

            Image(systemName: "hammer.fill")
                .font(.system(size: size * 0.43, weight: .black))
                .foregroundStyle(P1ckTheme.canvasBottom)
                .rotationEffect(.degrees(-43))
                .offset(x: -size * 0.02, y: size * 0.015)

            Circle()
                .fill(.white.opacity(0.78))
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(x: size * 0.26, y: -size * 0.25)
        }
        .frame(width: size, height: size)
        .shadow(color: P1ckTheme.neon.opacity(0.46), radius: size * 0.26)
        .accessibilityHidden(true)
    }
}

struct P1ckHeader: View {
    @Binding var language: LaraLanguage
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            P1ckBrandMark(size: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text("P1CK4X3")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(P1ckTheme.mint)

                Text(LaraL10n.text(en: "MAKE IT YOURS", es: "HAZLO TUYO"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(P1ckTheme.subdued.opacity(0.88))
            }

            Spacer(minLength: 8)

            Menu {
                Picker(
                    LaraL10n.text(en: "Language", es: "Idioma"),
                    selection: $language
                ) {
                    ForEach(LaraLanguage.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
            } label: {
                Text(language.shortName)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(P1ckTheme.mint)
                    .frame(width: 38, height: 38)
                    .background(P1ckTheme.panelRaised, in: Circle())
                    .overlay {
                        Circle().strokeBorder(P1ckTheme.outline, lineWidth: 1)
                    }
            }
            .accessibilityLabel(LaraL10n.text(en: "Language", es: "Idioma"))

            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(P1ckTheme.mint)
                    .frame(width: 42, height: 42)
                    .background(P1ckTheme.panelRaised, in: Circle())
                    .overlay {
                        Circle().strokeBorder(P1ckTheme.outline, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LaraL10n.text(en: "Settings", es: "Ajustes"))
        }
    }
}

struct P1ckSectionTitle: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.45)
                .foregroundStyle(P1ckTheme.neon)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(P1ckTheme.subdued)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct P1ckPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(P1ckTheme.panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(P1ckTheme.outline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
    }
}

struct P1ckTabBar: View {
    @Binding fileprivate var selection: P1ckSection

    var body: some View {
        HStack(spacing: 8) {
            tabButton(section: .studio, title: "Studio", icon: "square.grid.2x2.fill")
            tabButton(section: .access, title: "Access", icon: "shield.checkered")
        }
        .padding(9)
        .background(P1ckTheme.canvasBottom.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(P1ckTheme.outline)
                .frame(height: 1)
        }
    }

    private func tabButton(section: P1ckSection, title: String, icon: String) -> some View {
        let selected = selection == section
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selection = section
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(selected ? P1ckTheme.canvasBottom : P1ckTheme.subdued)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(
                selected ? P1ckTheme.neon : Color.clear,
                in: Capsule()
            )
            .overlay {
                if !selected {
                    Capsule().strokeBorder(P1ckTheme.outline, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct P1ckAccessView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @State private var showingSettings = false
    @State private var showingLogs = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                P1ckHeader(language: $language) {
                    showingSettings = true
                }

                P1ckPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            P1ckSectionTitle(
                                eyebrow: LaraL10n.text(en: "Device access", es: "Acceso al dispositivo"),
                                title: LaraL10n.text(en: "Ready when you are.", es: "Listo cuando tú lo estés."),
                                detail: LaraL10n.text(
                                    en: "Prepare is deliberate, checked, and never runs until you choose it.",
                                    es: "Preparar es deliberado, se verifica y nunca se ejecuta hasta que lo elijas."
                                )
                            )
                            Spacer(minLength: 8)
                            Image(systemName: manager.sbxready ? "checkmark.seal.fill" : "shield.lefthalf.filled")
                                .font(.system(size: 31, weight: .bold))
                                .foregroundStyle(manager.sbxready ? P1ckTheme.neon : P1ckTheme.mint)
                        }

                        LaraAccessView()
                            .tint(P1ckTheme.neon)
                    }
                    .padding(18)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(LaraL10n.text(en: "Control room", es: "Centro de control"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    P1ckPanel {
                        VStack(spacing: 0) {
                            NavigationLink(destination: EagleCompatibilityCenterView()) {
                                P1ckAccessRow(
                                    title: LaraL10n.text(en: "Compatibility", es: "Compatibilidad"),
                                    detail: LaraL10n.text(en: "Check support and feature availability", es: "Comprueba soporte y funciones"),
                                    icon: "checkmark.shield.fill"
                                )
                            }

                            divider

                            NavigationLink(destination: EagleSystemView()) {
                                P1ckAccessRow(
                                    title: LaraL10n.text(en: "System tools", es: "Herramientas del sistema"),
                                    detail: LaraL10n.text(en: "Recovery and protected operations", es: "Recuperación y operaciones protegidas"),
                                    icon: "wrench.and.screwdriver.fill"
                                )
                            }

                            divider

                            if EagleFeaturePolicy.allows(
                                .advancedSystemTools,
                                channel: EagleFeaturePolicy.channel(from: channelRaw)
                            ) {
                                NavigationLink(destination: EagleLaboratoryView()) {
                                    P1ckAccessRow(
                                        title: LaraL10n.text(en: "Laboratory", es: "Laboratorio"),
                                        detail: LaraL10n.text(en: "Offsets, Kernelcache and RemoteCall", es: "Offsets, Kernelcache y RemoteCall"),
                                        icon: "flask.fill"
                                    )
                                }
                                divider
                            }

                            Button {
                                showingLogs = true
                            } label: {
                                P1ckAccessRow(
                                    title: LaraL10n.text(en: "Live activity", es: "Actividad en vivo"),
                                    detail: LaraL10n.text(en: "Open the current log", es: "Abre el registro actual"),
                                    icon: "terminal.fill",
                                    showsChevron: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Label(
                    LaraL10n.text(
                        en: "P1CK4X3 keeps every operation visible. Nothing runs in the background without a tap.",
                        es: "P1CK4X3 mantiene visible cada operación. Nada se ejecuta en segundo plano sin un toque."
                    ),
                    systemImage: "eye.fill"
                )
                .font(.footnote)
                .foregroundStyle(P1ckTheme.subdued)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(manager)
                .tint(P1ckTheme.neon)
        }
        .sheet(isPresented: $showingLogs) {
            LogsView(logger: globallogger)
                .tint(P1ckTheme.neon)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(P1ckTheme.outline)
            .frame(height: 1)
            .padding(.leading, 66)
    }
}

struct P1ckAccessRow: View {
    let title: String
    let detail: String
    let icon: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(P1ckTheme.neon)
                .frame(width: 42, height: 42)
                .background(P1ckTheme.neon.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(P1ckTheme.subdued)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(P1ckTheme.neon)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}
