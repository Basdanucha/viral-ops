---
title: "Feature Specification: Cost & Profit Tracking System"
description: "Per-content cost attribution (LLM + TTS + API quota), revenue tracking (affiliates + platform monetization), ROI engine, daily/monthly dashboards, and budget alerts for the viral-ops pipeline"
trigger_phrases:
  - "cost tracking"
  - "profit tracking"
  - "ROI"
  - "budget alerts"
  - "token cost"
  - "API cost"
  - "LLM cost"
  - "TTS cost"
  - "revenue attribution"
  - "viral-ops cost"
importance_tier: "normal"
contextType: "general"
---
# Feature Specification: Cost & Profit Tracking System

<!-- SPECKIT_LEVEL: 1 -->
<!-- SPECKIT_TEMPLATE_SOURCE: spec-core | v2.2 -->

<!-- DR-SEED:REQUIREMENTS -->
<!-- DR-SEED:SCOPE -->

---

<!-- ANCHOR:metadata -->
## 1. METADATA

| Field          | Value                                                                 |
|----------------|-----------------------------------------------------------------------|
| **Level**      | 1 (research phase; may escalate to L2/L3 after synthesis)             |
| **Priority**   | P1                                                                    |
| **Status**     | Research in progress                                                  |
| **Created**    | 2026-04-16                                                            |
| **Branch**     | `008-cost-profit-tracking`                                            |
| **Session**    | `c573a9af-db20-427c-9916-5c6cdf48ab41`                                |

<!-- /ANCHOR:metadata -->
---

<!-- ANCHOR:problem -->
## 2. PROBLEM & PURPOSE

### Problem Statement
viral-ops burns real money on every piece of content: LLM calls (GPT-4o-mini, Claude Haiku/Sonnet/Opus, DeepSeek) for scripting/scoring, TTS calls (ElevenLabs primary, OpenAI fallback) for Thai voiceovers, and platform API quota on upload (TikTok, YouTube, Instagram, Facebook). Revenue arrives via affiliate links, platform monetization, and brand deals — but is currently invisible at per-content granularity. Without cost and revenue attribution, we cannot:
- Detect when a niche becomes unprofitable
- Catch runaway token usage before monthly bills land
- Decide which content formats / platforms / niches to scale
- Trigger budget alerts before hitting provider throttles or hard caps

### Purpose
Build a per-content cost + revenue ledger with an ROI engine, daily/monthly dashboards, and budget-alert pipelines so every video, platform, and niche exposes its true economic picture.

<!-- /ANCHOR:problem -->
---

<!-- ANCHOR:scope -->
## 3. SCOPE

### In Scope
- Per-call cost ingestion for LLM providers (Anthropic, OpenAI, DeepSeek) with token-accurate attribution
- Per-call cost ingestion for TTS providers (ElevenLabs, OpenAI) with character / second accounting
- Platform API quota tracking and pre-emptive budget alerts (TikTok, YouTube, Instagram, Facebook)
- Per-content cost rollup joining every stage of the pipeline to a `contentId`
- Revenue ingestion from affiliate programs + platform monetization + brand deals
- ROI calculation engine at per-video / per-platform / per-niche granularity
- Daily + monthly cost dashboard (shadcn/ui + charts) with drill-down
- Budget alert pipeline (threshold breach, forecast exhaustion) via n8n

### Out of Scope
- End-to-end accounting/bookkeeping (general ledger, tax, payroll) — use external system
- Invoice automation, A/R, A/P workflows
- FX hedging / multi-currency risk management (display-only conversion OK)
- Pricing simulator for speculative future API price changes
- External BI tools (Tableau, PowerBI) — in-app dashboard only
- ML cost-prediction model (deterministic accounting first)

### Files to Change
*To be populated after research/research.md synthesis. Expected touch points:*

