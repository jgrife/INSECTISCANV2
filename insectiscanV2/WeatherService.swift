// WeatherService.swift
import Foundation

class WeatherService {
    static let shared = WeatherService()
    private init() {}

    private let apiKey = "c228432daa356fe5a3cd8b71f3665af1" // Replace if needed

    func fetchWeather(forCity city: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let cityQuery = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Yosemite"
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityQuery)&units=imperial&appid=\(apiKey)"

        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                completion(.success(weather))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchWeather(forLatitude lat: Double, longitude lon: Double, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&units=imperial&appid=\(apiKey)"

        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                completion(.success(weather))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
