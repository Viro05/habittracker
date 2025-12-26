import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    @EnvironmentObject var habitStore: HabitStore
    @State private var isHovered = false

    private var currentHabit: Habit {
        habitStore.habits.first { $0.id == habit.id } ?? habit
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                habitStore.toggleHabitCompletion(habit)
            }
        }) {
            HStack(spacing: 16) {
                // Completion checkbox
                ZStack {
                    // Visible circle border
                    Circle()
                        .stroke(Color(hex: currentHabit.color), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if currentHabit.isCompletedOn(date: Date()) {
                        Circle()
                            .fill(Color(hex: currentHabit.color))
                            .frame(width: 16, height: 16)
                            .scaleEffect(currentHabit.isCompletedOn(date: Date()) ? 1.0 : 0.0)
                    }
                }

                // Habit name
                Text(currentHabit.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .strikethrough(currentHabit.isCompletedOn(date: Date()))
                    .opacity(currentHabit.isCompletedOn(date: Date()) ? 0.6 : 1.0)

                Spacer()

                // Delete button (shown on hover)
                if isHovered {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            habitStore.removeHabit(habit)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                            .font(.system(size: 18))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity)
                    .onTapGesture {
                        // Prevent parent button from receiving tap
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(isHovered ? 0.6 : 0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct HabitRowView_Previews: PreviewProvider {
    static var previews: some View {
        HabitRowView(habit: Habit(name: "Drink Water", color: "#007AFF"))
            .environmentObject(HabitStore())
            .padding()
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
