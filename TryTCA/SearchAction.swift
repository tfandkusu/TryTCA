// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/SearchView.swift
// より引用

import ComposableArchitecture

enum SearchAction: Equatable {
    /// 検索キーワードを入力するテキストフィールドの内容が変わった
    case searchQueryChanged(String)

    /// 検索キーワードが確定した
    case searchQueryChangeDebounced

    /// 検索結果を取得した。TaskResultには例外を含めることができる。
    case searchResponse(TaskResult<GeocodingSearch>)

    /// 検索結果としての地名がタップされた
    case searchResultTapped(GeocodingSearch.Result)

    /// 天気を取得した
    case forecastResponse(GeocodingSearch.Result.ID, TaskResult<Forecast>)
}
