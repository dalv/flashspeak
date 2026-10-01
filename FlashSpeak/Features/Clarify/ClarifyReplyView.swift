import SwiftUI

/// The reply to a clarification: the explanation, then candidates or a
/// note that the current translation already fits.
struct ClarifyReplyView: View {
    let model: ClarifyModel
    let reply: ClarificationResult
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("You said: “\(model.sentText)”")
                .appTextStyle(.secondary)
                .foregroundStyle(DS.Color.inkSecondary)
            Text(reply.explanation)
                .appTextStyle(.body)
                .foregroundStyle(DS.Color.ink)

            if reply.keepsCurrent {
                PrimaryButton("Keep this translation", action: onDone)
            } else {
                ForEach(Array(reply.candidates.enumerated()), id: \.offset) { _, candidate in
                    ClarifyCandidateCard(
                        english: model.result.english,
                        candidate: candidate,
                        languageCode: model.result.languageCode,
                        onPlay: { model.play(candidate) },
                        onUse: {
                            model.use(candidate)
                            onDone()
                        }
                    )
                }
            }

            Button("Try a different clarification", systemImage: "arrow.counterclockwise", action: model.tryAgain)
                .buttonStyle(.secondary)
                .disabled(model.isLimitReached)
        }
    }
}
