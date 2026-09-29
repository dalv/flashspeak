import SwiftUI

struct HomeView: View {
    @Binding var navigateToPractice: Bool
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                Text("FlashSpeak")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button(action: cycleLanguage) {
                    HStack(spacing: 8) {
                        Text("\(settings.currentLanguage.flag) \(settings.currentLanguage.name)")
                            .font(.title)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    NavigationLink(destination: NewPhraseView()) {
                        Label("New Phrase", systemImage: "mic.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: PracticeView(), isActive: $navigateToPractice) {
                        Label("Practice", systemImage: "brain.head.profile")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink(destination: ManageCardsView()) {
                            Label("Manage Cards", systemImage: "rectangle.stack")
                        }
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                    }
                }
            }
        }
    }
    private func cycleLanguage() {
        let codes = settings.myLanguageCodes
        guard codes.count > 1,
              let currentIndex = codes.firstIndex(of: settings.currentLanguageCode) else { return }
        let nextIndex = (currentIndex + 1) % codes.count
        if let next = Language.find(byCode: codes[nextIndex]) {
            settings.setCurrentLanguage(next)
        }
    }
}

#Preview {
    HomeView(navigateToPractice: .constant(false))
}
