# TRIM — Release Notes

## Version 1.0.1 (Build 2002) — Voice V3 & Workspace Build Desk Update

**Release Date**: September 17, 2026  
**Target Platform**: Android 16 (API 36) / OriginOS 6 / Snapdragon 8 Elite Gen 5 (iQOO 15) & Modern Web  
**Application ID**: `com.antigravity.trim.trim`  

### What's New in v1.0.1:
1. **Voice V3 Reliability Pipeline**:
   - Upgraded voice dictation with automated initialization retry and `en-IN` / system locale fallback.
   - Long pause resilience: automatic stream flush prevents speech cutoff during pauses.
   - Enhanced user feedback banners for microphone permissions and engine availability.
2. **Workspace Build Desk Artifact Persistence**:
   - Build Desk markdown specifications (`MVP_SPEC.md`, `BUILD_ORDER.md`, `CUT_FEATURES.md`, `PRODUCT_TRUTH.md`) are now stored directly in Hive workspace documents.
   - Full in-app preview sheet with syntax-highlighted code views and clipboard copy.
   - Historical sessions in Workspace now display the `BUILD DESK · 4 FILES` badge.
3. **Verified Quality**:
   - 133 / 133 automated tests passing.
   - Zero static analysis issues (`flutter analyze`).

### Distribution Artifacts (`build/releases/`):
| Artifact File | Size | Architecture / Target | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **`TRIM-v1.0.1-arm64.apk`** | **18.0 MB** | **`arm64-v8a` (iQOO 15 / Snapdragon 8 Elite)** | `9E176066543D959D203DC65BA66FF8D7350899C58D9DA94C9908B041A33FB8C8` |
| `TRIM-v1.0.1-armeabi-v7a.apk` | 15.6 MB | `armeabi-v7a` (32-bit ARM Legacy) | `448D28D249166246D7215370C7340E39A94A6982564DCEDCD930FCC392592866` |
| `TRIM-v1.0.1-x86_64.apk` | 19.4 MB | `x86_64` (Emulators / ChromeOS) | `2F1C9B91DA3692CF65B38CBD17FC51AED41E3F5BADE48A1EC3DA56AA55167548` |

---

## Version 1.0.0 (Build 2001) — Initial Screening Prototype

**Release Date**: September 16, 2026  
**Target Platform**: Android 16 (API 36) / OriginOS 6 / Snapdragon 8 Elite Gen 5 (iQOO 15) & Modern Web  
**Application ID**: `com.antigravity.trim.trim`  

---

## 1. Executive Summary

TRIM transforms bloated feature wishlists into razor-sharp, buildable MVPs in seconds. Built for the iQOO Hackathon, TRIM enforces the core product philosophy:
$$\text{CHAOS} \longrightarrow \text{AI} \longrightarrow \text{TRIM} \longrightarrow \text{MVP} \longrightarrow \text{LOCK} \longrightarrow \text{BUILD}$$

This release candidate is finalized, frozen, and verified across all production release gates.

---

## 2. Release Artifacts & Distribution

All release artifacts are organized in `build/releases/`:

| Artifact File | Size | Architecture / Target | Description |
| :--- | :--- | :--- | :--- |
| **`TRIM-arm64-v8a-release.apk`** | **18.0 MB** | **`arm64-v8a`** | **Primary target for iQOO 15 / Snapdragon 8 Elite Gen 5** |
| `TRIM-release.apk` | 50.5 MB | Universal (Fat APK) | Standalone release bundle supporting all ABIs |
| `TRIM-armeabi-v7a-release.apk` | 15.5 MB | `armeabi-v7a` | 32-bit ARM legacy support |
| `TRIM-x86_64-release.apk` | 19.3 MB | `x86_64` | 64-bit emulator / ChromeOS support |
| `TRIM-release.aab` | 49.6 MB | App Bundle | Google Play Store distribution package |
| `build/web/` | Optimized | Web (HTML5/CanvasKit/Wasm) | Production web build |

---

## 3. Core Features

- **The Brain Dump**: High-speed idea capture supporting both manual text typing and natural voice dictation. Real-time counter and fast sample injection.
- **Single-Tap Ruthless Triage**: One-tap "TRIM THE FAT" trigger that evaluates project concepts through a strict MVP discipline.
- **Cinematic Processing Phase**: 4-phase radar animation displaying real-time feedback during inference (`AUDITING_SCOPE`, `EXTRACTING_ESSENCE`, `SEVERING_BLOAT`, `SYNTHESIZING_MVP`).
- **Verdict & MVP Score**: Quantitative 0–100 MVP viability index with visual color banding.
- **Core vs. Noise Breakdown**: 
  - **Must Haves**: Non-negotiable core value propositions.
  - **Discarded Bloat**: Premature optimizations, vanity features, and speculative distractions, accompanied by brutal justifications.