| File Path | Change Type | Description |
|-----------|-------------|-------------|
| `packages/database/prisma/schema.prisma` | Modify | Add `ApiCostLedger`, `ContentCostRollup`, `RevenueLedger`, `BudgetAlert`, `QuotaReservation` models |
| `apps/api/cost/*` | Create | Cost ingestion endpoints + ROI query API |
| `apps/web/app/cost-dashboard/*` | Create | Dashboard pages (daily, monthly, per-video, alerts) |
| `n8n/workflows/cost-*.json` | Create | Cost ingestion + budget alert workflows |

<!-- /ANCHOR:scope -->
---

<!-- ANCHOR:requirements -->
## 4. REQUIREMENTS

### P0 — Blockers (MUST complete)

| ID      | Requirement                                                | Acceptance Criteria |
|---------|------------------------------------------------------------|---------------------|
| REQ-001 | Capture every LLM call as a cost-ledger event              | All Claude / OpenAI / DeepSeek calls emit `{provider, model, inputTokens, outputTokens, cacheHitTokens, unitPriceUSD, billedUSD, contentId, correlationId}` |
| REQ-002 | Capture every TTS call as a cost-ledger event              | ElevenLabs + OpenAI TTS calls emit `{provider, voice, inputChars OR seconds, unitPriceUSD, billedUSD, contentId}` with Thai-safe char counting |
| REQ-003 | Track platform API quota consumption pre-emptively         | Quota reservation before upload, rejection when reservation exceeds ceiling, auto-reset per-window |
| REQ-004 | Per-content cost rollup query                              | `GET /api/cost/content/:id` returns full cost breakdown grouped by pipeline stage |

### P1 — Required (complete OR user-approved deferral)

| ID      | Requirement                                                | Acceptance Criteria |
|---------|------------------------------------------------------------|---------------------|
| REQ-005 | Revenue ledger ingestion                                   | Affiliate clicks/conversions + platform monetization payouts land in `RevenueLedger`, joinable to content |
| REQ-006 | ROI engine per-video / per-platform / per-niche            | `GET /api/roi/...` returns net profit, margin, payback period, confidence interval for delayed revenue |
| REQ-007 | Daily + monthly cost dashboard                             | shadcn-powered dashboard with >=4 views: daily cost, monthly cost, per-video ROI table, budget alert status |
| REQ-008 | Budget alert pipeline                                      | n8n workflow fires Slack/email when daily/monthly threshold crossed OR 7-day forecast breaches budget |

### P2 — Nice-to-have

| ID      | Requirement                                                | Acceptance Criteria |
|---------|------------------------------------------------------------|---------------------|
| REQ-009 | Cost anomaly detection                                     | Alert when per-content cost deviates >2σ from niche mean |
| REQ-010 | Provider-switch recommender                                | Suggest cheaper equivalent model when margin is thin |

<!-- /ANCHOR:requirements -->
---

<!-- ANCHOR:success-criteria -->
## 5. SUCCESS CRITERIA

- **SC-001:** Every published video exposes an authoritative cost breakdown within 60 seconds of the last pipeline event
- **SC-002:** Dashboards refresh within 2 seconds for the last 30 days of data
- **SC-003:** Budget alerts fire before any provider hard-limit or platform throttle is hit (zero after-the-fact alerts in production)
- **SC-004:** ROI numbers reconcile within ±2% against provider invoices at month end

<!-- /ANCHOR:success-criteria -->
---

<!-- ANCHOR:risks -->
## 6. RISKS & DEPENDENCIES

| Type        | Item                                           | Impact                                | Mitigation |
|-------------|------------------------------------------------|---------------------------------------|------------|
| Dependency  | Provider pricing pages (changes mid-year)      | Cost numbers drift from truth         | Snapshot pricing + monthly reconciliation against invoice |
| Dependency  | Platform monetization APIs (YouTube, TikTok)   | Revenue lag 7-45 days, incomplete API | Batch reconciliation + confidence-interval reporting |
| Risk        | Token/char counting inconsistency (Thai UTF-8) | Mis-priced TTS cost                   | Use provider-reported billable units, not client-side count |
| Risk        | Quota reservation race conditions              | Double-reservation under load         | Postgres advisory locks or Redis atomic SET |
| Risk        | Affiliate attribution cookie lag               | Revenue misattributed across videos   | Short link / UTM with content-id, 30-day window |

