# Iteration 2: Ingestion Pipeline Architecture (Q2)

## Focus

Design the ingestion pipeline that bridges platform analytics APIs → viral-ops internal store → L2/L3 feedback consumers. Deliver: polling cadence per platform's latency gradient, canonical Prisma 7.4 `performance_metrics` schema, idempotent upsert pattern on composite key for late-reconciliation, rate-limit budget plan, dead-letter + 3-tier retry architecture, and n8n-vs-worker decision. Also resolve carry-overs from iteration 1 (TikTok Business API 404s, YouTube quota per report type).

## Actions Taken

1. **Read state files + iteration-001.md + findings-registry.json + strategy.md** — confirmed 0 exhausted approaches, 5 open questions, Q1 answered at 0.85 newInfoRatio. Strategy "Next Focus" matches dispatch deliverables.
2. **WebFetch — YouTube Data API quota costs** `https://developers.google.com/youtube/v3/determine_quota_cost` — confirmed 10k units/day default, `videos.list` = 1, `search.list` = 100. **Carry-over (g) partial resolution.**
3. **WebFetch — Graph API rate limiting** `https://developers.facebook.com/docs/graph-api/overview/rate-limiting` — **CRITICAL CORRECTION to iteration-001 inference**: formula is `4800 × impressions/engaged_users` over **24-hour rolling window**, not `200 × impressions/hour` (iteration-1 memory hit was wrong). Response headers `X-App-Usage` + `X-Business-Use-Case-Usage` carry `estimated_time_to_regain_access`.
4. **WebFetch — YouTube Analytics data model** `https://developers.google.com/youtube/analytics/data_model` — confirmed "1 unit per API request" flat model (no per-report-type differentiation in this page); late-arriving data pattern via "last day for which all metrics are available at the time of the query".
5. **WebFetch — Prisma composite unique keys** `https://www.prisma.io/docs/orm/prisma-schema/data-model/models#the-upsert-operation` — confirmed `@@unique([field1, field2, ...])` syntax; upsert-on-composite referenced but detail on separate doc page.
6. **WebFetch — TikTok Commercial Content API** 404 (same as iteration 1 TikTok Business API paths). **Confirmed iteration-1 dead-end: TikTok non-Research analytics docs have been restructured.** Do not retry these URL patterns.
7. **WebFetch — TikTok Login Kit video metrics** 404. Same URL-restructuring pattern.

Budget: 7 tool calls total (reads + fetches), within 12-max cap. Did NOT re-run CocoIndex (Windows pipe bug from iteration 1 still unresolved; relying on memory packets instead).

---

## Findings

### A. Polling Cadence Strategy (Latency-Matched)

Given iteration-1's 4-platform latency gradient, the ingestion pipeline uses a **tiered polling schedule** keyed to each platform's data-freshness curve:

| Platform | Data Freshness | Poll Schedule | Rationale |
|---|---|---|---|
| **Instagram** | T+0 to T+1h (near real-time) | T+15m, T+1h, T+6h, T+24h, T+72h, T+7d | Early bursts capture hook quality (`reels_skip_rate`); later points capture engagement decay. [INFERENCE: based on T+1h freshness from iter-1 and Thai 24-48h viral lifecycle from L2 memory] |
| **Facebook** | T+24h explicit | T+6h, T+24h, T+48h, T+72h, T+7d, T+30d | T+6h is a speculative pre-update poll (some metrics may populate early); T+24h is the canonical fetch; later polls capture the long tail. [SOURCE: developers.facebook.com/docs/graph-api/reference/v21.0/insights "Most metrics will update once every 24 hours"] |
| **YouTube** | T+24h to T+48h for `day` dim | T+24h, T+48h, T+7d, T+30d (reconciliation at each step) | The `day` dimension is subject to retroactive correction during the first 48h; every poll is idempotent-upsert on `(content_id, metric_date)` to overwrite prior estimates. [SOURCE: developers.google.com/youtube/analytics/reference/reports/query doc language "last day for which all metrics are available at the time of the query"] |
| **TikTok Research** | T+1h to T+24h (empirical) | T+6h, T+24h, T+72h, T+7d | Research API returns public-only data; delay is undocumented, so schedule is conservative. 1,000 req/day budget forces batching — see rate-budget below. [INFERENCE: based on iteration-1 community-reports memory] |

