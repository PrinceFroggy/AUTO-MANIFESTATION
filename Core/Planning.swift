import Foundation
import SwiftUI

// MARK: - Modes & Histogram

enum Mode { case wave, particle }
enum PlanMode: String, Codable { case waveAligned, particleAligned }

func histogram(events: [UInt8], bins: Int, mode: Mode) -> [Int] {
    var hist = Array(repeating: 0, count: bins)
    switch mode {
    case .wave:
        for (i, b) in events.enumerated() {
            let x = Double(i % bins)
            let p = Double(b) / 255.0
            let val = 0.5 * (1 + sin(2 * .pi * (x / Double(bins)) * 6.0 + p * 2 * .pi))
                    + 0.3 * (1 + sin(2 * .pi * (x / Double(bins)) * 11.0 + p * 2 * .pi))
            let idx = Int(x)
            hist[idx] += Int(val * 10.0)
        }
    case .particle:
        let _ = bins / 2
        for b in events {
            let left = (b & 0b1) == 0
            let spread = Int(b % 12) - 6 // ±6 bins
            let center = left ? bins/4 : 3*bins/4
            let idx = max(0, min(bins-1, center + spread))
            hist[idx] += 10
        }
    }
    return hist
}

// MARK: - Intent & Plan

struct Intent: Identifiable, Codable {
    let id = UUID()
    var text: String
    var createdAt: Date = .now
}

struct ActionStep: Identifiable, Codable {
    let id = UUID()
    var title: String
    var detail: String
    var done: Bool = false
}

/// Deterministic planner from events + intent + mode
func buildPlan(events: [UInt8], intent: String, mode: PlanMode, count: Int = 6) -> [ActionStep] {
    var pool = events
    pool += Array(mode.rawValue.utf8)
    pool += Array(intent.lowercased().utf8)
    var ix = 0
    func nextByte() -> UInt8 { defer { ix = (ix + 1) % pool.count }; return pool[ix] }

    let waveLibrary: [(String, String)] = [
        ("Journal: rewrite the story", "Describe a past event as a setup for your success. Extract 3 strengths."),
        ("Visualization sprint (5 min)", "Close eyes; visualize the goal completed. Note one surprising aid."),
        ("Skill micro-rep (10 min)", "Do a focused micro-practice related to your goal. Log the change."),
        ("Idea remix (x10)", "Generate 10 variants of your solution; keep the weirdest 2."),
        ("Frictions → fuel", "List 3 blockers from the past; write 1 advantage from each."),
        ("Signal to self", "Place a visible token/note that encodes your goal in one word.")
    ]
    let particleLibrary: [(String, String)] = [
        ("Outreach x1", "Message one person who can move this forward. Ask a small, specific thing."),
        ("Commitment token", "Schedule or pay a small non-refundable item to act this week."),
        ("Evidence binder", "Collect 3 datapoints that you’re closer than last week."),
        ("Environment tweak", "Change one default (home screen, desk, route) to reduce friction."),
        ("Ship a slice (45m)", "Publish a thin vertical slice today, however rough."),
        ("Follow-up now", "Send a 3-line follow-up from a prior thread. Be clear.")
    ]

    let lib = (mode == .waveAligned) ? waveLibrary : particleLibrary
    let keywords = intent.lowercased().split(whereSeparator: { !$0.isLetter })
    func score(_ i: Int) -> Int {
        let b = Int(nextByte())
        return b + (keywords.isEmpty ? 0 : (keywords.count * (i+1) % 37))
    }
    let choices = lib.enumerated().sorted { score($0.offset) > score($1.offset) }
        .prefix(count).map { ActionStep(title: $0.element.0, detail: $0.element.1) }
    return choices
}
