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
    
    /// この画面のStore
    let store: StoreOf<SearchReducer>
    
    /// この画面のView
    var body: some View {
        /// ViewWithStoreで状態をView反映してViewを構築することができる
        WithViewStore(self.store, observe: { $0 /* state in state と同じ。クロージャーの0番目の引数を使う */ }) { viewStore in
            NavigationView {
                // 縦並べ
                VStack(alignment: .leading) {
                    // 説明書き
                    Text(readMe)
                        .padding()
                    // 横並べ
                    HStack {
                        // 虫眼鏡画像
                        Image(systemName: "magnifyingglass")
                        // テキスト入力
                        // Storeの状態を反映している
                        TextField(
                            "New York, San Francisco, ...",
                            text: viewStore.binding(
                                get: \.searchQuery /* 現在の状態を受け取り */, send: SearchAction.searchQueryChanged /* 新たな状態をReducerに渡す */
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 16)
                    
                    // スクロールする縦並べ
                    List {
                        // 検索結果としての地名一覧ループ
                        ForEach(viewStore.results) { location in
                            // 縦並べ
                            VStack(alignment: .leading) {
                                // 地名はボタンとして表示
                                Button(action: { viewStore.send(.searchResultTapped(location)) }) {
                                    // 横並べ
                                    HStack {
                                        // 地名テキスト
                                        Text(location.name)
                                        // 天気取得中の場合はプログレスを表示する
                                        if viewStore.resultForecastRequestInFlight?.id == location.id {
                                            ProgressView()
                                        }
                                    }
                                }
                                // 天気が取得されていたら天気を表示
                                if location.id == viewStore.weather?.id {
                                    self.weatherView(locationWeather: viewStore.weather)
                                }
                            }
                        }
                    }
                    // API提供元リンク
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
    
    /// 天気表示View
    func weatherView(locationWeather: SearchState.Weather?) -> some View {
        guard let locationWeather = locationWeather else {
            return AnyView(EmptyView())
        }
        // 気温文字列に変換
        let days = locationWeather.days
            .enumerated()
            .map { idx, weather in formattedWeatherDay(weather, isToday: idx == 0) }
        
        return AnyView(
            // 縦並べ
            VStack(alignment: .leading) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                }
            }
                .padding(.leading, 16)
        )
    }
}

/// 気温文字列を作成
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
