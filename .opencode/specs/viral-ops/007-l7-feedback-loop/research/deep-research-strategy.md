---
title: Deep Research Strategy - L7 Feedback Loop
description: Runtime strategy file tracking research progress, focus decisions, and outcomes across iterations for the L7 feedback loop investigation.
---

# Deep Research Strategy - Session Tracking

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose

Serves as the "persistent brain" for this L7 Feedback Loop deep research session. Records what to investigate, what worked, what failed, and where to focus next.

### Usage

- **Init:** Populated from config and memory context during initialization.
- **Per iteration:** Agent reads Next Focus, writes iteration evidence, and the reducer refreshes machine-owned sections.
- **Mutability:** Analyst-owned sections stable; machine-owned sections rewritten by reducer.

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC

L7 Feedback Loop — analytics APIs (TikTok Analytics, YouTube Analytics, Instagram Insights, Facebook Insights), performance data ingestion pipeline, views/engagement/retention tracking, GBDT model retraining triggers, drift detection, 4-channel feedback to L3 Content Lab, prompt tuning automation.

This is **Layer 7** of the viral-ops multi-layer architecture. Prior layers researched:
- L1+L2: Trend detection & Viral Brain (see `005-trend-viral-brain/research/research.md`) — LightGBM 38 features, BERTopic
- L3: Content Lab (see `006-content-lab/research/research.md`) — 4-channel feedback architecture, Thompson Sampling

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
- [x] Q1: Platform analytics API specs — ANSWERED (iter-1, refined iter-2 & iter-6)
- [x] Q2: Ingestion pipeline architecture — ANSWERED (iter-2, refined iter-6)
- [x] Q3: GBDT retraining + drift detection — ANSWERED (iter-3)
- [x] Q4: 4-channel feedback L7 → L3 — ANSWERED (iter-4, refined iter-6)
- [x] Q5: Prompt tuning automation — ANSWERED (iter-5, refined iter-6)

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS

- Implementation of L3 Content Lab prompt chains (already covered in `006-content-lab`)
- Trend detection / viral brain scoring (already covered in `005-trend-viral-brain`)
- Platform upload mechanics (already covered in `004-platform-upload-deepdive`)
- Thai-specific TTS or voice pipeline (covered in `003-thai-voice-pipeline`)
- Re-auditing existing Pixelle endpoints (covered in `002-pixelle-video-audit`)
- UI/dashboard layout for analytics visualization (Phase 2 consideration, out of scope for research)
- Building new ML feature stores from scratch (must reuse existing GBDT/LightGBM stack from L2)

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS

- **Convergence:** `weighted_stop_score > 0.60` with graph STOP_ALLOWED decision (rolling-avg + MAD + question entropy signals)
- **All questions resolved:** Q1–Q5 all marked resolved in registry
- **Max iterations:** 15 iterations completed
- **Quality guards passed:** ≥4 sources cited per key question, ≥1 concrete implementation pattern per question, no TOC-only or vanity findings
- **Explicit kill:** Pause sentinel `.deep-research-pause` created by user

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS

| Q | Text | Primary Iteration | Refined At |
|---|---|---|---|
| Q1 | Platform analytics API specs (TikTok/YouTube/Instagram/Facebook) | iter-1 | iter-2, iter-6 |
| Q2 | Ingestion pipeline architecture (polling cadence, Prisma schema, dedup, rate budgets) | iter-2 | iter-6 |
| Q3 | GBDT retraining + drift detection (Evidently, NannyML, hybrid triggers, MLflow stages) | iter-3 | — |
| Q4 | 4-channel feedback loop L7→L3 (envelope, Thompson update, guardrails, n8n topology) | iter-4 | iter-6 |
| Q5 | Prompt tuning automation (DSPy/OPRO/PromptBreeder, meta-bandit, SHADOW→PROD, Thai lock-list) | iter-5 | iter-6 |

All 5 questions registry-sealed via `question_resolution` records appended to `deep-research-state.jsonl` at iteration 6.

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
[None yet]

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
[None yet]

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
[No exhausted approach categories yet]

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
[None yet]

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
**STOP — PROCEED TO SYNTHESIS PHASE.** Synthesis tasks (out-of-scope for this agent): 1. Final `research/research.md` gap-closure addendum (done this iteration, §10 + §11 updates). 2. Orchestrator-driven `findings-registry.json` resolution for Q1–Q5 (via `question_resolution` records appended to state.jsonl by this iteration). 3. Reducer-driven strategy/dashboard refresh (orchestrator's job post-iter-6). 4. Spec folder promotion to implementation-ready status — `/spec_kit:plan` with `:with-phases` recommended given the 4-phase prompt-tuning rollout (iter-5 §H.5 MVP→OPRO→DSPy→PromptBreeder). ---

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From viral-ops memory (MEMORY.md):

**L2 Viral Brain (005-trend-viral-brain):** GBDT 38-feature LightGBM model used for viral scoring. BERTopic multilingual as FastAPI. LLM 1-5 scoring (6 dims). Thai 24-48h lifecycle.

**L3 Content Lab (006-content-lab):** 5-stage prompt chain, 3x3 variant expansion (9 variants/concept), Thompson Sampling for multi-armed bandit variant selection, AV handoff JSON schema, engine-agnostic TTS, **4-channel feedback loop architecture**, 5 n8n workflows, 6 video formats. **This is the primary consumer of L7 feedback signals.**

**Platform Upload (004-platform-upload-deepdive):** Per-platform upload APIs with rate limits: TikTok (6 req/min, 4GB), YouTube (100 quota, n8n native), Instagram (400 containers/24h, 24h expiry), Facebook (30 Reels/Page/24h, Pages-only); 3-tier retry; `rate_limit_tracker` table; staggered posting. **Upload metadata links to L7 performance tracking via content_id + platform_post_id.**

**Base app (001-base-app-research):** next-forge v6.0.2, Prisma 7.4, n8n 2.16, Clerk auth. Prisma is the canonical ORM for any new feedback tables.

**Pixelle audit (002-pixelle-video-audit):** 21 endpoints, 29 workflows, 28 TTS voices. Existing dashboard pages map to Pixelle pipeline stages — L7 dashboard will likely extend one of these 5 pages.

### Prior-work deltas this research must close:
1. No prior spec covers performance-API polling cadence, quota budgeting, or drift-based retraining triggers.
2. `006-content-lab` declares the 4-channel feedback architecture but does not specify the data schema, aggregation window, or exact handoff format from L7 → L3.
3. GBDT 38-feature set from L2 needs a retraining feedback loop — this research must determine signal inputs and cadence.

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 15
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true (default)
- research/research.md ownership: workflow-owned canonical synthesis output
- Lifecycle branches: `resume`, `restart`, `fork`, `completed-continue`
- Machine-owned sections: reducer controls Sections 3, 6, 7-11
- Canonical pause sentinel: `research/.deep-research-pause`
- Capability matrix: `.opencode/skill/sk-deep-research/assets/runtime_capabilities.json`
- Current generation: 1
- Started: 2026-04-16T20:09:45Z
- Session ID: afdd77c9-4f63-4333-8740-2175433f0041
<!-- /ANCHOR:research-boundaries -->
