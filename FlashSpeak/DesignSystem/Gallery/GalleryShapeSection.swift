import SwiftUI

/// Corner radii and spacing steps.
struct GalleryShapeSection: View {
    private let radii: [(String, CGFloat)] = [
        ("cardLarge", DS.Radius.cardLarge),
        ("card", DS.Radius.card),
        ("tile", DS.Radius.tile),
        ("list", DS.Radius.list),
        ("field", DS.Radius.field),
        ("small", DS.Radius.small),
    ]

    private let spacing: [(String, CGFloat)] = [
        ("xxs", DS.Spacing.xxs),
        ("xs", DS.Spacing.xs),
        ("s", DS.Spacing.s),
        ("m", DS.Spacing.m),
        ("l", DS.Spacing.l),
        ("xl", DS.Spacing.xl),
        ("xxl", DS.Spacing.xxl),
    ]

    private let columns = [GridItem(.adaptive(minimum: DS.Size.minTouch * 1.6), spacing: DS.Spacing.s)]

    var body: some View {
        Section("Shape and spacing") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: DS.Spacing.s) {
                ForEach(radii, id: \.0) { name, radius in
                    VStack(spacing: DS.Spacing.xxs) {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(DS.Color.ground)
                            .strokeBorder(DS.Color.hairline, lineWidth: DS.Size.hairlineWidth)
                            .frame(height: DS.Size.minTouch * 1.5)
                        Text(name)
                            .appTextStyle(.caption)
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                }
            }
            .padding(.vertical, DS.Spacing.xs)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                ForEach(spacing, id: \.0) { name, value in
                    HStack(spacing: DS.Spacing.s) {
                        Text(name)
                            .appTextStyle(.caption)
                            .foregroundStyle(DS.Color.inkSecondary)
                            .frame(width: DS.Size.minTouch, alignment: .leading)
                        Capsule()
                            .fill(DS.Color.inkSecondary)
                            .frame(width: value, height: DS.Spacing.xs)
                    }
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
        .dsListRows()
    }
}
