# E-GO — Engineering Monorepo

E-GO is a ride-hailing platform for **Toto/e-rickshaw trips in Jhargram, West Bengal, India**. The MVP is Toto-only, cash-only, phone-OTP authenticated, and on-demand.

---

## 1. Repository Layout

```
D:\E-RICKSHAW RIDE
├── E-go/            Customer Mobile Application (Flutter for Android, iOS & Web)
├── E-go-web/        Customer Web Portal (Next.js 16, React 19, TypeScript, Tailwind)
├── E-go-rider/      Driver Partner Application (Flutter — scaffolded for upcoming phase)
├── E-go-admin/      Administrative Console (Flutter Web — scaffolded for upcoming phase)
├── backend/         Go API foundation, Supabase/PostGIS migrations, RLS, and contracts
├── packages/        Shared Dart packages (e_go_core, e_go_design_system)
├── infrastructure/  Docker, CI/CD, database schemas, and deployment configurations
└── docs/            System architecture, booking workflows, navigation, and web specs
```

---

## 2. Applications Status & Capabilities

### 🟢 `E-go` — Customer Mobile Application (Implemented & Test-Verified)
- **Tech Stack:** Flutter 3.x, Dart 3.x, Sound Null Safety, Provider (`AppState`), `flutter_map` (OpenStreetMap).
- **Status:** **Implemented** with rich mock-data repositories and offline-first simulation:
  - **Phone OTP Authentication:** Seamless 10-digit Indian phone login, OTP verification, and onboarding sequence.
  - **Map-First Home Screen:** Interactive Jhargram map canvas, responsive destination discovery panel ("Where to?").
  - **Three-Stage Booking Journey:** Stage 1 (Discovery) → Stage 2 (Location Selection with interactive map pin) → Stage 3 (Place Order with live fare estimates & Toto vehicle selection).
  - **Gooey Fluid Navigation:** Custom canvas-rendered liquid tab bar connecting Home, My Rides, Safety, and Account.
  - **Help & Support:** Categorized searchable FAQs, interactive accordion, and direct support modals.
  - **Safety Center:** Trusted emergency contacts, ride sharing, and quick SOS emergency trigger.
  - **My Rides & History:** Filter tabs (Active, Completed, Cancelled) with trip summaries.
  - **Automated Test Suite:** +290 passing tests spanning unit, widget, responsive viewports, and integration flows.

### 🟢 `E-go-web` — Customer Web Portal (Implemented)
- **Tech Stack:** Next.js 16 (App Router), React 19, TypeScript 5.9, Tailwind CSS 4, Leaflet map engine.
- **Status:** **Implemented** for desktop and mobile web browsers:
  - Interactive booking flow with address lookups and OpenStreetMap integration.
  - Simulated customer auth and deterministic ride lifecycle state machine.
  - Responsive design tokens aligned with E-GO branding.

### 🟡 `E-go-rider` — Driver Partner Application (Scaffolded)
- **Tech Stack:** Flutter / Dart.
- **Status:** Architecture and directory layout scaffolded. Driver onboarding, document verification, ride dispatch, and turn-by-turn navigation scheduled for next release phase.

### 🟡 `E-go-admin` — Administrative Console (Scaffolded)
- **Tech Stack:** Flutter Web.
- **Status:** Architecture and directory layout scaffolded. Driver verification, active fleet tracking, dynamic fare configuration, and dispatch analytics scheduled for upcoming phase.

### 🟡 `backend` (Stage 0 foundation) · `packages` & `infrastructure` (placeholders)
- The Go API currently provides health/readiness, Supabase JWT verification, and pgx transaction foundations. PostgreSQL schema and RLS are defined; booking, dispatch, ride, location, cash, and admin workflows are not implemented.
- Shared Dart packages and infrastructure automation remain unimplemented.

---

## 3. Official Brand Identity

The E-GO design language reflects clean contrast, accessibility, and high visibility:

- **Primary Brand Yellow:** `#FFC928` / `#F5C928` (High-visibility Toto vehicle identity)
- **Deep Navy & Core Black:** `#142B45` and `#171717` (Strong typographic hierarchy)
- **Surfaces & Backgrounds:** Crisp White (`#FFFFFF`) with soft neutrals (`#F5F7FA`)
- **Semantic Indicators:** Green (`#16A34A` for completed rides), Amber (`#D97706` for in-flight/matching), Red (`#DC2626` for emergencies/cancellations)
- **Typography:** **Manrope** for primary headings and brand accents; **Inter** for clean body text and numeric displays.

---

## 4. Development Setup

### Running the Customer Flutter App (`E-go`)
```powershell
cd E-go
flutter pub get
flutter test
flutter run
```

### Running the Customer Web App (`E-go-web`)
```powershell
cd E-go-web
npm install
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 5. Documentation Directory

Detailed specifications and architectural decisions live in the [`docs/`](docs/) directory:

- [Booking System Architecture](docs/booking_system/booking_system_architecture.md)
- [Booking Workflow & State Transitions](docs/booking_system/booking_workflow.md)
- [Global Navigation Architecture](docs/navigation/global_navigation_architecture.md)
- [Help & Support Specification](docs/help_support/help_support_implementation_report.md)
- [Customer Web Architecture](docs/web/ego_web_architecture.md)
- [Flutter App Documentation](E-go/docs/)
- [Repository Cleanup & Audit Reports](docs/repository_cleanup/)