<!-- /ANCHOR:risks -->
---

<!-- ANCHOR:questions -->
## 7. OPEN QUESTIONS

- Cost & Profit Tracking — LLM token costs (GPT-4o-mini, Claude, DeepSeek), TTS costs (ElevenLabs, OpenAI), API quota consumption, per-content cost attribution, revenue tracking from affiliates/monetization, ROI calculation per video, per-platform, per-niche, daily/monthly cost dashboard, budget alerts

<!-- /ANCHOR:questions -->

---

<!-- ANCHOR:research-context -->
## 8. RESEARCH CONTEXT

Deep-research session `c573a9af-db20-427c-9916-5c6cdf48ab41` (max 15 iterations, convergence 0.05) is active for this topic.

`research/research.md` remains the canonical synthesis output. The generated findings fence below is rewritten at synthesis time from that source; do not hand-edit between the `<!-- BEGIN GENERATED -->` and `<!-- END GENERATED -->` markers.

<!-- BEGIN GENERATED: deep-research/spec-findings -->
<!-- Auto-generated from research/research.md at 2026-04-17T05:35:00Z. Regenerated on each deep-research run; do not hand-edit between the fence markers. Source: session c573a9af-db20-427c-9916-5c6cdf48ab41, 7 iterations, 55 findings. -->

### Key Findings Summary (from 7-iteration deep research, stopped converged)

**Q1 — Cost Schema & Pricing Feeds (~97% answered)**
- Authoritative 2026-04 pricing captured for Anthropic (Haiku 4.5 / Sonnet 4.6 / Opus 4.7), DeepSeek V3.2 (chat + reasoner, identical $/MTok), ElevenLabs (5 tiers × credit-per-char economics, V2.5 Turbo ~33-50% cheaper than V2 Multilingual for Thai). OpenAI pricing via LiteLLM canonical + Azure Foundry mirror (direct page 403-blocked in 2 sessions).
- **3-layer Prisma design:** `ApiCostLedger` (append-only event log, `Decimal(12,8)` unit price + `Decimal(14,4)` billed USD) + `PricingCatalog` (SCD-style version history with `priceSnapshotVersion` FK) + `ContentCostRollup` (materialized view, refresh ≤5min).
- **Unit discriminator column** (`BillingUnit` enum: TOKEN_INPUT/OUTPUT/CACHE_READ/CACHE_WRITE, CHARACTER, CREDIT, SECOND, REQUEST…) lets one table hold token-billed LLMs, char-billed TTS, credit-billed ElevenLabs, second-billed audio.
- **Source-of-truth `rawResponse` Json column** stores provider-returned `usage` dict for dispute/recompute.
- **1M-context surcharge:** CONFIRMED none for Opus 4.7 on current pricing (iter-5 residual closure).
- **Fast Mode (Opus 4.6 only):** **6x multiplier** — flag `isFastMode` on ledger events.
- **Data residency `inference_geo=US`:** **1.1x multiplier** — capture `inferenceGeo` per call.

