# E-GO Workspace Repository Inventory

**Workspace Root:** `D:\E-RICKSHAW RIDE`  
**Date:** November 18, 2026  
**Auditor:** E-GO Engineering System  
**Git Branch:** `main`  
**Remote:** `origin https://github.com/StarPijush/E-RICKSHAW-RIDE.git`  
**Commit History:** 2 commits on `main` (`7f94b0e`, `2ec523d`)

---

## 1. Top-Level Directory Structure

| Directory / File | Type | Purpose | Git Tracking Status |
|---|---|---|---|
| `.git/` | Directory | Git repository metadata and index | Hidden, Repository Root |
| `E-go/` | Directory | Flutter Customer Mobile Application (Android / iOS / Web) | Tracked + active updates |
| `E-go-rider/` | Directory | Flutter Driver Mobile Application | Scaffolded (.gitkeep tracked) |
| `E-go-admin/` | Directory | Flutter Admin Web Portal | Scaffolded (.gitkeep tracked) |
| `E-go-web/` | Directory | Next.js 16 / React 19 Customer Web Portal | Untracked (ready for commit) |
| `backend/` | Directory | Shared backend services, migrations, workers | Scaffolded (.gitkeep tracked) |
| `packages/` | Directory | Shared packages (`e_go_core`, `e_go_design_system`) | Scaffolded (.gitkeep tracked) |
| `infrastructure/` | Directory | Docker, CI/CD, database, monitoring configurations | Scaffolded (.gitkeep tracked) |
| `docs/` | Directory | Monorepo architecture, booking, help, navigation, web docs | Tracked + untracked docs |
| `rapido-analysis/` | Directory | Competitive analysis and decompiled reference research | **Ignored** (Proprietary) |
| `toto-go-blueprint/` | Directory | Product and engineering blueprint documentation | **Ignored** (Proprietary) |
| `.gitignore` | File | Root Git ignore configuration | Tracked, updated |
| `EGO-AGENT-INSTRUCTIONS.md` | File | Internal AI agent instructions | **Ignored** (Proprietary) |
| `README.md` | File | Root monorepo overview and developer guide | Tracked, updated |

---

## 2. Project Sub-Applications Inventory

### 2.1 `E-go` — Flutter Customer Application
- **Framework:** Flutter 3.x (Dart 3.x) with Sound Null Safety.
- **State Management:** `ChangeNotifierProvider<AppState>` with feature repositories.
- **Core Features Implemented:**
  - Phone OTP Authentication flow (`features/auth/`)
  - Interactive Map Discovery with `flutter_map` and LatLng routing (`features/home/`)
  - Location Selection & Map Location Picker (`features/location/`)
  - Three-Stage Booking Flow (`features/booking/`)
  - Gooey Fluid Tab Navigation (`shared/widgets/ego_gooey_bottom_navigation.dart`)
  - Help & Support Screen with categorized FAQ accordion (`features/support/`)
  - Safety Center with Emergency SOS trigger (`features/safety/`)
  - Profile & Settings Management (`features/account/`)
  - My Rides & Ride Tracking (`features/rides/`)
- **Assets:**
  - Official brand assets (`assets/branding/`: `ego_brand_background.jpg`, `ego_logo_icon.png`, `ego_logo_master.jpg`, `ego_logo_primary.png`, `ego_logo_wordmark.png`)
  - Destination photos (`assets/destinations/`: `central_bus_stand.jpg`, `jhargram_palace.jpg`, `jhargram_station.jpg`, `kanak_durga_temple.jpg`)
  - Official Typography (`assets/fonts/`: Inter and Manrope TTF files)
  - Logo archive (`LOGO/IMG-20261027-WA0005.jpg`)
- **Tests:**
  - Unit tests: `test/unit/` (11 test suites covering auth, booking, pricing, validation, state)
  - Widget tests: `test/widget/` (22 test suites covering UI journeys, gooey nav, responsive viewports)
  - Integration tests: `test/integration/auth_flow_test.dart`
  - Test helpers: `test/helpers/test_tile_provider.dart`