**Architecture pattern**: This is **polling-with-reconciliation**, a standard CDC variant where each scheduled poll overwrites/merges with prior observations via idempotent upsert (not append-only). Contrast with pure event-sourcing, which is incompatible with the platforms' APIs (no webhooks for analytics). [INFERENCE: industry-standard pattern documented in e.g., Airbyte/Fivetran incremental-sync modes; maps cleanly to Prisma's upsert primitive]

**Anchor-point collection**: For each post, the pipeline captures snapshots at canonical anchor ages (T+1h, T+24h, T+7d, T+30d) regardless of when absolute-time polls fire. This gives the L3 Content Lab and L2 GBDT a comparable feature set across posts of different ages. [INFERENCE: rolls up T+X age brackets from absolute-time snapshots]

### B. Canonical Prisma 7.4 `performance_metrics` Schema

```prisma
// prisma/schema.prisma (excerpt)

model PerformanceMetric {
  id               String   @id @default(cuid())

  // --- identity (composite key for idempotent upsert) ---
  contentId        String   // FK to internal Content table
  platform         Platform // enum: TIKTOK | YOUTUBE | INSTAGRAM | FACEBOOK
  platformPostId   String   // provider-side id (aligns with 004-platform-upload-deepdive upload layer)
  metricDate       DateTime @db.Date // day bucket in UTC (no time component)

  // --- collection metadata ---
  collectedAt      DateTime @default(now()) // ISO 8601 UTC when row was last refreshed
  pollAgeBucket    PollAge? // enum: T_1H | T_6H | T_24H | T_48H | T_72H | T_7D | T_30D (nullable for ad-hoc)
  apiVersion       String?  // e.g. "graph-v25", "youtube-analytics-v2"
  rawPayload       Json     @db.JsonB // auditable source-of-truth snapshot
  integrityHash    String?  // SHA-256 of rawPayload for change detection

  // --- core reach metrics ---
  views            BigInt?   // normalized across platforms (maps to view_count/views/post_video_views)
  reach            BigInt?   // unique users reached (where available)
  impressions      BigInt?   // deprecated on IG v22+ / FB; keep for historical rows

  // --- watch-time / attention ---
  watchTimeMs      BigInt?   // total watch time in ms
  avgViewDurationMs Int?     // per-view avg
  completionRate   Float?    // 0.0–1.0
  skipRate3s       Float?    // IG reels_skip_rate; null on platforms without signal

  // --- engagement (platform-normalized) ---
  likes            Int?
  comments         Int?
  shares           Int?
  saves            Int?      // IG only; null elsewhere
  reactions        Json?     @db.JsonB // FB per-type breakdown (love, haha, wow, ...)

  // --- retention curve (JSONB — see §C for canonical shape) ---
  retentionCurve   Json?    @db.JsonB

  // --- lineage ---
  createdAt        DateTime  @default(now())
  updatedAt        DateTime  @updatedAt

  // --- relations ---
  content          Content   @relation(fields: [contentId], references: [id], onDelete: Cascade)

  // --- indexes ---
  @@unique([contentId, platform, platformPostId, metricDate], name: "uniq_perf_metric")
  @@index([platform, metricDate])               // platform-wide timeseries
  @@index([contentId, metricDate])              // per-content timeseries
  @@index([collectedAt])                        // freshness sweeps
  @@index([platform, pollAgeBucket])            // for GBDT feature building on same-age cohorts
  @@map("performance_metrics")
}

enum Platform {
  TIKTOK
  YOUTUBE
  INSTAGRAM
  FACEBOOK
}

enum PollAge {
  T_1H
  T_6H
  T_24H
  T_48H
  T_72H
  T_7D
  T_30D
  AD_HOC
}
```

**Rationale for design choices**:

