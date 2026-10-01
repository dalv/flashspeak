import SwiftUI

/// Audio recall: setup, the hands-free session, then a summary.
struct AudioRecallScreen: View {
    @State private var model: AudioRecallModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        _model = State(initialValue: AudioRecallModel(dependencies: dependencies))
    }

    init(model: AudioRecallModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            if let session = model.session, !session.isFinished {
                RecallPlayerView(session: session) {
                    model.endSession()
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
                .persistentSystemOverlays(.hidden)
            } else if let session = model.session {
                RecallSummaryView(
                    practised: session.practisedCount,
                    elapsed: session.elapsed,
                    onAgain: { model.start() },
                    onDone: { dismiss() }
                )
            } else {
                RecallSetupView(
                    length: $model.length,
                    setCount: model.setCount,
                    sectionTitle: model.section.title,
                    speed: model.speed,
                    onStart: { model.start() }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SectionMenu(selection: $model.section, sections: model.sections)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.ground)
        .navigationTitle("Audio recall")
        .navigationBarTitleDisplayMode(.inline)
        .languageTheme(model.theme)
        .onAppear { model.refresh() }
        .onDisappear { model.session?.stop() }
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NavigationStack { AudioRecallScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Indonesian, answer", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "id"
    let model = AudioRecallModel(dependencies: dependencies)
    model.refresh()
    model.start(sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
    return NavigationStack { AudioRecallScreen(model: model) }
        .dependencies(dependencies)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ko"
    return NavigationStack { AudioRecallScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ja"
    return NavigationStack { AudioRecallScreen(dependencies: dependencies) }
        .dependencies(dependencies)
        .preferredColorScheme(.dark)
}
