import SwiftUI

struct AutoManifestView: View {
    @EnvironmentObject var auto: AutomationCoordinator
    @State private var intention: String = UserDefaults.standard.string(forKey:"current_intention") ?? ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Your intention for today", text: $intention, onCommit: {
                    UserDefaults.standard.set(intention, forKey: "current_intention")
                })
                .textInputAutocapitalization(.sentences)
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                
                if let s = auto.lastSnapshot {
                    Group {
                        Text("Yesterday (fixed past)").font(.headline)
                        Label("Events: \(s.calendarEvents)", systemImage: "calendar")
                        Label("Focus blocks: \(s.focusBlocks)", systemImage: "timer")
                        Label("Completed reminders: \(s.completedReminders)", systemImage: "checkmark")
                        Label("Streak: \(s.streakDays) day(s)", systemImage: "flame")
                        Text("Commitment:").font(.caption).foregroundStyle(.secondary)
                        Text(auto.commitmentShown).font(.footnote).monospaced().lineLimit(1).minimumScaleFactor(0.5)
                        if let seed = s.seedHex {
                            Text("Seed:").font(.caption).foregroundStyle(.secondary)
                            Text(seed).font(.footnote).monospaced().lineLimit(1).minimumScaleFactor(0.5)
                        }
                    }
                } else {
                    Text("First run? Tap Refresh to generate your plan for today.")
                }
                
                Divider().padding(.vertical, 6)
                
                Text("Today’s mode: \(auto.chosenMode == .waveAligned ? "Wave (explore)" : "Particle (execute)")")
                    .font(.headline)
                
                if auto.todayPlan.isEmpty {
                    Text("No plan yet. Tap Refresh.")
                } else {
                    List(auto.todayPlan) { step in
                        VStack(alignment: .leading) {
                            Text(step.title).bold()
                            Text(step.detail).font(.footnote).foregroundStyle(.secondary)
                        }
                    }.frame(maxHeight: 320)
                }
                
                HStack {
                    Button("Refresh now") { Task { await auto.refreshIfNeeded(force: true) } }
                        .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Auto-Manifest")
        }
    }
}
