// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/SearchView.swift
// より引用

import ComposableArchitecture

enum SearchAction: Equatable {
    case forecastResponse(GeocodingSearch.Result.ID, TaskResult<Forecast>)
    case searchQueryChanged(String)
    case searchQueryChangeDebounced
    case searchResponse(TaskResult<GeocodingSearch>)
    case searchResultTapped(GeocodingSearch.Result)
}
