// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/SearchView.swift
// より引用

import SwiftUI

/// Search画面の状態
struct SearchState: Equatable {
    /// 検索結果としての地名一覧
    var results: [GeocodingSearch.Result] = []
    
    ///現在天気要求中の地名
    var resultForecastRequestInFlight: GeocodingSearch.Result?
    
    /// 現在テキストフィールドに設定されている内容
    var searchQuery = ""
    
    /// クリックされた地点の天気の情報
    var weather: Weather?
    
    /// 天気の情報
    struct Weather: Equatable {
        var id: GeocodingSearch.Result.ID
        
        /// その日の気温一覧
        var days: [Day]

        
        /// その日の気温情報
        struct Day: Equatable {
            /// 日付
            var date: Date
            
            /// 最高気温
            var temperatureMax: Double
            
            /// 最高気温の単位
            var temperatureMaxUnit: String


            /// 最低気温
            var temperatureMin: Double

            /// 最低気温の単位
            var temperatureMinUnit: String
        }
    }
}
