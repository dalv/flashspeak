import SwiftUI

extension View {
    /// Styles a native `List` as the app's inset-grouped list on `ground`.
    /// Apply `.dsListRows()` to its sections or rows as well.
    func dsGroupedList() -> some View {
        listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.Color.ground)
    }

    /// `surface` row background and app separators, for list sections or rows.
    func dsListRows() -> some View {
        listRowBackground(DS.Color.surface)
            .listRowSeparatorTint(DS.Color.separator)
    }
}
