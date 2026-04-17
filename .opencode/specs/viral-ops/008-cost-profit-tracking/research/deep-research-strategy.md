---
title: Deep Research Strategy — 008-cost-profit-tracking
description: Runtime strategy for viral-ops Cost & Profit Tracking research session. Tracks research progress, focus decisions, and outcomes across iterations.
---

# Deep Research Strategy — Cost & Profit Tracking

Runtime file for session `c573a9af-db20-427c-9916-5c6cdf48ab41`. Tracks research progress across iterations.

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose

Serves as the "persistent brain" for a deep research session. Records what to investigate, what worked, what failed, and where to focus next. Read by the orchestrator and agents at every iteration.

### Usage

- **Init:** Orchestrator copied this template on 2026-04-16T21:18:38Z and populated Topic, Key Questions, Known Context, and Research Boundaries from config and memory context.
- **Per iteration:** Agent reads Next Focus, writes iteration evidence, and the reducer refreshes What Worked/Failed, answered questions, ruled-out directions, and Next Focus.
- **Mutability:** Mutable — analyst-owned sections remain stable, while machine-owned sections are rewritten by the reducer after each iteration.
- **Protection:** Shared state with explicit ownership boundaries. Orchestrator validates consistency on resume.

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
Cost & Profit Tracking — LLM token costs (GPT-4o-mini, Claude, DeepSeek), TTS costs (ElevenLabs, OpenAI), API quota consumption, per-content cost attribution, revenue tracking from affiliates/monetization, ROI calculation per video, per-platform, per-niche, daily/monthly cost dashboard, budget alerts

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
- [ ] **Q1 — Cost Schema & Pricing Feeds:** What is the optimal schema + ingestion strategy for tracking LLM and TTS API costs per content piece across multi-provider stack (GPT-4o-mini, Claude, DeepSeek, ElevenLabs, OpenAI) with correct token/char unit accounting and current 2025-2026 pricing?
- [ ] **Q2 — Quota & Rate-Limit Tracking:** How to track API quota consumption and platform rate limits (YouTube, TikTok, Instagram, Facebook) with pre-emptive budget alerts, quota reservation, and deterministic back-off before provider throttle/ban?
- [ ] **Q3 — Revenue Attribution:** What are the best practices for revenue attribution from affiliate programs (Amazon, Shopee, TikTok Shop, CJ Affiliate, Impact.com) + platform monetization (YouTube Partner, TikTok Creator Fund/Rewards, IG Reels bonus, FB Reels monetization), and how to map delayed/aggregated revenue back to individual content pieces?
- [ ] **Q4 — ROI Engine:** How to design ROI calculation at per-video / per-platform / per-niche granularity that reconciles variable-lag cost data with delayed revenue, handles multi-touch attribution across reposts, and exposes confidence intervals?
- [ ] **Q5 — Dashboard + Alerts Architecture:** What's the recommended architecture for daily/monthly cost dashboards and budget-alert pipelines on next-forge + Prisma 7.4 + n8n stack, including storage tier strategy, alert channels, and dashboard UI patterns (shadcn/ui + chart library)?

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- NOT building an end-to-end accounting/bookkeeping system — focus is per-content cost/revenue attribution, not general ledger
- NOT implementing tax calculation or invoice generation automation
- NOT building FX hedging, currency risk management, or multi-currency reconciliation beyond simple display
- NOT building a pricing-simulator for speculative future API price changes
- NOT researching generic BI tools (Tableau, PowerBI) — assume in-app dashboard via shadcn/ui + charts
- NOT building a full experimental ML cost-prediction model — deterministic accounting first
- NOT covering payroll, ad spend, or external human-labor costs unless directly piped into video cost

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
Stop when ALL of the following are satisfied:

1. All 5 key questions answered with citations from authoritative primary sources (official pricing pages, API docs, platform policies), preferably dated 2025-2026
2. Prisma schema sketched for: `ApiCostLedger`, `ContentCostRollup`, `RevenueLedger`, `BudgetAlert`, `QuotaReservation` tables (or equivalents)
3. End-to-end flow documented: token/char event → cost ledger → content rollup → ROI view → dashboard → alert
4. Current (2025-2026) pricing cited for: Anthropic Claude (Haiku 4.5, Sonnet 4.6, Opus 4.7), OpenAI GPT-4o-mini + TTS, DeepSeek V3/R1, ElevenLabs Creator/Pro/Multilingual
5. Quota/rate-limit numbers cross-referenced with existing 004-platform-upload-deepdive findings (TikTok 6 req/min, YouTube 100 quota, etc.) — no contradictions
6. At least 2 n8n workflow blueprints sketched (cost ingestion + budget alert)
7. Dashboard component inventory includes at least 4 views: daily cost, monthly cost, per-video ROI, budget alert status
8. Open questions count <= 1 OR 3+ iterations produce newInfoRatio < convergence threshold (0.05)

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

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
### **`rate_limit_tracker` preservation for backward compat with 004** — rejected; 004 has not shipped yet (greenfield codebase per iter-1 §F6), so no backward-compat debt. Clean migration during 008 implementation is strictly better than dual-write. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **`rate_limit_tracker` preservation for backward compat with 004** — rejected; 004 has not shipped yet (greenfield codebase per iter-1 §F6), so no backward-compat debt. Clean migration during 008 implementation is strictly better than dual-write.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **`rate_limit_tracker` preservation for backward compat with 004** — rejected; 004 has not shipped yet (greenfield codebase per iter-1 §F6), so no backward-compat debt. Clean migration during 008 implementation is strictly better than dual-write.

### **Amazon developer portal WebFetch across 3+ sessions (iter-1, iter-3, iter-5)** — Cloudflare 403 persistent. Direct portal is inaccessible without actual developer sign-up. Dead-end for public WebFetch; live only via account. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Amazon developer portal WebFetch across 3+ sessions (iter-1, iter-3, iter-5)** — Cloudflare 403 persistent. Direct portal is inaccessible without actual developer sign-up. Dead-end for public WebFetch; live only via account.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Amazon developer portal WebFetch across 3+ sessions (iter-1, iter-3, iter-5)** — Cloudflare 403 persistent. Direct portal is inaccessible without actual developer sign-up. Dead-end for public WebFetch; live only via account.

