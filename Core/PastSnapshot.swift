import Foundation
import EventKit
import CryptoKit

// MARK: - Past Snapshot

struct PastSnapshot: Codable {
    var day: Date
    var calendarEvents: Int
    var focusBlocks: Int
    var completedReminders: Int
    var streakDays: Int
    var seedHex: String?
    var commitmentHex: String
}

final class PastCollector {
    private let ekStore = EKEventStore()
    
    func requestAccess() async throws {
        try await ekStore.requestFullAccessToEvents()
        try await ekStore.requestFullAccessToReminders()
    }
    
    func collectYesterday() async throws -> (snapshot: PastSnapshot, seed: Data) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yStart = cal.date(byAdding: .day, value: -1, to: today),
              let yEnd = cal.date(byAdding: .second, value: -1, to: today) else {
            throw NSError(domain: "time", code: 1)
        }
        let pred = ekStore.predicateForEvents(withStart: yStart, end: yEnd, calendars: nil)
        let events = ekStore.events(matching: pred)
        let focus = events.filter {
            let t = $0.title.lowercased()
            return t.contains("focus") || t.contains("work") || t.contains("deep")
        }.count
        
        let remPred = EKPredicate(forCompletedRemindersWith: .init(start: yStart, end: yEnd, calendars: nil))
        let reminders = try await ekStore.fetchReminders(matching: remPred) ?? []
        let completedCount = reminders.count
        
        var streak = 0
        var d = yStart
        for _ in 0..<30 {
            let s = cal.startOfDay(for: d)
            let e = cal.date(byAdding: .day, value: 1, to: s)!
            let rp = EKPredicate(forCompletedRemindersWith: .init(start: s, end: e, calendars: nil))
            let rs = try await ekStore.fetchReminders(matching: rp) ?? []
            if rs.isEmpty { break } else { streak += 1 }
            d = cal.date(byAdding: .day, value: -1, to: s)!
        }
        
        let core = PastSnapshot(day: yStart, calendarEvents: events.count, focusBlocks: focus,
                                completedReminders: completedCount, streakDays: streak,
                                seedHex: nil, commitmentHex: "")
        let coreData = try JSONEncoder().encode(core)
        let seed = randomSeed32()
        var commitInput = Data()
        commitInput.append(seed)
        commitInput.append(coreData)
        let commitment = sha256Hex(commitInput)
        
        let snap = PastSnapshot(day: yStart, calendarEvents: events.count, focusBlocks: focus,
                                completedReminders: completedCount, streakDays: streak,
                                seedHex: nil, commitmentHex: commitment)
        return (snap, seed)
    }
}

func autoSelectMode(from s: PastSnapshot) -> PlanMode {
    let heavySchedule = s.calendarEvents >= 6 || s.focusBlocks >= 3
    let goodMomentum  = s.completedReminders >= 3 || s.streakDays >= 3
    let idle          = s.calendarEvents <= 2 && s.completedReminders == 0 && s.focusBlocks == 0
    if idle { return .waveAligned }
    if heavySchedule && !goodMomentum { return .particleAligned }
    if goodMomentum { return .particleAligned }
    return .waveAligned
}

func deriveEventBytes(seed: Data, snapshot: PastSnapshot, count: Int) throws -> [UInt8] {
    var out: [UInt8] = []
    var counter: UInt64 = 0
    var core = snapshot
    core.seedHex = nil
    let coreData = try JSONEncoder().encode(core)
    while out.count < count {
        var buf = Data()
        buf.append(seed)
        buf.append(coreData)
        var c = counter.littleEndian
        withUnsafeBytes(of: &c) { buf.append(contentsOf: $0) }
        let block = SHA256.hash(data: buf)
        out.append(contentsOf: block) // 32 bytes
        counter &+= 1
    }
    out.removeLast(out.count - count)
    return out
}
