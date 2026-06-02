import WidgetKit
import SwiftUI

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let lectures: [[String: String]]
}

fileprivate func parseTime(_ timeStr: String, on referenceDate: Date = Date()) -> Date? {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    guard let t = f.date(from: timeStr) else { return nil }
    var c = Calendar.current.dateComponents([.year, .month, .day], from: referenceDate)
    let tc = Calendar.current.dateComponents([.hour, .minute], from: t)
    c.hour = tc.hour
    c.minute = tc.minute
    c.second = 0
    return Calendar.current.date(from: c)
}

fileprivate func filterUpcoming(_ lectures: [[String: String]], at date: Date) -> [[String: String]] {
    lectures.filter { lecture in
        guard let endStr = lecture["end"],
              let endDate = parseTime(endStr, on: date) else { return true }
        return endDate >= date
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: .now, lectures: [
            ["name": "Aplikacje www", "start": "08:00", "end": "09:35", "location": "WChrobrego 112"],
            ["name": "Bezpieczeństwo systemów", "start": "09:45", "end": "11:25", "location": "WChrobrego 208"],
            ["name": "Bazy danych", "start": "11:35", "end": "13:10", "location": "WChrobrego 305"],
            ["name": "Sieci komputerowe", "start": "13:20", "end": "15:00", "location": "WChrobrego 101"],
            ["name": "Matematyka dyskretna", "start": "15:10", "end": "16:45", "location": "WChrobrego 204"],
            ["name": "Programowanie obiektowe", "start": "21:00", "end": "22:00", "location": "WChrobrego 215"],
        ])
    }
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let raw = UserDefaults(suiteName: "group.com.piotrwittig.plan_pm")?
            .string(forKey: "schedule_data") ?? "[]"
        let allLectures = (try? JSONDecoder().decode([[String: String]].self,
            from: Data(raw.utf8))) ?? []

        let now = Date()
        var entries: [ScheduleEntry] = [
            ScheduleEntry(date: now, lectures: allLectures)
        ]

        let endTimes = allLectures
            .compactMap { parseTime($0["end"] ?? "") }
            .filter { $0 > now }
            .sorted()
        for endTime in endTimes {
            let transition = endTime.addingTimeInterval(1)
            entries.append(ScheduleEntry(date: transition, lectures: allLectures))
        }

        let next = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
        completion(Timeline(entries: entries, policy: .after(next)))
    }
}

private let cardGradients: [[Color]] = [
    [Color(red: 0.42, green: 0.32, blue: 0.92), Color(red: 0.30, green: 0.52, blue: 0.96)],
    [Color(red: 0.18, green: 0.72, blue: 0.64), Color(red: 0.12, green: 0.58, blue: 0.72)],
    [Color(red: 0.82, green: 0.28, blue: 0.52), Color(red: 0.68, green: 0.18, blue: 0.72)],
    [Color(red: 0.94, green: 0.52, blue: 0.10), Color(red: 0.82, green: 0.28, blue: 0.18)],
]

struct LectureCard: View {
    let lecture: [String: String]
    let colors: [Color]
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    @ViewBuilder
    private var cardBackground: some View {
        if renderingMode == .accented {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lecture["name"] ?? "")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image("ClockIcon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 11, height: 11)
                    Text("\(lecture["start"] ?? "") - \(lecture["end"] ?? "")")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                if family != .systemSmall, let loc = lecture["location"], !loc.isEmpty {
                    HStack(spacing: 4) {
                        Image("MapPinIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 11, height: 11)
                        Text(loc)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                }
            }
            Color.clear.frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBackground)
        .overlay(alignment: .bottom) {
            if #available(iOS 16, *) {
                let start = parseTime(lecture["start"] ?? "")
                let end = parseTime(lecture["end"] ?? "")
                if let s = start, let e = end, s <= Date(), Date() <= e {
                    ProgressView(timerInterval: s...e, countsDown: false)
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .labelsHidden()
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
        }
    }
}

struct ScheduleWidgetView: View {
    let entry: ScheduleEntry
    @Environment(\.widgetFamily) var family

    var maxCards: Int {
        family == .systemLarge ? 5 : 2
    }

    var visibleLectures: [[String: String]] {
        if family != .systemLarge {
            return Array(filterUpcoming(entry.lectures, at: entry.date).prefix(maxCards))
        }
        if entry.lectures.count <= maxCards {
            return entry.lectures
        }
        return Array(filterUpcoming(entry.lectures, at: entry.date).prefix(maxCards))
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            if visibleLectures.isEmpty {
                Spacer()
                Text("Brak zajęć na dziś")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(0..<visibleLectures.count, id: \.self) { idx in
                    LectureCard(lecture: visibleLectures[idx],
                                colors: cardGradients[idx % cardGradients.count])
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: visibleLectures.count == maxCards ? .center : .top)
        .padding(12)
        .widgetURL(URL(string: "planpm://schedule"))
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

@main
struct ScheduleWidgetBundle: WidgetBundle {
    var body: some Widget { ScheduleWidget() }
}

struct ScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PlanPMScheduleWidget", provider: Provider()) { entry in
            ScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("Plan zajęć")
        .description("Zajęcia na dziś")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