### **Athena as primary cold-tier query engine** — infra cost + AWS account setup friction for current scale. DuckDB in-process is zero-setup for single-query reporting workflows. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Athena as primary cold-tier query engine** — infra cost + AWS account setup friction for current scale. DuckDB in-process is zero-setup for single-query reporting workflows.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Athena as primary cold-tier query engine** — infra cost + AWS account setup friction for current scale. DuckDB in-process is zero-setup for single-query reporting workflows.

### **CocoIndex semantic search on Windows this session** — daemon crashes at startup with `PermissionError: [WinError 5] Access is denied` on named-pipe creation. Not a research dead-end for the topic, but a tooling dead-end for this machine until the daemon is repaired (separate maintenance spec). Grep + Glob remain available as structural substitutes. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **CocoIndex semantic search on Windows this session** — daemon crashes at startup with `PermissionError: [WinError 5] Access is denied` on named-pipe creation. Not a research dead-end for the topic, but a tooling dead-end for this machine until the daemon is repaired (separate maintenance spec). Grep + Glob remain available as structural substitutes.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **CocoIndex semantic search on Windows this session** — daemon crashes at startup with `PermissionError: [WinError 5] Access is denied` on named-pipe creation. Not a research dead-end for the topic, but a tooling dead-end for this machine until the daemon is repaired (separate maintenance spec). Grep + Glob remain available as structural substitutes.

