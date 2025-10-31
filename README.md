# Game Sentry

A Flutter application for managing kids’ gaming time with smart rules, Appwrite-backed persistence, and real-time session tracking. The app enforces healthy gaming habits via configurable play windows, lunch breaks, and a “time between breaks” system.

## Table of Contents
- Overview
- Key Features
- Core Concepts & Rules
- Session & Break Logic (Important)
- Notifications & Warnings
- Data Model
- Architecture & State
- Development (Setup, Linting, Run)
- Roadmap / TODOs
- Known Issues & Notes

## Overview
Game Sentry helps parents manage and monitor kids’ gaming activity. It supports multiple sessions per day, respects playtime windows and breaks, and persists data via Appwrite.

## Key Features
- Kids profile management (username, avatar, limits, preferences)
- Appwrite-backed session tracking (start/stop, duration aggregation)
- Smart validation of gaming availability:
  - Daily limit tracking (with overtime supported)
  - Playtime window enforcement (e.g., 07:00–22:00)
  - Lunch break enforcement (e.g., 12:30–14:00)
  - Minimum break time between major play blocks
- New: “Time Between Breaks” system using `max_session_limit` (see next section)
- Real-time UI updates and warnings
- Overtime tracking (keeps running past daily limit but flags overtime)
- Configurable rules per kid
- Clear in-app messages for why gaming is or isn’t available

## Core Concepts & Rules
- Daily Limit: Maximum total playtime allowed per day (but we do not force-stop; we track overtime)
- Time Between Breaks: `max_session_limit` defines how much total gaming time is allowed before a mandatory break must occur, regardless of how many discrete sessions occurred
- Playtime Window: Allowed hours within the day when gaming is permitted
- Lunch Break: No gaming allowed during lunch break window
- Minimum Break Time: Required cool-down period after a mandatory break is triggered, before gaming can resume

## Session & Break Logic (Important)
- `max_session_limit` is the total “time between breaks”. Example with max 2 hours:
  - Sessions: 30 min + 45 min + 45 min = 120 minutes → Break enforced
  - Multiple short sessions count cumulatively toward the limit
- Warnings:
  - At 80% of `max_session_limit`, the UI shows a warning (e.g., at 96 minutes for 120 minutes limit)
  - At 100%, a mandatory break is triggered and the active session is stopped
- After the mandatory break ends (minimum break time configured per kid), a new 2-hour block (or configured `max_session_limit`) becomes available
- Daily limit behavior:
  - We do not force-stop on daily limit; we track overtime and show it in UI
- Playtime window and lunch break are always enforced (attempts to play outside these windows are blocked)

## Notifications & Warnings
- Warning badge and color changes when approaching a break (>= 80% of `max_session_limit`)
- “Break soon” UI callouts
- Clear “Mandatory break” messages when the break is enforced
- Overtime indicator when daily time exceeds the configured daily maximum

## Data Model (Appwrite)
Gaming session document fields (collection: gaming sessions):
- `kid_id`: string (or relation) — kid identifier
- `status`: boolean — true = active, false = completed
- `date`: string — ISO date or YYYY-MM-DD
- `start_time`: string — HH:mm
- `stop_time`: string — HH:mm or empty string when active
- `duration`: integer — minutes (0 for active sessions)

Notes:
- Code supports flexible types for some fields (handles strings, relations, lists) to accommodate schema changes
- Queries use boolean `status` (true/false) to find active/completed sessions

## Architecture & State
- Riverpod StateNotifier manages `SessionState`:
  - `currentSession`, `isActive`, `canStart`
  - `dailyTimeUsed`, `dailyTimeRemaining`, `overtime`
  - `timeSinceLastBreak`, `timeUntilBreak`, `breakWarning`, `breakRequired`
  - `validation` + `validationMessage`
  - Rule helpers: `isInPlaytimeWindow`, `isInLunchBreak`, `needsBreak` (maps to `breakRequired` in the new logic)
- Timers:
  - Session timer: updates every second during active session
  - Validation timer: runs periodically (60s) to avoid UI flicker
- Validation flow:
  - Starting a session checks play window, lunch break, daily limit, and whether a mandatory break is required
  - Active session is force-stopped only by mandatory break (time-between-breaks reached) or rules (playtime window/lunch break)

## Development
### Prerequisites
- Flutter (stable channel recommended)
- Appwrite instance and credentials

### Install dependencies
```
flutter pub get
```

### Analyze & Lint
- The project uses `flutter_lints` (enabled via `analysis_options.yaml`)
```
flutter analyze
```

### Run
```
flutter run
```

### Project Structure Highlights
- `lib/src/features/kids` — kids profiles and repository
- `lib/src/features/gaming/data/models` — `GamingSession`, `SessionState`
- `lib/src/features/gaming/data/repositories` — Appwrite repository
- `lib/src/features/gaming/presentation/notifiers` — `GamingSessionNotifier` (timers, validation, break logic)
- `analysis_options.yaml` — lint rules (Flutter recommended)

## Roadmap / TODOs
- Persist last mandatory break time per kid (new field) to compute `timeSinceLastBreak` more precisely across app restarts
- Push/local notifications for warnings (“Break in 5 minutes”) and mandatory breaks
- Parental dashboard with daily/weekly reports and charts
- Configurable warning threshold (e.g., 70%, 80%, 90% of `max_session_limit`)
- Optional soft break mode (prompt only) vs hard break (auto-stop)
- Multi-device sync and conflict resolution
- Accessibility pass: larger fonts, better contrast, screen reader labels
- Internationalization (i18n)
- Unit and widget tests for session/break logic
- CI pipeline with formatting and analysis gates

## Known Issues & Notes
- Appwrite schema differences: some fields may be returned as relations/maps; the code coerces values safely
- Daily overtime is informational only (does not stop sessions)
- Validation timer runs every 60 seconds to minimize UI flicker; real-time session timer still updates every second
- The current calculation of `timeSinceLastBreak` is based on today’s accumulated time and the current session; persisting explicit break timestamps is planned in the roadmap

---

### Utilities
#### Number Utilities
Helpers for parsing and validating integers with proper error handling:
- `parseInt` — safely parse string to int or return null
- `parseIntWithDefault` — parse with a default fallback
- `isValidInt` — validate numeric strings

See [docs/number_utils.md](docs/number_utils.md) for examples.

---

### Contributing
Issues and PRs are welcome. Please run `flutter analyze` before submitting changes and adhere to the existing code style and architecture patterns.
