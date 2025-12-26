import SwiftUI

@main
struct HabitTrackerApp: App {
    @StateObject private var habitStore = HabitStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .preferredColorScheme(.dark)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
    }
}
