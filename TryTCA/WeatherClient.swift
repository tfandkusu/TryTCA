// https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/Search/Search/WeatherClient.swift
// より引用

import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay

/// 地名検索APIのレスポンスボディ
/// JsonパースのためにDecodableプロトコルに準拠
/// 比較可能にするためにEquatableプロトコルに準拠
/// Sendable プロトコルに準拠したことで、@Sendable 属性がついたメソッドに渡すことができる
struct GeocodingSearch: Decodable, Equatable, Sendable {
    var results: [Result]
    
    struct Result: Decodable, Equatable, Identifiable, Sendable {
        var country: String
        var latitude: Double
        var longitude: Double
        var id: Int
        var name: String
        var admin1: String?
    }
}

struct Forecast: Decodable, Equatable, Sendable {
    var daily: Daily
    var dailyUnits: DailyUnits
    
    struct Daily: Decodable, Equatable, Sendable {
        var temperatureMax: [Double]
        var temperatureMin: [Double]
        var time: [Date]
    }
    
    struct DailyUnits: Decodable, Equatable, Sendable {
        var temperatureMax: String
        var temperatureMin: String
    }
}

/// APIクライアントのインターフェースを定義
struct WeatherClient {
    var forecast: @Sendable (GeocodingSearch.Result) async throws -> Forecast
    var search: @Sendable (String) async throws -> GeocodingSearch
}


/// 実際のアプリで動く実装を定義する
/// TCAには依存管理システムが搭載されている
/// 書き方はTCAのREADME.mdに準拠したもの
extension WeatherClient: DependencyKey {
    
    /// ここに実際のアプリでWeatherClientの実装
    static let liveValue = WeatherClient(
        forecast: { result in
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: "\(result.latitude)"),
                URLQueryItem(name: "longitude", value: "\(result.longitude)"),
                URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
                URLQueryItem(name: "timezone", value: TimeZone.autoupdatingCurrent.identifier),
            ]
            
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try jsonDecoder.decode(Forecast.self, from: data)
        },
        search: { query in
            var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            components.queryItems = [URLQueryItem(name: "name", value: query)]
            
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try jsonDecoder.decode(GeocodingSearch.self, from: data)
        }
    )
}


/// テスト用の実装を定義する
extension WeatherClient: TestDependencyKey {
    
    /// Xcodeのプレビューで使う
    static let previewValue = Self(
        forecast: { _ in .mock },
        search: { _ in .mock }
    )
    
    /// 単体テストで使う
    static let testValue = Self(
        forecast: unimplemented("\(Self.self).forecast"),
        search: unimplemented("\(Self.self).search")
    )
}


extension Forecast {
    
    /// モックデータ
    static let mock = Self(
        daily: Daily(
            temperatureMax: [90, 70, 100],
            temperatureMin: [70, 50, 80],
            time: [0, 86_400, 172_800].map(Date.init(timeIntervalSince1970:))
        ),
        dailyUnits: DailyUnits(temperatureMax: "°F", temperatureMin: "°F")
    )
}

extension GeocodingSearch {
    
    /// モックデータ
    static let mock = Self(
        results: [
            GeocodingSearch.Result(
                country: "United States",
                latitude: 40.6782,
                longitude: -73.9442,
                id: 1,
                name: "Brooklyn",
                admin1: nil
            ),
            GeocodingSearch.Result(
                country: "United States",
                latitude: 34.0522,
                longitude: -118.2437,
                id: 2,
                name: "Los Angeles",
                admin1: nil
            ),
            GeocodingSearch.Result(
                country: "United States",
                latitude: 37.7749,
                longitude: -122.4194,
                id: 3,
                name: "San Francisco",
                admin1: nil
            ),
        ]
    )
}

/// こちらもTCAのREADME.mdに準拠したもの
extension DependencyValues {
    var weatherClient: WeatherClient {
        get { self[WeatherClient.self] }
        set { self[WeatherClient.self] = newValue }
    }
}


// MARK: - Private helpers
private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    decoder.dateDecodingStrategy = .formatted(formatter)
    return decoder
}()

extension Forecast {
    private enum CodingKeys: String, CodingKey {
        case daily
        case dailyUnits = "daily_units"
    }
}

extension Forecast.Daily {
    private enum CodingKeys: String, CodingKey {
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case time
    }
}

extension Forecast.DailyUnits {
    private enum CodingKeys: String, CodingKey {
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
    }
}
