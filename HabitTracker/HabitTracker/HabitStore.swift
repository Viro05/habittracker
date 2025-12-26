import SwiftUI
import Foundation
import os.log

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var selectedHabits: HabitSelection = .all

    private let saveKey = "SavedHabits"
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "HabitTracker", category: "HabitStore")

    init() {
        loadHabits()
    }

    func addHabit(name: String, color: String = "#007AFF") {
        let newHabit = Habit(name: name, color: color)
        habits.append(newHabit)
        saveHabits()
    }

    func removeHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }

    func toggleHabitCompletion(_ habit: Habit, for date: Date = Date()) {
        logger.info("Toggling habit: \(habit.name)")
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let dateString = DateFormatter.dayFormatter.string(from: date)
            let wasCompleted = habits[index].completions.contains(dateString)

            if wasCompleted {
                habits[index].completions.remove(dateString)
                logger.info("Removed completion for \(habit.name) on \(dateString)")
            } else {
                habits[index].completions.insert(dateString)
                logger.info("Added completion for \(habit.name) on \(dateString)")
            }

            // Force SwiftUI to recognize the change
            let updatedHabits = habits
            habits = updatedHabits
            saveHabits()
        } else {
            logger.error("Could not find habit with ID: \(habit.id)")
        }
    }

    func getPieChartData(for period: TimePeriod, customDate: Date? = nil) -> PieChartData {
        let filteredHabits = getSelectedHabits()

        guard !filteredHabits.isEmpty else {
            return PieChartData(
                completedPercentage: 0.0,
                notCompletedPercentage: 0.0,
                completedDays: 0,
                totalDays: 0,
                selectedHabits: []
            )
        }

        let calendar = Calendar.current
        let range = period.dateRange(for: customDate)

        var totalPossibleDays = 0
        var totalCompletedDays = 0
        var currentDate = range.start

        // Calculate total days in period
        if period == .day {
            // For single day, just count as 1 day
            totalPossibleDays = 1
        } else {
            while currentDate <= range.end {
                totalPossibleDays += 1
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? range.end
            }
        }

        // Calculate total completed days across all selected habits
        for habit in filteredHabits {
            if period == .day {
                // For single day, check if habit is completed on the target date
                let targetDate = customDate ?? Date()
                totalCompletedDays += habit.isCompletedOn(date: targetDate) ? 1 : 0
            } else {
                totalCompletedDays += habit.completionsInPeriod(from: range.start, to: range.end)
            }
        }

        let totalPossibleCompletions = totalPossibleDays * filteredHabits.count
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletedDays) / Double(totalPossibleCompletions) : 0.0

        return PieChartData(
            completedPercentage: completionRate * 100,
            notCompletedPercentage: (1.0 - completionRate) * 100,
            completedDays: totalCompletedDays,
            totalDays: totalPossibleCompletions,
            selectedHabits: filteredHabits.map { $0.name }
        )
    }

    func getSelectedHabits() -> [Habit] {
        switch selectedHabits {
        case .all:
            return habits
        case .specific(let ids):
            return habits.filter { ids.contains($0.id) }
        }
    }

    func toggleHabitSelection(_ habitId: UUID) {
        switch selectedHabits {
        case .all:
            // If all selected, switch to specific with all except the toggled one
            let allIds = Set(habits.map { $0.id })
            var newIds = allIds
            newIds.remove(habitId)
            selectedHabits = .specific(newIds)
        case .specific(var ids):
            if ids.contains(habitId) {
                ids.remove(habitId)
                if ids.isEmpty {
                    selectedHabits = .all
                } else {
                    selectedHabits = .specific(ids)
                }
            } else {
                ids.insert(habitId)
                if ids.count == habits.count {
                    selectedHabits = .all
                } else {
                    selectedHabits = .specific(ids)
                }
            }
        }
    }

    func selectAllHabits() {
        selectedHabits = .all
    }

    func selectOnlyHabit(_ habitId: UUID) {
        selectedHabits = .specific(Set([habitId]))
    }

    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            userDefaults.set(encoded, forKey: saveKey)
        }
    }

    private func loadHabits() {
        if let data = userDefaults.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }

    func getHabitsForToday() -> [Habit] {
        return habits
    }

    func getTodayCompletionRate() -> Double {
        guard !habits.isEmpty else { return 0.0 }
        let completedToday = habits.filter { $0.isCompletedOn(date: Date()) }.count
        return Double(completedToday) / Double(habits.count)
    }
}
