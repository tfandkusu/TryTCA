// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/SearchView.swift
// より引用

import ComposableArchitecture

struct SearchReducer: ReducerProtocol {
    
    @Dependency(\.weatherClient) var weatherClient
    private enum SearchLocationID {}
    private enum SearchWeatherID {}
    
    func reduce(into state: inout SearchState, action: SearchAction) -> EffectTask<SearchAction> {
        switch action {
        case .forecastResponse(_, .failure):
            state.weather = nil
            state.resultForecastRequestInFlight = nil
            return .none
            
        case let .forecastResponse(id, .success(forecast)):
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
            state.resultForecastRequestInFlight = nil
            return .none
            
        case let .searchQueryChanged(query):
            state.searchQuery = query
            
            // When the query is cleared we can clear the search results, but we have to make sure to cancel
            // any in-flight search requests too, otherwise we may get data coming in later.
            guard !query.isEmpty else {
                state.results = []
                state.weather = nil
                return .cancel(id: SearchLocationID.self)
            }
            return .none
            
        case .searchQueryChangeDebounced:
            guard !state.searchQuery.isEmpty else {
                return .none
            }
            return .task { [query = state.searchQuery] in
                await .searchResponse(TaskResult { try await self.weatherClient.search(query) })
            }
            .cancellable(id: SearchLocationID.self)
            
        case .searchResponse(.failure):
            state.results = []
            return .none
            
        case let .searchResponse(.success(response)):
            state.results = response.results
            return .none
            
        case let .searchResultTapped(location):
            state.resultForecastRequestInFlight = location
            
            return .task {
                await .forecastResponse(
                    location.id,
                    TaskResult { try await self.weatherClient.forecast(location) }
                )
            }
            .cancellable(id: SearchWeatherID.self, cancelInFlight: true)
        }
    }
}
