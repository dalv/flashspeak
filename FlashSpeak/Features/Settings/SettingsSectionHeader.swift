import SwiftUI

/// A Settings section title.
struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .appTextStyle(.sectionLabel)
            .foregroundStyle(DS.Color.inkSecondary)
    }
}
