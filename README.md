# TRIM

> TRIM is a phone-first AI Product Manager that turns bloated product ideas into focused, locked MVPs.

<p align="center">
  <img src="https://raw.githubusercontent.com/LuxShar007/Trim/main/web/icons/Icon-192.png" width="84" height="84" alt="Trim Logo" />
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" /></a>
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20Web-black" alt="Platforms" />
  <img src="https://img.shields.io/badge/Tests-119%20Passing-10B981" alt="Tests" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-emerald" alt="License" /></a>
</p>

---

## What is TRIM?

TRIM transforms chaotic, over-engineered feature wishlists into razor-sharp, buildable MVPs in seconds.

Instead of bloated dashboards and endless user stories, TRIM establishes a strict, non-negotiable triage pipeline:

$$\text{CHAOS} \longrightarrow \text{AI ANALYSIS} \longrightarrow \text{CORE VALUE} \longrightarrow \text{MUST-HAVES} \longrightarrow \text{DISCARDED BLOAT} \longrightarrow \text{BUILD FIRST} \longrightarrow \text{PRODUCT TRUTH} \longrightarrow \text{SCOPE REDUCTION} \longrightarrow \text{MVP LOCK} \longrightarrow \text{BUILD DESK}$$

---

## Why TRIM?

Most software projects fail not because they lack features, but because they have far too many of them.

Feature creep kills velocity, dilutes core value, confuses early users, and burns out founders. TRIM acts as an objective, brutally honest product manager directly in your pocket. Its singular purpose is to enforce discipline: **Remove what does not matter.**

---

## Core Experience

### 1. Brain Dump
An edge-to-edge, distraction-free mobile canvas designed for rapid thought capture. Features live character telemetry, instant sample prompt insertion, and robust input validation.

### 2. Voice Input
Phone-native speech recognition pipeline with seamless `TYPE` $\longleftrightarrow$ `SPEAK` mode toggling. Dictate ideas on the fly, review and edit transcripts with full user agency, and confirm before submission.

### 3. AI Trimming
A cinematic 4-phase radar transformation engine that transparently visualizes reasoning states:
1. `AUDITING_SCOPE` (0–25%)
2. `EXTRACTING_ESSENCE` (25–50%)
3. `SEVERING_BLOAT` (50–75%)
4. `SYNTHESIZING_MVP` (75–100%)

### 4. Verdict
Delivers a quantitative **MVP Score** (0–100) alongside an unambiguous categorization:
- **Must Haves (The Core)**: The non-negotiable features essential for core loop validation.
- **Discarded Bloat (The Noise)**: Features cut from V1, backed by ruthless, unambiguous justifications. Progressive noise disclosure cleanly organizes large cut lists.

### 5. Build First
A clear, numbered development roadmap (Step 01 through Step N) identifying the exact execution order to reach a working build with zero overlapping dependencies.

### 6. Product Truth
Uncompromising strategic critique that cuts through founder delusion and answers: *"What is the actual reality of this market and product?"*

### 7. MVP Lock
A deliberate psychological and functional commitment. Tapping **LOCK MVP** freezes scope, confirms survivor counts, and prevents scope creep. Can be reopened for reconsideration at any time.

### 8. Workspace
Offline-first personal product memory powered by local Hive document storage. Displays global telemetry (Ideas Trimmed, Features Cut, Scope Removed) and full historical session replay.

### 9. Export & Markdown Handoff
Generates clean, standardized specifications formatted for direct import into GitHub Issues, Linear, Notion, or Slack.

### 10. Build Desk / Office Kit
Bridge mobile ideation to desktop execution. One tap packages structured development specifications and transmits them directly to your development machine.

---

## Phone-First Design

TRIM is engineered from the ground up for mobile hardware:
- **Tactile Touch Targets**: Generous 48pt+ interactable surfaces calibrated for one-handed thumb use.
- **Natural Voice Capture**: Dictate raw thoughts while walking or away from your desk.
- **Physical Spring Motion**: Custom spring simulations (`SpringSimulation`, `Curves.easeOutBack`) that provide weight and tactile presence. Zero linear animations.
- **High-Refresh Display Polish**: Designed and tested for smooth interaction on high-refresh Android devices (120Hz/144Hz).
- **Pure OLED Dark Mode**: Deep `#000000` canvas with subtle `#0D0D11` glass cards, minimizing battery consumption and eye strain.
- **Device-Local Privacy**: All session history remains on your device.

---

## AI Architecture

TRIM employs a secure, low-latency, proxy-based architecture:

```
Flutter Client (Web / Android)
        │
        ▼ (Single-Flight HTTPS)
Vercel Serverless Function (/api/trim)
        │
        ▼ (Server-Side GROQ_API_KEY)
Groq LPU Cloud (openai/gpt-oss-120b)
```

