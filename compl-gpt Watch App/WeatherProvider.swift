import Foundation
import CoreLocation

class WeatherProvider {
    func getWeather(location: CLLocation) async throws -> Weather {
        let apiKey = "TODO"
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=metric"
        let url = URL(string: urlString)!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
        
        var weatherIcon = "questionmark.circle"
        var rawWeatherIcon = "?"
        if let openWeatherIcon = weatherResponse.weather.first?.icon {
            rawWeatherIcon = openWeatherIcon
            weatherIcon = self.mapWeatherIconToSFIcon(icon: openWeatherIcon)
        }
        
        return Weather(weatherIcon: weatherIcon, rawWeatherIcon: rawWeatherIcon, temp: weatherResponse.main.temp)
    }
    
    private func mapWeatherIconToSFIcon(icon: String) -> String {
        switch icon {
        case "01d", "01n":
            return "sun.max"
        case "02d", "02n":
            return "cloud.sun"
        case "03d", "03n", "04d", "04n":
            return "cloud"
        case "09d", "09n":
            return "cloud.heavyrain"
        case "10d", "10n":
            return "cloud.sun.rain"
        case "11d", "11n":
            return "cloud.bolt.rain"
        case "13d", "13n":
            return "cloud.snow"
        case "50d", "50n":
            return "cloud.fog"
        default:
            return "questionmark.circle"
        }
    }
}

private struct WeatherResponse: Codable {
    let main: Main
    let weather: [WeatherItem]
}

private struct Main: Codable {
    let temp: Double
}

private struct WeatherItem: Codable {
    let icon: String
}

struct Weather {
    static let Sample = Weather(weatherIcon: "sun.max", rawWeatherIcon: "sun", temp: 100)
    
    let weatherIcon: String
    let rawWeatherIcon: String
    let temp: Double
}
