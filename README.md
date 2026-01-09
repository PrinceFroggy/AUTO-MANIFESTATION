# AutoManifest (SwiftUI)

BY: ANDREW JUSTIN SOLESA

https://hostr.co/file/970/pr3V3KudJCRV/IMG_0764.png

This is a **SwiftUI** source bundle that implements the “Same past → two interpretations → different plans” automation with a **manifestation layer**:

- Collects a lightweight **Past Snapshot** from Calendar/Reminders (yesterday).
- **Commits** that snapshot with a hash (past is fixed).
- **Auto-selects** Wave (explore) vs Particle (execute) from yesterday’s facts.
- Builds a **deterministic action plan** from your *committed past* + current intention.
- Schedules **local notifications** for nudges (9am, 2pm).

> This zip contains **Swift source files** + an example **Info.plist**. Create a new Xcode project and drop these in.

## Quick Setup (Xcode 15+ / iOS 17+)

1) **Create** a new project: *iOS → App*  
   - Product Name: `AutoManifest`
   - Interface: SwiftUI  
   - Language: Swift

2) **Replace/Add files** in your project:  
   - Drag the `App/`, `Core/`, and `UI/` folders into your Xcode project (copy items if needed).  
   - Replace the default `App.swift` / `ContentView.swift` with the ones provided.

3) **Background tasks & notifications**  
   In your **Signing & Capabilities**:
   - Add **Background Modes** → enable **Background fetch**.
   - Add **Push Notifications** (not required for local, but fine).

   In **Info.plist** (or Project → Info → Custom iOS Target Properties), add:
   - `BGTaskSchedulerPermittedIdentifiers` → Array → `com.your.bundle.refresh`
   - `NSUserTrackingUsageDescription` (optional text)
   - `NSCalendarsUsageDescription` → “To analyze yesterday’s schedule.”
   - `NSRemindersUsageDescription` → “To read completed tasks for momentum.”
   - `UIApplicationSceneManifest` should be present (default).
   - For reference, see `Info/Example-Info.plist` in this bundle.

   **Important:** Replace `com.your.bundle` with your **actual** bundle identifier everywhere.

4) **Run** on a device/simulator. On first launch the app will:
   - Ask for Calendar/Reminders and Notification permissions.
   - Auto-generate **today’s plan** from yesterday’s snapshot + your intention.

5) **Notifications**  
   You’ll get nudges for the top two steps at **9:00 AM** and **2:00 PM** (local).

## Files overview

- `App/AutoManifestApp.swift` — App entry; bootstraps automation.
- `UI/AutoManifestView.swift` — Main screen (intention, snapshot, plan, refresh).
- `UI/PlotView.swift` — Tiny bar-plot (used if you extend histograms).
- `Core/CryptoHelpers.swift` — Seed & SHA256 helpers.
- `Core/Planning.swift` — “Wave/Particle” plan generators + histogram modes.
- `Core/PastSnapshot.swift` — Calendar/Reminders snapshot, auto-select logic.
- `Core/AutomationCoordinator.swift` — Orchestrates daily collect → commit → plan → notifications.
- `Info/Example-Info.plist` — Example keys to copy into your target’s Info.

## Notes

- This project uses **EventKit** for Calendar/Reminders. You can rip it out and substitute any “past facts” you like (HealthKit, Git commits, Screen Time).  
- The plan is **deterministic** for a given (snapshot, seed, intention, mode). That’s your “past is fixed” guarantee.
- **Manifestation layer** is implemented through:
  - Intention setting
  - Mode selection (Wave = unlock options, Particle = ship)
  - Concrete action steps + notifications
  - Space for evening reflections (extend `AutoManifestView` where noted)

Enjoy!
