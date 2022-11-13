import SwiftUI
import ComposableArchitecture

@main
struct TryTCAApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView(
                store: Store(
                    initialState: SearchState(),
                    reducer: SearchReducer()
                )
            )
        }
    }
}
