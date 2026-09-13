# Trim — The Phone-First AI Product Manager

<p align="center">
  <img src="https://raw.githubusercontent.com/LuxShar007/Trim/main/web/icons/Icon-192.png" width="84" height="84" alt="Trim Logo" />
</p>

<p align="center">
  <strong>Ruthlessly trim chaotic, over-scoped product ideas into locked, executable MVPs.</strong><br>
  <em>"Remove what does not matter."</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-black" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-emerald" alt="License" />
</p>

---

## 💡 The Philosophy

Most early-stage software dies not from a lack of features, but from an excess of them. 

**TRIM** is a minimalist, phone-first AI Product Manager designed for founders, solo makers, and engineers. You dump a messy, chaotic, 15-feature product concept, and TRIM ruthlessly dissects it:

* **Identifies the Core Value**: What actual problem is being solved?
* **Isolates the Must-Haves**: The 2–3 capabilities required for user value.
* **Discards the Bloat**: Rejects features with blunt, uncompromising justifications.
* **Prescribes Build First Sequence**: A numbered, non-overlapping execution roadmap.
* **Delivers Product Truth**: Strategic, realistic guidance on what actually moves metrics.
* **Calculates Scope Reduction**: Telemetry highlighting exactly how much complexity was eliminated.
* **Locks the MVP Scope**: A deliberate contract to commit to this version and prevent feature creep before shipping.

---

## ✨ Core Features

### 1. 🧠 Brain Dump Canvas
* OLED edge-to-edge minimalist canvas free of noise and dashboards.
* Live quiet character telemetry counter.
* One-tap sample bloated idea insertion for rapid testing.
* Tactile, spring-physics **Trim the Fat** CTA with double-tap protection and cancellation safety.

### 2. ⚡ 4-Stage Processing Pipeline
* Real product sequence without fake progress bars or developer jargon:
  `TRIM · ANALYZING` ➔ `UNDERSTANDING` ➔ `TRIMMING` ➔ `LOCKING` ➔ `{TOTAL} → {SURVIVORS} SURVIVE`.
* Continuous animated liquid feature separation and noise collapse.

### 3. 🎴 Morphing Verdict Cards (`TrimMorphCard`)
* Custom spring-physics morphing cards — the card remains the exact same visual object throughout expansion and collapse.
* **The Core**: Emerald check badges and anchored expansion revealing **"WHY KEEP?"** justifications.
* **The Noise**: Strikethrough titles with red cut tags and anchored expansion revealing **"WHY CUT?"** reasoning.
* **Progressive Noise Disclosure**: When $> 5$ noise features exist, displays the top 4 items with a spring-animated `+ X MORE CUT` expansion trigger.

### 4. 🔒 Lock & Reopen MVP
* **Lock MVP**: Expanding restrained glass surface detailing committed capabilities vs rejected features.
* Persists `isLocked = true` to the local session database with tactile haptic feedback.
* **Reopen MVP**: Allows unlocking and reconsideration without invalidating or altering the AI verdict.

### 5. 🗂️ Local-First Trim Workspace
* **Zero Accounts, Zero Cloud, Zero Tracking**: Your device is your product memory.
* **Dynamic Telemetry Grid**:
  * `IDEAS TRIMMED`
  * `FEATURES CUT`
  * `AVG SCOPE REMOVED (%)`
* **Recent Trims History**: Reverse-chronological session list displaying scope reduction badges (`18 → 3`), relative timestamps, and `LOCKED` status pills.
* **Instant Offline Reopening**: Open any past verdict immediately with zero network requests or API costs.
* **Empty Workspace State**: Minimalist onboarding with `"TRIM AN IDEA"` fast action.

### 6. 📄 Clean Markdown Export
* Standardized specification export directly shareable to GitHub issues, Notion, Linear, or team Slack.
* Formatted strictly according to the TRIM spec:
  * `# Project Name`
  * `## Core Value`
  * `## MVP` (`### Must-Haves`, `### Explicitly Cut`)
  * `## Build First`
  * `## Product Truth`
  * `## MVP Status` (`Locked` / `Unlocked`)
  * `## Scope Reduction` (`18 → 3`, `83% removed`)
* Smooth button morphing states: `EXPORT MVP` ➔ `EXPORTING...` ➔ `EXPORTED ✓`.

---

## 🎨 Visual Design Language & Typography

TRIM follows its own philosophy: **Remove what does not matter.**

* **Canvas**: Pure OLED Black (`#000000`) with restrained near-black glass surfaces (`#0D0D11` / `#111116`).
* **Color Accents**:
  * **Emerald (`#10B981`)**: Strictly reserved for `PASS` badges, surviving feature counts, and locked states.
  * **Muted Red (`#EF4444`)**: Strictly reserved for `CUT` badges and rejected features.
  * **Monster Orange (`#FF5E00`)**: Reserved for primary action controls and the signature logo dot.
* **Typography Hierarchy**:
  * **Primary UI Font**: `Manrope` (Humanist, editorial, modern sans-serif) for titles, body, reasons, buttons, and Product Truth.
  * **Technical Monospace Font**: `JetBrains Mono` strictly reserved for section labels (`THE CORE`, `THE NOISE`, `BUILD FIRST`), status badges (`PASS`, `CUT`), and telemetry counters.
* **Motion Physics**: Restrained spring simulations and liquid morphing (`SpringSimulation`, `Curves.easeOutBack`). Zero linear animations.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technologies Used |
| :--- | :--- |
| **Framework** | Flutter 3.47+ / Dart 3.13+ |
| **Database** | Pure-Dart `Hive` & `Hive Flutter` (fast, structured local document storage) |
| **Typography** | `google_fonts` (`Manrope`, `JetBrains Mono`) |
| **Export** | `share_plus` |
| **AI Inference** | Groq API (`openai/gpt-oss-120b`) with request-scoped cancellation tokens, 60s timeouts, and robust error classification |

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (version $\ge 3.13.0$)
* Android Studio / Xcode / VS Code
* A free [Groq API Key](https://console.groq.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/LuxShar007/Trim.git
   cd Trim
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   * **Chrome (Web):**
     ```bash
     flutter run -d chrome
     ```
   * **Android / iOS:**
     ```bash
     flutter run
     ```

4. **Add your Groq API Key:**
   * In the app, **long-press the Trim wordmark** on the top left of the Brain Dump screen to open the secure API Key modal.
   * Paste your Groq API key (stored securely and solely on your local device).

---

## 🧪 Testing & Verification

TRIM is covered by an automated test suite verifying serialization, database persistence, interaction flows, and request lifecycles:

```bash
# Run code analysis
flutter analyze

# Run all test suites
flutter test
```

### Key Test Suites:
* `test/trim_session_test.dart`: Serialization, deserialization, and Section 24 Markdown formatting.
* `test/trim_session_repository_test.dart`: Local Hive CRUD, reverse-chronological sorting, and dynamic telemetry calculations.
* `test/trim_workspace_flow_test.dart`: Workspace empty/populated views, progressive noise disclosure, and Lock/Reopen MVP interactions.
* `test/trim_request_lifecycle_test.dart`: 60s timeout handling, cancellation tokens, distinct error headers, and 10 consecutive triage executions.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
