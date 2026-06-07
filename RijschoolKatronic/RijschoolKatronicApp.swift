import SwiftUI

// Startpunt van de iPhone-app.
@main
struct RijschoolKatronicApp: App {
    // Centrale opslag voor leerlingen, lessen en instellingen.
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            // De store wordt gedeeld met alle schermen in de app.
            ContentView()
                .environmentObject(store)
        }
    }
}