- **Strict Build Order**: Numbered step-by-step engineering sequence (Phase 1 through Phase N).
- **Product Truth (The Harsh Reality)**: Uncompromising strategic critique preventing founder delusion.
- **MVP Lock & Session Persistence**: Local Hive database storage allowing founders to lock down MVP scope and archive historical triage runs.

---

## 4. AI Architecture & Security Verification

- **Model**: `openai/gpt-oss-120b` running on high-throughput Groq LPU inference.
- **Backend Architecture**: Secure Vercel Serverless Function proxy (`/api/trim`) shielding upstream Groq endpoints and API keys.
- **Client Security (Zero-Key Principle)**:
  - Binary inspection confirmed **zero master Groq API keys** compiled into client binaries.
  - No direct client-to-`api.groq.com` requests.
  - Enforced single-flight request deduplication with coalescing for concurrent requests.
  - Exponential backoff with jitter on transient network errors.

---

## 5. Phone-First & Native Experience

- **Designed for iQOO 15**: 120Hz/144Hz fluid animations, 8pt spatial layout, modern glassmorphism, and OLED dark mode palette.
- **Haptic Feedback**: Context-aware tactile vibrations on triage actions, lock confirmation, and mode switching.
- **Immersive Micro-interactions**: Smooth collapsible panels, expanding bloat cards, and spring physics.

---

## 6. Voice Pipeline Status

- **Engine**: Integrated speech recognition with auto-punctuation and continuous listening.
- **Fail-Safe Flow**:
  - `TYPE` $\longleftrightarrow$ `SPEAK` mode toggle.
  - Graceful microphone permission handling with clear in-app banners.
  - Review & Edit step prior to submission (explicit user confirmation required).
  - Complete 8-point automated test suite verified (100% pass rate).

---

## 7. Office Kit & Build Desk Integration

- **Concept**: The phone is the product planning surface; the laptop is the execution surface.
- **Cross-Device Hand-off**:
  - One-tap "SEND TO BUILD DESK" triggers immediate cross-device hand-off via OriginOS 6 file sharing, Bluetooth, and clipboard synchronization.
  - Packages complete markdown specifications into `TRIMMED_MVP/`:
    - `MVP_SPEC.md` (System overview, score, core features, architecture)
    - `BUILD_ORDER.md` (Sequential development checklist)
    - `CUT_FEATURES.md` (Discarded bloat log with explicit reasons)
    - `PRODUCT_TRUTH.md` (Strategic reality check)
  - Fully tested and verified with `office_kit_build_desk_test.dart`.

---

## 8. On-Device AI Status (Feasibility Spike)

- **Comprehensive Evaluation Conducted**: Documented in `on_device_ai_feasibility.md`.
- **Status**: **FEASIBILITY SPIKE COMPLETE — DEFERRED / NOT APPLICABLE FOR PRODUCTION GENERATIVE TRIAGE**.
- **Key Findings**:
  - Android AICore / Gemini Nano is restricted to Google Pixel and select Samsung flagships; not exposed on Vivo/OriginOS 6.
  - Qualcomm AI Engine / ONNX local runtimes require >900MB–2GB quantized weights, degrading cold-start performance and battery without matching Groq GPT-OSS 120B's reasoning depth.
  - The hybrid model (zero-key serverless proxy + Groq LPU) delivers sub-second inference with zero bloat and 100% security.

---

## 9. Quality & Verification Gates

- **`flutter analyze`**: **0 errors, 0 warnings, 0 lints** (`Analyzing Trim... No issues found!`).
- **`flutter test`**: **109 of 109 tests passing** across unit, widget, and integration test suites.
- **Web Verification**: Clean release build in `build/web/` verified with zero direct external API keys.
- **Android Verification**:
  - `com.antigravity.trim.trim`
  - Version: `1.0.0` (Code `2001`)
  - Target SDK: `36` (Android 16)
  - Minimum SDK: `24` (Android 7.0)

---

## 10. Known Limitations

- **Speech Recognition Offline Dependency**: Speech-to-text accuracy depends on the device's installed Google Speech Services or OriginOS voice transcription language packs when offline.
- **Office Kit Direct Wireless Pairing**: Relies on system-level OriginOS 6 PC Link / EasyShare or standard Android Nearby Share / Bluetooth targets.
