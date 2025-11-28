//
//  ContentView.swift
//  rain-app
//
//  Created by Natasha Bullimore on 20/08/2025.
//
import SwiftUI
import CoreLocation
import UserNotifications

struct ContentView: View {
    @StateObject private var weatherMonitor = WeatherMonitor()
    @State private var message: String = "Loading..."
    @State private var weatherCode: String = ""
    @State private var precipitation: String = ""
    @State private var isMonitoring: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.title)
                .padding()
            
            if !weatherCode.isEmpty {
                Text("Weather Code: \(weatherCode)")
                    .padding()
            }
            
            if !precipitation.isEmpty {
                Text("Precipitation: \(precipitation) mm")
                    .padding()
            }
            
            if let location = weatherMonitor.locationManager.location {
                Text("📍 \(String(format: "%.4f, %.4f", location.latitude, location.longitude))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Toggle("Monitor Rain", isOn: $isMonitoring)
                .padding()
                .onChange(of: isMonitoring) { newValue in
                    if newValue {
                        weatherMonitor.startMonitoring()
                    } else {
                        weatherMonitor.stopMonitoring()
                    }
                }
            
            if isMonitoring {
                Text("🔔 Checking every 15 minutes - you'll be notified when rain is coming")
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Button("Check Now") {
                weatherMonitor.checkWeatherNow()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            weatherMonitor.requestPermissions()
            weatherMonitor.onWeatherUpdate = { weather in
                message = weather.raining ? "🌧️ Rain expected in next 15 minutes!" : "☀️ No rain in next 15 minutes"
                weatherCode = weather.weatherCode
                precipitation = String(format: "%.1f", weather.precipitation)
            }
        }
    }
}

// Weather Monitor - handles updates and notifications
class WeatherMonitor: NSObject, ObservableObject {
    let locationManager = LocationManager()
    private var timer: Timer?
    private var lastRainStatus: Bool = false
    var onWeatherUpdate: ((Weather) -> Void)?
    
    @Published var isMonitoring: Bool = false
    
    override init() {
        super.init()
        locationManager.onLocationUpdate = { [weak self] in
            self?.checkWeather()
        }
    }
    
    func requestPermissions() {
        // Request location permission (When In Use is sufficient)
        locationManager.requestPermission()
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func startMonitoring() {
        isMonitoring = true
        
        // Check weather every 15 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            self?.checkWeatherNow()
        }
        
        // Check immediately
        checkWeatherNow()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    func checkWeatherNow() {
        locationManager.requestSingleUpdate()
    }
    
    private func checkWeather() {
        guard let location = locationManager.location else {
            print("No location available")
            return
        }
        
        var components = URLComponents(string: "http://34.197.144.98:8000/weather")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude))
        ]
        
        guard let url = components?.url else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let weather = try? JSONDecoder().decode(Weather.self, from: data) else {
                return
            }
            
            DispatchQueue.main.async {
                self.onWeatherUpdate?(weather)
                
                // Send notification if it will rain in the next 15 minutes
                if weather.raining && !self.lastRainStatus {
                    self.sendRainNotification(precipitation: weather.precipitation)
                }
                
                self.lastRainStatus = weather.raining
            }
        }.resume()
    }
    
    private func sendRainNotification(precipitation: Double) {
        let content = UNMutableNotificationContent()
        content.title = "🌧️ Rain Coming Soon!"
        content.body = "It will rain in the next 15 minutes. Expected precipitation: \(String(format: "%.1f", precipitation)) mm"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Send immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

// Location Manager Class - simplified for foreground only
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    var onLocationUpdate: (() -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestSingleUpdate() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation.coordinate
        onLocationUpdate?()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location authorized")
        case .denied, .restricted:
            print("Location permission denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

// Weather Model
struct Weather: Codable {
    let raining: Bool
    let weatherCode: String
    let precipitation: Double
    
    enum CodingKeys: String, CodingKey {
        case raining
        case weatherCode = "weather_code"
        case precipitation
    }
}

#Preview {
    ContentView()
}