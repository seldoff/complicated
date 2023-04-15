import Foundation
import SwiftUI
import HealthKit
import CoreLocation
import WidgetKit

struct ContentView: View {
    @StateObject private var locationProvider = LocationProvider()
    @StateObject private var activityProvider = ActivityProvider()
    
    @State private var weather: Weather?
    @State private var weatherError: String?
    @State private var activity: Activity?
    @State private var activityError: String?
    @State private var lastUpdated: Date?
    @State private var updateTimer: Timer? = nil
    
    var body: some View {
        VStack {
            if let w = weather {
                HStack {
                    Image(systemName: w.weatherIcon)
                    Text("(\(w.rawWeatherIcon))")
                    Text("\(w.temp, specifier: "%.0f")°")
                }
            } else if let e = weatherError {
                Text("Error fetching weather:")
                Text(e).foregroundColor(.red)
            } else {
                Text("Fetching weather...")
            }
            
            Spacer()
            
            if let a = activity {
                Text("🏃\(a.steps.formatted())")
                Spacer()
                Text("🔥\(a.calories.formatted())")
            } else if let e = activityError {
                Text("Error fetching activity:")
                Text(e).foregroundColor(.red)
            } else {
                Text("Fetching activity...")
            }
            
            Spacer()

            Button {
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Text("Update")
            }

            
            Spacer()
            
            if let lu = lastUpdated {
                Text("Last update: \(lu.formatted())")
            } else {
                Text("Last update: na")
            }
        }
        .task {
            startUpdateTimer()
            await update()
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await update()
            }
        }
    }
    
    func update() async {
        lastUpdated = Date()

        await withTaskGroup(of: Any.self) { taskGroup in
            taskGroup.addTask {
                await updateActivity()
            }
            taskGroup.addTask {
                await updateWeather()
            }
            for await _ in taskGroup {
            }
        }
    }
    
    func updateActivity() async {
        do {
            activity = try await activityProvider.getActivity()
        } catch {
            activityError = "\(error)"
            print(activityError)
        }
    }
    
    func updateWeather() async {
        do {
            let location = try await locationProvider.getLocation()
            let weatherProvider = WeatherProvider()
            weather = try await weatherProvider.getWeather(location: location)
        } catch {
            weatherError = "\(error)"
            print(weatherError)
        }
    }
}