### **developers.tiktok.com/doc/creator-rewards-program** — 404. No direct TikTok dev doc page exists for Creator Rewards Program earnings API (because the API doesn't exist). -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **developers.tiktok.com/doc/creator-rewards-program** — 404. No direct TikTok dev doc page exists for Creator Rewards Program earnings API (because the API doesn't exist).
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **developers.tiktok.com/doc/creator-rewards-program** — 404. No direct TikTok dev doc page exists for Creator Rewards Program earnings API (because the API doesn't exist).

### **Direct ElevenLabs rate-limit documentation URLs** — multiple variants (api-reference/rate-limits, developer-guides/quickstart, help.elevenlabs.io) all 404/403. Must fall back to iter-1's pricing-page data + inferred concurrency tables from community sources. Not a research dead-end for the question, but for the direct-source verification path — a dedicated iter-5+ pass with a different source (archive.org? elevenlabs-python SDK source comments?) will be needed. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Direct ElevenLabs rate-limit documentation URLs** — multiple variants (api-reference/rate-limits, developer-guides/quickstart, help.elevenlabs.io) all 404/403. Must fall back to iter-1's pricing-page data + inferred concurrency tables from community sources. Not a research dead-end for the question, but for the direct-source verification path — a dedicated iter-5+ pass with a different source (archive.org? elevenlabs-python SDK source comments?) will be needed.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Direct ElevenLabs rate-limit documentation URLs** — multiple variants (api-reference/rate-limits, developer-guides/quickstart, help.elevenlabs.io) all 404/403. Must fall back to iter-1's pricing-page data + inferred concurrency tables from community sources. Not a research dead-end for the question, but for the direct-source verification path — a dedicated iter-5+ pass with a different source (archive.org? elevenlabs-python SDK source comments?) will be needed.

### **Direct impact.com / CJ / Amazon dev portal WebFetch** — all returned portal-only or empty pages. Search-engine summaries of these APIs are more useful than direct WebFetch this session. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Direct impact.com / CJ / Amazon dev portal WebFetch** — all returned portal-only or empty pages. Search-engine summaries of these APIs are more useful than direct WebFetch this session.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Direct impact.com / CJ / Amazon dev portal WebFetch** — all returned portal-only or empty pages. Search-engine summaries of these APIs are more useful than direct WebFetch this session.

### **Direct Instagram Reels Play Bonus API** — program **discontinued globally 2023-03**. Current IG bonuses are invite-only seasonal programs with no API. Revenue from IG in 2026 for viral-ops is limited to Subscriptions + Branded Content + Instagram Gifts + affiliate-originated clicks. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Direct Instagram Reels Play Bonus API** — program **discontinued globally 2023-03**. Current IG bonuses are invite-only seasonal programs with no API. Revenue from IG in 2026 for viral-ops is limited to Subscriptions + Branded Content + Instagram Gifts + affiliate-originated clicks.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Direct Instagram Reels Play Bonus API** — program **discontinued globally 2023-03**. Current IG bonuses are invite-only seasonal programs with no API. Revenue from IG in 2026 for viral-ops is limited to Subscriptions + Branded Content + Instagram Gifts + affiliate-originated clicks.

### **Direct-source Anthropic 1M context surcharge docs** — resolved negatively: no surcharge exists, so no dedicated docs page exists for it. Dead-end in the "there is nothing to find" sense. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Direct-source Anthropic 1M context surcharge docs** — resolved negatively: no surcharge exists, so no dedicated docs page exists for it. Dead-end in the "there is nothing to find" sense.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Direct-source Anthropic 1M context surcharge docs** — resolved negatively: no surcharge exists, so no dedicated docs page exists for it. Dead-end in the "there is nothing to find" sense.

### **Direct TikTok Creator Rewards earnings API** — **does not exist** in 2026-04. Industry sources (3 separate 2026 guides) confirm creators can only access earnings via in-app dashboard. viral-ops must accept manual CSV upload OR re-author via screen-scrape-with-ToS-risk. Deterministic API ingestion is impossible. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Direct TikTok Creator Rewards earnings API** — **does not exist** in 2026-04. Industry sources (3 separate 2026 guides) confirm creators can only access earnings via in-app dashboard. viral-ops must accept manual CSV upload OR re-author via screen-scrape-with-ToS-risk. Deterministic API ingestion is impossible.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Direct TikTok Creator Rewards earnings API** — **does not exist** in 2026-04. Industry sources (3 separate 2026 guides) confirm creators can only access earnings via in-app dashboard. viral-ops must accept manual CSV upload OR re-author via screen-scrape-with-ToS-risk. Deterministic API ingestion is impossible.

### **DLA Piper page as sole PDPA source for GDPR-comparable depth** — page is a solid field-guide but lacks Regulator rulings specificity. For production implementation, follow-up with Thai Bar Association or DPO consulting firm needed. Not a dead-end for research, but flagged in F44 with `[CONFIDENCE: 0.80]`. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **DLA Piper page as sole PDPA source for GDPR-comparable depth** — page is a solid field-guide but lacks Regulator rulings specificity. For production implementation, follow-up with Thai Bar Association or DPO consulting firm needed. Not a dead-end for research, but flagged in F44 with `[CONFIDENCE: 0.80]`.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **DLA Piper page as sole PDPA source for GDPR-comparable depth** — page is a solid field-guide but lacks Regulator rulings specificity. For production implementation, follow-up with Thai Bar Association or DPO consulting firm needed. Not a dead-end for research, but flagged in F44 with `[CONFIDENCE: 0.80]`.

### **ElevenLabs rate-limit docs URL space (iter-2, 3 variants)** — all 404/403. The URL space itself is dead; only community/SDK source remains. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **ElevenLabs rate-limit docs URL space (iter-2, 3 variants)** — all 404/403. The URL space itself is dead; only community/SDK source remains.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **ElevenLabs rate-limit docs URL space (iter-2, 3 variants)** — all 404/403. The URL space itself is dead; only community/SDK source remains.

### **Monte Carlo simulation as primary method** (alternative to bootstrap/Beta-Bernoulli) — considered, rejected: Beta-Bernoulli gives the same answer at O(1) for the common case; bootstrap handles the long-tail. Monte Carlo adds computational cost without adding accuracy for the ROI confidence-interval use case. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Monte Carlo simulation as primary method** (alternative to bootstrap/Beta-Bernoulli) — considered, rejected: Beta-Bernoulli gives the same answer at O(1) for the common case; bootstrap handles the long-tail. Monte Carlo adds computational cost without adding accuracy for the ROI confidence-interval use case.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Monte Carlo simulation as primary method** (alternative to bootstrap/Beta-Bernoulli) — considered, rejected: Beta-Bernoulli gives the same answer at O(1) for the common case; bootstrap handles the long-tail. Monte Carlo adds computational cost without adding accuracy for the ROI confidence-interval use case.

### **Mutable `SharedCostMonth` retroactive edits** — rejected in F27 + F31: `lockedAt` is immutable after allocation. Corrections go through `SharedCostCorrection` rows, preserving audit trail. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Mutable `SharedCostMonth` retroactive edits** — rejected in F27 + F31: `lockedAt` is immutable after allocation. Corrections go through `SharedCostCorrection` rows, preserving audit trail.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Mutable `SharedCostMonth` retroactive edits** — rejected in F27 + F31: `lockedAt` is immutable after allocation. Corrections go through `SharedCostCorrection` rows, preserving audit trail.

### None this iteration — all planned lines of inquiry were productive. The deferred items from iter-3 (ShareASale direct docs, CJ GraphQL schema, Amazon Creators API endpoint deep-dive) remain deferred to iter-5+ as planned; they are not dead-ends but scheduled work. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: None this iteration — all planned lines of inquiry were productive. The deferred items from iter-3 (ShareASale direct docs, CJ GraphQL schema, Amazon Creators API endpoint deep-dive) remain deferred to iter-5+ as planned; they are not dead-ends but scheduled work.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None this iteration — all planned lines of inquiry were productive. The deferred items from iter-3 (ShareASale direct docs, CJ GraphQL schema, Amazon Creators API endpoint deep-dive) remain deferred to iter-5+ as planned; they are not dead-ends but scheduled work.

### **One single `rate_limit_tracker` table (as in 004)** — too coarse for a mixed token/count/semaphore system. 004's `rate_limit_tracker` covered only platform count-based quotas. For viral-ops, we need `QuotaReservation` (per-call immutable audit) + `QuotaWindow` (aggregated state) — 004's table becomes a special case of `QuotaWindow`. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **One single `rate_limit_tracker` table (as in 004)** — too coarse for a mixed token/count/semaphore system. 004's `rate_limit_tracker` covered only platform count-based quotas. For viral-ops, we need `QuotaReservation` (per-call immutable audit) + `QuotaWindow` (aggregated state) — 004's table becomes a special case of `QuotaWindow`.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **One single `rate_limit_tracker` table (as in 004)** — too coarse for a mixed token/count/semaphore system. 004's `rate_limit_tracker` covered only platform count-based quotas. For viral-ops, we need `QuotaReservation` (per-call immutable audit) + `QuotaWindow` (aggregated state) — 004's table becomes a special case of `QuotaWindow`.

### **OpenAI pricing / TTS endpoint WebFetch across 2 sessions (iter-1, iter-5)** — Cloudflare 403 persistent across all subdomains. Dead-end for direct WebFetch; workaround is LiteLLM (partial, null on TTS) + historical snapshots + future Azure-mirror / Helicone attempt. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **OpenAI pricing / TTS endpoint WebFetch across 2 sessions (iter-1, iter-5)** — Cloudflare 403 persistent across all subdomains. Dead-end for direct WebFetch; workaround is LiteLLM (partial, null on TTS) + historical snapshots + future Azure-mirror / Helicone attempt.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **OpenAI pricing / TTS endpoint WebFetch across 2 sessions (iter-1, iter-5)** — Cloudflare 403 persistent across all subdomains. Dead-end for direct WebFetch; workaround is LiteLLM (partial, null on TTS) + historical snapshots + future Azure-mirror / Helicone attempt.

### **OpenAI's own rate-limit page** — Cloudflare 403 confirmed again (same wall as iter-1 pricing). Azure Foundry mirror is the legitimate 2026-04 workaround. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **OpenAI's own rate-limit page** — Cloudflare 403 confirmed again (same wall as iter-1 pricing). Azure Foundry mirror is the legitimate 2026-04 workaround.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **OpenAI's own rate-limit page** — Cloudflare 403 confirmed again (same wall as iter-1 pricing). Azure Foundry mirror is the legitimate 2026-04 workaround.

### **Opening a new key question (Q6)** — not triggered; all 5 Qs remain ≥92% confidence, production-readiness gate closed in iter-6, no contradiction discovered this iteration. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Opening a new key question (Q6)** — not triggered; all 5 Qs remain ≥92% confidence, production-readiness gate closed in iter-6, no contradiction discovered this iteration.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Opening a new key question (Q6)** — not triggered; all 5 Qs remain ≥92% confidence, production-readiness gate closed in iter-6, no contradiction discovered this iteration.

### **Option A (flat per-video) shared-cost allocation** — rejected in F27: massively undercosts expensive long-form content, overcosts trivial reposts. The economic reality is that always-on infra serves content while it's live. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Option A (flat per-video) shared-cost allocation** — rejected in F27: massively undercosts expensive long-form content, overcosts trivial reposts. The economic reality is that always-on infra serves content while it's live.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Option A (flat per-video) shared-cost allocation** — rejected in F27: massively undercosts expensive long-form content, overcosts trivial reposts. The economic reality is that always-on infra serves content while it's live.

### **Option B (per-minute-rendered) as primary allocation** — rejected in F27: rewards pathologically-long videos at the expense of short-form, which is the opposite of Thai viral strategy (24-48h half-life, spec 005). Kept as tiebreaker only. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Option B (per-minute-rendered) as primary allocation** — rejected in F27: rewards pathologically-long videos at the expense of short-form, which is the opposite of Thai viral strategy (24-48h half-life, spec 005). Kept as tiebreaker only.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Option B (per-minute-rendered) as primary allocation** — rejected in F27: rewards pathologically-long videos at the expense of short-form, which is the opposite of Thai viral strategy (24-48h half-life, spec 005). Kept as tiebreaker only.

### **PA-API / Amazon developer docs** — persistent Cloudflare 403 across iter-1/3/5 already logged as BLOCKED; not retried this iteration. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **PA-API / Amazon developer docs** — persistent Cloudflare 403 across iter-1/3/5 already logged as BLOCKED; not retried this iteration.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **PA-API / Amazon developer docs** — persistent Cloudflare 403 across iter-1/3/5 already logged as BLOCKED; not retried this iteration.

### **PA-API (Amazon Product Advertising) for new integrations** — **deprecates 2026-04-30 (in 13 days)**. Any new viral-ops Amazon integration must start on **Creators API**. PA-API dev work is wasted effort past 2026-04-30. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **PA-API (Amazon Product Advertising) for new integrations** — **deprecates 2026-04-30 (in 13 days)**. Any new viral-ops Amazon integration must start on **Creators API**. PA-API dev work is wasted effort past 2026-04-30.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **PA-API (Amazon Product Advertising) for new integrations** — **deprecates 2026-04-30 (in 13 days)**. Any new viral-ops Amazon integration must start on **Creators API**. PA-API dev work is wasted effort past 2026-04-30.

### **Path B (CSS Grid) for niche heatmap** — tooltip/legend inconsistency with F36 pattern outweighs simplicity benefit. Path A locked. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Path B (CSS Grid) for niche heatmap** — tooltip/legend inconsistency with F36 pattern outweighs simplicity benefit. Path A locked.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Path B (CSS Grid) for niche heatmap** — tooltip/legend inconsistency with F36 pattern outweighs simplicity benefit. Path A locked.

### **Per-request sliding-log reservation** — O(N) memory grows unbounded at 60s sliding window × thousands of content generations. Token bucket gives equivalent accuracy at O(1). -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Per-request sliding-log reservation** — O(N) memory grows unbounded at 60s sliding window × thousands of content generations. Token bucket gives equivalent accuracy at O(1).
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Per-request sliding-log reservation** — O(N) memory grows unbounded at 60s sliding window × thousands of content generations. Token bucket gives equivalent accuracy at O(1).

### **Pro-rating cost across platforms uniformly** — rejected in F32: should be weighted by actual view share (needs `PlatformViewShare` from spec 007 BUC). Fallback to equal split only when feedback-loop data absent. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Pro-rating cost across platforms uniformly** — rejected in F32: should be weighted by actual view share (needs `PlatformViewShare` from spec 007 BUC). Fallback to equal split only when feedback-loop data absent.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Pro-rating cost across platforms uniformly** — rejected in F32: should be weighted by actual view share (needs `PlatformViewShare` from spec 007 BUC). Fallback to equal split only when feedback-loop data absent.

### **Pure frequentist point estimate for pending revenue** — rejected in F26: discards information about historical acceptance-rate variance, which is the whole reason confidence intervals matter. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Pure frequentist point estimate for pending revenue** — rejected in F26: discards information about historical acceptance-rate variance, which is the whole reason confidence intervals matter.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Pure frequentist point estimate for pending revenue** — rejected in F26: discards information about historical acceptance-rate variance, which is the whole reason confidence intervals matter.

### **Real-time `ROIView` materialization** — rejected in F30: overkill. Unmaterialized view with upstream materialized rollups hits <50ms on warm cache at viral-ops scale. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Real-time `ROIView` materialization** — rejected in F30: overkill. Unmaterialized view with upstream materialized rollups hits <50ms on warm cache at viral-ops scale.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time `ROIView` materialization** — rejected in F30: overkill. Unmaterialized view with upstream materialized rollups hits <50ms on warm cache at viral-ops scale.

### **Real-time revenue attribution** — the 30-90 day affiliate reconciliation lag makes real-time attribution structurally impossible. Viral-ops accepts "expected" (low-confidence) projections in dashboard but only counts "confirmed" in ROI alerts. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Real-time revenue attribution** — the 30-90 day affiliate reconciliation lag makes real-time attribution structurally impossible. Viral-ops accepts "expected" (low-confidence) projections in dashboard but only counts "confirmed" in ROI alerts.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time revenue attribution** — the 30-90 day affiliate reconciliation lag makes real-time attribution structurally impossible. Viral-ops accepts "expected" (low-confidence) projections in dashboard but only counts "confirmed" in ROI alerts.

### **Real-time (sub-5-min) budget-alert cadence** — evaluated: Prisma query cost × 12/hour for every threshold is wasteful. 5-min cadence hits "high viral push over 80% in hour 18" case within SC-002 budget. Sub-minute cadence deferred until operator feedback justifies it. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Real-time (sub-5-min) budget-alert cadence** — evaluated: Prisma query cost × 12/hour for every threshold is wasteful. 5-min cadence hits "high viral push over 80% in hour 18" case within SC-002 budget. Sub-minute cadence deferred until operator feedback justifies it.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time (sub-5-min) budget-alert cadence** — evaluated: Prisma query cost × 12/hour for every threshold is wasteful. 5-min cadence hits "high viral push over 80% in hour 18" case within SC-002 budget. Sub-minute cadence deferred until operator feedback justifies it.

### **Redis for alert dedup** — adds second source of truth. Postgres `AlertDedup` table with `UNIQUE INDEX` on `dedupKey` + 4h TTL cleanup cron does the same at zero ops cost at viral-ops scale. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Redis for alert dedup** — adds second source of truth. Postgres `AlertDedup` table with `UNIQUE INDEX` on `dedupKey` + 4h TTL cleanup cron does the same at zero ops cost at viral-ops scale.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Redis for alert dedup** — adds second source of truth. Postgres `AlertDedup` table with `UNIQUE INDEX` on `dedupKey` + 4h TTL cleanup cron does the same at zero ops cost at viral-ops scale.

### **Redis SETNX for quota counter** — adds a second source of truth that must be kept in sync with Postgres (primary via Prisma). Advisory locks on Postgres give us atomicity without the split-brain risk. Revisit only if we breach 1000 req/s. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Redis SETNX for quota counter** — adds a second source of truth that must be kept in sync with Postgres (primary via Prisma). Advisory locks on Postgres give us atomicity without the split-brain risk. Revisit only if we breach 1000 req/s.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Redis SETNX for quota counter** — adds a second source of truth that must be kept in sync with Postgres (primary via Prisma). Advisory locks on Postgres give us atomicity without the split-brain risk. Revisit only if we breach 1000 req/s.

### **Re-FX'ing reversals at reversal-date** — breaks the sum invariant. Always use `earnedAt` FX rate for the reversal to preserve `sum(confirmed.amountUsd) == net_revenue_at_earned_date`. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Re-FX'ing reversals at reversal-date** — breaks the sum invariant. Always use `earnedAt` FX rate for the reversal to preserve `sum(confirmed.amountUsd) == net_revenue_at_earned_date`.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Re-FX'ing reversals at reversal-date** — breaks the sum invariant. Always use `earnedAt` FX rate for the reversal to preserve `sum(confirmed.amountUsd) == net_revenue_at_earned_date`.

### **Re-running any WebFetch this iteration** — rejected per iter-7 dispatch constraint "prefer zero external fetches to keep ratio honest." Consolidation work does not require new primary sources. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Re-running any WebFetch this iteration** — rejected per iter-7 dispatch constraint "prefer zero external fetches to keep ratio honest." Consolidation work does not require new primary sources.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Re-running any WebFetch this iteration** — rejected per iter-7 dispatch constraint "prefer zero external fetches to keep ratio honest." Consolidation work does not require new primary sources.

### **Rewriting research.md §0–16** — rejected; append-only per dispatch. §17–19 added. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Rewriting research.md §0–16** — rejected; append-only per dispatch. §17–19 added.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Rewriting research.md §0–16** — rejected; append-only per dispatch. §17–19 added.

### **S3-proxy based Amazon reports** — **deprecated in 2026**. Any script that pulls Amazon commission CSVs from S3 will break. Creators API is canonical replacement. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **S3-proxy based Amazon reports** — **deprecated in 2026**. Any script that pulls Amazon commission CSVs from S3 will break. Creators API is canonical replacement.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **S3-proxy based Amazon reports** — **deprecated in 2026**. Any script that pulls Amazon commission CSVs from S3 will break. Creators API is canonical replacement.

### **Single `alert_channel` table vs fan-out chain** — considered: one row per alert-channel pair instead of fan-out at dispatch time. Rejected: channel set is typically 2-3, table approach adds write amplification without query benefit; fan-out at dispatch time (F38) is simpler. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Single `alert_channel` table vs fan-out chain** — considered: one row per alert-channel pair instead of fan-out at dispatch time. Rejected: channel set is typically 2-3, table approach adds write amplification without query benefit; fan-out at dispatch time (F38) is simpler.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single `alert_channel` table vs fan-out chain** — considered: one row per alert-channel pair instead of fan-out at dispatch time. Rejected: channel set is typically 2-3, table approach adds write amplification without query benefit; fan-out at dispatch time (F38) is simpler.

### **Single flat table with nullable volume columns for every possible unit** — considered, rejected: leads to 15+ nullable columns, insert-side bugs where wrong unit gets populated, and dashboard queries full of `COALESCE(...)`. Three-layer design is strictly better. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Single flat table with nullable volume columns for every possible unit** — considered, rejected: leads to 15+ nullable columns, insert-side bugs where wrong unit gets populated, and dashboard queries full of `COALESCE(...)`. Three-layer design is strictly better.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single flat table with nullable volume columns for every possible unit** — considered, rejected: leads to 15+ nullable columns, insert-side bugs where wrong unit gets populated, and dashboard queries full of `COALESCE(...)`. Three-layer design is strictly better.

### **Single-niche-per-content** — rejected in F28: loses the intersectional signal (e.g., "Thai street food" + "budget travel" + "life-hack") that feeds spec 005 trend-viral-brain. Many-tag + one-dominant is strictly better. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Single-niche-per-content** — rejected in F28: loses the intersectional signal (e.g., "Thai street food" + "budget travel" + "life-hack") that feeds spec 005 trend-viral-brain. Many-tag + one-dominant is strictly better.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single-niche-per-content** — rejected in F28: loses the intersectional signal (e.g., "Thai street food" + "budget travel" + "life-hack") that feeds spec 005 trend-viral-brain. Many-tag + one-dominant is strictly better.

### **Single-table audit log** — considered one `AuditLog` table for all audit events; rejected: mixing financial audit (SOX-flavored) with alert-ack audit (ops-flavored) complicates retention and RBAC. Three separate tables (`LedgerAuditLog`, `PricingCatalogAudit`, `AlertAckAudit`) is strictly better. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Single-table audit log** — considered one `AuditLog` table for all audit events; rejected: mixing financial audit (SOX-flavored) with alert-ack audit (ops-flavored) complicates retention and RBAC. Three separate tables (`LedgerAuditLog`, `PricingCatalogAudit`, `AlertAckAudit`) is strictly better.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single-table audit log** — considered one `AuditLog` table for all audit events; rejected: mixing financial audit (SOX-flavored) with alert-ack audit (ops-flavored) complicates retention and RBAC. Three separate tables (`LedgerAuditLog`, `PricingCatalogAudit`, `AlertAckAudit`) is strictly better.

### **Storing a single "attributedContentId" on each RevenueLedger row** — rejected; multi-touch attribution needs N:M mapping (one revenue row to multiple contentIds with varying weights). The dedicated `RevenueAttribution` table is strictly better. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Storing a single "attributedContentId" on each RevenueLedger row** — rejected; multi-touch attribution needs N:M mapping (one revenue row to multiple contentIds with varying weights). The dedicated `RevenueAttribution` table is strictly better.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Storing a single "attributedContentId" on each RevenueLedger row** — rejected; multi-touch attribution needs N:M mapping (one revenue row to multiple contentIds with varying weights). The dedicated `RevenueAttribution` table is strictly better.

### **Storing only billed USD without pricing snapshot** — rejected: blocks any historical audit if a vendor changes a rate or we discover a computation bug; the raw `usage` dict + versioned `PricingCatalog` lookup is essential for reproducibility. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Storing only billed USD without pricing snapshot** — rejected: blocks any historical audit if a vendor changes a rate or we discover a computation bug; the raw `usage` dict + versioned `PricingCatalog` lookup is essential for reproducibility.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Storing only billed USD without pricing snapshot** — rejected: blocks any historical audit if a vendor changes a rate or we discover a computation bug; the raw `usage` dict + versioned `PricingCatalog` lookup is essential for reproducibility.

### **Storing quota state in-memory only (no Prisma table)** — fails across n8n worker restarts + cross-worker races. Rejected. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Storing quota state in-memory only (no Prisma table)** — fails across n8n worker restarts + cross-worker races. Rejected.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Storing quota state in-memory only (no Prisma table)** — fails across n8n worker restarts + cross-worker races. Rejected.

### **tiktok.com/support/faq_detail?id=7581821550694013452** — returned empty content; redirects provide no structured data. TikTok's support pages remain an unreliable source for authoritative API data. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **tiktok.com/support/faq_detail?id=7581821550694013452** — returned empty content; redirects provide no structured data. TikTok's support pages remain an unreliable source for authoritative API data.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **tiktok.com/support/faq_detail?id=7581821550694013452** — returned empty content; redirects provide no structured data. TikTok's support pages remain an unreliable source for authoritative API data.

### **Trigger-based `updated_at` on ledger tables** — rejected: ledger tables are append-only; no `updated_at` by design. State changes happen via new rows (F45 Layer 1). -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Trigger-based `updated_at` on ledger tables** — rejected: ledger tables are append-only; no `updated_at` by design. State changes happen via new rows (F45 Layer 1).
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Trigger-based `updated_at` on ledger tables** — rejected: ledger tables are append-only; no `updated_at` by design. State changes happen via new rows (F45 Layer 1).

### **WebFetch against openai.com + platform.openai.com** — all endpoints returned 403. Need an alternative source for OpenAI TTS pricing (Helicone docs, Azure OpenAI portal pricing, OpenAI GitHub sample repos, or a cached-snapshot service) in iteration 2. Not a dead-end for the question, just a dead-end for this single source. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **WebFetch against openai.com + platform.openai.com** — all endpoints returned 403. Need an alternative source for OpenAI TTS pricing (Helicone docs, Azure OpenAI portal pricing, OpenAI GitHub sample repos, or a cached-snapshot service) in iteration 2. Not a dead-end for the question, just a dead-end for this single source.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **WebFetch against openai.com + platform.openai.com** — all endpoints returned 403. Need an alternative source for OpenAI TTS pricing (Helicone docs, Azure OpenAI portal pricing, OpenAI GitHub sample repos, or a cached-snapshot service) in iteration 2. Not a dead-end for the question, just a dead-end for this single source.

### **WebFetch to Thai PDPC official portal (pdpc.or.th)** — not attempted this iteration; DLA Piper was the chosen secondary source. Flagged as backlog for spec-008 implementation phase. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **WebFetch to Thai PDPC official portal (pdpc.or.th)** — not attempted this iteration; DLA Piper was the chosen secondary source. Flagged as backlog for spec-008 implementation phase.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **WebFetch to Thai PDPC official portal (pdpc.or.th)** — not attempted this iteration; DLA Piper was the chosen secondary source. Flagged as backlog for spec-008 implementation phase.

### **WebFetch webservices.amazon.com/paapi5/documentation/migration-to-creators-api.html** (403 — same Cloudflare wall as iter-1/2/3 OpenAI/Amazon). Will not retry this session. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **WebFetch webservices.amazon.com/paapi5/documentation/migration-to-creators-api.html** (403 — same Cloudflare wall as iter-1/2/3 OpenAI/Amazon). Will not retry this session.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **WebFetch webservices.amazon.com/paapi5/documentation/migration-to-creators-api.html** (403 — same Cloudflare wall as iter-1/2/3 OpenAI/Amazon). Will not retry this session.

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
- **CocoIndex semantic search on Windows this session** — daemon crashes at startup with `PermissionError: [WinError 5] Access is denied` on named-pipe creation. Not a research dead-end for the topic, but a tooling dead-end for this machine until the daemon is repaired (separate maintenance spec). Grep + Glob remain available as structural substitutes. (iteration 1)
- **Single flat table with nullable volume columns for every possible unit** — considered, rejected: leads to 15+ nullable columns, insert-side bugs where wrong unit gets populated, and dashboard queries full of `COALESCE(...)`. Three-layer design is strictly better. (iteration 1)
- **Storing only billed USD without pricing snapshot** — rejected: blocks any historical audit if a vendor changes a rate or we discover a computation bug; the raw `usage` dict + versioned `PricingCatalog` lookup is essential for reproducibility. (iteration 1)
- **WebFetch against openai.com + platform.openai.com** — all endpoints returned 403. Need an alternative source for OpenAI TTS pricing (Helicone docs, Azure OpenAI portal pricing, OpenAI GitHub sample repos, or a cached-snapshot service) in iteration 2. Not a dead-end for the question, just a dead-end for this single source. (iteration 1)
- **Direct ElevenLabs rate-limit documentation URLs** — multiple variants (api-reference/rate-limits, developer-guides/quickstart, help.elevenlabs.io) all 404/403. Must fall back to iter-1's pricing-page data + inferred concurrency tables from community sources. Not a research dead-end for the question, but for the direct-source verification path — a dedicated iter-5+ pass with a different source (archive.org? elevenlabs-python SDK source comments?) will be needed. (iteration 2)
- **One single `rate_limit_tracker` table (as in 004)** — too coarse for a mixed token/count/semaphore system. 004's `rate_limit_tracker` covered only platform count-based quotas. For viral-ops, we need `QuotaReservation` (per-call immutable audit) + `QuotaWindow` (aggregated state) — 004's table becomes a special case of `QuotaWindow`. (iteration 2)
- **OpenAI's own rate-limit page** — Cloudflare 403 confirmed again (same wall as iter-1 pricing). Azure Foundry mirror is the legitimate 2026-04 workaround. (iteration 2)
- **Per-request sliding-log reservation** — O(N) memory grows unbounded at 60s sliding window × thousands of content generations. Token bucket gives equivalent accuracy at O(1). (iteration 2)
- **Redis SETNX for quota counter** — adds a second source of truth that must be kept in sync with Postgres (primary via Prisma). Advisory locks on Postgres give us atomicity without the split-brain risk. Revisit only if we breach 1000 req/s. (iteration 2)
- **Storing quota state in-memory only (no Prisma table)** — fails across n8n worker restarts + cross-worker races. Rejected. (iteration 2)
- **developers.tiktok.com/doc/creator-rewards-program** — 404. No direct TikTok dev doc page exists for Creator Rewards Program earnings API (because the API doesn't exist). (iteration 3)
- **Direct impact.com / CJ / Amazon dev portal WebFetch** — all returned portal-only or empty pages. Search-engine summaries of these APIs are more useful than direct WebFetch this session. (iteration 3)
- **Direct Instagram Reels Play Bonus API** — program **discontinued globally 2023-03**. Current IG bonuses are invite-only seasonal programs with no API. Revenue from IG in 2026 for viral-ops is limited to Subscriptions + Branded Content + Instagram Gifts + affiliate-originated clicks. (iteration 3)
- **Direct TikTok Creator Rewards earnings API** — **does not exist** in 2026-04. Industry sources (3 separate 2026 guides) confirm creators can only access earnings via in-app dashboard. viral-ops must accept manual CSV upload OR re-author via screen-scrape-with-ToS-risk. Deterministic API ingestion is impossible. (iteration 3)
- **PA-API (Amazon Product Advertising) for new integrations** — **deprecates 2026-04-30 (in 13 days)**. Any new viral-ops Amazon integration must start on **Creators API**. PA-API dev work is wasted effort past 2026-04-30. (iteration 3)
- **Real-time revenue attribution** — the 30-90 day affiliate reconciliation lag makes real-time attribution structurally impossible. Viral-ops accepts "expected" (low-confidence) projections in dashboard but only counts "confirmed" in ROI alerts. (iteration 3)
- **Re-FX'ing reversals at reversal-date** — breaks the sum invariant. Always use `earnedAt` FX rate for the reversal to preserve `sum(confirmed.amountUsd) == net_revenue_at_earned_date`. (iteration 3)
- **S3-proxy based Amazon reports** — **deprecated in 2026**. Any script that pulls Amazon commission CSVs from S3 will break. Creators API is canonical replacement. (iteration 3)
- **Storing a single "attributedContentId" on each RevenueLedger row** — rejected; multi-touch attribution needs N:M mapping (one revenue row to multiple contentIds with varying weights). The dedicated `RevenueAttribution` table is strictly better. (iteration 3)
- **tiktok.com/support/faq_detail?id=7581821550694013452** — returned empty content; redirects provide no structured data. TikTok's support pages remain an unreliable source for authoritative API data. (iteration 3)
- **Monte Carlo simulation as primary method** (alternative to bootstrap/Beta-Bernoulli) — considered, rejected: Beta-Bernoulli gives the same answer at O(1) for the common case; bootstrap handles the long-tail. Monte Carlo adds computational cost without adding accuracy for the ROI confidence-interval use case. (iteration 4)
- **Mutable `SharedCostMonth` retroactive edits** — rejected in F27 + F31: `lockedAt` is immutable after allocation. Corrections go through `SharedCostCorrection` rows, preserving audit trail. (iteration 4)
- None this iteration — all planned lines of inquiry were productive. The deferred items from iter-3 (ShareASale direct docs, CJ GraphQL schema, Amazon Creators API endpoint deep-dive) remain deferred to iter-5+ as planned; they are not dead-ends but scheduled work. (iteration 4)
- **Option A (flat per-video) shared-cost allocation** — rejected in F27: massively undercosts expensive long-form content, overcosts trivial reposts. The economic reality is that always-on infra serves content while it's live. (iteration 4)
- **Option B (per-minute-rendered) as primary allocation** — rejected in F27: rewards pathologically-long videos at the expense of short-form, which is the opposite of Thai viral strategy (24-48h half-life, spec 005). Kept as tiebreaker only. (iteration 4)
- **Pro-rating cost across platforms uniformly** — rejected in F32: should be weighted by actual view share (needs `PlatformViewShare` from spec 007 BUC). Fallback to equal split only when feedback-loop data absent. (iteration 4)
- **Pure frequentist point estimate for pending revenue** — rejected in F26: discards information about historical acceptance-rate variance, which is the whole reason confidence intervals matter. (iteration 4)
- **Real-time `ROIView` materialization** — rejected in F30: overkill. Unmaterialized view with upstream materialized rollups hits <50ms on warm cache at viral-ops scale. (iteration 4)
- **Single-niche-per-content** — rejected in F28: loses the intersectional signal (e.g., "Thai street food" + "budget travel" + "life-hack") that feeds spec 005 trend-viral-brain. Many-tag + one-dominant is strictly better. (iteration 4)
- **Amazon developer portal WebFetch across 3+ sessions (iter-1, iter-3, iter-5)** — Cloudflare 403 persistent. Direct portal is inaccessible without actual developer sign-up. Dead-end for public WebFetch; live only via account. (iteration 5)
- **Athena as primary cold-tier query engine** — infra cost + AWS account setup friction for current scale. DuckDB in-process is zero-setup for single-query reporting workflows. (iteration 5)
- **Direct-source Anthropic 1M context surcharge docs** — resolved negatively: no surcharge exists, so no dedicated docs page exists for it. Dead-end in the "there is nothing to find" sense. (iteration 5)
- **ElevenLabs rate-limit docs URL space (iter-2, 3 variants)** — all 404/403. The URL space itself is dead; only community/SDK source remains. (iteration 5)
- **OpenAI pricing / TTS endpoint WebFetch across 2 sessions (iter-1, iter-5)** — Cloudflare 403 persistent across all subdomains. Dead-end for direct WebFetch; workaround is LiteLLM (partial, null on TTS) + historical snapshots + future Azure-mirror / Helicone attempt. (iteration 5)
- **Path B (CSS Grid) for niche heatmap** — tooltip/legend inconsistency with F36 pattern outweighs simplicity benefit. Path A locked. (iteration 5)
- **Real-time (sub-5-min) budget-alert cadence** — evaluated: Prisma query cost × 12/hour for every threshold is wasteful. 5-min cadence hits "high viral push over 80% in hour 18" case within SC-002 budget. Sub-minute cadence deferred until operator feedback justifies it. (iteration 5)
- **Redis for alert dedup** — adds second source of truth. Postgres `AlertDedup` table with `UNIQUE INDEX` on `dedupKey` + 4h TTL cleanup cron does the same at zero ops cost at viral-ops scale. (iteration 5)
- **Single `alert_channel` table vs fan-out chain** — considered: one row per alert-channel pair instead of fan-out at dispatch time. Rejected: channel set is typically 2-3, table approach adds write amplification without query benefit; fan-out at dispatch time (F38) is simpler. (iteration 5)
- **WebFetch webservices.amazon.com/paapi5/documentation/migration-to-creators-api.html** (403 — same Cloudflare wall as iter-1/2/3 OpenAI/Amazon). Will not retry this session. (iteration 5)
- **`rate_limit_tracker` preservation for backward compat with 004** — rejected; 004 has not shipped yet (greenfield codebase per iter-1 §F6), so no backward-compat debt. Clean migration during 008 implementation is strictly better than dual-write. (iteration 6)
- **DLA Piper page as sole PDPA source for GDPR-comparable depth** — page is a solid field-guide but lacks Regulator rulings specificity. For production implementation, follow-up with Thai Bar Association or DPO consulting firm needed. Not a dead-end for research, but flagged in F44 with `[CONFIDENCE: 0.80]`. (iteration 6)
- **PA-API / Amazon developer docs** — persistent Cloudflare 403 across iter-1/3/5 already logged as BLOCKED; not retried this iteration. (iteration 6)
- **Single-table audit log** — considered one `AuditLog` table for all audit events; rejected: mixing financial audit (SOX-flavored) with alert-ack audit (ops-flavored) complicates retention and RBAC. Three separate tables (`LedgerAuditLog`, `PricingCatalogAudit`, `AlertAckAudit`) is strictly better. (iteration 6)
- **Trigger-based `updated_at` on ledger tables** — rejected: ledger tables are append-only; no `updated_at` by design. State changes happen via new rows (F45 Layer 1). (iteration 6)
- **WebFetch to Thai PDPC official portal (pdpc.or.th)** — not attempted this iteration; DLA Piper was the chosen secondary source. Flagged as backlog for spec-008 implementation phase. (iteration 6)
- **Opening a new key question (Q6)** — not triggered; all 5 Qs remain ≥92% confidence, production-readiness gate closed in iter-6, no contradiction discovered this iteration. (iteration 7)
- **Re-running any WebFetch this iteration** — rejected per iter-7 dispatch constraint "prefer zero external fetches to keep ratio honest." Consolidation work does not require new primary sources. (iteration 7)
- **Rewriting research.md §0–16** — rejected; append-only per dispatch. §17–19 added. (iteration 7)

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
**Primary: Trigger phase 3 (synthesize).** All stop conditions satisfied: - 7-of-8 ✓, 1 △ on OpenAI TTS (accepted per residual table) - 0 open questions; 5 Qs at ≥92% confidence - Consolidated schema compile-clean (F50) - Citation sweep complete with tier distribution (F51) - 11 residuals explicitly dispositioned (F52) - Graph coherent, no orphans (F55) - research.md §17–19 appended **Secondary (low priority): iter-8 is NOT needed.** All loop-exit conditions met. If phase_synthesis adds requirements, they'll be handled there, not in a new research iteration. ---

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

**Memory search result:** No prior research directly on cost-profit tracking. Memory returned degraded/empty results for this topic.

**Relevant prior specs** (from MEMORY.md index + spec folder inventory):
- **001-base-app-research:** next-forge v6.0.2, Prisma 7.4, n8n 2.16, Clerk auth — base stack
- **002-pixelle-video-audit:** 21 endpoints, 29 workflows, 8-stage pipeline — existing cost emission points
- **003-thai-voice-pipeline:** TTS ranking: ElevenLabs > OpenAI > Google > Edge-TTS > F5-TTS-THAI — TTS providers in scope
- **004-platform-upload-deepdive:** rate_limit_tracker table, TikTok 6 req/min 4GB, YouTube 100 quota, IG 400 containers/24h, FB 30 Reels/Page/24h — quota ceiling data
- **005-trend-viral-brain:** LLM scoring 1-5 (6 dims) 38-feature LightGBM — LLM cost generators
- **006-content-lab:** 5-stage prompt chain, 3x3 variants, Thompson Sampling, 5 n8n workflows — major LLM cost source
- **007-l7-feedback-loop:** L7FeedbackEnvelope + Thompson quarantine, Evidently+NannyML, BUC 4800×/24h — revenue-signal ingestion

**Stack assumptions (carry forward):**
- Backend: next-forge v6.0.2, Prisma 7.4 (Postgres)
- Orchestration: n8n 2.16 workflows
- Auth: Clerk
- Frontend: shadcn/ui + DESIGN.md (Linear-inspired) + shadcn charts
- TTS providers: ElevenLabs (primary), OpenAI (secondary), Google/Edge-TTS fallback
- LLM providers: Anthropic Claude (Opus 4.7, Sonnet 4.6, Haiku 4.5), OpenAI GPT-4o-mini, DeepSeek V3/R1
- Existing rate_limit_tracker table and BUC (Budget Usage Controller?) model

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 15
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- research/research.md ownership: workflow-owned canonical synthesis output
- Lifecycle branches: `resume`, `restart` (fork/completed-continue deferred per protocol)
- Machine-owned sections: reducer controls Sections 3, 6, 7-11
- Canonical pause sentinel: `research/.deep-research-pause`
- Capability matrix: `.opencode/skill/sk-deep-research/assets/runtime_capabilities.json`
- Capability matrix doc: `.opencode/skill/sk-deep-research/references/capability_matrix.md`
- Capability resolver: `.opencode/skill/sk-deep-research/scripts/runtime-capabilities.cjs`
- Current generation: 1
- Started: 2026-04-16T21:18:38Z
<!-- /ANCHOR:research-boundaries -->