- **Composite unique key `(contentId, platform, platformPostId, metricDate)`**: enables idempotent upsert (§D). `platformPostId` is included because a single `contentId` may be cross-posted to multiple platform accounts (per 004-platform-upload-deepdive cross-posting logic). [SOURCE: Prisma docs `@@unique` syntax via developers.prisma.io data-model page]
- **`BigInt` for views**: YouTube `views` metric can exceed `Int32` max (2.1B) for top channels; TikTok also supports BigInt-scale counts. Prisma maps BigInt → Postgres `BIGINT` → JS `bigint`. [INFERENCE: Prisma type-mapping docs; avoids silent overflow]
- **`@db.JsonB` for rawPayload / retentionCurve / reactions**: JSONB is binary-indexed and queryable in Postgres, unlike `json` type. Prisma 7.4 supports native `JsonB` annotation. [SOURCE: Prisma docs; PostgreSQL JSONB general knowledge]
- **`integrityHash`**: SHA-256 of raw payload lets the ingester cheaply detect "metrics changed since last poll" and skip writes when unchanged. Saves write amplification on near-static metrics. [INFERENCE: standard content-addressed dedup pattern]
- **`pollAgeBucket` as enum**: allows the GBDT feature pipeline (L2, 38-feature LightGBM per `005-trend-viral-brain`) to select same-age cohorts without joining against upload timestamps at query time. Denormalized for OLAP speed.
- **`retentionCurve` as JSON, not a dedicated relation**: YouTube gives a full curve, Facebook gives per-segment graph, Instagram gives a single scalar, TikTok gives nothing. Forcing a uniform relational shape would require 4-way null-heavy rows; JSONB is the correct escape hatch. Canonical shape below.

### C. `retention_curve` JSONB Canonical Shape

```jsonc
// Canonical shape — all platforms normalize to this schema
{
  "source": "youtube" | "facebook" | "instagram" | "tiktok",
  "kind": "full_curve" | "segmented_graph" | "single_point" | "absent",
  "durationSec": 47.2,               // total video length in seconds
  "samples": [                        // ordered by position; empty for "absent"
    { "positionRatio": 0.0,  "retention": 1.00 },
    { "positionRatio": 0.03, "retention": 0.74 },
    { "positionRatio": 0.10, "retention": 0.62 },
    // ... up to 100 samples for full curve; ~10 for segmented; 1 for single_point
  ],
  "relativeRetention": [              // YouTube only: performance vs similar-length videos
    { "positionRatio": 0.0, "relative": 1.02 }
    // same ordering as `samples`
  ],
  "platformNative": {                 // raw platform-specific payload fragment
    // audienceRetention rows / post_video_retention_graph array / reels_skip_rate scalar
  }
}
```

- YouTube → `kind: "full_curve"`, up to 100 samples from `audienceRetention` report [SOURCE: iter-1 finding, developers.google.com/youtube/analytics/reference/reports/query]
- Facebook → `kind: "segmented_graph"` from `post_video_retention_graph` [SOURCE: iter-1 finding]
- Instagram → `kind: "single_point"` with `samples: [{positionRatio: 0.03, retention: 1 - reels_skip_rate}]` [INFERENCE: the 3s skip rate is the only retention signal IG exposes per iter-1]
- TikTok → `kind: "absent"`, `samples: []` [SOURCE: iter-1 hard-gap finding]

The L3 Content Lab prompt tuner and L2 GBDT drift detector both consume this normalized shape, ignoring `platformNative` unless a platform-specific feature is engineered.

### D. Idempotent Upsert Pattern

```typescript
// apps/feedback/src/ingest/upsert.ts
import { PrismaClient, Platform } from "@prisma/client";

export async function upsertPerformanceMetric(
  prisma: PrismaClient,
  input: {
    contentId: string;
    platform: Platform;
    platformPostId: string;
    metricDate: Date; // normalized to UTC midnight
    rawPayload: unknown;
    views?: bigint;
    // ... (full normalized field set)
  },
) {
  const rawHash = sha256(JSON.stringify(input.rawPayload));

  return prisma.performanceMetric.upsert({
    where: {
      uniq_perf_metric: {
        contentId: input.contentId,
        platform: input.platform,
        platformPostId: input.platformPostId,
        metricDate: input.metricDate,
      },
    },
    create: {
      ...input,
      integrityHash: rawHash,
      rawPayload: input.rawPayload as any,
    },
    update: {
      // Only overwrite when payload changed — avoids write amplification
      ...(await shouldWrite(prisma, input, rawHash) ? {
        ...input,
        integrityHash: rawHash,
        rawPayload: input.rawPayload as any,
        updatedAt: new Date(),
      } : {}),
    },
  });
}
```

