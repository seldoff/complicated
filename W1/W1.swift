import WidgetKit
import SwiftUI

struct WeatherActivityCountProvider: TimelineProvider {
    typealias Entry = WeatherActivityEntry
    static let sampleEntry = WeatherActivityEntry(date: Date(), weather: Weather.Sample, activity: Activity.Sample)
    
    private var locationProvider = LocationProvider()
    private var weatherProvider = WeatherProvider()
    private var activityProvider = ActivityProvider()
    
    func placeholder(in context: Context) -> WeatherActivityEntry {
        return Self.sampleEntry
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WeatherActivityEntry) -> Void) {
        getEntryCompl(completion: completion)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherActivityEntry>) -> Void) {
        print("getTimeline")
        
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        getTimelineCompl(refreshDate: refreshDate, completion: completion)
    }
    
    func getEntryCompl(completion: @escaping (WeatherActivityEntry) -> Void) {
        Task {
            let entry = await getEntry()
            completion(entry)
        }
    }
    
    func getTimelineCompl(refreshDate: Date, completion: @escaping (Timeline<WeatherActivityEntry>) -> Void) {
        Task {
            let entry = await getEntry()
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
    
    func getEntry() async -> WeatherActivityEntry {
        let weather = await getWeather()
        let activity = await getActivity()
        return WeatherActivityEntry(date: Date(), weather: weather, activity: activity)
//        return WeatherActivityEntry(date: Date(), weather: Weather(weatherIcon: "sun.max", temp: 12), activity: Activity(steps: 11000, calories: 1234))
    }
    
    func getWeather() async -> Weather {
        do {
            let location = try await locationProvider.getLocation()
            return try await weatherProvider.getWeather(location: location)
        } catch {
            return Weather.Sample
        }
    }
    
    func getActivity() async -> Activity {
        do {
            return try await activityProvider.getActivity()
        } catch {
            return Activity.Sample
        }
    }
}

struct WeatherActivityEntry: TimelineEntry {
    let date: Date
    let weather: Weather
    let activity: Activity
}

struct W1EntryView : View {
    var entry: WeatherActivityCountProvider.Entry
    
    func intWithSeparator(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    func intWithoutSeparator(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    @State var stepsStr = ""
    @State var caloriesStr = ""
    
    var body: some View {
        HStack {
            Text("✦ \(caloriesStr) ·🏃\(stepsStr) · \(Int(entry.weather.temp).formatted())°")
            Image(systemName: entry.weather.weatherIcon)
        }.onAppear(perform: {
            if entry.activity.steps > 9999 && entry.activity.calories > 999 {
                stepsStr = intWithoutSeparator(entry.activity.steps)
                caloriesStr = intWithoutSeparator(entry.activity.calories)
            } else if entry.activity.steps > 9999 {
                stepsStr = intWithoutSeparator(entry.activity.steps)
                caloriesStr = intWithSeparator(entry.activity.calories)
            } else {
                stepsStr = intWithSeparator(entry.activity.steps)
                caloriesStr = intWithSeparator(entry.activity.calories)
            }
        })
    }
}

@main
struct W1: Widget {
    let kind: String = "W1"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherActivityCountProvider()) { entry in
            W1EntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct W1_Previews: PreviewProvider {
    static var previews: some View {
        W1EntryView(entry: WeatherActivityCountProvider.sampleEntry)
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
