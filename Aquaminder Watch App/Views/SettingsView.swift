import SwiftUI

struct SettingsView: View {
    @Binding var dailyGoal: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Daily Goal")
                .font(.headline)
                .foregroundColor(.cyan)
            
            Picker("Goal", selection: $dailyGoal) {
                ForEach([2000, 2500, 3000, 3500, 4000, 4500, 5000], id: \.self) { value in
                    Text("\(value) ml").tag(value)
                }
            }
            .labelsHidden()
            
            Button("Done") {
                dismiss()
            }
            .font(.system(size: 15))
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding()
    }
}
