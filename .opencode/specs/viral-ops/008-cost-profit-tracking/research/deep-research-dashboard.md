---
title: Deep Research Dashboard
description: Auto-generated reducer view over the research packet.
---

# Deep Research Dashboard - Session Overview

Auto-generated from JSONL state log, iteration files, findings registry, and strategy state. Never manually edited.

<!-- ANCHOR:overview -->
## 1. OVERVIEW

Reducer-generated observability surface for the active research packet.

<!-- /ANCHOR:overview -->
<!-- ANCHOR:status -->
## 2. STATUS
- Topic: Cost & Profit Tracking — LLM token costs (GPT-4o-mini, Claude, DeepSeek), TTS costs (ElevenLabs, OpenAI), API quota consumption, per-content cost attribution, revenue tracking from affiliates/monetization, ROI calculation per video, per-platform, per-niche, daily/monthly cost dashboard, budget alerts
- Started: 2026-04-16T21:18:38Z
- Status: INITIALIZED
- Iteration: 7 of 15
- Session ID: c573a9af-db20-427c-9916-5c6cdf48ab41
- Parent Session: none
- Lifecycle Mode: new
- Generation: 1
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | Q1 — Cost Schema & Pricing Feeds | schema-pricing | 0.93 | 7 | insight |
| 2 | Q2 — Quota & Rate-Limit Tracking | quota-rate-limits | 0.94 | 9 | insight |
| 3 | Q3 — Revenue Attribution | revenue-attribution | 0.94 | 8 | insight |
| 4 | Q4 — ROI Engine | roi-engine | 0.95 | 10 | insight |
| 5 | Q5 — Dashboard + Alerts + residuals | dashboard-alerts | 0.85 | 9 | insight |
| 6 | Production readiness — security/compliance/integration/testing/runbooks | production-readiness | 0.82 | 6 | insight |
| 7 | Consolidation + residual closure + synthesis prep | consolidation-validation | 0.30 | 6 | thought |

- iterationsCompleted: 7
- keyFindings: 264
- openQuestions: 5
- resolvedQuestions: 0

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 0/5
- [ ] **Q1 — Cost Schema & Pricing Feeds:** What is the optimal schema + ingestion strategy for tracking LLM and TTS API costs per content piece across multi-provider stack (GPT-4o-mini, Claude, DeepSeek, ElevenLabs, OpenAI) with correct token/char unit accounting and current 2025-2026 pricing?
- [ ] **Q2 — Quota & Rate-Limit Tracking:** How to track API quota consumption and platform rate limits (YouTube, TikTok, Instagram, Facebook) with pre-emptive budget alerts, quota reservation, and deterministic back-off before provider throttle/ban?
- [ ] **Q3 — Revenue Attribution:** What are the best practices for revenue attribution from affiliate programs (Amazon, Shopee, TikTok Shop, CJ Affiliate, Impact.com) + platform monetization (YouTube Partner, TikTok Creator Fund/Rewards, IG Reels bonus, FB Reels monetization), and how to map delayed/aggregated revenue back to individual content pieces?
- [ ] **Q4 — ROI Engine:** How to design ROI calculation at per-video / per-platform / per-niche granularity that reconciles variable-lag cost data with delayed revenue, handles multi-touch attribution across reposts, and exposes confidence intervals?
- [ ] **Q5 — Dashboard + Alerts Architecture:** What's the recommended architecture for daily/monthly cost dashboards and budget-alert pipelines on next-forge + Prisma 7.4 + n8n stack, including storage tier strategy, alert channels, and dashboard UI patterns (shadcn/ui + chart library)?

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.95 -> 0.85 -> 0.82
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.30
- coverageBySources: {"affiliate-program.amazon.com":2,"affinco.com":2,"api-docs.deepseek.com":4,"claude.com":2,"code":50,"developer.amazon.com":2,"developers.cj.com":2,"developers.google.com":6,"developers.tiktok.com":2,"elevenlabs.io":8,"en.wikipedia.org":2,"help.elevenlabs.io":2,"help.instagram.com":2,"improvado.io":2,"integrations.impact.com":5,"learn.microsoft.com":2,"linkutm.com":2,"logie.ai":2,"multilogin.com":2,"newsroom.tiktok.com":2,"openai.com":3,"other":8,"platform.claude.com":4,"platform.openai.com":2,"raw.githubusercontent.com":2,"techcrunch.com":2,"trueprofit.io":2,"ui.shadcn.com":2,"webservices.amazon.com":3,"wecantrack.com":2,"www.dlapiperdataprotection.com":2,"www.tubefilter.com":2}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
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

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
**Primary: Trigger phase 3 (synthesize).** All stop conditions satisfied: - 7-of-8 ✓, 1 △ on OpenAI TTS (accepted per residual table) - 0 open questions; 5 Qs at ≥92% confidence - Consolidated schema compile-clean (F50) - Citation sweep complete with tier distribution (F51) - 11 residuals explicitly dispositioned (F52) - Graph coherent, no orphans (F55) - research.md §17–19 appended **Secondary (low priority): iter-8 is NOT needed.** All loop-exit conditions met. If phase_synthesis adds requirements, they'll be handled there, not in a new research iteration. ---

<!-- /ANCHOR:next-focus -->
<!-- ANCHOR:active-risks -->
## 8. ACTIVE RISKS
- None active beyond normal research uncertainty.

<!-- /ANCHOR:active-risks -->
<!-- ANCHOR:blocked-stops -->
## 9. BLOCKED STOPS
No blocked-stop events recorded.

<!-- /ANCHOR:blocked-stops -->
<!-- ANCHOR:graph-convergence -->
## 10. GRAPH CONVERGENCE
- graphConvergenceScore: 0.00
- graphDecision: [Not recorded]
- graphBlockers: none recorded

<!-- /ANCHOR:graph-convergence -->
