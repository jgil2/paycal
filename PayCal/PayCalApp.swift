import SwiftUI
import SwiftData

@main
struct PayCalApp: App {
    // Shared SwiftData model container for PayCalItem
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PayCalItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request notification permission and refresh schedule on launch
                    NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.rescheduleAllNotifications(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Refresh local notifications whenever app returns to foreground
                NotificationManager.shared.rescheduleAllNotifications(context: sharedModelContainer.mainContext)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Upcoming", systemImage: "calendar.badge.clock")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
        .accentColor(.emerald)
    }
}
