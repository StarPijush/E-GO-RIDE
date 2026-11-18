# E-GO Flutter — Help & Support Page Research

## 1. Existing Implementation Overview

- **Primary Screen File:** `lib/features/support/presentation/help_support_screen.dart`
- **Route Name:** `EGoRouter.helpSupport` (`/help-support`) defined in `lib/app/router.dart`.
- **Navigation Ingress Points:**
  1. `lib/features/safety/presentation/screens/safety_screen.dart`:
     - Emergency & Safety section action "Report a Safety Issue" (`Navigator.pushNamed(context, EGoRouter.helpSupport)`)
     - Passenger Support Access card "Help & Support" (`Navigator.pushNamed(context, EGoRouter.helpSupport)`)
  2. `lib/features/account/presentation/profile_screen.dart`:
     - Support section tile "Help & support" (`Navigator.pushNamed(context, EGoRouter.helpSupport)`)
- **Navigation Type:** Standalone child route pushed on top of root Navigator.
  - The 4-tab global `EgoGooeyBottomNavigation` is absent as expected on child screens.
  - Back navigation returns cleanly to the preceding screen via standard Navigator pop.

---

## 2. Existing Components & Data

### 2.1 Existing UI Components
- Current `HelpSupportScreen` is a simple `Scaffold` containing:
  - Default `AppBar(title: const Text('Help & Support'))`
  - A yellow gradient support banner card with an issue reporting dialog
  - A basic FAQ list mapping `MockData.faqs` to standard `ExpansionTile` widgets
  - A simulated emergency SOS card at the bottom

### 2.2 Existing FAQ Data
- Stored in `lib/mock_data/mock_data.dart`:
  - `FaqItem` class with `question` and `answer`.
  - `MockData.faqs` contains 7 items, but the answers in the provided HTML specification (`code(10).html`) have more specific wording and keywords.

---

## 3. Specification & Visual Target Analysis

The visual target is specified by `screen(20261117-025445).png`, `code(10).html`, and `DESIGN(20261117-025445).md`:

1. **Top App Bar:**
   - 56dp height, white background, hairline divider (`#E7EAF0`).
   - Back arrow (`Icons.arrow_back`, `#142B45`).
   - Centered title "Help & Support" (Manrope, 18px bold, `#142B45`).
   - Action button on right: `Icons.contact_support` / `Icons.help_outline` button triggering the contact modal.
2. **Hero / Introduction:**
   - Title: "How can we help?" (Manrope, 24px bold, `#142B45`).
   - Subtitle: "Find answers, report trip issues, or contact local support in E-GO" (Inter, 14px, `#8490A0`).
3. **Search Bar:**
   - Rounded 12px (`rounded-xl`), white background, light border (`#E5EAF0`).
   - Leading search icon, placeholder: "Search for help, topics, or FAQs...".
   - Clear icon button when text is present.
   - Result count stats row with clear action.
   - Live query filtering across questions, answers, and tags.
   - Dedicated "No matching topics found" empty state with "Reset search" CTA.
4. **Browse by Topic (4 categories in a grouped card):**
   - White rounded card (`rounded-2xl`, 16px radius) with dividers.
   - Rides & Booking (`Icons.electric_rickshaw` / vehicle) -> filters FAQs.
   - Payments & Fare (`Icons.payments` / wallet) -> filters FAQs.
   - Account & Profile (`Icons.person`) -> filters FAQs.
   - Safety & Emergency (`Icons.shield`) -> filters FAQs and/or shows safety center modal.
   - Smooth auto-scroll to FAQ section.
5. **Frequently Asked Questions (7 accordion cards):**
   - Individual rounded cards with light border and subtle shadow.
   - Question in Inter 14px bold, `#142B45`.
   - Rotating chevron (`keyboard_arrow_down`).
   - Smooth expand/collapse, allowing only one card open at a time.
   - Preserves all 7 questions and exact answers from HTML reference.
6. **Still Need Help? Card:**
   - White rounded card with headset icon (`Icons.headset_mic`) and title.
   - Subtitle: "Our local customer care team is available to assist you."
   - Full-width yellow button (`#FFC928`, height 54dp, 12px rounded corners) with chat icon and "Contact support".
7. **Contact Support Modal / Bottom Sheet:**
   - Native Flutter modal bottom sheet with drag handle and close button.
   - Header: "Customer Care", subtitle: "Jhargram Help Desk · 6 AM – 10 PM".
   - Quick channels:
     - Live Chat (`Icons.chat`, `< 2 min wait`)
     - Call Desk (`Icons.call`, `Toll-free voice`)
   - Support request form:
     - Issue Category dropdown (Fare, Lost Item, Ride & Driver, Account, Safety)
     - Trip Reference text field
     - Details multiline text field (required)
     - Cancel and Send Request buttons with loading and feedback simulation.
8. **Safety Center Information Modal:**
   - Sheet displaying verified driver details, live route sharing, and local hotline info.

---

## 4. Reusable Architecture & Plan

1. **Model Layer (`lib/features/support/domain/faq_item.dart` or separate FAQ data model):**
   - `SupportFaq`: question, answer, category, keywords.
   - Centralized dataset of the 7 official FAQs.
2. **Component Structure:**
   - `HelpSupportScreen`: main coordinator, state management (search text, selected topic, expanded FAQ id, scrolling).
   - `HelpSupportAppBar`: custom preferred-size app bar.
   - `HelpSearchField`: search input with clear button and result counter.
   - `HelpTopicGrid` / `HelpTopicList`: 4-topic card with icons.
   - `FaqAccordionList` & `FaqAccordionCard`: smooth animated expansion tiles.
   - `ContactSupportSheet`: modal bottom sheet with contact channels & form.
   - `SafetyCenterSheet`: modal bottom sheet for safety information.
3. **Preserve Design Tokens:**
   - Brand yellow: `#FFC928`
   - Brand navy: `#142B45`
   - Background: `#F5F7FA`
   - Card surface: `#FFFFFF`
   - Divider/border: `#E7EAF0` / `#E5EAF0`
   - Slate muted: `#8490A0`
   - Fonts: Manrope (headings) & Inter (body).
