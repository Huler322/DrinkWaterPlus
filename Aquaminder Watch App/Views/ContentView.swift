import SwiftUI
import WatchKit
import Combine
import CoreMotion
import UserNotifications

struct ContentView: View {
    @AppStorage("waterAmount") private var waterAmount: Int = 0
    @AppStorage("dailyGoal") private var dailyGoal: Int = 2500
    @AppStorage("waterHistory") private var waterHistoryData: Data = Data()
    
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var phase: CGFloat = 0
    
    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getHistory() -> [String: Int] {
        (try? JSONDecoder().decode([String: Int].self, from: waterHistoryData)) ?? [:]
    }
    
    private func setHistory(_ newValue: [String: Int]) {
        if let encoded = try? JSONEncoder().encode(newValue) {
            waterHistoryData = encoded
        }
    }
    
    @StateObject private var motion = MotionManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    GeometryReader { geo in
                        let height = geo.size.height
                        let progress = CGFloat(Double(waterAmount) / Double(dailyGoal))
                        let waterLevel = max(0, min(height * progress, height)) // clamp
                        
                        ZStack(alignment: .bottom) {
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.4),
                                    Color.cyan.opacity(0.2)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: waterLevel)
                            .animation(.easeInOut(duration: 0.3), value: waterAmount)
                            
                            if progress > 0 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(height: 2)
                                    .offset(y: -waterLevel)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .mask(GlassShape())
                    }
                    .frame(width: 80, height: 110)
                    
                    GlassShape()
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                        .frame(width: 80, height: 110)
                }
                .padding(.top, 6)

                Text("\(waterAmount) / \(dailyGoal) ml")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.bottom, 4)
                
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        waterButton("+100", amount: 100)
                        waterButton("+200", amount: 200)
                    }
                    waterButton("+500", amount: 500)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                
                HStack(spacing: 20) {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(dailyGoal: $dailyGoal)
                    }
                    
                    Button {
                        showingHistory.toggle()
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.cyan)
                    }
                    .sheet(isPresented: $showingHistory) {
                        HistoryView(history: getHistory(), dailyGoal: dailyGoal)
                    }
                }
                Button("Reset") {
                    resetWater()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
                .padding(.top, 4)
            }
            .padding(.horizontal)
        }
        .onDisappear {
            saveTodayProgress()
        }
        .onAppear {
            requestNotificationPermission()
            checkForNewDay()
            scheduleWaterReminders()
        }
    }
    
    private func checkForNewDay() {
        let lastSavedDate = UserDefaults.standard.string(forKey: "lastSavedDate")
        let today = todayKey

        if lastSavedDate != today {
            waterAmount = 0
            saveTodayProgress()
            UserDefaults.standard.set(today, forKey: "lastSavedDate")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error:", error)
            }
        }
    }
    
    private func scheduleWaterReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let totalGoal = dailyGoal
        let intervals: Int
        
        switch totalGoal {
        case ..<2000:
            intervals = 3
        case ..<3000:
            intervals = 5
        case ..<4000:
            intervals = 6
        default:
            intervals = 8
        }
        
        let step = 24.0 / Double(intervals)
        for i in 1...intervals {
            let hours = step * Double(i)
            let content = UNMutableNotificationContent()
            content.title = "💧 Time to drink water!"
            content.body = "About \(max(totalGoal - waterAmount, 0)) ml left to reach your goal."
            content.sound = .default
            
            var date = DateComponents()
            date.hour = Int(hours) % 24
            date.minute = Int((hours.truncatingRemainder(dividingBy: 1)) * 60)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            let request = UNNotificationRequest(identifier: "water_reminder_\(i)", content: content, trigger: trigger)
            
            center.add(request)
        }
    }

    
    private func waterButton(_ label: String, amount: Int) -> some View {
        Button(label + " ml") {
            addWater(amount)
        }
        .font(.system(size: 16, weight: .medium))
        .buttonStyle(.plain)
        .frame(width: 80, height: 34)
        .background(Color.cyan.opacity(0.25))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
        )
    }
    
    private func addWater(_ amount: Int) {
        WKInterfaceDevice.current().play(.click)
        waterAmount = min(waterAmount + amount, dailyGoal)
        saveTodayProgress()

        if waterAmount >= dailyGoal {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            let content = UNMutableNotificationContent()
            content.title = "🎉 Goal reached!"
            content.body = "You’ve completed your daily water goal!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let request = UNNotificationRequest(identifier: "goal_reached", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func resetWater() {
        WKInterfaceDevice.current().play(.failure)
        waterAmount = 0
        saveTodayProgress()
    }
    
    private func saveTodayProgress() {
        var updated = getHistory()
        updated[todayKey] = waterAmount
        setHistory(updated)
    }
    
    private func waterHeight() -> CGFloat {
        let percent = min(Double(waterAmount) / Double(dailyGoal), 1.0)
        return CGFloat(percent * 100)
    }
}
