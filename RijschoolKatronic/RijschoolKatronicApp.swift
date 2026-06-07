// Laadt SwiftUI voor schermen, knoppen, formulieren en navigatie.
import SwiftUI

// Startpunt van de iPhone-app.
// Startpunt van de app.
@main
// App-container die de gedeelde data aan alle schermen geeft.
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
