import SwiftUI
import ComposableArchitecture

@main
struct TryTCAApp: App {
    var body: some Scene {
        WindowGroup {
            // 初期状態とReducerをもってStoreを作成する
            // StoreをViewに渡す
            SearchView(
                store: Store(
                    initialState: SearchState(),
                    reducer: SearchReducer()
                )
            )
        }
    }
}
