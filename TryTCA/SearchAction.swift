import SwiftUI
import ComposableArchitecture

enum SearchAction: Equatable {
    case forecastResponse(GeocodingSearch.Result.ID, TaskResult<Forecast>)
    case searchQueryChanged(String)
    case searchQueryChangeDebounced
    case searchResponse(TaskResult<GeocodingSearch>)
    case searchResultTapped(GeocodingSearch.Result)
}
