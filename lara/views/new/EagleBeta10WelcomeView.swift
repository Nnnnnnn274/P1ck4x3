import SwiftUI

struct EagleBeta10WelcomeView: View {
    let onContinue: () -> Void

    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @Environment(\.colorScheme) private var colorScheme

    private var support: EagleSupportAssessment {
        eagleSupportAssessment()
    }

    private var deviceName: String {
        EagleDeviceIdentity.displayName(for: devicemachine())
    }

    private var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return [version.majorVersion, version.minorVersion, version.patchVersion]
            .map(String.init)
            .joined(separator: ".")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    currentDeviceCard
                    updatesCard
                    fixesCard
                    compatibilityCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background {
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    LinearGradient(
                        colors: [Color.primary.opacity(0.025), .clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                }
                .ignoresSafeArea()
            }
            .navigationTitle(LaraL10n.text(en: "Updates", es: "Actualizaciones"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Text(LaraL10n.text(en: "Continue", es: "Continuar"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(EagleVisualTheme.actionFill)
                .foregroundStyle(EagleVisualTheme.actionText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .overlay(alignment: .top) {
                    Divider().opacity(0.32)
                }
            }
        }
        .interactiveDismissDisabled(true)
        .environment(\.locale, language.locale)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))

            LinearGradient(
                colors: [Color.primary.opacity(0.055), .clear, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                EagleWordmark(logoSize: 58, nameSize: 34, spacing: 12)

                Text(LaraL10n.text(
                    en: "A more polished Eagle.",
                    es: "Una Eagle más pulida."
                ))
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.10")  •  \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "97")")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(EagleVisualTheme.secondaryText(for: colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.primary.opacity(0.065), in: Capsule())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 18, y: 8)
    }

    private var currentDeviceCard: some View {
        welcomeCard {
            HStack(spacing: 13) {
                Image(systemName: supportSymbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(supportColor)
                    .frame(width: 42, height: 42)
                    .background(supportColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(LaraL10n.text(en: "This device", es: "Este dispositivo"))
                                .font(.headline)
                                .fixedSize()
                            Spacer(minLength: 8)
                            supportBadge
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LaraL10n.text(en: "This device", es: "Este dispositivo"))
                                .font(.headline)
                            supportBadge
                        }
                    }

                    Text("\(deviceName) · iOS \(systemVersion)")
                        .font(.subheadline.weight(.medium))

                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var supportBadge: some View {
        Text(supportTitle)
            .font(.caption.weight(.bold))
            .foregroundStyle(supportColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(supportColor.opacity(0.13), in: Capsule())
            .fixedSize()
    }

    private var updatesCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "What’s new", es: "Novedades"),
                systemImage: "sparkles",
                color: .primary
            )

            welcomeRow(
                icon: "play.rectangle.on.rectangle.fill",
                color: .primary,
                title: LaraL10n.text(en: "Living previews", es: "Previews con vida"),
                detail: LaraL10n.text(
                    en: "Photos, GIFs and videos now enter smoothly and keep their correct framing.",
                    es: "Fotos, GIFs y videos aparecen con fluidez y mantienen el encuadre correcto."
                )
            )

            welcomeRow(
                icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                color: .primary,
                title: LaraL10n.text(en: "Gallery motion", es: "Movimiento en Gallery"),
                detail: LaraL10n.text(
                    en: "New swipe, selection and favorite animations in Island and Dock Gallery.",
                    es: "Nuevas animaciones al deslizar, seleccionar y guardar en Island y Dock Gallery."
                )
            )

            welcomeRow(
                icon: "move.3d",
                color: .primary,
                title: LaraL10n.text(en: "Precise placement", es: "Posición precisa"),
                detail: LaraL10n.text(
                    en: "Move Island and Dock artwork in quarter-point steps and restore it instantly.",
                    es: "Mueve el arte de Island y Dock en pasos de un cuarto de punto y restáuralo al instante."
                )
            )

            welcomeRow(
                icon: "bell.and.waves.left.and.right.fill",
                color: .primary,
                title: LaraL10n.text(en: "Eagle notifications", es: "Notificaciones de Eagle"),
                detail: LaraL10n.text(
                    en: "Results appear after each action without shifting the screen.",
                    es: "Los resultados aparecen después de cada acción sin mover la pantalla."
                )
            )

            welcomeRow(
                icon: "rectangle.bottomthird.inset.filled",
                color: .primary,
                title: LaraL10n.text(en: "Clearer navigation", es: "Navegación más clara"),
                detail: LaraL10n.text(
                    en: "A translucent tab bar, monochrome controls and a smoother Ready transition.",
                    es: "Barra translúcida, controles monocromáticos y transición más suave a Listo."
                )
            )
        }
    }

    private var fixesCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Corrections", es: "Correcciones"),
                systemImage: "checkmark.shield",
                color: .primary
            )

            welcomeRow(
                icon: "checkmark.shield.fill",
                color: .green,
                title: LaraL10n.text(en: "Public engines preserved", es: "Motores públicos conservados"),
                detail: LaraL10n.text(
                    en: "Prepare, theme Apply, Hide Dock and Aura keep their established execution paths.",
                    es: "Prepare, Aplicar temas, Hide Dock y Aura conservan sus rutas de ejecución establecidas."
                )
            )

