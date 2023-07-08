// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/SearchTests/SearchTests.swift
// より引用

import ComposableArchitecture
import XCTest

@testable import TryTCA

/// SearchReducer構造体のテストコード
@MainActor
final class SearchTests: XCTestCase {

    /// 地名検索のテスト
    func testSearchAndClearQuery() async {
        // テスト用のストアを初期状態とReducerを設定して作る
        let store = TestStore(
            initialState: SearchState(),
            reducer: SearchReducer()
        )
        // APIクライアントにはテスト用の実装を注入
        store.dependencies.weatherClient.search = { _ in .mock }
        
        // searchQueryChangedアクションを発行したら、状態のsearchQueryフィールドが変わる
        await store.send(.searchQueryChanged("S")) {
            $0.searchQuery = "S"
        }
        // searchQueryChangeDebouncedアクションが発行されたら、そこからsearchResponseアクションが発行される
        await store.send(.searchQueryChangeDebounced)
        // この行を省略するとテストが失敗する
        await store.receive(.searchResponse(.success(.mock))) {
            // 検索結果を状態に反映
            $0.results = GeocodingSearch.mock.results
        }
        // searchQueryChangedアクションを発行したら、状態のsearchQueryフィールドが変わる
        await store.send(.searchQueryChanged("")) {
            // 検索キーワード入力欄が空になったら、検索結果も消える
            // これらの代入も消すとテストが失敗する
            $0.results = []
            $0.searchQuery = ""
        }
    }
    
    /// 地名検索API呼び出しでエラーケース
    func testSearchFailure() async {
        let store = TestStore(
            initialState: SearchState(),
            reducer: SearchReducer()
        )
        
        store.dependencies.weatherClient.search = { _ in throw SomethingWentWrong() }
        
        await store.send(.searchQueryChanged("S")) {
            $0.searchQuery = "S"
        }
        await store.send(.searchQueryChangeDebounced)
        await store.receive(.searchResponse(.failure(SomethingWentWrong())))
    }
    
    func testClearQueryCancelsInFlightSearchRequest() async {
        let store = TestStore(
            initialState: SearchState(),
            reducer: SearchReducer()
        )
        
        store.dependencies.weatherClient.search = { _ in .mock }
        
        let searchQueryChanged = await store.send(.searchQueryChanged("S")) {
            $0.searchQuery = "S"
        }
        await searchQueryChanged.cancel()
        await store.send(.searchQueryChanged("")) {
            $0.searchQuery = ""
        }
    }
    
    func testTapOnLocation() async {
        let specialResult = GeocodingSearch.Result(
            country: "Special Country",
            latitude: 0,
            longitude: 0,
            id: 42,
            name: "Special Place"
        )
        
        var results = GeocodingSearch.mock.results
        results.append(specialResult)
        
        let store = TestStore(
            initialState: SearchState(results: results),
            reducer: SearchReducer()
        )
        
        store.dependencies.weatherClient.forecast = { _ in .mock }
        
        await store.send(.searchResultTapped(specialResult)) {
            $0.resultForecastRequestInFlight = specialResult
        }
        await store.receive(.forecastResponse(42, .success(.mock))) {
            $0.resultForecastRequestInFlight = nil
            $0.weather = SearchState.Weather(
                id: 42,
                days: [
                    SearchState.Weather.Day(
                        date: Date(timeIntervalSince1970: 0),
                        temperatureMax: 90,
                        temperatureMaxUnit: "°F",
                        temperatureMin: 70,
                        temperatureMinUnit: "°F"
                    ),
                    SearchState.Weather.Day(
                        date: Date(timeIntervalSince1970: 86_400),
                        temperatureMax: 70,
                        temperatureMaxUnit: "°F",
                        temperatureMin: 50,
                        temperatureMinUnit: "°F"
                    ),
                    SearchState.Weather.Day(
                        date: Date(timeIntervalSince1970: 172_800),
                        temperatureMax: 100,
                        temperatureMaxUnit: "°F",
                        temperatureMin: 80,
                        temperatureMinUnit: "°F"
                    ),
                ]
            )
        }
    }
    
    /// ある地名を選択して、すぐに別の地名を選択したケース
    func testTapOnLocationCancelsInFlightRequest() async {
        let specialResult = GeocodingSearch.Result(
            country: "Special Country",
            latitude: 0,
            longitude: 0,
            id: 42,
            name: "Special Place"
        )
        
        var results = GeocodingSearch.mock.results
        results.append(specialResult)
        
        let store = TestStore(
            initialState: SearchState(results: results),
            reducer: SearchReducer()
        )
        // テスト用待機担当
        let clock = TestClock()
        store.dependencies.weatherClient.forecast = { _ in
            try await clock.sleep(for: .seconds(0))
            return .mock
        }
        // 1番目の地名を選択
        // !はnull安全無視
        await store.send(.searchResultTapped(results.first!)) {
            $0.resultForecastRequestInFlight = results.first!
        }
        // 2番目の地名を選択
        await store.send(.searchResultTapped(specialResult)) {
            $0.resultForecastRequestInFlight = specialResult
        }
        // 時間を進める
        await clock.advance()
        // 2番目の地名の天気を表示
        await store.receive(.forecastResponse(42, .success(.mock))) {
            $0.resultForecastRequestInFlight = nil
            $0.weather = SearchState.Weather(
                id: 42,
                days: [
                    SearchState.Weather.Day(
                        date: Date(timeIntervalSince1970: 0),
                        temperatureMax: 90,
                        temperatureMaxUnit: "°F",
                        temperatureMin: 70,
                        temperatureMinUnit: "°F"
                    ),
                    SearchState.Weather.Day(
                        date: Date(timeIntervalSince1970: 86_400),
                        temperatureMax: 70,
                        temperatureMaxUnit: "°F",
                        temperatureMin: 50,
                        temperatureMinUnit: "°F"
                    ),
                    SearchState.Weather.Day(
                        date: Date(timeIntervalSince1970: 172_800),
                        temperatureMax: 100,
                        temperatureMaxUnit: "°F",
                        temperatureMin: 80,
                        temperatureMinUnit: "°F"
                    ),
                ]
            )
        }
    }
}

private struct SomethingWentWrong: Equatable, Error {}
