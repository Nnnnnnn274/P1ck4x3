import SwiftUI
import UIKit

struct NotificationStudioView: View {
    @AppStorage("eagle.notice.red") private var red = 0.43
    @AppStorage("eagle.notice.green") private var green = 0.71
    @AppStorage("eagle.notice.blue") private var blue = 1.0

    private var accent: Color {
        Color(red: red, green: green, blue: blue)
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { accent },
            set: { selected in
                let color = UIColor(selected).resolvedColor(with: .current)
                var r: CGFloat = 0
                var g: CGFloat = 0
                var b: CGFloat = 0
                var a: CGFloat = 0
                guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
                red = Double(r)
                green = Double(g)
                blue = Double(b)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(LaraL10n.text(en: "Notification color", es: "Color de avisos"))
                        .font(.title2.bold())
                    Text(LaraL10n.text(
                        en: "Choose the accent for P1ck4x3 information alerts. Success and error colors stay recognizable.",
                        es: "Elige el color de los avisos informativos de P1ck4x3. Los colores de éxito y error conservan su significado."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundStyle(accent)
                        .frame(width: 44, height: 44)
                        .background(accent.opacity(0.16), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("P1ck4x3")
                            .font(.headline)
                        Text(LaraL10n.text(en: "Your preview alert", es: "Vista previa del aviso"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(accent.opacity(0.6), lineWidth: 1.5)
                }

                ColorPicker(
                    LaraL10n.text(en: "Information accent", es: "Acento informativo"),
                    selection: accentBinding,
                    supportsOpacity: false
                )
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 12) {
                    preset("Sky", color: Color(red: 0.43, green: 0.71, blue: 1.0),
                           values: (0.43, 0.71, 1.0))
                    preset("Mint", color: .mint, values: (0.36, 0.88, 0.67))
                    preset("Violet", color: .purple, values: (0.65, 0.45, 0.96))
                    preset("Rose", color: .pink, values: (0.98, 0.40, 0.65))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 6)

                Button {
                    EagleNotifications.shared.show(
                        title: "P1ck4x3",
                        message: LaraL10n.text(
                            en: "This is your new alert color.",
                            es: "Este es tu nuevo color de aviso."
                        ),
                        kind: .information
                    )
                } label: {
                    Label(LaraL10n.text(en: "Try alert", es: "Probar aviso"),
                          systemImage: "bell.badge.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                }
                .buttonStyle(.borderedProminent)

                Text(LaraL10n.text(
                    en: "This changes alerts inside P1ck4x3. System notification banners are not changed.",
                    es: "Esto cambia los avisos dentro de P1ck4x3. No modifica los banners de notificaciones del sistema."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(LaraL10n.text(en: "Notifications", es: "Notificaciones"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func preset(
        _ name: String,
        color: Color,
        values: (Double, Double, Double)
    ) -> some View {
        Button {
            red = values.0
            green = values.1
            blue = values.2
        } label: {
            Circle()
                .fill(color)
                .frame(width: 38, height: 38)
                .overlay { Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }
}