            welcomeRow(
                icon: "photo.on.rectangle.angled",
                color: .primary,
                title: LaraL10n.text(en: "Reliable media", es: "Contenido confiable"),
                detail: LaraL10n.text(
                    en: "Previews no longer reuse the previous image and stop cleanly in the background.",
                    es: "Los previews ya no reutilizan la imagen anterior y se detienen correctamente en segundo plano."
                )
            )

            welcomeRow(
                icon: "figure.walk.motion",
                color: .primary,
                title: LaraL10n.text(en: "Efficient animation", es: "Animación eficiente"),
                detail: LaraL10n.text(
                    en: "Only the featured preview moves; grids remain light and Reduce Motion is respected.",
                    es: "Solo se mueve el preview destacado; las cuadrículas siguen ligeras y se respeta Reducir movimiento."
                )
            )

            welcomeRow(
                icon: "iphone.gen3",
                color: .primary,
                title: LaraL10n.text(en: "Model alignment", es: "Alineación por modelo"),
                detail: LaraL10n.text(
                    en: "Island alignment remains corrected for iPhone 15 Pro Max and iPhone 16.",
                    es: "La alineación de Island mantiene su corrección para iPhone 15 Pro Max y iPhone 16."
                )
            )

            welcomeRow(
                icon: "slider.horizontal.3",
                color: .primary,
                title: LaraL10n.text(en: "Focused tools", es: "Herramientas ordenadas"),
                detail: LaraL10n.text(
                    en: "Settings and Laboratory Tools now have distinct roles; three unsuitable Island styles were removed from that gallery.",
                    es: "Ajustes y Laboratory Tools tienen funciones distintas; se retiraron tres estilos inadecuados de Island Gallery."
                )
            )

            welcomeRow(
                icon: "creditcard.fill",
                color: .primary,
                title: LaraL10n.text(en: "Readable Card controls", es: "Botones legibles en Tarjetas"),
                detail: LaraL10n.text(
                    en: "Light action buttons now use dark text; matching contrast was corrected in related controls.",
                    es: "Los botones claros ahora usan texto oscuro; se corrigió el contraste en controles relacionados."
                )
            )
        }
    }

    private var compatibilityCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Compatibility", es: "Compatibilidad"),
                systemImage: "checkmark.shield.fill",
                color: .green
            )

            compatibilityRow(
                status: LaraL10n.text(en: "Limited test", es: "Prueba limitada"),
                range: "iOS 16.7.2",
                color: .orange
            )
            compatibilityRow(
                status: LaraL10n.text(en: "Supported", es: "Compatible"),
                range: "iOS 17.0 – iOS 18.7.1",
                color: .green
            )
            compatibilityRow(
                status: LaraL10n.text(en: "Supported", es: "Compatible"),
                range: "iOS 26.0 – iOS 26.0.1",
                color: .green
            )

            Divider()

            Label {
                Text(LaraL10n.text(
                    en: "Availability still follows Eagle’s verified device and iOS matrix.",
                    es: "La disponibilidad sigue la matriz verificada de dispositivos e iOS de Eagle."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "shield.checkered")
                    .foregroundStyle(EagleVisualTheme.accent)
            }
        }
    }

    private var referenceDeviceCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Reference device", es: "Dispositivo de referencia"),
                systemImage: "iphone.gen3",
                color: .cyan
            )

            Text("iPhone 16 Pro · iOS 18.6.2 (22G100)")
                .font(.headline)

            Text(LaraL10n.text(
                en: "Physical reference for development. Results can vary by device and iOS version.",
                es: "Referencia física de desarrollo. Los resultados pueden variar según el dispositivo y la versión de iOS."
            ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var safetyNote: some View {
        Label {
            Text(LaraL10n.text(
                en: "Back up important data, apply one feature at a time, and stop after any reboot, timeout, or protected-call error. You can review compatibility again from Eagle Home.",
                es: "Respalda tus datos importantes, aplica una función a la vez y detente ante cualquier reinicio, espera agotada o error de llamada protegida. Puedes volver a revisar la compatibilidad desde Inicio."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 4)
    }

    private func welcomeCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 12, y: 5)
    }

    private func welcomeSectionTitle(
        _ title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }

    private func welcomeRow(
        icon: String,
        color: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(.primary.opacity(0.065), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func compatibilityRow(
        status: String,
        range: String,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .accessibilityHidden(true)
            Text(range)
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 8)
            Text(status)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }

    private var supportTitle: String {
        switch support.status {
        case .possible:
            return LaraL10n.text(en: "LIMITED TEST", es: "PRUEBA LIMITADA")
        case .testedNeedsMoreTesting:
            return LaraL10n.text(en: "LIMITED TEST", es: "PRUEBA LIMITADA")
        case .supported:
            return LaraL10n.text(en: "SUPPORTED", es: "COMPATIBLE")
        case .unsupported:
            return LaraL10n.text(en: "BLOCKED", es: "BLOQUEADO")
        }
    }

    private var supportColor: Color {
        switch support.status {
        case .possible, .testedNeedsMoreTesting: return .orange
        case .supported: return .green
        case .unsupported: return .red
        }
    }

    private var supportSymbol: String {
        switch support.status {
        case .possible, .testedNeedsMoreTesting: return "exclamationmark.shield.fill"
        case .supported: return "checkmark.shield.fill"
        case .unsupported: return "xmark.shield.fill"
        }
    }
}

#Preview {
    EagleBeta10WelcomeView(onContinue: {})
}