**Q2 — Quota & Rate-Limit Tracking (~92% answered)**
- Authoritative 2026-04 LLM rate-limits captured: Anthropic 4 tiers (RPM/ITPM/OTPM/ITokenCap + `x-ratelimit-*` headers), Azure OpenAI 6 tiers, DeepSeek "no hard limit, dynamic adjustment + connection-hold" (circuit-break strategy required), ElevenLabs community-inferred concurrency (primary-source blocked).
- Platform upload quotas verified against 004-platform-upload-deepdive: TikTok 6 req/min + 4GB, YouTube 100 quota-units/day, Instagram 400 containers/24h, Facebook 30 Reels/Page/24h. **No contradictions with 004.**
- **`QuotaReservation` + `QuotaWindow` schema** with `pg_advisory_xact_lock` atomic reservation. Selection matrix: fixed-daily (YouTube), sliding-window (TikTok), token-bucket (Anthropic TPM), semaphore (ElevenLabs concurrency).
- **Unified exponential backoff** (base 500ms × 2^attempt + jitter, max 32s), provider-scoped.
- **004 `rate_limit_tracker` is DEPRECATED** in favor of 008's `QuotaWindow` superset (clean break since 004 hadn't shipped).
- Per-provider reservation strategy: **LLM tokens = post-hoc ledger only** (reservation too expensive); **platform upload = strict pre-reservation** (provider ban risk); **TTS credits = pre-reservation with over-commit tolerance**.

**Q3 — Revenue Attribution (~92% answered)**
- **Amazon Associates PA-API sunsets 2026-04-30** — must migrate to Creators API. S3-proxy reports also deprecated. Schema places `integrationStatus='pending-creators-api-sign-up'` placeholder.
- **TikTok Creator Rewards Program:** Thailand NOT in eligible country list (US/UK/DE/JP/KR/FR/BR only). Thai creators earn via TikTok Shop Affiliate + brand deals + LIVE Gifts only.
- **IG Reels Play Bonus discontinued 2023-03 globally**; current IG bonuses are invite-only without API.
- **YouTube Partner Program** via Analytics API + Reporting API (full access tier required).
- **Impact.com / CJ / ShareASale**: each needs its own n8n ingester (REST + subId1-5 / GraphQL + SID / REST + afftrack). No unified API.
- **`RevenueLedger` + `RevenueAttribution` + `SubIdMapping` + `ShortLink` + `ShortLinkClick` + `AttributionModelConfig` + `ContentRevenueRollup` + `FxSnapshot` Prisma schemas.**
- **5-state SCD-style revenue lifecycle:** `expected → pending → confirmed → extended → reversed`.
- **5 attribution models pre-computed side-by-side:** time-decay (λ=0.05/hr default), view-weighted linear, first-touch, last-touch, deterministic-UTM override.
- **30-90 day payout lag** explicitly modeled via confidence-interval fields.

**Q4 — ROI Engine (~95% answered)**
- Core formulas: gross margin, contribution margin, payback period, LTV-to-CAC proxy (where applicable), time-to-ROI curve.
- **Bayesian/bootstrap CI for pending revenue:** Beta-Bernoulli for conversion probability + bootstrap for revenue distribution; expose 80% + 95% bands.
- **Shared-cost amortization policy:** fixed monthly costs (Postgres, n8n hosting, Clerk, domain, workflow compute) allocated per-video by `minutesRendered` share (fallback: per-video equal-weight).
- **Niche taxonomy:** `Niche` + `ContentNicheTag` many-to-many (joins to 005-trend-viral-brain taxonomy, not duplicated).
- **Materialization hybrid:** `ROIView` SQL VIEW for real-time drill-down; `ContentCostRollup` + `ContentRevenueRollup` materialized views refresh ≤5min on trigger.
- **Confidence flag:** every ROI row exposes `confidenceTier` enum (EARLY <30d / SETTLED >90d / STALE deprecated-source).
- **Hierarchical aggregation SQL:** per-video → per-content-pack (cross-posted) → per-niche → per-platform → per-month.

