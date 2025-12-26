import SwiftUI

struct ContentView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var showingAddHabit = false
    @State private var newHabitName = ""
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingChart = false
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingWeekPicker = false
    @State private var showingMonthPicker = false
    @State private var showingYearPicker = false

    private let habitColor = "#FFFFFF"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Content
            if showingChart {
                chartView
            } else {
                habitListView
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showingAddHabit) {
            addHabitSheet
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Habits")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Toggle view button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingChart.toggle()
                    }
                }) {
                    Image(systemName: showingChart ? "list.bullet" : "chart.pie.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())

                // Add habit button
                Button(action: {
                    showingAddHabit = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Progress indicator
            if !habitStore.habits.isEmpty {
                progressView
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                let completionRate = habitStore.getTodayCompletionRate()
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            ProgressView(value: habitStore.getTodayCompletionRate())
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 0.8)
        }
    }

    private var habitListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if habitStore.habits.isEmpty {
                    emptyStateView
                } else {
                    ForEach(habitStore.habits) { habit in
                        HabitRowView(habit: habit)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var chartView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                // Period selector
                HStack(spacing: 16) {
                    Text("View:")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPeriod = period
                            }
                        }) {
                            Text(period.rawValue)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(selectedPeriod == period ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedPeriod == period ? Color.white : Color.white.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer()
                }

                // Period-specific date selectors
                HStack(spacing: 16) {
                    Text("Select:")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    switch selectedPeriod {
                    case .day:
                        daySelector
                    case .week:
                        weekSelector
                    case .month:
                        monthSelector
                    case .year:
                        yearSelector
                    }

                    Spacer()

                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("Current")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 32)

            // Habit Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Habits:")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 32)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All habits button
                        Button(action: {
                            habitStore.selectAllHabits()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: habitStore.selectedHabits == .all ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(habitStore.selectedHabits == .all ? .white : .white.opacity(0.7))

                                Text("All Habits")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(habitStore.selectedHabits == .all ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(habitStore.selectedHabits == .all ? Color.white : Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Individual habit buttons
                        ForEach(habitStore.habits) { habit in
                            Button(action: {
                                habitStore.toggleHabitSelection(habit.id)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: habitStore.selectedHabits.isSelected(habit.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(habitStore.selectedHabits.isSelected(habit.id) ? .white : .white.opacity(0.7))

                                    Text(habit.name)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(habitStore.selectedHabits.isSelected(habit.id) ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(habitStore.selectedHabits.isSelected(habit.id) ? Color.white : Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }

            // Chart
            ScrollView {
                PieChartView(data: habitStore.getPieChartData(for: selectedPeriod, customDate: selectedDate))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("No habits yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Text("Add your first habit to get started")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 100)
    }

    private var addHabitSheet: some View {
        VStack(spacing: 24) {
            Text("New Habit")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            TextField("Habit name", text: $newHabitName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 16, weight: .medium, design: .rounded))

            HStack {
                Button("Cancel") {
                    showingAddHabit = false
                    newHabitName = ""
                }
                .foregroundColor(.white.opacity(0.7))

                Spacer()

                Button("Add") {
                    if !newHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        habitStore.addHabit(name: newHabitName.trimmingCharacters(in: .whitespacesAndNewlines), color: habitColor)
                        showingAddHabit = false
                        newHabitName = ""
                    }
                }
                .foregroundColor(.blue)
                .disabled(newHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(32)
        .background(Color.black.opacity(0.9))
        .preferredColorScheme(.dark)
    }

    private func formattedDate(_ date: Date, for period: TimePeriod) -> String {
        let formatter = DateFormatter()

        switch period {
        case .day:
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        case .week:
            let calendar = Calendar.current
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date

            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            return "\(startString) - \(endString)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }

    // MARK: - Period-specific selectors

    private var daySelector: some View {
        Button(action: {
            showingDatePicker.toggle()
        }) {
            Text(formattedDate(selectedDate, for: .day))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showingDatePicker) {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color.black.opacity(0.9))
                .preferredColorScheme(.dark)
        }
    }

    private var weekSelector: some View {
        HStack(spacing: 8) {
            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                showingWeekPicker.toggle()
            }) {
                Text(formattedDate(selectedDate, for: .week))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingWeekPicker) {
                DatePicker("Select Week", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .preferredColorScheme(.dark)
            }

            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var monthSelector: some View {
        HStack(spacing: 8) {
            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                showingMonthPicker.toggle()
            }) {
                Text(formattedDate(selectedDate, for: .month))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingMonthPicker) {
                DatePicker("Select Month", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .preferredColorScheme(.dark)
            }

            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var yearSelector: some View {
        HStack(spacing: 8) {
            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                showingYearPicker.toggle()
            }) {
                Text(formattedDate(selectedDate, for: .year))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingYearPicker) {
                DatePicker("Select Year", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .preferredColorScheme(.dark)
            }

            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HabitStore())
            .preferredColorScheme(.dark)
    }
}
