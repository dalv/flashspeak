import SwiftUI

/// Placeholder for screens built in Milestone 3.
struct ComingSoonView: View {
    let route: HomeRoute

    var body: some View {
        ContentUnavailableView {
            Label(route.title, systemImage: route.systemImage)
        } description: {
            Text("This screen is coming in the next milestone.")
                .appTextStyle(.body)
        }
        .foregroundStyle(DS.Color.inkSecondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.ground)
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    NavigationStack {
        ComingSoonView(route: .flashcards)
    }
}
