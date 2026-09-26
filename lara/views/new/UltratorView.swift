import SwiftUI
import UIKit

private enum UltratorArea: String, CaseIterable, Identifiable {
    case home
    case dock
    case lock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return LaraL10n.text(en: "Home Screen", es: "Pantalla de inicio")
        case .dock: return "Dock"
        case .lock: return LaraL10n.text(en: "Lock Screen", es: "Pantalla bloqueada")
        }
    }

    var symbol: String {
        switch self {
        case .home: return "square.grid.3x3.fill"
        case .dock: return "dock.rectangle"
        case .lock: return "lock.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .home: return .cyan
        case .dock: return .purple
        case .lock: return .pink
        }
    }
}

struct UltratorView: View {
    @AppStorage("eagle.ultrator.selectedArea") private var selectedAreaRaw = UltratorArea.home.rawValue
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @AppStorage("eagle.homeLabelColor.red") private var labelRed = 1.0
    @AppStorage("eagle.homeLabelColor.green") private var labelGreen = 1.0
    @AppStorage("eagle.homeLabelColor.blue") private var labelBlue = 1.0
    @AppStorage("eagle.dock.capacity") private var dockCapacity = 5

    private var labelColor: Color {
        Color(red: labelRed, green: labelGreen, blue: labelBlue)
    }