- **Server-Side Key Isolation**: The client application contains **zero Groq API keys**. All credentials reside securely in server-side environment variables (`GROQ_API_KEY`).
- **Single-Flight Request Protection**: Concurrent or rapid repeated taps automatically coalesce into the active in-flight request, preventing duplicate backend calls.
- **Strict Output Grammar**: Enforces an exact JSON schema containing structured MVP components.

---

## Security

- **Zero Client-Side Secrets**: Release APKs and web bundles contain no API keys, private tokens, or Bearer authorization headers.
- **No Direct Groq Endpoints**: The client communicates exclusively with `/api/trim`.
- **Local Data Isolation**: Historical triage sessions are stored entirely in local on-device Hive storage. No ideas are transmitted to third-party databases.

---

## Office Kit / Build Desk

TRIM connects the phone (planning surface) to the laptop (execution surface).

Tapping **SEND TO BUILD DESK** compiles and packages four dedicated markdown artifacts into `TRIMMED_MVP/`:
1. `MVP_SPEC.md` — Complete system overview, MVP score, core architecture, and surviving features.
2. `BUILD_ORDER.md` — Sequential step-by-step engineering checklist.
3. `CUT_FEATURES.md` — Discarded features log with explicit rationale.
4. `PRODUCT_TRUTH.md` — Harsh market reality check and strategic guidance.

Files are dispatched via OriginOS 6 PC Link / EasyShare, Bluetooth, system share targets, and clipboard synchronization.

---

## On-Device AI Feasibility

During the v1.0.0 engineering cycle, on-device AI was evaluated in depth:
- **Android AICore / Gemini Nano**: Currently restricted to Google Pixel and select Samsung devices; not exposed to third-party runtimes on OriginOS 6.
- **Local Qualcomm NPU Runmodels**: Requires packaging 900MB–2GB quantized model weights, introducing heavy cold-start latency and reduced reasoning fidelity.
- **Conclusion**: v1.0.0 uses the high-speed serverless Groq LPU proxy for sub-second, zero-footprint inference with 100% security. On-device local models remain deferred until native OS LLM APIs achieve vendor-wide standardization.

---

## Performance & Quality

- **High-Refresh Interaction**: Designed and tested for smooth interaction on high-refresh Android devices.
- **Binary Footprint**: Optimized split APK (`arm64-v8a`) is only **18.0 MB**.
- **Automated Verification**: **119 of 119 automated tests passing** across unit, widget, and integration test suites.
- **Static Analysis**: **0 issues found** via `flutter analyze`.

---

## Tech Stack

- **Client Framework**: Flutter (Channel stable, Dart 3)
- **Local Storage**: Hive & Hive Flutter (pure Dart document database)
- **Design & Typography**: Custom Glassmorphism, Google Fonts (`Manrope`, `JetBrains Mono`)
- **Backend Function**: Vercel Serverless Node.js Runtime (`api/trim.js`)
- **LLM Engine**: Groq Cloud LPU (`openai/gpt-oss-120b`)
- **Cross-Device Handoff**: `share_plus` & native Android intent dispatchers
- **Speech Recognition**: Mobile speech-to-text pipeline

---

## Android Releases

Pre-compiled release packages are available in `build/releases/`:

| Binary | Size | Target Architecture |
| :--- | :--- | :--- |
| **`TRIM-arm64-v8a-release.apk`** | **18.0 MB** | **64-bit ARM (iQOO 15 / Snapdragon 8 Elite Gen 5)** |
| `TRIM-release.apk` | 50.5 MB | Universal Android Release |
| `TRIM-release.aab` | 49.6 MB | Google Play Store App Bundle |
| `TRIM-armeabi-v7a-release.apk` | 15.5 MB | 32-bit Legacy ARM |
| `TRIM-x86_64-release.apk` | 19.3 MB | 64-bit Emulators / ChromeOS |

---

## Installation & Setup

### Installing on Android
1. Download `TRIM-arm64-v8a-release.apk` (or universal `TRIM-release.apk`) from [Releases](https://github.com/LuxShar007/Trim/releases).
2. Install the APK on your Android device (ensure "Install unknown apps" permission is granted).
3. Launch **TRIM** and start trimming product ideas immediately. No API key setup required!

### Local Development Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/LuxShar007/Trim.git
   cd Trim
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code analysis & tests:
   ```bash
   flutter analyze
   flutter test --platform=tester
   ```
4. Launch the application:
   ```bash
   flutter run
   ```

### Vercel Function Development
For running the local serverless proxy:
1. Ensure Node.js 18+ is installed.
2. In `.env.local` (kept local, never committed), configure:
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   ```
3. Launch Vercel local dev server:
   ```bash
   npx vercel dev
   ```

---

## Product Preview

<!-- TODO: Add final screenshot and demonstration recording embeds here -->
*A product walkthrough video and high-resolution screenshots will be linked here.*

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for full details.
