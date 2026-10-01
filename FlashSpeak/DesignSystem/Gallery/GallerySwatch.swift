import SwiftUI

/// A colour sample with its token name.
struct GallerySwatch: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                .fill(color)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .strokeBorder(DS.Color.hairline, lineWidth: DS.Size.hairlineWidth)
                }
                .frame(height: DS.Size.minTouch)
            Text(name)
                .appTextStyle(.caption)
                .foregroundStyle(DS.Color.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }
}