    private var labelColorBinding: Binding<Color> {
        Binding(
            get: { labelColor },
            set: { newValue in
                let color = UIColor(newValue).resolvedColor(with: .current)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return }
                labelRed = Double(red)
                labelGreen = Double(green)
                labelBlue = Double(blue)
            }
        )
    }

    private var selectedArea: UltratorArea {
        UltratorArea(rawValue: selectedAreaRaw) ?? .home
    }

    private var channel: EagleReleaseChannel {
        EagleFeaturePolicy.channel(from: channelRaw)
    }

    private var verifiedLiveHomeDevice: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return devicemachine() == "iPhone17,1" &&
            version.majorVersion == 18 &&
            version.minorVersion == 6 &&
            version.patchVersion == 2
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                areaPicker
                phonePreview
                editorList
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Ultrator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ultra editor")
                .font(.largeTitle.bold())
            Text(LaraL10n.text(
                en: "Tap a part of the phone or choose an area, then pick what to change.",
                es: "Toca una parte del iPhone o elige una zona y después qué cambiar."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var areaPicker: some View {
        HStack(spacing: 8) {
            ForEach(UltratorArea.allCases) { area in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedAreaRaw = area.rawValue
                    }
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: area.symbol)
                            .font(.title3)
                        Text(area.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selectedArea == area ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(
                        selectedArea == area ? area.color : Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityValue(selectedArea == area
                    ? LaraL10n.text(en: "Selected", es: "Seleccionado") : "")
            }
        }
    }

    private var phonePreview: some View {
        HStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 27)
                    .fill(Color.black)
                    .frame(width: 126, height: 236)
                    .overlay {
                        RoundedRectangle(cornerRadius: 27)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                    }

                VStack(spacing: 0) {
                    Capsule().fill(.white.opacity(0.7))
                        .frame(width: 38, height: 9)
                        .padding(.top, 13)
                    Spacer()
                    if selectedArea == .lock {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("9:41").font(.system(size: 28, weight: .light))
                        Spacer()
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(21), spacing: 6), count: 4), spacing: 8) {
                            ForEach(0..<16, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(index.isMultiple(of: 3) ? Color.cyan.opacity(0.85) : Color.white.opacity(0.72))
                                    .frame(width: 21, height: 21)
                            }
                        }
                        .padding(.horizontal, 13)
                        Text("Apps")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(labelColor)
                            .padding(.top, 5)
                        Spacer()
                        RoundedRectangle(cornerRadius: 11)
                            .fill(.white.opacity(0.27))
                            .frame(width: 108, height: 33)
                            .overlay {
                                HStack(spacing: 4) {
                                    ForEach(0..<max(4, min(6, dockCapacity)), id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(.white.opacity(0.75))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 17)
                                    }
                                }
                                .padding(.horizontal, 7)
                            }
                    }
                    Capsule().fill(.white.opacity(0.8))
                        .frame(width: 38, height: 3)
                        .padding(.vertical, 8)
                }
                .frame(width: 126, height: 236)
                .foregroundStyle(.white)

                RoundedRectangle(cornerRadius: selectedArea == .dock ? 12 : 20)
                    .stroke(selectedArea.color, lineWidth: 3)
                    .frame(
                        width: selectedArea == .dock ? 112 : 122,
                        height: selectedArea == .dock ? 39 : (selectedArea == .lock ? 228 : 164)
                    )
                    .offset(y: selectedArea == .dock ? 84 : (selectedArea == .home ? -12 : 0))
                    .shadow(color: selectedArea.color.opacity(0.8), radius: 8)

                VStack(spacing: 0) {
                    previewTarget(.lock, height: 52)
                    previewTarget(.home, height: 136)
                    previewTarget(.dock, height: 48)
                }
                .frame(width: 126, height: 236)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(selectedArea.title)
                    .font(.title2.bold())
                Text(areaDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(LaraL10n.text(en: "Preview only", es: "Solo vista previa"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selectedArea.color)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22))
    }

    private func previewTarget(_ area: UltratorArea, height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedAreaRaw = area.rawValue
            }
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 126, height: height)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(area.title)
        .accessibilityHint(LaraL10n.text(
            en: "Show this area in Ultrator",
            es: "Mostrar esta parte en Ultrator"
        ))
    }

    private var areaDescription: String {
        switch selectedArea {
        case .home:
            return LaraL10n.text(en: "Wallpaper, app names, and icon glow.", es: "Fondo, nombres y brillo de iconos.")
        case .dock:
            return LaraL10n.text(en: "Layout, artwork, and glow.", es: "Diseño, arte y brillo.")
        case .lock:
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 18 {
                return LaraL10n.text(en: "Wallpaper, passcode, and temporary accents.", es: "Fondo, código y acentos temporales.")
            }
            return LaraL10n.text(en: "Wallpaper and passcode styles.", es: "Fondos y estilos del código.")
        }
    }

    @ViewBuilder
    private var editorList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LaraL10n.text(en: "Edit this part", es: "Editar esta parte"))
                .font(.headline)

            switch selectedArea {
            case .home:
                editorLink("Wallpapers", es: "Fondos", detail: "Choose or create", detailES: "Elegir o crear", symbol: "photo.fill", color: .blue) {
                    AnimatedWallpapersView()
                }
                if EagleFeaturePolicy.allows(.homeIconNeon, channel: channel) {
                    editorLink("Icon glow", es: "Brillo de iconos", detail: "Glow and outline", detailES: "Brillo y contorno", symbol: "sparkle.square.fill", color: .cyan) {
                        HomeIconNeonView()
                    }
                }
                if EagleFeaturePolicy.allows(.homeLabelColor, channel: channel) {
                    VStack(alignment: .leading, spacing: 10) {
                        ColorPicker(
                            LaraL10n.text(en: "App name color", es: "Color de nombres"),
                            selection: labelColorBinding,
                            supportsOpacity: false
                        )
                        Text(LaraL10n.text(
                            en: "Draft color saved. Open App name color to preview and apply it.",
                            es: "Color guardado. Abre Color de nombres para verlo y aplicarlo."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 16))
                    editorLink("App name color", es: "Color de nombres", detail: "Home Screen labels", detailES: "Nombres en Inicio", symbol: "textformat", color: .purple) {
                        HomeLabelColorView()
                    }
                } else {
                    channelPrompt(
                        en: "Choose Advanced for icon glow and app name color",
                        es: "Elige Avanzado para el brillo y color de nombres"
                    )
                }
                if EagleFeaturePolicy.allows(.homeIconNeon, channel: channel),
                   !verifiedLiveHomeDevice {
                    Label(
                        LaraL10n.text(
                            en: "Live icon and app name effects are verified on iPhone 16 Pro with iOS 18.6.2. Their editors check support before applying.",
                            es: "Los efectos en vivo de iconos y nombres están verificados en iPhone 16 Pro con iOS 18.6.2. Los editores comprueban la compatibilidad antes de aplicar."
                        ),
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                }
            case .dock:
                VStack(alignment: .leading, spacing: 10) {
                    Picker(
                        LaraL10n.text(en: "Dock capacity", es: "Capacidad del Dock"),
                        selection: $dockCapacity
                    ) {
                        ForEach([4, 5, 6], id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(LaraL10n.text(
                        en: "Draft layout saved. Open Dock layout to apply or restore it.",
                        es: "Diseño guardado. Abre Diseño del Dock para aplicarlo o restaurarlo."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 16))
                editorLink("Dock layout", es: "Diseño del Dock", detail: "Fit up to six apps", detailES: "Hasta seis apps", symbol: "dock.rectangle", color: .blue) {
                    DockCustomizerView()
                }
                editorLink("Dock artwork", es: "Arte del Dock", detail: "Choose a gallery style", detailES: "Elegir un estilo", symbol: "photo.artframe", color: .pink) {
                    DockGalleryView()
                }
                editorLink("Dock glow", es: "Brillo del Dock", detail: "Choose Dock in Aura Studio", detailES: "Elige Dock en Aura Studio", symbol: "sparkles", color: .purple) {
                    AuraStudioView()
                }
            case .lock:
                editorLink("Wallpapers", es: "Fondos", detail: "Choose or create", detailES: "Elegir o crear", symbol: "photo.fill", color: .blue) {
                    AnimatedWallpapersView()
                }
                editorLink("Passcode", es: "Código", detail: "Unlock key styles", detailES: "Números de desbloqueo", symbol: "circle.grid.3x3.fill", color: .purple) {
                    PasscodeView(mgr: laramgr.shared)
                }
                if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 18,
                   EagleFeaturePolicy.allows(.lockScreenAccents, channel: channel) {
                    editorLink("Lock Screen accents", es: "Acentos de bloqueo", detail: "Temporary clock and quick-action frames", detailES: "Marcos temporales", symbol: "lock.square.fill", color: .pink) {
                        LockScreenAccentsView()
                    }
                }
            }

            if selectedArea == .lock,
               ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 18,
               !EagleFeaturePolicy.allows(.lockScreenAccents, channel: channel) {
                channelPrompt(
                    en: "Choose Laboratory for live accents",
                    es: "Elige Laboratorio para acentos en vivo"
                )
            }
        }
    }

    private func channelPrompt(en: String, es: String) -> some View {
        NavigationLink(destination: EagleCompatibilityCenterView()) {
            Label(LaraL10n.text(en: en, es: es), systemImage: "flask")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16))
    }

    private func editorLink<Destination: View>(
        _ title: String,
        es: String,
        detail: String,
        detailES: String,
        symbol: String,
        color: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 38, height: 38)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text(LaraL10n.text(en: title, es: es))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(LaraL10n.text(en: detail, es: detailES))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
