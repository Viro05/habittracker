import Foundation
import SwiftUI

struct Habit: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var color: String
    var completions: Set<String> // Date strings in "yyyy-MM-dd" format
    let createdDate: Date

    init(name: String, color: String = "#007AFF") {
        self.name = name
        self.color = color
        self.completions = []
        self.createdDate = Date()
    }

    func isCompletedOn(date: Date) -> Bool {
        let dateString = DateFormatter.dayFormatter.string(from: date)
        return completions.contains(dateString)
    }

    mutating func toggleCompletion(for date: Date) {
        let dateString = DateFormatter.dayFormatter.string(from: date)
        if completions.contains(dateString) {
            completions.remove(dateString)
        } else {
            completions.insert(dateString)
        }
    }

    func completionsInPeriod(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        var count = 0
        var currentDate = startDate

        while currentDate <= endDate {
            if isCompletedOn(date: currentDate) {
                count += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }

        return count
    }

    static func == (lhs: Habit, rhs: Habit) -> Bool {
        return lhs.id == rhs.id
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

enum TimePeriod: String, CaseIterable {
    case day = "Today"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    func dateRange(for customDate: Date? = nil) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let targetDate = customDate ?? Date()

        switch self {
        case .day:
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? targetDate
            return (startOfDay, endOfDay)
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.start ?? targetDate
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? targetDate
            return (startOfWeek, endOfWeek)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: targetDate)?.start ?? targetDate
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? targetDate) ?? targetDate
            return (startOfMonth, endOfMonth)
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: targetDate)?.start ?? targetDate
            let endOfYear = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? targetDate) ?? targetDate
            return (startOfYear, endOfYear)
        }
    }
}

struct HabitChartData: Equatable {
    let habit: Habit
    let completedDays: Int
    let totalDays: Int
    let completionRate: Double
    let color: Color

    init(habit: Habit, period: TimePeriod, customDate: Date? = nil) {
        self.habit = habit
        let range = period.dateRange(for: customDate)
        let calendar = Calendar.current

        var totalDaysCount = 0
        var currentDate = range.start

        while currentDate <= range.end {
            totalDaysCount += 1
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? range.end
        }

        self.totalDays = totalDaysCount
        self.completedDays = habit.completionsInPeriod(from: range.start, to: range.end)
        self.completionRate = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
        self.color = Color(hex: habit.color)
    }

    static func == (lhs: HabitChartData, rhs: HabitChartData) -> Bool {
        return lhs.habit.id == rhs.habit.id && lhs.completedDays == rhs.completedDays && lhs.totalDays == rhs.totalDays
    }
}

struct PieChartData: Equatable {
    let completedPercentage: Double
    let notCompletedPercentage: Double
    let completedDays: Int
    let totalDays: Int
    let selectedHabits: [String] // Habit names

    static func == (lhs: PieChartData, rhs: PieChartData) -> Bool {
        return lhs.completedDays == rhs.completedDays && lhs.totalDays == rhs.totalDays && lhs.selectedHabits == rhs.selectedHabits
    }
}

enum HabitSelection: Equatable {
    case all
    case specific(Set<UUID>)

    func isSelected(_ habitId: UUID) -> Bool {
        switch self {
        case .all:
            return true
        case .specific(let ids):
            return ids.contains(habitId)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
