import SwiftUI

struct HomeView: View {
    @Environment(\.navigateToPractice) private var navigateToPractice
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                Text("FlashSpeak")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("中文")
                    .font(.title)
                    .foregroundStyle(.secondary)
                
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
                    
                    NavigationLink(destination: PracticeView(), isActive: navigateToPractice) {
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
}

#Preview {
    HomeView()
}
