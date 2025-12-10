import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var notifications = NotificationManager.shared
    @ObservedObject private var store = StoreManager.shared
    @Query private var phrases: [Phrase]
    
    @State private var showingPaywall = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Auto-Play Audio", isOn: $settings.autoPlayAudio)
            } header: {
                Text("Audio")
            } footer: {
                Text("Automatically speak the Chinese translation when viewing results and practicing flashcards.")
            }
            
            Section {
                Picker("Translation Style", selection: $settings.formality) {
                    Text("Informal").tag("informal")
                    Text("Formal").tag("formal")
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Translation")
            } footer: {
                Text("Informal: Casual, everyday speech.\nFormal: Polite language for professional or respectful contexts.")
            }
            
            Section {
                Toggle("Daily Reminder", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { _, newValue in
                        handleNotificationToggle(newValue)
                    }
                
                if settings.notificationsEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: Binding(
                            get: { settings.notificationTime },
                            set: { newTime in
                                settings.notificationTime = newTime
                                scheduleNotification()
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get a daily reminder to practice with a random phrase from your deck.")
            }
            
            Section {
                if store.isSubscribed {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Pro Member")
                            .font(.headline)
                    }
                } else {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Text("Upgrade to Pro")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button("Restore Purchases") {
                    Task {
                        await store.restorePurchases()
                    }
                }
                .foregroundStyle(.secondary)
            } header: {
                Text("Subscription")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notifications.checkAuthorizationStatus()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notifications.requestPermission()
                if granted {
                    scheduleNotification()
                } else {
                    await MainActor.run {
                        settings.notificationsEnabled = false
                    }
                }
            }
        } else {
            notifications.cancelAll()
        }
    }
    
    private func scheduleNotification() {
        notifications.scheduleDaily(
            at: settings.notificationHour,
            minute: settings.notificationMinute,
            phrases: phrases
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: Phrase.self, inMemory: true)
}
