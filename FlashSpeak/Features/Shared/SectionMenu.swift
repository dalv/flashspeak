import SwiftUI

/// A toolbar menu that narrows a review session to one section of the
/// library. `extra` adds items below the section picker.
struct SectionMenu<Extra: View>: View {
    @Binding var selection: PhraseSection
    let sections: [PhraseSection]
    @ViewBuilder var extra: () -> Extra

    init(selection: Binding<PhraseSection>, sections: [PhraseSection], @ViewBuilder extra: @escaping () -> Extra = { EmptyView() }) {
        _selection = selection
        self.sections = sections
        self.extra = extra
    }

    var body: some View {
        Menu("Options", systemImage: "line.3.horizontal.decrease") {
            Picker("Section", selection: $selection) {
                ForEach(sections, id: \.self) { section in
                    Text(section.title).tag(section)
                }
            }
            extra()
        }
        .tint(DS.Color.ink)
    }
}
