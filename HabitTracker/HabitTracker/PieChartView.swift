import SwiftUI

struct PieChartView: View {
    let data: PieChartData
    @State private var animatedCompletedAngle: Double = 0

    private let completedColor = Color.white
    private let notCompletedColor = Color.white.opacity(0.3)

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                if data.totalDays == 0 {
                    // Empty state
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 200, height: 200)

                    Text("No data")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    // Not completed slice (background)
                    Circle()
                        .fill(notCompletedColor)
                        .frame(width: 200, height: 200)

                    // Completed slice (foreground)
                    PieSlice(
                        startAngle: Angle(degrees: -90),
                        endAngle: Angle(degrees: -90 + animatedCompletedAngle),
                        color: completedColor
                    )
                    .frame(width: 200, height: 200)


                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedCompletedAngle = (data.completedPercentage / 100.0) * 360.0
                }
            }
            .onChange(of: data) { newData in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedCompletedAngle = (newData.completedPercentage / 100.0) * 360.0
                }
            }

            // Minimal Statistics
            if data.totalDays > 0 {
                VStack(spacing: 16) {
                    // Percentage Display
                    VStack(spacing: 8) {
                        Text("\(Int(data.completedPercentage))%")
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .foregroundColor(.white)

                        Text("Complete")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Minimal Stats
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("\(data.completedDays)")
                                .font(.system(size: 20, weight: .light, design: .rounded))
                                .foregroundColor(.white)
                            Text("Done")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 40)

                        VStack(spacing: 4) {
                            Text("\(data.totalDays)")
                                .font(.system(size: 20, weight: .light, design: .rounded))
                                .foregroundColor(.white)
                            Text("Total")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Minimal habits display
                    if !data.selectedHabits.isEmpty {
                        Text(data.selectedHabits.joined(separator: " · "))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 80

            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
        .overlay(
            Path { path in
                let center = CGPoint(x: 100, y: 100)
                let radius: CGFloat = 80

                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .stroke(Color.black.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PieChartView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = PieChartData(
            completedPercentage: 65.0,
            notCompletedPercentage: 35.0,
            completedDays: 13,
            totalDays: 20,
            selectedHabits: ["Exercise", "Reading"]
        )

        PieChartView(data: sampleData)
            .padding()
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
