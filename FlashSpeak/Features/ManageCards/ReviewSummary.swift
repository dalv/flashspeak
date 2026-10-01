import SwiftUI

/// When the card is next due and how often it was reviewed.
struct ReviewSummary: View {
    let phrase: Phrase

    var body: some View {
        let reviews = phrase.reviews?.count ?? 0
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            if phrase.hiddenFromReview {
                Text("Hidden from review")
            } else if reviews == 0 {
                Text("New card, not reviewed yet")
            } else {
                Text("Next review \(phrase.nextReviewAt.formatted(.relative(presentation: .named)))")
                Text(reviews == 1 ? "Reviewed once" : "Reviewed \(reviews) times")
            }
            Text("Added \(phrase.createdAt.formatted(date: .abbreviated, time: .omitted))")
        }
        .appTextStyle(.footnote)
        .foregroundStyle(DS.Color.inkSecondary)
        .padding(.top, DS.Spacing.s)
    }
}

#Preview(traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        ForEach(Language.supportedCodes, id: \.self) { code in
            if let phrase = try? dependencies.phrases.phrases(in: code, section: .all, sort: .newest).last {
                ReviewSummary(phrase: phrase)
            }
        }
    }
    .padding(DS.Spacing.screenPadding)
}
