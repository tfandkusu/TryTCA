// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/SearchView.swift
// より引用

import SwiftUI
import ComposableArchitecture

private let readMe = """
  This application demonstrates live-searching with the Composable Architecture. As you type the \
  events are debounced for 300ms, and when you stop typing an API request is made to load \
  locations. Then tapping on a location will load weather.
  """

struct SearchView: View {
    let store: StoreOf<SearchReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack(alignment: .leading) {
                    Text(readMe)
                        .padding()
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField(
                            "New York, San Francisco, ...",
                            text: viewStore.binding(
                                get: \.searchQuery, send: SearchAction.searchQueryChanged
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 16)
                    
                    List {
                        ForEach(viewStore.results) { location in
                            VStack(alignment: .leading) {
                                Button(action: { viewStore.send(.searchResultTapped(location)) }) {
                                    HStack {
                                        Text(location.name)
                                        
                                        if viewStore.resultForecastRequestInFlight?.id == location.id {
                                            ProgressView()
                                        }
                                    }
                                }
                                
                                if location.id == viewStore.weather?.id {
                                    self.weatherView(locationWeather: viewStore.weather)
                                }
                            }
                        }
                    }
                    
                    Button("Weather API provided by Open-Meteo") {
                        UIApplication.shared.open(URL(string: "https://open-meteo.com/en")!)
                    }
                    .foregroundColor(.gray)
                    .padding(.all, 16)
                }
                .navigationTitle("Search")
            }
            .navigationViewStyle(.stack)
            .task(id: viewStore.searchQuery) {
                do {
                    try await Task.sleep(nanoseconds: NSEC_PER_SEC / 3)
                    await viewStore.send(.searchQueryChangeDebounced).finish()
                } catch {}
            }
        }
    }
    
    func weatherView(locationWeather: SearchState.Weather?) -> some View {
        guard let locationWeather = locationWeather else {
            return AnyView(EmptyView())
        }
        
        let days = locationWeather.days
            .enumerated()
            .map { idx, weather in formattedWeatherDay(weather, isToday: idx == 0) }
        
        return AnyView(
            VStack(alignment: .leading) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                }
            }
                .padding(.leading, 16)
        )
    }
}

// MARK: - Private helpers
private func formattedWeatherDay(_ day: SearchState.Weather.Day, isToday: Bool)
-> String
{
    let date =
    isToday
    ? "Today"
    : dateFormatter.string(from: day.date).capitalized
    let min = "\(day.temperatureMin)\(day.temperatureMinUnit)"
    let max = "\(day.temperatureMax)\(day.temperatureMaxUnit)"
    
    return "\(date), \(min) – \(max)"
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()
