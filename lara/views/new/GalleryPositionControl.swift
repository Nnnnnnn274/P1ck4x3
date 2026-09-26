import SwiftUI

struct GalleryFilterItem: Identifiable {
    let id: String
    let title: String
    let icon: String
}

struct GalleryFilterBar: View {
    let items: [GalleryFilterItem]
    let selectedID: String
    let disabled: Bool
    let accessibilityPrefix: String
    let onSelect: (String) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            buttons
            ScrollView(.horizontal, showsIndicators: false) { buttons }
        }
        .disabled(disabled)
    }

    private var buttons: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                let selected = selectedID == item.id
                Button { onSelect(item.id) } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .fixedSize()
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(selected ? Color(uiColor: .systemBackground) : .primary)
                    .background(selected ? Color.primary : .clear, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("\(accessibilityPrefix)-filter-\(item.id)")
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 17))
    }
}

nonisolated struct GalleryPosition: Equatable, Sendable {
    let x: Double
    let y: Double

    static func component(_ value: Double) -> Double {
        value.isFinite ? (min(12, max(-12, value)) * 4).rounded() / 4 : 0
    }

    init(x: Double, y: Double) {
        self.x = Self.component(x)
        self.y = Self.component(y)
    }

    static func saved(_ surface: String) -> Self {
        Self(
            x: UserDefaults.standard.double(
                forKey: "eagle.\(surface)Gallery.positionX"
            ),
            y: UserDefaults.standard.double(
                forKey: "eagle.\(surface)Gallery.positionY"
            )
        )
    }
}

struct GalleryPositionControl: View {
    @Binding var x: Double
    @Binding var y: Double
    var disabled: Bool

    @State private var step = 0.5

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(LaraL10n.text(en: "Position", es: "Posición"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Picker(
                    LaraL10n.text(en: "Step", es: "Paso"),
                    selection: $step
                ) {
                    ForEach([0.25, 0.5, 1.0], id: \.self) { value in
                        Text(value.formatted() + " pt").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                Button {
                    x = 0
                    y = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(LaraL10n.text(
                    en: "Reset position",
                    es: "Restablecer posición"
                ))
                .accessibilityIdentifier("gallery-position-reset")
            }

            HStack(spacing: 12) {
                direction(
                    "arrow.left", dx: -1, dy: 0,
                    en: "Move left", es: "Mover a la izquierda"
                )
                direction(
                    "arrow.up", dx: 0, dy: -1,
                    en: "Move up", es: "Mover hacia arriba"
                )
                direction(
                    "arrow.down", dx: 0, dy: 1,
                    en: "Move down", es: "Mover hacia abajo"
                )
                direction(
                    "arrow.right", dx: 1, dy: 0,
                    en: "Move right", es: "Mover a la derecha"
                )
            }

            Text(
                "X \(GalleryPosition.component(x).formatted()) · " +
                    "Y \(GalleryPosition.component(y).formatted())"
            )
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            Color.primary.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityElement(children: .contain)
    }

    private func direction(
        _ symbol: String,
        dx: Double,
        dy: Double,
        en: String,
        es: String
    ) -> some View {
        Button {
            x = GalleryPosition.component(x + dx * step)
            y = GalleryPosition.component(y + dy * step)
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Color.primary.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .accessibilityLabel(LaraL10n.text(en: en, es: es))
        .accessibilityIdentifier("gallery-position-\(symbol)")
        .disabled(
            (dx != 0 && GalleryPosition.component(x + dx * step) ==
                GalleryPosition.component(x)) ||
            (dy != 0 && GalleryPosition.component(y + dy * step) ==
                GalleryPosition.component(y))
        )
    }
}