### 2.2 `E-go-web` — Next.js Customer Web Application
- **Framework:** Next.js 16 (App Router), React 19, TypeScript 5.9, Tailwind CSS 4.
- **Core Features:**
  - Map-backed booking interface using Leaflet / OpenStreetMap.
  - Multi-step customer ride booking lifecycle (home, pickup/drop, confirm, matching, active trip).
  - In-memory mock repositories and simulation engine.
  - Responsive layout for desktop and mobile web browsers.
- **Source Paths:** `src/app/`, `src/components/`, `src/lib/`, `public/`.
- **Environment:** Safe `.env.example` provided; `.env.local` kept gitignored.

### 2.3 `E-go-rider`, `E-go-admin`, `backend`, `packages`, `infrastructure`
- Directory structures, modular architectures, and `.gitkeep` placeholders established for future expansion.

---

## 3. Git Status & Tracking Analysis

### 3.1 Modified Tracked Files
- `.gitignore`: Complete rewrite separating Flutter, Next.js, Python, Secrets, Test Output, and OS files.
- `E-go/.gitignore`: Scoped Flutter-specific rules.
- `E-go/README.md`: Updated application description.
- `E-go/pubspec.yaml`: Asset and dependency registrations.
- `E-go/lib/`: Application source refactoring into feature-first clean architecture.
- `E-go/test/`: Unit and widget test updates (`repositories_test.dart`, `booking_screens_test.dart`, `customer_journey_test.dart`, `home_screen_test.dart`).

### 3.2 Deleted Tracked Files (Refactored / Replaced)
- `E-go/lib/core/branding/ego_brand_theme.dart`: Merged into `lib/app/theme/theme.dart`.
- `E-go/lib/features/home/presentation/widgets/home_location_marker.dart`: Replaced by `home_current_location_marker.dart`.
- `E-go/lib/features/location/presentation/destination_selection_screen.dart`: Replaced by `location_selection_screen.dart`.
- `E-go/lib/features/location/presentation/pickup_selection_screen.dart`: Replaced by unified `location_selection_screen.dart`.
- `E-go/lib/features/location/presentation/recent_destinations_bottom_sheet.dart`: Replaced by `home_destination_panel.dart`.
- `E-go/test/widget/my_rides_screen_test.dart`: Refactored into `your_rides_screen_test.dart`.

### 3.3 New Untracked Source Files & Assets
- `E-go-web/`: Entire Next.js project source, configs, and assets (excluding `.next/` and `node_modules/`).
- `E-go/assets/destinations/`: 4 regional photographic assets.
- `E-go/assets/fonts/`: Inter and Manrope TTF typography files.
- `E-go/lib/core/booking_stage.dart`, `booking_validation.dart`.
- `E-go/lib/features/`: New modular auth, booking, home, location, onboarding, support, and gooey navigation components.
- `E-go/test/`: 30+ new test files across `unit/`, `widget/`, `integration/`, and `helpers/`.
- `docs/`: Comprehensive architecture, booking, help, navigation, and web documentation.

---

## 4. Generated Artifacts & Dependencies Scan

| Directory / Pattern | Size | Action |
|---|---|---|
| `E-go/.dart_tool/` | ~30 MB | **Ignored** via root & nested `.gitignore` |
| `E-go/build/` | ~45 MB | **Ignored** via root & nested `.gitignore` |
| `E-go-web/.next/` | ~230 MB | **Ignored** via root & nested `.gitignore` |
| `E-go-web/node_modules/` | ~360 MB | **Ignored** via root & nested `.gitignore` |
| `E-go/test/screenshots/` | ~4.75 MB (54 files) | **Ignored** via `**/test/screenshots/` in `.gitignore` |

---

## 5. Security & Sensitive Files Audit

- **Environment Files Found:**
  - `E-go-web/.env.example`: Non-secret template (safe to commit).
  - `E-go-web/.env.local`: Local runtime configuration (ignored via `.gitignore`).
- **Private Keys / Certificates:** 0 found.
- **Service Account JSONs:** 0 found.
- **Hardcoded AWS / GitHub Tokens:** 0 found.
- **Large Binaries (> 1 MB):** 0 untracked files outside ignored build/dependency directories.
