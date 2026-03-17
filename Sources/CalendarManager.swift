import EventKit
import Foundation

@MainActor
final class CalendarManager: ObservableObject {
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var accessGranted: Bool = false

    private let store = EKEventStore()

    struct CalendarEvent: Identifiable {
        let id: String
        let title: String
        let startDate: Date
        let isAllDay: Bool

        var timeString: String {
            if isAllDay { return "All day" }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: startDate)
        }

        var isHappeningNow: Bool {
            !isAllDay && abs(startDate.timeIntervalSinceNow) < 15 * 60
        }
    }

    func requestAccess() {
        Task {
            do {
                let granted = try await store.requestFullAccessToEvents()
                self.accessGranted = granted
                if granted { self.fetchUpcoming() }
            } catch {
                NSLog("Audite: calendar access error: \(error)")
                self.accessGranted = false
            }
        }
    }

    func fetchUpcoming() {
        guard accessGranted else { return }

        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let predicate = store.predicateForEvents(withStart: now.addingTimeInterval(-30 * 60), end: endOfDay, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        upcomingEvents = ekEvents
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(id: $0.eventIdentifier, title: $0.title ?? "Untitled", startDate: $0.startDate, isAllDay: $0.isAllDay) }
    }
}