**Q5 — Dashboard + Alerts Architecture (~100% answered)**
- **9-route dashboard tree under `apps/app/app/(authenticated)/cost-profit/`:** `/overview`, `/daily`, `/monthly`, `/content`, `/content/[id]`, `/roi`, `/niche`, `/alerts`, `/settings`. RSC (heavy rollups) vs Client (drill-down) split locked.
- **shadcn Charts:** canonical install `pnpm dlx shadcn@latest add chart`; 6 chart primitives confirmed; heatmap via Recharts `ScatterChart` custom path.
- **5-trigger n8n alert pipeline DAG:** threshold-breach · forecast-exhaustion · quota-near-ceiling · anomaly (2σ vs niche mean) · provider-outage. 4-channel fan-out: Slack (primary) + Resend email + webhook + in-app toast. `AlertAck` + `AlertDedup` schemas handle dismiss/snooze and anti-spam rolling windows.
- **Storage tier strategy:** hot 0-30d Postgres → warm 30-180d Postgres partitioned → cold >180d S3 Parquet (n8n archiver, DuckDB in-process cold queries).
- **Clerk-org RBAC 3 roles:** admin (all) / editor (own content) / viewer (read-only).
- **Performance:** p95 <2s for 30-day views (SC-002); btree indexes on `(contentId, stage, createdAt DESC)` and `(publishedAt, platform)`.

**Production-Readiness Gates (iter-6, all PASSED)**
- **Thailand PDPA:** field-level classification (personal vs transactional metadata); 10-year Thai Revenue retention reconciled with §33 deletion rights; US cross-border SCC required for Postgres/S3 in US region.
- **Tamper-evident audit:** 5-layer defense = Postgres append-only triggers + hash-chain over `ApiCostLedger` rows + `LedgerAuditLog` + `PricingCatalogAudit` + `AlertAckAudit` + monthly reconciliation job.
- **Testing pyramid:** 3 unit (decimal precision, cost formula invariants, Thai multibyte char counting) + 2 property-based (cost = volume × unit-price) + 2 integration (end-to-end ledger attribution) + 2 E2E (dashboard render, alert fires). Per CLAUDE.md TEST RULE.
- **3 operational runbooks:** budget-alert response · monthly provider-invoice reconciliation · provider-outage recovery.
- **Disaster recovery:** PITR 15-min RPO + ledger replay from `rawResponse` snapshots.

**Integration Touchpoints (6 prior specs)**
- **002 pixelle-video-audit:** 8-stage pipeline cost emission at each stage (LLM script, TTS voice, video render, storage, upload).
- **003 thai-voice-pipeline:** TTS fallback ladder (ElevenLabs → OpenAI → Google → Edge-TTS → F5) — `ApiCostLedger` captures `providerTier` so fallback cost deltas are visible.
- **004 platform-upload-deepdive:** `rate_limit_tracker` → deprecated, merge into 008 `QuotaWindow` superset.
- **005 trend-viral-brain:** 38-feature LightGBM scoring cost per-content via emission hook in scoring loop.
- **006 content-lab:** 5-stage prompt chain × 3×3 variants × Thompson Sampling = 9-15 LLM calls per content, all attributed to same `contentId` via `correlationId`.
- **007 l7-feedback-loop:** L7FeedbackEnvelope Thompson quarantine hooks into `RevenueLedger` (revenue-signal arm).

**Residuals deferred to OPS (3 non-blocking)**
- OpenAI TTS canonical pricing page (direct 403 both sessions) — revisit Helicone blog / Azure OpenAI.
- ElevenLabs concurrency primary-source doc — contact ElevenLabs sales; seed `QuotaWindow` at plan-switch.
- Thailand PDPC Data Mapping Template — fetch Thai legal memo + pdpc.or.th/th before go-live.

### Source of truth
Full synthesis, citations, schema DSL, and SQL patterns live in `research/research.md` (989 lines, §0–§20). Iteration files under `research/iterations/iteration-00{1-7}.md`.
<!-- END GENERATED: deep-research/spec-findings -->

<!-- /ANCHOR:research-context -->

---

<!--
CORE TEMPLATE (~80 lines)
- Essential what/why/how only
- Level 1 scope; escalate to L2 if complexity grows after synthesis
-->
