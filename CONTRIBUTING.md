# Contributing to TRIM

Thank you for your interest in contributing to TRIM — the phone-first AI Product Manager that ruthlessly trims bloated product ideas into locked MVPs.

To maintain architectural integrity, high visual polish, and strict security, please review the guidelines below before submitting a pull request.

---

## 1. Development Setup

### Prerequisites
- **Flutter SDK**: `>=3.10.0` (Dart `>=3.0.0`)
- **Node.js**: `>=18.0.0` (for local Vercel serverless function development)
- **Android SDK**: API level 34+ recommended (Target: API 36 / Android 16)

### Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/LuxShar007/Trim.git
   cd Trim
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development server (Optional for local backend):
   ```bash
   npx vercel dev
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## 2. Quality Gates & Verification

Before submitting any contribution, you **must** verify that the codebase passes all analysis and test suites cleanly:

```bash
# Static analysis (must report 0 issues)
flutter analyze

# Automated test suite (all tests must pass)
flutter test --platform=tester
```

---

## 3. Strict Security Rules

TRIM adheres to a **Zero-Client-Secret** architecture:
- **Never commit secrets**: Never commit `.env`, `.env.local`, API keys, certificates, or keystores.
- **Never embed GROQ_API_KEY**: Never add a Groq API key into client-side Flutter Dart code or `--dart-define` client parameters.
- All upstream AI requests must flow through the secure serverless backend proxy (`api/trim.js`), where `process.env.GROQ_API_KEY` is resolved server-side.

---

## 4. Architectural Principles

When proposing changes, preserve TRIM's core ethos:
- **Phone-First Experience**: Interactions are optimized for one-handed mobile touch, fluid spring physics, and high-refresh screens (120Hz/144Hz). Avoid desktop-centric or mouse-heavy UI assumptions.
- **Ruthless Scope & Minimal Bloat**: TRIM exists to prevent bloat. Do not propose complex, sprawling feature sets that dilute the focused triage loop.
- **Accessibility & Performance**: Maintain responsive animations, high contrast OLED dark-mode palettes, and clear screen reader / semantic labels.

---

## 5. Pull Request Expectations

1. Fork the repo and create your branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
2. Write clean, self-documenting code with comprehensive widget/unit tests.
3. Ensure `flutter analyze` and `flutter test` pass with 0 warnings and 0 failures.
4. Fill out the pull request template completely, detailing mobile performance impact and verification steps.
