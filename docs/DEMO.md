# TRIM — Screening Prototype Demo

> **Pre-Event Technical Proof of Concept**  
> This document details the demonstration flow for the **TRIM Pre-Event Screening Prototype**.  
> This demonstration showcases our core product concept, mobile UX, AI pipeline behavior, and technical execution for idea screening evaluation in the **iQOO Hackathon 2026 Developer Tools track**.  
> 
> *In accordance with hackathon rules, this prototype demonstrates pre-event technical capability; the official City Battle implementation will be built from scratch during the permitted 30-hour event window.*

---

## The Screening Demo: What is Being Demonstrated?

1. **Product Concept**:
   - Demonstrating the upstream product-triage layer that sits *before* AI coding agents (Antigravity, Claude Code, Cursor, Copilot Workspace).
   - Transforming unbounded product wishlists into focused, locked MVPs.

2. **Product Behavior**:
   - Turning a chaotic 8-domain product pitch into 1–3 non-negotiable core features, clear cut rationale, and sequential build order.

3. **AI Workflow & Architecture**:
   - Secure proxy architecture (`/api/trim`) with zero client secrets.
   - Low-latency LPU inference (`openai/gpt-oss-120b`) enforcing a strict JSON output schema.
   - Client single-flight request protection preventing duplicate backend calls.

4. **Phone-Native UX**:
   - Distraction-free OLED black canvas (`#050508`) with 48pt+ touch targets.
   - Dual-mode input (`TYPE` $\longleftrightarrow$ `SPEAK`) with speech-to-text review and user agency before submission.
   - Tactile spring micro-physics and guarded haptic feedback.

5. **Technical Execution & Cross-Device Handoff**:
   - Offline-first local storage via Hive document database.
   - Cross-device packaging and handoff to the laptop execution surface (`TRIMMED_MVP/`).

---

## Demo Concept Pipeline

$$\text{CHAOS} \longrightarrow \text{CONTEXT UNDERSTANDING} \longrightarrow \text{SCOPE REDUCTION} \longrightarrow \text{PRODUCT TRUTH} \longrightarrow \text{MVP LOCK} \longrightarrow \text{BUILD HANDOFF}$$

---

## Sample Demo Input (Bloated Chaos)

> *"An AI-powered productivity super-app with habit tracking, pomodoro timers, crypto staking for streaks, an integrated social network for founders, direct messaging, web3 NFT avatars, and full enterprise team permissions."*

---

## 60–90 Second Screening Demonstration Timeline

| Time | Action / Screen | Visual / Audio Cue | Technical Aspect Demonstrated |
| :--- | :--- | :--- | :--- |
| **00:00 - 00:10** | **1. Open TRIM** | App opens with OLED dark mode and spring physics. | Mobile-first architecture, zero glare, high-contrast typography. |
| **00:10 - 00:25** | **2. Brain Dump (Speak or Type)** | Tap **SPEAK** (or sample text). Dictate bloated idea. Real-time transcript populates. | Phone-native speech recognition pipeline with live transcript streaming. |
| **00:25 - 00:30** | **3. Review Transcript** | Inspect and edit transcript before submission. | Full user agency; avoids accidental submissions or recognition errors. |
| **00:30 - 00:35** | **4. Tap "TRIM THE FAT"** | Strong tactile click. Single-tap triggers triage. | Single-flight request management; dispatches to secure `/api/trim` proxy. |
| **00:35 - 00:45** | **5. Scope Collapse Transformation** | Cinematic 4-phase radar animation: `AUDITING` $\rightarrow$ `EXTRACTING` $\rightarrow$ `SEVERING` $\rightarrow$ `SYNTHESIZING`. | Visualized reasoning states with fast-forward timeline for sub-second responses. |
| **00:45 - 00:55** | **6. Verdict & Scope Severance** | Verdict lands. Highlight **MVP Score (e.g., 92)**. Highlight scope reduction: **7 submitted $\rightarrow$ 1 survivor**. | Strict JSON schema parsing and quantitative triage scoring. |
| **00:55 - 01:05** | **7. Core vs. Noise Breakdown** | - **Must Haves**: Daily habit tracker with core feedback loop.<br>- **Discarded Bloat**: Progressive disclosure reveals severed features with brutal justification. | Upstream feature categorization; cuts crypto, social network, and NFT avatars. |
| **01:05 - 01:15** | **8. Build First & Product Truth** | - **Build First**: Step 01 engineering roadmap.<br>- **Product Truth**: *"Validate the core habit loop before adding a crypto economy."* | Uncompromising strategic critique and dependency-free build ordering. |
| **01:15 - 01:22** | **9. Lock MVP** | Tap **LOCK MVP**. Scope freezes to prevent feature creep. | Local NoSQL persistence in Hive; offline memory. |
| **01:22 - 01:30** | **10. Send to Build Desk** | Tap **SEND TO BUILD DESK**. Packages `MVP_SPEC.md`, `BUILD_ORDER.md`, `CUT_FEATURES.md`, and `PRODUCT_TRUTH.md`. | Cross-device handoff connecting mobile planning to laptop execution. |

---

## Key Takeaway for Screening Evaluators

> *"TRIM solves founder delusion and eliminates garbage prompts before coding starts. The phone is where you plan, triage, and lock the MVP; the laptop and AI coding agents are where you execute with precision."*
