import SwiftUI

struct EagleLaboratoryView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @State private var showingSettings = false

    private var unlocked: Bool {
        EagleFeaturePolicy.allows(
            .advancedSystemTools,
            channel: EagleFeaturePolicy.channel(from: channelRaw)
        )
    }

    var body: some View {
        List {
            if unlocked {
                Section {
                    NavigationLink(destination: ControlCenterThemesView()) {
                        Label(
                            LaraL10n.text(en: "Control Center Accents", es: "Acentos del Centro de control"),
                            systemImage: "square.grid.2x2.fill"
                        )
                    }

                    NavigationLink(destination: OffsetManagementView().environmentObject(manager)) {
                        Label(
                            LaraL10n.text(en: "Modify Offsets", es: "Modificar offsets"),
                            systemImage: "number.square.fill"
                        )
                    }

                    Button {
                        showingSettings = true
                    } label: {
                        Label(
                            LaraL10n.text(en: "Exploit and Kernelcache", es: "Exploit y Kernelcache"),
                            systemImage: "cpu.fill"
                        )
                    }

                    #if !DISABLE_REMOTECALL
                    Button {
                        showingSettings = true
                    } label: {
                        Label("RemoteCall", systemImage: "waveform.path.ecg")
                    }
                    #endif
                } header: {
                    Text(LaraL10n.text(en: "Advanced controls", es: "Controles avanzados"))
                } footer: {
                    Text(LaraL10n.text(
                        en: "Exploit, Kernelcache and RemoteCall controls are in Settings. Opening this page never runs an operation.",
                        es: "Los controles de Exploit, Kernelcache y RemoteCall están en Ajustes. Abrir esta página no ejecuta ninguna operación."
                    ))
                }

                if !manager.dsready {
                    LaraAccessView(compact: true)
                }
            } else {
                Section {
                    NavigationLink(destination: EagleCompatibilityCenterView()) {
                        Label(
                            LaraL10n.text(en: "Choose Laboratory channel", es: "Elige el canal Laboratorio"),
                            systemImage: "flask"
                        )
                    }
                }
            }
        }
        .navigationTitle(LaraL10n.text(en: "Laboratory", es: "Laboratorio"))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(manager)
        }
    }
}
