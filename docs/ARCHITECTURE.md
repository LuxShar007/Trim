# TRIM — System Architecture

This document provides a technical specification of the TRIM client-server architecture, data flow, security model, and cross-device handoff system.

---

## 1. High-Level Architectural Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    TRIM Client                          │
│          (Flutter 3.x / Dart / Web & Android)           │
│                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌─────────────┐  │
│  │  Brain Dump  │──▶│  Processing  │──▶│   Verdict   │  │
│  │ (Text/Voice) │   │  (4 Phases)  │   │   Screen    │  │
│  └──────────────┘   └──────────────┘   └─────────────┘  │
│         │                                     │         │
│         ▼                                     ▼         │
│  ┌──────────────┐                      ┌─────────────┐  │
│  │ Hive Storage │                      │ Office Kit  │  │
│  │(Local Scope) │                      │(Build Desk) │  │
│  └──────────────┘                      └─────────────┘  │
└────────────────────────────┬────────────────────────────┘
                             │
                  POST /api/trim (HTTPS)
                 [Single-Flight Protected]
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│              Vercel Serverless Function                 │
│                     (api/trim.js)                       │
│                                                         │
│  - Environment Secret Resolution (GROQ_API_KEY)         │
│  - Request Validation & Schema Enforcement              │
│  - Rate Limiting & Error Sanitization                   │
└────────────────────────────┬────────────────────────────┘
                             │
                   HTTPS Request (Upstream)
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                    Groq Cloud LPU                       │
│               (openai/gpt-oss-120b)                     │
│                                                         │
│  - Sub-second LPU Inference                             │
│  - JSON Schema-Strict Output Parsing                    │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Client Architecture (Flutter / Dart)

TRIM’s front-end is architected around phone-first interactions and deterministic state machines:

- **Brain Dump Screen**:
  - High-velocity idea capture supporting tactile text input and speech dictation.
  - Character metrics and fast sample insertion.
- **Voice Pipeline**:
  - Dual-mode architecture (`TYPE` $\longleftrightarrow$ `SPEAK`).
  - Seamless fallback handling for denied permissions, cancellations, or quiet audio.
  - Explicit user verification before submission.
- **Processing Engine**:
  - 4-phase radar animation reflecting inference states:
    1. `AUDITING_SCOPE` (0–25%)
    2. `EXTRACTING_ESSENCE` (25–50%)
    3. `SEVERING_BLOAT` (50–75%)
    4. `SYNTHESIZING_MVP` (75–100%)
- **Verdict & Triage Screen**:
  - Quantitative MVP viability score (0–100).
  - Core vs. Noise breakdown:
    - **Must-Haves**: Essential feature set.
    - **Discarded Bloat**: Premature optimizations and distraction features with explicit rationale.
  - Sequential build order (numbered implementation roadmap).
  - Product Truth (harsh strategic reality check).
- **Workspace & Local Persistence**:
  - Implemented with **Hive** on-device NoSQL storage.
  - Fully offline historical session review, MVP scope locking, and export capabilities.

---

## 3. Backend & Proxy Architecture (Vercel Serverless)

- **Serverless Endpoint**: `/api/trim` deployed on Vercel Node.js runtime (`api/trim.js`).
- **Secret Isolation**: Upstream `GROQ_API_KEY` is strictly resolved on the server via `process.env.GROQ_API_KEY`.
- **Inference Model**: `openai/gpt-oss-120b` running on Groq LPUs.
- **Strict JSON Schema**: AI output is constrained to an exact JSON schema containing `project_name`, `core_value`, `mvp_score`, `must_haves`, `discarded_bloat`, `build_order`, and `harsh_truth`.

---

## 4. Security Model

1. **Zero Client Secrets**:
   - The production APK and Web bundles contain no API keys, credentials, or Bearer auth headers.
   - All client traffic routes through `/api/trim`.
2. **Local Privacy**:
   - Session data and raw project ideas are stored solely on the user's device in local Hive boxes.
3. **Attack Surface Minimization**:
   - Direct calls to `api.groq.com` are blocked at the client layer.
   - Server-side CORS headers restrict unauthorized cross-origin requests.

---

## 5. Request Lifecycle & Reliability

To ensure bulletproof reliability under erratic mobile network conditions:

- **Single-Flight Request Protection**: If a user double-taps "TRIM THE FAT" or triggers parallel submissions, subsequent calls join the active in-flight request without issuing duplicate HTTP queries.
- **Bounded Exponential Backoff**: Automatic retry with jitter (up to 3 attempts) on transient network anomalies.
- **Header-Driven Throttling**: Honors upstream `Retry-After` headers during rate-limiting intervals.
- **Graceful Error Recovery**: Translates backend network codes into human-readable, non-technical recovery messages while preserving draft input.

---

## 6. Office Kit & Build Desk Integration

TRIM connects mobile ideation to desktop execution:
- **Phone as Planning Surface**: Triage, ruthlessly cut bloat, and lock MVP.
- **Laptop as Execution Surface**: With one tap ("SEND TO BUILD DESK"), TRIM packages structured development files into `TRIMMED_MVP/`:
  - `MVP_SPEC.md`
  - `BUILD_ORDER.md`
  - `CUT_FEATURES.md`
  - `PRODUCT_TRUTH.md`
- **Handoff Pipeline**: Dispatched via OriginOS 6 PC Link / EasyShare, Bluetooth, system share targets, and clipboard synchronization.

---

## 7. Android Distribution Architecture

- **Primary Target**: iQOO 15 (Snapdragon 8 Elite Gen 5, OriginOS 6, Android 16 / API 36).
- **Binary Architecture**:
  - `TRIM-arm64-v8a-release.apk` (18.0 MB) — Optimized 64-bit ARM binary.
  - `TRIM-release.apk` (50.5 MB) — Universal release APK.
  - `TRIM-release.aab` (49.6 MB) — Google Play Store App Bundle.