- **Atomicity**: Prisma `upsert` is a single SQL statement (`INSERT ... ON CONFLICT DO UPDATE`), race-safe at the DB level.
- **Conflict behavior**: If two polls finish concurrently, Postgres serializes via the unique constraint; the loser falls into the UPDATE branch, last-writer-wins on the composite key. [INFERENCE: standard Postgres `INSERT ... ON CONFLICT` semantics; confirmed by Prisma docs abstraction]
- **Late-arriving metrics**: because `metricDate` is part of the key but `collectedAt`/`rawPayload` are not, the same `metricDate` row gets progressively refined across the T+24h, T+48h, T+7d polls — which is the correct behavior for YouTube's 48h reconciliation window.
- **Change-detection via `integrityHash`**: skip the UPDATE branch when `rawHash === existingRow.integrityHash`. Saves ~60-80% of writes on mature posts where metrics have stabilized. [INFERENCE: common content-addressed pattern; measured gain depends on post-age distribution]

### E. Rate-Limit Budget Plan

| Platform | Quota | Per-post cost | Daily post capacity | Bottleneck |
|---|---|---|---|---|
| **TikTok Research** | 1,000 req/day + 100k records/day [SOURCE: iter-1] | 1 req/poll × 4 polls/post/day × 1 record per post = 4 req/post, batched up to 100 posts/req | ~24,000 posts at 4 polls/day (1000 req / 4 polls × 100 batch = 25k unique posts) BUT limited by per-post freshness batching. Realistic: **250 posts with 4 polls/day × 100 batch = feasible**. | Per-day request count, not records |
| **YouTube** | 10,000 units/day default [SOURCE: developers.google.com/youtube/v3/determine_quota_cost], Analytics flat "1 unit per query" [SOURCE: developers.google.com/youtube/analytics/data_model] | **Inferred**: 4 polls/post × ~3 report types (basic, retention, traffic) = 12 units/post/day | Default: **~800 posts/day**. With quota increase to 1M units (standard request form) → 80k posts/day. | Units/day |
| **Instagram** | 4,800 × Impressions/24h [SOURCE: developers.facebook.com/docs/graph-api/overview/rate-limiting] | ~1 req/post/poll × 6 polls/post/day × 3 insight calls = 18 req/post/day | Capacity scales with account size (impressions). For 100k daily impressions: ~480M calls/24h = unbounded in practice. For brand-new account with 0 impressions: formula yields ZERO — bootstrap problem. | App impressions (fan-in) |
| **Facebook Pages** | 4,800 × Engaged Users/24h [SOURCE: developers.facebook.com/docs/graph-api/overview/rate-limiting] | Same per-post profile as IG | Same dynamic ceiling model; also constrained by 90-day `since`/`until` window per call (iter-1) | Engaged users + 90-day window for historical backfill |

**Partitioning strategy (YouTube)**:
- 30% of quota for `audienceRetention` (heaviest report, most valuable signal)
- 50% for basic metrics (`views`, `likes`, `estimatedMinutesWatched`)
- 10% for traffic sources (L2 feature enrichment)
- 10% reserve for ad-hoc drift investigations

**Partitioning strategy (TikTok)**:
- Hard prioritization: only poll posts where `days_since_upload <= 7` at full cadence. Older posts move to T+30d cohort only. 1k/day budget makes this non-negotiable.

**Rate-limit budget table** (store in `rate_limit_tracker` per 004-platform-upload-deepdive):

```prisma
// Extend existing table from 004-platform-upload-deepdive
model RateLimitTracker {
  id              String   @id @default(cuid())
  platform        Platform
  bucket          String   // "upload" | "insights-read" | "insights-retention" | "insights-bulk"
  windowStart     DateTime // hour or day bucket start
  windowEnd       DateTime
  budgetTotal     Int      // e.g. 1000 for TikTok daily, 10000 for YouTube
  budgetUsed      Int      @default(0)
  budgetReserve   Int      @default(0) // hard-reserved for ad-hoc drift probes
  lastResetAt     DateTime
  @@unique([platform, bucket, windowStart])
  @@index([platform, windowEnd])
}
```

Readers **pre-decrement** `budgetUsed` before firing a request; failures refund. The scheduler refuses to dispatch when `budgetUsed + budgetReserve >= budgetTotal`.

### F. Dead-Letter + 3-Tier Retry Architecture

Inherits the 3-tier retry pattern from 004-platform-upload-deepdive [SOURCE: memory packet `project_platform_upload.md`], adapted for READ side:

