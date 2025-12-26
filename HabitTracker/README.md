# Habit Tracker - Minimal Dark Mode macOS App

A beautifully minimal dark-themed habit tracker for macOS built with SwiftUI.

## Features

- ✅ **Add & Remove Habits**: Easily manage your daily habits
- 🎯 **Daily Tracking**: Mark habits as complete for each day
- 📊 **Visual Analytics**: View your progress with animated pie charts
- 📅 **Flexible Time Periods**: Analyze habits by week, month, or year
- 🌙 **Pure Dark Mode**: Aesthetic black interface with subtle animations
- 💾 **Data Persistence**: Your habits are automatically saved

## How to Use

### Running the App
1. Open the project in Xcode 15 or later
2. Select your Mac as the target device
3. Press `Cmd + R` to build and run

### Adding Habits
1. Click the `+` button in the top-right corner
2. Enter your habit name
3. Click "Add" - the app will assign a random color

### Tracking Progress
- Click the circle next to any habit to mark it complete for today
- Completed habits will show a filled circle and strikethrough text
- Hover over habits to reveal the delete button (red X)

### Viewing Analytics
1. Click the pie chart icon in the header to switch to analytics view
2. Select time period: Week, Month, or Year
3. View the animated pie chart showing your completion data
4. Click the list icon to return to the habit list

### Progress Overview
- The progress bar in the header shows today's completion percentage
- Empty states guide you when starting fresh

## Technical Details

- **Platform**: macOS 13.0+
- **Framework**: SwiftUI
- **Data Storage**: UserDefaults (automatically synced)
- **Architecture**: MVVM with ObservableObject
- **Animations**: Native SwiftUI animations for smooth interactions

## Project Structure

```
HabitTracker/
├── HabitTrackerApp.swift      # Main app entry point
├── ContentView.swift          # Primary interface
├── HabitModel.swift           # Data models and logic
├── HabitStore.swift           # Data persistence layer
├── HabitRowView.swift         # Individual habit component
└── PieChartView.swift         # Chart visualization component
```

## Design Philosophy

This app embraces extreme minimalism with:
- Pure black backgrounds
- Subtle white text and borders
- Smooth hover and completion animations
- Clean typography using SF Pro Rounded
- Intuitive gestures and interactions

## Color Palette

The app uses a curated set of colors for habit visualization:
- Red: #FF6B6B
- Teal: #4ECDC4  
- Blue: #45B7D1
- Green: #96CEB4
- Yellow: #FFEAA7
- Purple: #DDA0DD
- Mint: #98D8C8
- Gold: #F7DC6F
- Lavender: #BB8FCE
- Sky: #85C1E9

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Building

No external dependencies required. Simply open the `.xcodeproj` file in Xcode and build.

---

*Built with ❤️ using SwiftUI*