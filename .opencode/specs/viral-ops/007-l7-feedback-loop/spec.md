---
title: L7 Feedback Loop — Spec (Seed)
spec_folder: .opencode/specs/viral-ops/007-l7-feedback-loop
level: 1
status: research
created: 2026-04-16T20:09:45Z
---

# L7 Feedback Loop — Specification (Seed)

> **NOTE:** This spec was seeded by the deep-research pre-init branch. Canonical research output lives in `research/research.md`. Bounded findings will be written back to the `## Research Findings` section below after synthesis.

## 1. Requirements

<!-- DR-SEED:REQUIREMENTS -->
- Ingest post-level analytics (views, engagement, watch-time, retention, shares, saves, comments, conversions) from TikTok, YouTube, Instagram, and Facebook at a cadence that keeps the feedback loop to L3 Content Lab usable within the 24-48h Thai viral lifecycle.
- Normalize per-platform metrics into a unified schema keyed by `content_id` × `platform` × `platform_post_id` × `time_bucket`.
- Drive GBDT (LightGBM, 38 features) retraining with drift-aware triggers, not fixed schedules alone.
- Emit a 4-channel feedback signal (engagement, retention, completion, conversion) to L3 Content Lab for prompt tuning, variant scoring, and Thompson Sampling posterior updates.
- Automate prompt tuning with safety rails (no overfitting to vanity metrics, guardrails against chasing rage engagement).
<!-- /DR-SEED:REQUIREMENTS -->

## 2. Scope

<!-- DR-SEED:SCOPE -->
**In scope:**
- Platform analytics API integration (TikTok, YouTube, Instagram, Facebook) for post-performance telemetry.
- Performance data ingestion pipeline (polling cadence, storage, dedup, reconciliation).
- Drift detection (data, concept, label drift) for the existing L2 GBDT viral scoring model.
- Retraining trigger logic and cadence.
- 4-channel feedback handoff schema to L3 Content Lab.
- Prompt-tuning automation rules and guardrails.

**Out of scope (see non-goals in `research/deep-research-strategy.md` §4):**
- L3 Content Lab prompt chain internals (already specified in `006-content-lab`).
- Trend detection / viral brain base model (`005-trend-viral-brain`).
- Platform upload orchestration (`004-platform-upload-deepdive`).
- UI/dashboard layout for analytics visualization.
<!-- /DR-SEED:SCOPE -->

## 3. Open Questions

- L7 feedback loop — analytics apis (tiktok/youtube/instagram/facebook), performance data ingestion pipeline, views/engagement/retention tracking, gbdt model retraining triggers, drift detection, 4-channel feedback to l3, prompt tuning automation

## 4. Research Context

Deep-research is active for this topic. `research/research.md` remains canonical. Iteration files live under `research/iterations/`. Synthesis will write a bounded `## Research Findings` block here when complete.

## 5. Research Findings

<!-- BEGIN GENERATED: deep-research/spec-findings -->
<!-- SOURCE: research/research.md -->
<!-- ITERATIONS: 6 of 15 | STOP_REASON: converged | CHECKSUM: synthesis@2026-04-16T20:09:45Z -->

**Registry Seal (all 5 key questions resolved):**

- **Q1 Platform analytics APIs** (iter-1, refined iter-2 & iter-6): TikTok Research API (1,000 req/day, no retention curve — structural dead-end for first-party Creator/Business), YouTube Analytics API v2 (`audienceRetention` full curve, flat 1-unit quota), Instagram Graph API v25 (`reels_skip_rate` Dec-2025, BUC 4800×impressions/24h), Facebook Graph API v21 (`post_video_retention_graph`, **critical 2026-06-15 deprecation**). Source-of-truth table in `research/research.md §2`.

- **Q2 Ingestion pipeline** (iter-2, refined iter-6): Prisma 7.4 `performance_metrics` + `retention_curve` JSONB, idempotent upsert on `(content_id, platform, platform_post_id, metric_date)`, polling cadence matched to latency gradient (T+1h TikTok/IG, T+6h+T+48h YouTube late-reconcile, T+24h Facebook), BUC header adapter, BullMQ DLQ, n8n workflows for scheduled polls + Node/TS worker for late-reconcile. BUC formula corrected to 4800×impressions/24h rolling (not 200/hr). See `research/research.md §7`.

- **Q3 GBDT retraining + drift** (iter-3): 4-axis drift model (data/prediction/label/performance/correlation), Evidently AI canonical method menu, hybrid trigger (weekly floor + drift-sustained-2d + MAE+15% ceiling), `training_feature_snapshots` + `drift_events` Prisma tables, MLflow stage machine (None → Staging-shadow → Staging-canary → Production → Archived), Python-worker + n8n wiring. See `research/research.md §8`.

- **Q4 4-channel feedback to L3** (iter-4, refined iter-6): 4 channels = engagement / retention / completion / conversion, cohort-normalized by `platform × niche × account_tier × age × thai_formality × code_switch_level`, Thompson arm granularity per `(variant_id, platform)`, canonical `L7FeedbackEnvelope` JSON + Prisma `l7_feedback_envelopes` model, Beta-Binomial update with `impressions_decile` virtual-trial scaling, 5 vanity-metric guardrails (rage/bot/clickbait/algo-boost/multi-dim), **quarantine-not-reset** on drift (widens ε-greedy 0.20→0.40), 6th n8n workflow `L7-Feedback-Emitter`. See `research/research.md §9`.

- **Q5 Prompt tuning automation** (iter-5, refined iter-6): Stage-by-stage tunable/locked matrix across L3's 5 prompt stages (Thai particles + 60+ particles lock-listed from 003), three-layer experiment separation (L3a content-bandit / L3b template-meta-bandit / L3c OPRO parameter-sweep), DSPy v3.1.3 + MIPROv2 hyperparameters validated, nested Thompson-Thompson meta-bandit with credit-attribution rule, SHADOW→CANARY→PROD_PARTIAL→PROD_FULL state machine with 5 auto-revert triggers + 14d cool-down + `L3_AUTO_TUNE_FROZEN` circuit breaker, MLflow prompt registry extension, drift-coupling matrix, 7th L3 n8n workflow `L3-Prompt-Tuner`. See `research/research.md §10`.

**Scale sanity** (iter-6 §E): TikTok = bottleneck at 250 posts/day; current 50 pieces × 7d window = 350 content_ids (3× headroom); 10× reconfigurable by dropping T+1h poll; storage ~2.3GB/year, 10-year retention 23GB (Postgres-comfortable). Feature-store migration deferred to 50M rows (~30 years away).

**Loop stability** (iter-6 §D): cadence-separation principle (each downstream layer updates slower than upstream) + circuit-breaker triad (quarantine-not-reset + 14d cool-down + L3_AUTO_TUNE_FROZEN) prove structural stability. Amplification-risk assessment: 4 of 5 high-risk modes LOW residual, 1 MEDIUM (content-L2-label collapse, mitigated by forced exploration 10% + exemplar diversity 30% + trend novelty + human quarterly).

**Implementation-phase open items** (do NOT block convergence): PromptBreeder hyperparameters (Phase 4), nested-bandit formal convergence guarantees, Thai comment-sentiment pipeline details, monthly Thompson recalibration window.

**Recommended next command**: `/spec_kit:plan :with-phases` for 4-phase rollout (ingestion → drift → feedback → prompt-tuning).
<!-- END GENERATED: deep-research/spec-findings -->
