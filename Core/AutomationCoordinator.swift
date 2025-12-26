import Foundation
import BackgroundTasks
import UserNotifications

final class AutomationCoordinator: ObservableObject {
    @Published var lastSnapshot: PastSnapshot?
    @Published var todayPlan: [ActionStep] = []
    @Published var chosenMode: PlanMode = .waveAligned
    @Published var commitmentShown: String = ""
    
    private let collector = PastCollector()
    private let storeKey = "auto_manifest_state_v1"
    static let refreshTaskId = "com.your.bundle.refresh" // <-- replace with your bundle id
    
    struct Saved: Codable {
        var snapshot: PastSnapshot
        var seedHex: String
        var mode: PlanMode
        var steps: [ActionStep]
    }
    
    func bootstrap() async {
        try? await collector.requestAccess()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { _, _ in }
        await refreshIfNeeded()
        scheduleBackground()
    }
    
    @MainActor
    func refreshIfNeeded(force: Bool = False) async {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let saved = load(),
           cal.isDate(saved.snapshot.day, inSameDayAs: cal.date(byAdding: .day, value: -1, to: today)!), !force {
            self.apply(saved)
            return
        }
        do {
            let (snap, seed) = try await collector.collectYesterday()
            let events = try deriveEventBytes(seed: seed, snapshot: snap, count: 20_000)
            let mode = autoSelectMode(from: snap)
            let intention = UserDefaults.standard.string(forKey: "current_intention") ?? "Ship iOS app milestone"
            let steps = buildPlan(events: events, intent: intention, mode: mode, count: 6)
            
            var revealSnap = snap
            revealSnap.seedHex = seed.map { String(format: "%02x", $0) }.joined()
            
            let saved = Saved(snapshot: revealSnap, seedHex: revealSnap.seedHex!, mode: mode, steps: steps)
            save(saved)
            await MainActor.run { self.apply(saved) }
            scheduleNudges(for: steps)
        } catch {
            print("automation error: \(error)")
        }
    }
    
    @MainActor private func apply(_ saved: Saved) {
        self.lastSnapshot = saved.snapshot
        self.todayPlan = saved.steps
        self.chosenMode = saved.mode
        self.commitmentShown = saved.snapshot.commitmentHex
    }
    
    private func save(_ s: Saved) {
        if let d = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(d, forKey: storeKey)
        }
    }
    private func load() -> Saved? {
        guard let d = UserDefaults.standard.data(forKey: storeKey) else { return nil }
        return try? JSONDecoder().decode(Saved.self, from: d)
    }
    
    private func scheduleNudges(for steps: [ActionStep]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let top = steps.prefix(2)
        let cal = Calendar.current
        let now = Date()
        let times: [Date] = [
            cal.date(bySettingHour: 9, minute: 0, second: 0, of: now)!,
            cal.date(bySettingHour: 14, minute: 0, second: 0, of: now)!
        ]
        for (i, step) in top.enumerated() where i < times.count {
            let content = UNMutableNotificationContent()
            content.title = step.title
            content.body = step.detail
            let comps = cal.dateComponents([.hour, .minute], from: times[i])
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: False)
            let request = UNNotificationRequest(identifier: "nudge_\(i)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func scheduleBackground() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AutomationCoordinator.refreshTaskId, using: nil) { task in
            Task {
                await self.refreshIfNeeded(force: true)
                task.setTaskCompleted(success: true)
            }
        }
        let req = BGAppRefreshTaskRequest(identifier: AutomationCoordinator.refreshTaskId)
        req.earliestBeginDate = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())
        try? BGTaskScheduler.shared.submit(req)
    }
}
