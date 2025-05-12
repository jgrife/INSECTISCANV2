// WeatherResponse.swift
import Foundation

struct WeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]

    struct Main: Codable {
        let temp: Double
        let humidity: Double
    }

    struct Weather: Codable {
        let main: String
        let description: String
    }
}
