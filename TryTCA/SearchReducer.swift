// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/SearchView.swift
// より引用

import ComposableArchitecture

struct SearchReducer: ReducerProtocol {
    
    /// 天気APIクライアント
    /// TCAの依存管理システムを使って依存するインスタンスを渡している
    @Dependency(\.weatherClient) var weatherClient
    
    
    /// 地名検索を中断するときに使う
    private enum SearchLocationID {}
    
    /// 天気取得を中断するときに使う
    private enum SearchWeatherID {}
    
    /// 現在の状態とアクションを渡して、状態を更新するか、次のアクションを発行する
    func reduce(into state: inout SearchState, action: SearchAction) -> EffectTask<SearchAction> {
        switch action {
        case let .searchQueryChanged(query):
            // テキストフィールドの中身が変わった
            state.searchQuery = query
            
            // テキストフィールドの中身が空になったら、searchQueryChangeDebouncedアクションから新たなアクションが発行されない
            guard !query.isEmpty else {
                state.results = []
                state.weather = nil
                return .cancel(id: SearchLocationID.self)
            }
            return .none
            
        case .searchQueryChangeDebounced:
            // 検索キーワードが確定した
            guard !state.searchQuery.isEmpty else {
                // 空になったときは何もしない
                return .none
            }
            // 非同期処理を行う
            // アクションの発行をキャンセルすることも可能
            return .task { [query = state.searchQuery] in
                // その結果としてアクションを発行する
                await .searchResponse(TaskResult {
                    // 地名検索API呼び出し
                    // 結果または例外はTaskResultが持ってくれる
                    try await self.weatherClient.search(query)
                })
            }
            .cancellable(id: SearchLocationID.self)
            
        case let .searchResponse(.success(response)):
            // 検索API呼び出しが成功した
            // 状態を更新
            state.results = response.results
            // 新たなアクションを発行しない
            return .none

        case .searchResponse(.failure):
            // 検索API呼び出しが失敗した
            // エラーの時は何も表示しないように状態を更新
            state.results = []
            // 新た無いアクションを発行しない
            return .none
            
        case let .searchResultTapped(location):
            // 地名がタップされた
            // 読み込み中の地名を控える
            state.resultForecastRequestInFlight = location
            
            return .task {
                // 天気取得完了アクション
                await .forecastResponse(
                    location.id,
                    TaskResult {
                        //
                        try await self.weatherClient.forecast(location)
                    }
                )
            }
            .cancellable(id: SearchWeatherID.self, cancelInFlight: true)
                    
        case let .forecastResponse(id, .success(forecast)):
            // 天気の取得が完了した
            // 天気を表示する
            state.weather = SearchState.Weather(
                id: id,
                days: forecast.daily.time.indices.map {
                    SearchState.Weather.Day(
                        date: forecast.daily.time[$0],
                        temperatureMax: forecast.daily.temperatureMax[$0],
                        temperatureMaxUnit: forecast.dailyUnits.temperatureMax,
                        temperatureMin: forecast.daily.temperatureMin[$0],
                        temperatureMinUnit: forecast.dailyUnits.temperatureMin
                    )
                }
            )
            // 読み込み中の地名を無くす
            state.resultForecastRequestInFlight = nil
            return .none
        
        case .forecastResponse(_, .failure):
            // 天気の取得が失敗した
            // 天気は表示しない
            state.weather = nil
            // 読み込み中の地名を無くす
            state.resultForecastRequestInFlight = nil
            return .none
        }
    }
}