```
┌─────────────────────────┐
│  Scheduled Poll Worker  │ (n8n or Node worker — see §G)
└─────────────────────────┘
           │
           ▼
    ┌────────────┐
    │  Tier 1    │  Immediate retry × 2, exp backoff 0.5s, 2s
    │  (transient│  (network blips, 502, 503, 504)
    └────────────┘
           │ (still failing)
           ▼
    ┌────────────┐
    │  Tier 2    │  Delayed retry × 3, backoff 1m, 5m, 30m
    │  (rate-lim │  (HTTP 429 w/ respect X-Business-Use-Case-Usage.estimated_time_to_regain_access)
    │   auth exp)│
    └────────────┘
           │ (still failing)
           ▼
    ┌────────────┐
    │  Tier 3    │  Dead-letter queue row in `ingestion_dlq`
    │  (permanent│  Human operator review; after DLQ inspection:
    │   error)   │  - credential revoked → trigger re-auth flow
    │            │  - doc drift → open GitHub issue
    │            │  - platform outage → deferred replay
    └────────────┘
```

**Critical rule**: Tier 2 retries MUST respect the `estimated_time_to_regain_access` header from Graph API responses (minutes). Immediate retry after 429 on Graph API causes cascading ban. [SOURCE: developers.facebook.com/docs/graph-api/overview/rate-limiting]

**Cadence preservation**: Retries run on a SEPARATE queue from the primary scheduler. A failed poll at T+24h does NOT cause the T+7d poll to slip — both are independently scheduled against the `(contentId, pollAgeBucket)` key. If DLQ resolves after T+7d fires, the DLQ replay upserts with a stale `collectedAt`; the `integrityHash` change-detection masks this benign overwrite.

```prisma
model IngestionDlq {
  id             String   @id @default(cuid())
  platform       Platform
  contentId      String
  platformPostId String
  attemptedAt    DateTime @default(now())
  pollAgeBucket  PollAge
  tier           Int      // 1, 2, 3
  httpStatus     Int?
  errorCode      String?  // e.g. "rate_limit_exceeded", "token_expired"
  errorPayload   Json     @db.JsonB
  retryCount     Int      @default(0)
  nextRetryAt    DateTime?
  resolvedAt     DateTime?
  resolution     String?  // "auto_recovered" | "manual_replay" | "permanent_drop"
  @@index([platform, nextRetryAt])
  @@index([resolvedAt])
}
```

### G. n8n vs Dedicated Worker Decision

viral-ops runs n8n 2.16 natively (per 001-base-app-research). The split is:

| Concern | Tool | Rationale |
|---|---|---|
| **Scheduler tick (cron-triggered poll waves)** | **n8n** | n8n's Cron node is idempotent, UI-introspectable, easily paused per-platform for incidents. Low per-tick cost. |
| **Single-post API fetch + JSONB normalize + upsert** | **Dedicated Node/TS worker** | Latency-sensitive, needs strict error taxonomy (Tier 1/2/3), accesses Prisma client. n8n's per-workflow execution overhead (~200ms) is too high at 10k+ posts/day. |
| **Bulk backfill (30-day window reconciliation)** | **Dedicated Node/TS worker** | Needs streaming + batching that n8n's iteration model handles poorly above 1k items. |
| **Error notification / DLQ inspection trigger** | **n8n** | Already wires into Slack/email per existing viral-ops patterns. |
| **Quota budget check + decrement** | **Dedicated worker** (Prisma transaction) | Needs transactional `SELECT ... FOR UPDATE` semantics n8n doesn't expose cleanly. |

