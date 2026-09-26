import SwiftUI

struct LaraHomeView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @State private var showingSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                P1ckHeader(language: $language) {
                    showingSettings = true
                }

                NavigationLink(destination: AuraStudioView()) {
                    P1ckHeroCard(
                        status: manager.sbxready
                            ? LaraL10n.text(en: "CONNECTED", es: "CONECTADO")
                            : LaraL10n.text(en: "CUSTOMIZATION STUDIO", es: "ESTUDIO DE PERSONALIZACIÓN"),
                        title: LaraL10n.text(en: "Build an iPhone that looks like yours.", es: "Crea un iPhone que se vea como el tuyo."),
                        detail: LaraL10n.text(
                            en: "Start with a full visual scene, then tune every detail.",
                            es: "Empieza con una escena visual completa y luego ajusta cada detalle."
                        )
                    )
                }
                .buttonStyle(.plain)

                P1ckSectionTitle(
                    eyebrow: LaraL10n.text(en: "Toolbox", es: "Caja de herramientas"),
                    title: LaraL10n.text(en: "Pick a surface.", es: "Elige una superficie."),
                    detail: LaraL10n.text(
                        en: "Every card opens a live customization tool — no previews, no placeholders.",
                        es: "Cada tarjeta abre una herramienta de personalización real; sin vistas previas ni marcadores."
                    )
                )

                LazyVGrid(columns: columns, spacing: 12) {
                    P1ckToolTile(
                        title: "Aura Studio",
                        detail: LaraL10n.text(en: "Island and Dock glow", es: "Brillo Island y Dock"),
                        icon: "sparkles",
                        destination: AuraStudioView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Island Gallery", es: "Galería Island"),
                        detail: LaraL10n.text(en: "Dynamic Island styles", es: "Estilos para Dynamic Island"),
                        icon: "capsule.fill",
                        destination: IslandGalleryView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Dock Gallery", es: "Galería Dock"),
                        detail: LaraL10n.text(en: "Artwork for your dock", es: "Arte para tu Dock"),
                        icon: "dock.rectangle",
                        destination: DockGalleryView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Wallpapers", es: "Fondos"),
                        detail: LaraL10n.text(en: "Explore and apply", es: "Explora y aplica"),
                        icon: "photo.on.rectangle.angled",
                        destination: AnimatedWallpapersView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Icon Lab", es: "Laboratorio de iconos"),
                        detail: LaraL10n.text(en: "Light up Home Screen icons", es: "Ilumina los iconos de Inicio"),
                        icon: "app.badge.checkmark",
                        destination: HomeIconNeonView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "App Name Color", es: "Color de nombres"),
                        detail: LaraL10n.text(en: "Color every label", es: "Colorea cada etiqueta"),
                        icon: "textformat",
                        destination: HomeLabelColorView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Passcode", es: "Código"),
                        detail: LaraL10n.text(en: "Restyle the keypad", es: "Rediseña el teclado"),
                        icon: "circle.grid.3x3.fill",
                        destination: PasscodeView(mgr: manager)
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Cards", es: "Tarjetas"),
                        detail: LaraL10n.text(en: "Give Wallet character", es: "Dale carácter a Wallet"),
                        icon: "creditcard.fill",
                        destination: CardView()
                    )

                    P1ckToolTile(
                        title: "Dock",
                        detail: LaraL10n.text(en: "Fit your essentials", es: "Ajusta tus esenciales"),
                        icon: "rectangle.3.group.fill",
                        destination: DockCustomizerView()
                    )

                    P1ckToolTile(
                        title: LaraL10n.text(en: "Full Styles", es: "Estilos completos"),
                        detail: LaraL10n.text(en: "Make a complete look", es: "Crea un aspecto completo"),
                        icon: "wand.and.stars",
                        destination: CompleteStylesView()
                    )
                }

                if EagleFeaturePolicy.allows(
                    .advancedSystemTools,
                    channel: EagleFeaturePolicy.channel(from: channelRaw)
                ) {
                    P1ckSectionTitle(
                        eyebrow: LaraL10n.text(en: "Laboratory", es: "Laboratorio"),
                        title: LaraL10n.text(en: "Advanced tools are unlocked.", es: "Herramientas avanzadas disponibles."),
                        detail: LaraL10n.text(
                            en: "Open offset, kernelcache and RemoteCall controls from one place.",
                            es: "Abre controles de offsets, kernelcache y RemoteCall desde un solo lugar."
                        )
                    )
                    LazyVGrid(columns: columns, spacing: 12) {
                        P1ckToolTile(
                            title: LaraL10n.text(en: "Laboratory", es: "Laboratorio"),
                            detail: LaraL10n.text(en: "Explore advanced controls", es: "Explora controles avanzados"),
                            icon: "flask.fill",
                            destination: EagleLaboratoryView()
                        )
                        P1ckToolTile(
                            title: LaraL10n.text(en: "Control Center", es: "Centro de control"),
                            detail: LaraL10n.text(en: "Live module accents", es: "Acentos temporales para módulos"),
                            icon: "square.grid.2x2.fill",
                            destination: ControlCenterThemesView()
                        )
                    }
                }

                P1ckPanel {
                    HStack(alignment: .center, spacing: 14) {
                        P1ckBrandMark(size: 48)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LaraL10n.text(en: "Your setup, your pace.", es: "Tu configuración, a tu ritmo."))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(LaraL10n.text(
                                en: "Changes only apply when you select them inside a tool.",
                                es: "Los cambios solo se aplican cuando los eliges dentro de una herramienta."
                            ))
                            .font(.caption)
                            .foregroundStyle(P1ckTheme.subdued)
                        }
                    }
                    .padding(16)
                }
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
    }
}

private struct P1ckHeroCard: View {
    let status: String
    let title: String
    let detail: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [P1ckTheme.panelRaised, P1ckTheme.deepGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(P1ckTheme.neon.opacity(0.20))
                .frame(width: 190, height: 190)
                .blur(radius: 9)
                .offset(x: 58, y: -65)

            Image(systemName: "sparkles")
                .font(.system(size: 92, weight: .thin))
                .foregroundStyle(P1ckTheme.mint.opacity(0.20))
                .rotationEffect(.degrees(-10))
                .offset(x: 26, y: 24)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(status)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(P1ckTheme.canvasBottom)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(P1ckTheme.neon, in: Capsule())

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(P1ckTheme.mint)
                        .frame(width: 32, height: 32)
                        .background(.black.opacity(0.18), in: Circle())
                }

                Spacer(minLength: 10)

                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(P1ckTheme.subdued)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(minHeight: 235)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(P1ckTheme.outline, lineWidth: 1)
        }
        .shadow(color: P1ckTheme.neon.opacity(0.16), radius: 20, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct P1ckToolTile<Destination: View>: View {
    let title: String
    let detail: String
    let icon: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(P1ckTheme.canvasBottom)
                        .frame(width: 42, height: 42)
                        .background(P1ckTheme.neon, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(P1ckTheme.mint.opacity(0.85))
                }

                Spacer(minLength: 5)

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(P1ckTheme.subdued)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 166, alignment: .leading)
            .padding(15)
            .background(P1ckTheme.panel, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(P1ckTheme.outline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
