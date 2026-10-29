import Foundation

enum PaneKind: String, CaseIterable, Codable, Identifiable {
    case weather
    case battery
    case clock
    case room
    case light
    case purifier
    case shortcut
    case music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weather: return "Weather"
        case .battery: return "Battery"
        case .clock: return "Time"
        case .room: return "Room"
        case .light: return "Lights"
        case .purifier: return "Purifier"
        case .shortcut: return "Shortcut"
        case .music: return "Music"
        }
    }

    var symbol: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .battery: return "battery.100percent"
        case .clock: return "clock.fill"
        case .room: return "thermometer.medium"
        case .light: return "lightbulb.fill"
        case .purifier: return "fan.fill"
        case .shortcut: return "bolt.fill"
        case .music: return "music.note"
        }
    }

    static let initial: [PaneKind] = [.weather, .light, .room, .purifier, .battery, .music]
}

enum PaneCity: String, CaseIterable, Codable, Identifiable {
    case sudbury
    case toronto
    case mississauga

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sudbury: return "Sudbury"
        case .toronto: return "Toronto"
        case .mississauga: return "Mississauga"
        }
    }

    var latitude: Double {
        switch self {
        case .sudbury: return 46.4917
        case .toronto: return 43.6532
        case .mississauga: return 43.5890
        }
    }

    var longitude: Double {
        switch self {
        case .sudbury: return -80.9930
        case .toronto: return -79.3832
        case .mississauga: return -79.6441
        }
    }
}

struct WeatherReading: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature_2m: Double
    }

    var temperature: Double { current.temperature_2m }
}

enum WeatherProvider {
    static func currentTemperature(in city: PaneCity) async throws -> Double {
        var parts = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        parts.queryItems = [
            URLQueryItem(name: "latitude", value: String(city.latitude)),
            URLQueryItem(name: "longitude", value: String(city.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m"),
            URLQueryItem(name: "temperature_unit", value: "celsius")
        ]
        let (data, response) = try await URLSession.shared.data(from: parts.url!)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(WeatherReading.self, from: data).temperature
    }
}
