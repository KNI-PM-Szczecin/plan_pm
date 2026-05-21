import WidgetKit
import SwiftUI

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let lectures: [[String: String]]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: .now, lectures: [
            ["name": "Aplikacje www", "start": "08:00", "end": "09:35", "location": "WChrobrego 112"],
            ["name": "Bezpieczeństwo systemów", "start": "09:45", "end": "11:25", "location": "WChrobrego 208"],
        ])
    }
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let raw = UserDefaults(suiteName: "group.com.piotrwittig.plan_pm")?
            .string(forKey: "schedule_data") ?? "[]"
        let lectures = (try? JSONDecoder().decode([[String: String]].self,
            from: Data(raw.utf8))) ?? []
        let entry = ScheduleEntry(date: .now, lectures: lectures)
        let next = Calendar.current.date(byAdding: .hour, value: 24, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(lecture["name"] ?? "")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(lecture["start"] ?? "") - \(lecture["end"] ?? "")",
                          systemImage: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                    if let loc = lecture["location"], !loc.isEmpty {
                        Label(loc, systemImage: "mappin.and.ellipse")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
        )
    }
}

struct ScheduleWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.lectures.isEmpty {
                Spacer()
                Text("Brak zajęć na dziś")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(0..<min(2, entry.lectures.count), id: \.self) { idx in
                    LectureCard(lecture: entry.lectures[idx],
                                colors: cardGradients[idx % cardGradients.count])
                }
            }
        }
        .padding(14)
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
        .supportedFamilies([.systemMedium])
    }
}
