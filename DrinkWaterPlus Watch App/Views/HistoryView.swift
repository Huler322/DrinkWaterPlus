import SwiftUI

struct HistoryView: View {
    let history: [String: Int]
    let dailyGoal: Int
    
    // ✅ теперь tuples (.0 / .1)
    var sortedDays: [(String, Int)] {
        history.sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Water History")
                .font(.headline)
                .foregroundColor(.cyan)
            
            ForEach(Array(sortedDays.prefix(7)), id: \.0) { day, amount in
                HStack {
                    Text(shortDate(day))
                        .font(.system(size: 13))
                        .frame(width: 45, alignment: .leading)
                    
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cyan.opacity(0.6))
                            .frame(
                                width: barWidth(for: amount, in: geo.size.width),
                                height: 8
                            )
                    }
                    .frame(height: 8)
                    
                    Text("\(amount) ml")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    private func barWidth(for amount: Int, in maxWidth: CGFloat) -> CGFloat {
        let percent = min(Double(amount) / Double(dailyGoal), 1.0)
        return CGFloat(percent * maxWidth)
    }
    
    private func shortDate(_ dateStr: String) -> String {
        if let date = ISO8601DateFormatter().date(from: dateStr) {
            let f = DateFormatter()
            f.dateFormat = "dd.MM"
            return f.string(from: date)
        } else {
            return String(dateStr.suffix(5)).replacingOccurrences(of: "-", with: ".")
        }
    }
}
