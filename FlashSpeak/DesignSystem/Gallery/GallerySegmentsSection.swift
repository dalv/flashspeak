import SwiftUI

/// Glass and inline segmented controls.
struct GallerySegmentsSection: View {
    @State private var mode = "Speak"
    @State private var speed = "Slow"
    @State private var register = "Casual"

    var body: some View {
        Section("Segmented controls") {
            SegmentedControl(selection: $mode, options: ["Speak", "Type", "Suggest"], variant: .glass) {
                Text($0)
            }
            .padding(.vertical, DS.Spacing.s)
            .listRowBackground(DS.Color.ground)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Inside a card: never glass")
                    .appTextStyle(.sectionLabel)
                    .foregroundStyle(DS.Color.inkSecondary)
                SegmentedControl(selection: $speed, options: ["Natural", "Slow", "Word by word"], variant: .inline) {
                    Text($0)
                }
                SegmentedControl(selection: $register, options: ["Casual", "Neutral", "Polite"], variant: .inline) {
                    Text($0)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .dsListRows()
        }
    }
}