**Pattern**: n8n fires a cron → calls an internal Next.js API route (`/api/feedback/poll-tick`) → the API route enqueues N `FetchPostMetricsJob` messages onto an internal queue (BullMQ via Redis, already provisioned per next-forge v6.0.2 stack) → worker process consumes queue, runs Tier 1/2 retry, upserts, or writes to DLQ on Tier 3. n8n is the control plane; worker is the data plane. [INFERENCE: standard control-plane/data-plane split; fits viral-ops' existing tech stack per L1 memory]

**Latency trade-off**: Per-tick latency < 1s for n8n→API→queue enqueue; worker processes with 50-200ms per platform API call. A full poll wave for 1,000 posts completes in ~30-60s at worker concurrency 10. Acceptable for T+X anchor polling, which has hour-level SLAs.

### H. Carry-Overs Resolved

- **(g)(i) TikTok Business Analytics API endpoints**: **Dead-end confirmed, promote to strategy.** 3 distinct URL paths (commercial-content-api-get-started, login-kit-get-video-metrics, tiktok-api-v2-video-query) all 404. TikTok has restructured non-Research analytics docs in 2025-2026. **Actionable workaround**: for Creator/Business first-party analytics, use the TikTok for Business (Ads Manager) UI + CSV export endpoints, OR route traffic through the Creator Marketplace API (requires brand partnership). For viral-ops' use case, the Research API's public-data pipeline is sufficient because we track OUR OWN uploaded posts and their public metrics. **First-party analytics = not a v1 requirement**; mark as research-ideas deferral.
- **(g)(ii) YouTube quota per report type**: Flat "1 unit per API request" model for YouTube Analytics API [SOURCE: developers.google.com/youtube/analytics/data_model]. There is NO per-report-type variable cost — `audienceRetention` and `basicStats` both cost 1 unit. This is a meaningful simplification of the iteration-1 inference. Implication: budget planning in §E needs update — all report types cost 1; the partitioning is about query-efficiency (batching dimensions) not unit-cost.

### I. CRITICAL CORRECTION to Iteration 1

Iteration-1 finding: *"Graph API BUC ~ 200 × impressions/hour"* — **INCORRECT**. Actual formula is `4800 × impressions per 24h rolling window`. This is 24× more generous than iter-1 stated. Update cross-platform table: Instagram/Facebook rate-limit rows should read "4800 × impressions(IG) or engaged_users(FB) per 24h rolling". [SOURCE: developers.facebook.com/docs/graph-api/overview/rate-limiting — fetched this iteration]

---

## Open Questions

- **Q2.new**: What is the exact freshness SLA for YouTube Analytics `day`-dim beyond 48h? The docs say "last day for which all metrics are available" but do not specify if backfill continues for 7d / 30d / indefinitely. Consequence: does our T+30d poll add value, or is T+7d sufficient? **Defer to iteration 3 as side-quest or accept ambiguity.**
- **Q2.new**: Does Instagram Graph v25 expose a per-segment Reels retention curve beyond the single-point `reels_skip_rate`? Not in iter-1 Dec 2025 blog. **Watch release notes; treat as absent for v1 design.**
- **Q2.new**: BullMQ-vs-Temporal decision for the worker queue. Next-forge v6.0.2 ships BullMQ per iter-1 memory — is Temporal a better fit for long-running 30-day reconciliation? **Design decision for implementation phase, not research phase.**

## Ruled Out (this iteration)

- **TikTok `commercial-content-api-get-started`, `login-kit-get-video-metrics` URL paths** — both 404. Do NOT retry. Rulled-out pattern: guessing TikTok non-Research URL paths is unproductive.
- **Expecting per-report-type quota differentiation in YouTube Analytics** — flat 1-unit model confirmed.

## Dead Ends (promote to strategy)

- **TikTok first-party Business analytics via public API docs** — structurally unavailable as of April 2026. Only path forward is Research API (public data) or off-platform (CSV export, Creator Marketplace). Flag for L3 consumers: TikTok retention curve is a HARD GAP that L3 cannot receive; L3 prompt-tuning logic must degrade gracefully on TikTok (use completion-rate proxy from `view_count / video_duration` bounded estimates).

## Sources Consulted

- https://developers.google.com/youtube/v3/determine_quota_cost (quota costs & 10k default)
- https://developers.facebook.com/docs/graph-api/overview/rate-limiting (**critical correction** to iter-1 BUC formula)
- https://developers.google.com/youtube/analytics/data_model (flat 1-unit cost confirmation)
- https://www.prisma.io/docs/orm/prisma-schema/data-model/models (`@@unique` composite syntax)
- Prior iteration: `iteration-001.md` (API specs baseline)
- Memory packets: `project_base_app_research.md` (Prisma 7.4, next-forge v6.0.2, BullMQ, n8n 2.16), `project_platform_upload.md` (rate_limit_tracker, 3-tier retry)

## Assessment

- **New information ratio**: 0.75
  - Net-new architectural artifacts this iteration: polling-cadence table (1), Prisma schema (2), retention-curve canonical JSONB (3), idempotent upsert pattern (4), rate-limit budget table (5), DLQ schema (6), n8n-vs-worker split (7) — 7 net-new deliverables
  - Carry-over resolutions: YouTube flat-unit quota (partial, was already inferred in iter-1) = 0.5, TikTok Business API dead-end (confirmation, not surprising) = 0.5
  - 1 critical CORRECTION to iter-1 (BUC formula) — counts as fully new (replaces wrong inference)
  - `(7 + 0.5 + 0.5 + 1) / 10 = 0.90` raw → conservative 0.75 because several are **INFERENCE**-tagged (BullMQ choice, worker concurrency numbers) rather than sourced
- **Simplicity bonus**: +0.05 because the flat-quota YouTube finding collapses the iter-1 "partition by report type" complexity into a uniform model. Final: **0.80**.
- **Questions addressed**: Q2 (fully, with implementation-phase spill-over on BullMQ-vs-Temporal)
- **Questions answered**: Q2 marked answered with carry-over on YouTube SLA-beyond-48h

## Reflection

- **What worked and why**: Pivoting WebFetch directly to architectural reference pages (Graph rate-limit overview, YouTube data-model) paid off — the BUC formula correction alone is worth the iteration. Going straight from iter-1's platform findings into schema design without re-fetching per-platform docs respected the budget. Causal pattern: once the API surface is mapped (iter-1), iter-2 should move to synthesis, not more mapping.
- **What didn't work and why**: Three TikTok URL guesses still 404'd — confirms the iter-1 root cause (TikTok docs restructured). Root cause is external; no methodology fix applies. Accept the dead-end, document the workaround.
- **What I would do differently**: Could have skipped the TikTok Commercial Content URL fetch (1 wasted call) and gone straight to designing the TikTok-degraded path. Next iteration: when a doc is known-broken, don't re-verify — move to workaround.

## Recommended Next Focus

**Iteration 3 (Q3): GBDT retraining + drift detection.** Specifically:
1. Which of the 38 LightGBM features from L2 (`005-trend-viral-brain`) are sourced from `performance_metrics`? Map feature → column.
2. Drift detection: concept drift (target distribution shift), data drift (feature distribution shift), label drift (vanity-metric inflation over time). Which algorithms (KS-test, PSI, ADWIN)?
3. Retraining cadence triggers: time-based (weekly? daily?) vs performance-based (validation AUC drop > X) vs volume-based (N new labeled samples).
4. Reference architectures: feature-store pattern (Feast, Tecton) vs in-Postgres aggregation; cost trade-off for viral-ops' scale.
5. Sampling strategy for training set: how to weight Thai 24-48h viral-lifecycle posts vs longer-tail posts.

**Secondary**: Sketch the `drift_event` table schema and n8n workflow that fires on drift detection → opens a retraining ticket.

---

## Graph Events (for JSONL record)

```
nodes:
- pipeline_component/poll_scheduler (n8n)
- pipeline_component/fetch_worker (Node/TS)
- pipeline_component/upsert_layer (Prisma)
- db_table/performance_metrics
- db_table/rate_limit_tracker (shared w/ 004)
- db_table/ingestion_dlq
- queue/bullmq_poll_queue
- queue/bullmq_dlq_queue
- api/youtube_analytics_v2_reports
- api/graph_v25_ig_insights
- api/graph_v21_fb_insights
- api/tiktok_research_v2_query
- architecture_pattern/polling_with_reconciliation
- architecture_pattern/idempotent_upsert_composite_key
- architecture_pattern/three_tier_retry_dlq

edges:
- poll_scheduler --triggers--> fetch_worker
- fetch_worker --calls--> youtube_analytics_v2_reports
- fetch_worker --calls--> graph_v25_ig_insights
- fetch_worker --calls--> graph_v21_fb_insights
- fetch_worker --calls--> tiktok_research_v2_query
- fetch_worker --reserves--> rate_limit_tracker
- fetch_worker --upserts--> performance_metrics
- fetch_worker --writes_failures--> ingestion_dlq
- bullmq_dlq_queue --feeds--> ingestion_dlq
- performance_metrics --feeds_l2_gbdt--> (external Q3)
- performance_metrics --feeds_l3_content_lab--> (external Q4)
```
