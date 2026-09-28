import SwiftUI
import SwiftData

@main
struct PayCalApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    // Create the shared ModelContainer manually so we can access it during App lifecycle events
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: PayCalItem.self)
        } catch {
            fatalError("Failed to create ModelContainer for PayCalItem: \(error.localizedDescription)")
        }
        
        // Request notification permissions on first launch
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "list.bullet")
                    }
                
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
            }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshNotifications()
            }
        }
    }
    
    // Fixed: Fetch items directly from the container context and pass them to the NotificationManager
    private func refreshNotifications() {
        Task {
            let descriptor = FetchDescriptor<PayCalItem>()
            if let items = try? container.mainContext.fetch(descriptor) {
                await NotificationManager.shared.scheduleNotifications(for: items)
            }
        }
    }
}