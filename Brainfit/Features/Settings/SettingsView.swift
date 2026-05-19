import SwiftUI
import UserNotifications

public struct SettingsView: View {
    @State private var reminderEnabled: Bool = UserDefaults.standard.bool(forKey: "reminderEnabled")
    @State private var reminderTime: Date = SettingsView.loadReminderTime()
    @State private var soundEnabled: Bool = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    @State private var iCloudStatus: String = "Sjekker…"

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Synk") {
                    HStack {
                        Image(systemName: "icloud.fill")
                        Text(iCloudStatus)
                    }
                }

                Section("Påminnelse") {
                    Toggle("Daglig påminnelse", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, new in
                            UserDefaults.standard.set(new, forKey: "reminderEnabled")
                            updateNotificationSchedule()
                        }
                    if reminderEnabled {
                        DatePicker("Tidspunkt", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, new in
                                UserDefaults.standard.set(new, forKey: "reminderTime")
                                updateNotificationSchedule()
                            }
                    }
                }

                Section("Lyd") {
                    Toggle("Lyd på", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { _, new in
                            UserDefaults.standard.set(new, forKey: "soundEnabled")
                        }
                }

                Section("Om Brainfit") {
                    LabeledContent("Versjon", value: appVersion)
                    Link("Lisens (MIT)", destination: URL(string: "https://github.com/frodesolem/brainfit-ios/blob/main/LICENSE")!)
                    Link("GitHub", destination: URL(string: "https://github.com/frodesolem/brainfit-ios")!)
                }
            }
            .navigationTitle("Innstillinger")
            .task { await checkICloudStatus() }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private static func loadReminderTime() -> Date {
        UserDefaults.standard.object(forKey: "reminderTime") as? Date
        ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    }

    @MainActor
    private func checkICloudStatus() async {
        // Forenklet — full sjekk ville bruke CKContainer.accountStatus
        iCloudStatus = FileManager.default.ubiquityIdentityToken != nil ? "Logget på iCloud" : "Ikke logget på iCloud"
    }

    private func updateNotificationSchedule() {
        Task {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            guard reminderEnabled else { return }
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Dagens trening venter"
            content.body = "Hold streak'en — start en kort økt nå."
            content.sound = soundEnabled ? .default : nil
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
