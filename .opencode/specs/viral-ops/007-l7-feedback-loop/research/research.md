---
title: L7 Feedback Loop — Progressive Research Synthesis
description: Rolling synthesis of deep research iterations on the L7 feedback loop. Overwritten and extended each iteration as new findings converge.
---

# L7 Feedback Loop — Progressive Research Synthesis

> **Status:** Iteration 6 of 15 complete. **All 5 key questions (Q1–Q5) registry-sealed.** Convergence REACHED with gap-closure validation. Ready for synthesis phase and `/spec_kit:plan :with-phases`.

## 1. Research Topic

L7 is Layer 7 of the viral-ops multi-layer architecture: the **feedback loop** that ingests platform analytics, detects model drift, retrains the L2 GBDT viral scorer, and closes the loop back to L3 Content Lab (prompt tuning, variant scoring, Thompson Sampling update).

## 2. Platform Analytics APIs — Reference Table (April 2026)

| Dimension | TikTok (Research API) | YouTube Analytics API v2 | Instagram Graph API v25 | Facebook Graph API v21 |
|---|---|---|---|---|
| **Core endpoint** | `POST https://open.tiktokapis.com/v2/research/video/query/` | `GET https://youtubeanalytics.googleapis.com/v2/reports` | `GET /{media}/insights` | `GET /{object}/insights` |
| **Primary view metric** | `view_count` | `views` | `views` (replaces deprecated `plays`, `video_views`) | `post_video_views` (plays ≥3s) |
| **Watch-time metrics** | `video_duration` (implied) | `estimatedMinutesWatched`, `averageViewDuration`, `averageViewPercentage` | `ig_reels_avg_watch_time`, `ig_reels_video_view_total_time` | `post_video_avg_time_watched` (ms), `post_video_view_time` |
| **Retention curve** | NONE (hard gap) | `audienceRetention` report — full curve (BEST) | `reels_skip_rate` (first-3s only) | `post_video_retention_graph` (per-segment) |
| **Engagement** | `like_count`, `comment_count`, `share_count`, `favorites_count` | `likes`, `dislikes`, `subscribersGained` | `likes`, `comments`, `shares`, `saved`, `total_interactions`, `reposts` (new Dec 2025) | `post_reactions_*_total`, shares, comments |
| **Reach/Impressions** | not exposed | `impressions`, `clickThroughRate` (separate report types) | `reach` (required), `impressions` DEPRECATED v22+ | `post_impressions*`, `post_video_views_unique` |
| **Completion** | not exposed | `averageViewPercentage` | not direct; derive from avg_watch_time / video_duration | `post_video_complete_views_30s` |
| **Auth model** | OAuth client credentials → `/v2/oauth/token/` | OAuth 2.0 authorization code | Instagram Login OR Facebook Login | Facebook Login |
| **Required scopes** | `research.data.basic` | `yt-analytics.readonly` (+`yt-analytics-monetary.readonly` for revenue, +`youtube.readonly` for reports.query) | `instagram_business_basic` + `instagram_business_manage_insights` (IG Login) OR `instagram_basic` + `instagram_manage_insights` + `pages_read_engagement` (FB Login) | `read_insights` + `pages_read_engagement` + ANALYZE task capability |
| **Token TTL** | Client token short-lived (re-fetch) | Access 3,600s; refresh non-expiring | Short-lived ~1h → long-lived 60-day | Page token long-lived via long-lived User token |
| **Rate limits** | 1,000 req/day + 100k records/day across Research API family | 10,000 quota units/day default; flat 1 unit/request for Analytics API v2 (iter-2 confirmed) | BUC model: `X-Business-Use-Case-Usage` / `X-App-Usage` headers; formula **4800 × impressions / 24h rolling** (iter-2 correction) | BUC model; 90-day since/until window; formula **4800 × engaged_users / 24h rolling**; error 80001 on overflow |
| **Latency** | T+1h–T+24h (undocumented; community-reported) | T+24h–T+48h for daily dim reports; near-real-time via `realtime` reports | T+24h (inferred, standard Graph pattern) | T+24h explicit |
| **Account types** | Research API = public videos only; requires institutional/researcher approval. First-party Business/Creator API URLs currently 404 — pending iteration 2 | Channel owner; Content Owner extras need YouTube Partner Program | Professional (Business OR Creator); Marketing API profile_visits ad-only | Pages only, ≥100 likes minimum; Personal profiles not supported |
| **2026 breaking changes** | Business API URL restructure suspected (docs 404) | None surfaced in reports.query doc (updated 2026-01-15) | `impressions` deprecated v22+ for post-Jul-2024 media; 4 Reels metrics sunset 2025-04-21 (already inactive) | CRITICAL: "By June 15, 2026, a number of Page Insights metrics will be deprecated for all API versions" |

## 3. New Signals From Instagram (Dec 2025 release)

Five new metrics introduced via IG Graph API, all available April 2026:

1. **`reels_skip_rate`** — % of views skipping within first 3 seconds. This is a **hook-quality signal** directly actionable by L3 Content Lab prompt tuning. Low skip_rate → hook prompt template is working.
2. **`reposts` (media-level)** — individual-media repost count.
3. **`reposts` (account-level)** — aggregate account repost.
4. **`profile_visits` via Marketing API** — ad-driven profile visits only.
5. **`crossposted_views` + `facebook_views`** — cross-platform reach for reels cross-posted IG ↔ FB.

## 4. Canonical Retention-Curve Strategy (Cross-Platform Normalization)

Because only YouTube and Facebook give full retention curves, and Instagram gives only a single-point skip gate, and TikTok gives nothing, the L7 ingestion pipeline must normalize to a common shape:

```json
{
  "platform": "youtube|facebook|instagram|tiktok",
  "content_id": "uuid",
  "platform_post_id": "string",
  "retention_curve": {
    "shape": "full|graph|single_point|none",
    "points": [{ "t_ratio": 0.03, "retention_ratio": 0.78 }],
    "derived": {
      "completion_rate": 0.42,
      "hook_survival_3s": 0.78,
      "midpoint_retention": 0.55,
      "avg_watch_ratio": 0.61
    }
  }
}
```

- YouTube → `shape: "full"`, dense `points` array.
- Facebook → `shape: "graph"`, per-segment percentages from `post_video_retention_graph`.
- Instagram → `shape: "single_point"`, one entry at `t_ratio=0.03` with `retention_ratio = 1 - reels_skip_rate`.
- TikTok → `shape: "none"`, compute only `completion_rate = view_count_completion / view_count` if completion counts become available; otherwise leave `null`.

## 5. Key Gaps Identified

1. **TikTok has no retention curve** — major L7 feedback asymmetry. Must either (a) use TikTok Creator Center first-party analytics (scraping → likely ToS risk), or (b) accept reduced signal on TikTok and compensate with engagement velocity.
2. **TikTok Business API URL churn** — `/doc/tiktok-api-v2-video-query` and `/doc/business-api-overview` both 404. Blocking first-party Creator/Business account analytics. Carry-over to iteration 2.
3. **YouTube quota unit cost per report type** — not on the reports.query reference page. Needs confirmation iteration 2.
4. **Facebook June 15 2026 deprecation** — specific metric list not yet documented publicly. L7 ingestion MUST pin Graph API version and have a deprecation-watch task in the n8n monitoring stack.
5. **Rate-limit header normalization** — TikTok uses HTTP 429 + error code `rate_limit_exceeded`; Graph API uses `X-App-Usage` / `X-Business-Use-Case-Usage` JSON in headers; YouTube uses `quotaExceeded` reason. L7 ingestion adapter layer must normalize all three.

## 6. Dependencies on Prior Research

- **L2 (GBDT)**: The 38-feature LightGBM model from `005-trend-viral-brain` consumes these performance metrics as features + labels for retraining (Q3 territory).
- **L3 (Content Lab)**: The 4-channel feedback loop from `006-content-lab` receives engagement/retention/completion/conversion signals derived from this table (Q4 territory).
- **L4 (Platform Upload)**: The `rate_limit_tracker` table from `004-platform-upload-deepdive` pairs with L7's READ-side rate limit tracker. They should share a unified quota-management service.

## 7. Ingestion Pipeline Architecture (Q2, iter-2)

### 7.1 Polling Cadence (latency-matched, anchor-point collection)

Each post captures snapshots at canonical age anchors (T+1h, T+6h, T+24h, T+48h, T+72h, T+7d, T+30d) so L2 GBDT and L3 Content Lab see comparable cross-platform feature vectors regardless of absolute time.

| Platform | Freshness | Scheduled Polls |
|---|---|---|
| Instagram | T+0–T+1h | T+15m, T+1h, T+6h, T+24h, T+72h, T+7d |
| Facebook | T+24h | T+6h, T+24h, T+48h, T+72h, T+7d, T+30d |
| YouTube | T+24h–T+48h (day dim) | T+24h, T+48h, T+7d, T+30d (reconciliation upsert on each) |
| TikTok | T+1h–T+24h (empirical) | T+6h, T+24h, T+72h, T+7d |

**Architecture pattern**: polling-with-reconciliation (idempotent upsert on composite key), not event-sourcing (no platform-side webhooks for analytics exist).

### 7.2 Canonical Prisma 7.4 `performance_metrics` Schema

Composite unique: `(contentId, platform, platformPostId, metricDate)` enables idempotent upsert for late-reconciling YouTube/Facebook data. Key columns:

- Identity: `contentId`, `platform`, `platformPostId`, `metricDate` (UTC day bucket)
- Collection: `collectedAt`, `pollAgeBucket` (enum T_1H…T_30D), `apiVersion`, `rawPayload` (JSONB), `integrityHash` (SHA-256 for change-detection / write skipping)
- Reach: `views` (BigInt), `reach`, `impressions`
- Watch-time: `watchTimeMs`, `avgViewDurationMs`, `completionRate`, `skipRate3s`
- Engagement: `likes`, `comments`, `shares`, `saves`, `reactions` (JSONB per-type)
- `retentionCurve` (JSONB — canonical shape §4)

Full schema with indexes and `RateLimitTracker` / `IngestionDlq` siblings: see `research/iterations/iteration-002.md` §B, §E, §F.

### 7.3 Rate-Limit Budget (revised with iter-2 corrections)

- **TikTok Research**: 1,000 req/day + 100k records/day → with 4 polls/post/day and 100 records/batch, **capacity ≈ 250 actively-tracked posts**. Hard prioritize posts where `days_since_upload ≤ 7`.
- **YouTube Analytics**: flat **1 unit / request**, 10k units/day default. With ~12 calls/post/day (4 polls × 3 report types) → **~800 posts/day**. Quota-increase form available for 1M units → 80k posts/day.
- **Instagram**: BUC formula `4800 × impressions per 24h rolling`. For 100k daily impressions: ~480M calls/24h (unbounded in practice); bootstrap problem for new accounts at 0 impressions.
- **Facebook**: BUC formula `4800 × engaged_users per 24h rolling`. Same dynamic ceiling.

**Critical iter-1 correction**: BUC formula is 24-hour rolling at 4800x, NOT 1-hour at 200x. The earlier inference was 24× too conservative.

### 7.4 Dead-Letter + 3-Tier Retry

```
Tier 1 (transient 5xx, network): immediate retry × 2, backoff 0.5s → 2s
Tier 2 (429 rate-limit, token-expiry): delayed retry × 3, respect `estimated_time_to_regain_access` header
Tier 3 (permanent): row in `ingestion_dlq` with errorCode, rawPayload, resolution workflow
```

Retries run on a separate queue; scheduled polls on different `pollAgeBucket`s proceed independently — a failed T+24h poll does not delay the T+7d poll.

### 7.5 n8n vs Dedicated Worker

- **n8n (control plane)**: cron triggers for poll waves, Slack/email alerts, DLQ inspection handoff.
- **Node/TS worker (data plane)**: per-post fetch → normalize → upsert via Prisma. Runs on BullMQ (Redis, already in next-forge v6.0.2) with concurrency 10.
- **Boundary**: n8n calls internal Next.js API route which enqueues `FetchPostMetricsJob` onto BullMQ. Worker handles Tier 1/2 retry and DLQ writes.

### 7.6 Carry-Over Resolutions

- **TikTok Business/Creator first-party analytics**: All 3 candidate URL paths 404. Structurally unavailable via public docs as of April 2026. **Decision**: v1 of viral-ops uses only Research API (public data on OUR uploaded posts). First-party Creator/Business analytics deferred to `research-ideas.md`.
- **YouTube Analytics quota per report type**: FLAT 1 unit / request (no per-report differentiation). Simplifies budget planning — partitioning is about query efficiency, not cost.

---

## 8. GBDT Retraining + Drift Detection (Q3, iter-3)

### 8.1 Drift Taxonomy — 4 Parallel Channels + 2 Lagged Channels

| Axis | What it measures | Observable when | Algorithm | Threshold |
|---|---|---|---|---|
| **Data drift (numerical)** — 32 of 38 features | `P(X)` shift on continuous features | At inference (no labels) | `psi` | > 0.20 severe / 0.10–0.20 warn |
| **Data drift (categorical)** — 4 of 38 features (platform, language, account_tier, time_bucket) | `P(X)` shift on discrete features | At inference | `jensenshannon` + `chisquare` fallback | 0.1 distance / 0.05 p-val |
| **Prediction drift** — `ŷ = log(views_168h/followers)` at T+1h snapshot | `P(ŷ)` shift | At inference (leading indicator) | `wasserstein` | 0.1 |
| **Label drift** — realized `y` when T+168h poll lands | `P(Y)` marginal shift | T+168h (lagged) | `psi` | > 0.20 |
| **Performance drift (concept)** — MAE on held-out daily labeled window | `P(Y\|X)` shift via measured error | T+168h (lagged) | MAE delta | +15% |
| **Correlation drift** — per LLM-dimension Spearman vs realized views | Rubric quality shift | Weekly | Spearman | < 0.15 for 2 weeks |

**Leading vs lagged**: the first 3 channels (data numerical, data categorical, prediction) fire immediately without labels; label + performance + correlation require T+168h ground truth. L7 monitoring prioritizes leading channels for early warning and uses lagged channels for confirmation.

**Evidently AI algorithm menu (canonical reference)**: 18+ methods documented — `ks`, `chisquare`, `z`, `wasserstein`, `kl_div`, `psi`, `jensenshannon`, `anderson`, `fisher_exact`, `cramer_von_mises`, `g-test`, `hellinger`, `mannw`, `ed`, `es`, `t_test`, `empirical_mmd`, `TVD` — each with column-type applicability and default threshold. `DataDriftPreset()` auto-selects per-column based on type and sample size; dataset-level `drift_share` default 0.5. [SOURCE: https://docs.evidentlyai.com/metrics/customize_data_drift]

### 8.2 Retraining Trigger Policy — Hybrid (Floor + Ceiling)

**Weekly cron (floor)**: `0 3 * * 0` UTC — unconditional retrain on 90-day rolling window of LABELED training snapshots. Cheap, bounds staleness ≤ 7d. [SOURCE: L2 baseline, 005-trend-viral-brain/research/research.md:511]

**Drift triggers (ceiling — can force early, cannot delay past weekly)**:
- `drift_share > 0.5` OR any feature PSI > 0.20 sustained **2 days** → retrain ticket (not immediate retrain — avoid drift-chasing thrash).
- Prediction drift `wasserstein > 0.1` for **2 consecutive hours** → alert + retrain eval queue.
- Performance drift MAE ↑ 15% on held-out daily window → **immediate retrain** (inherited L2 rule).
- Correlation collapse Spearman < 0.15 per LLM dimension for **2 weeks** → rubric review (inherited L2).
- Data milestone: +200 new labeled videos → opportunistic retrain (min 48h since last retrain — anti-thrash).

**Why weekly (not daily) is structurally correct**: label latency is T+168h (7d). Daily retrain would always include mostly-unlabeled training examples. Weekly gives every batch a full week of completed labels.

### 8.3 Training-Data Construction (Label-Latency Aware)

- **Target**: `log(views_168h / followers)` — regression, inherited from L2 [SOURCE: 005:326].
- **Row eligibility**: a post is training-eligible iff `metricDate >= upload_date + 168h` AND its `performance_metrics` row with `pollAgeBucket = T_7D` has landed.
- **Feature snapshot (anti-skew)**: capture the frozen 38-feature vector at first prediction time (T+1h) and persist on the `content` row. Pair with `labelY` when T+168h poll lands. Never re-derive features from later observations (target leakage risk).
- **Time-decay weighting**: `sample_weight = exp(-age_days / 30)` on training rows so fresh examples dominate without losing the long tail.
- **Class imbalance handling**: for a secondary binary `is_viral` classifier downstream, prefer LightGBM `sample_weight` / `scale_pos_weight`; avoid SMOTE (degrades probability calibration required by Thompson Sampling in L3).

### 8.4 Feature Store Decision — Option A (Postgres + Prisma)

**Chosen: Option A** (pure Postgres + Prisma + materialized views, reusing `performance_metrics` from iter-2). Option B (Feast/Tecton) is overkill until >50M rows; Option C (hybrid S3 + Parquet) adopts only if Postgres grows past 50M rows or training >30 min.

New Prisma models (append to schema):

```prisma
model TrainingFeatureSnapshot {
  id               String   @id @default(cuid())
  contentId        String   @unique
  platform         Platform
  snapshotAt       DateTime // T+1h freeze moment
  featuresJson     Json     @db.JsonB // frozen 38-feature vector
  featureSchemaVer String   // "v1.0"
  predictionYhat   Float    // ŷ at snapshot time
  modelVersion     String   // which model produced ŷ
  labelY           Float?   // NULL until T+168h
  labelLandedAt    DateTime?
  @@index([platform, snapshotAt])
  @@index([labelLandedAt])
  @@index([modelVersion])
  @@map("training_feature_snapshots")
}

model DriftEvent {
  id              String    @id @default(cuid())
  detectedAt      DateTime  @default(now())
  driftKind       DriftKind
  columnName      String?
  method          String    // "psi" | "wasserstein" | "jensenshannon" | "mae_delta" | "spearman"
  thresholdValue  Float
  observedValue   Float
  sampleSize      Int
  referenceWindow Json      @db.JsonB
  currentWindow   Json      @db.JsonB
  severity        Severity  // INFO | WARN | CRITICAL
  action          String    // "logged" | "retrain_queued" | "retrain_triggered" | "alerted"
  retrainJobId    String?
  resolvedAt      DateTime?
  resolution      String?
  @@index([detectedAt])
  @@index([driftKind, severity])
  @@index([retrainJobId])
  @@map("drift_events")
}

enum DriftKind { FEATURE_NUMERICAL FEATURE_CATEGORICAL PREDICTION LABEL PERFORMANCE CORRELATION }
enum Severity  { INFO WARN CRITICAL }
```

### 8.5 Model Registry — MLflow Shadow/Canary/Production

**Registry**: MLflow, self-hosted, Postgres-backed (reuse existing Postgres). Chosen over W&B (SaaS lock-in) and DIY (lineage + signed artifacts + stage audit non-trivial to build).

**State machine**:
```
[train complete] → register_model("viral-gbdt")
    → stage=None → stage=Staging (shadow mode; scored alongside Production, not served)
    → stage=Staging + canary=10%  (48h minimum; challenger MAE ≤ Production MAE ±3%)
    → stage=Production (full rollout)
      ↓ (drift regression: ΔMAE > 15%)
    → stage=Archived (newest Production archived, previous Archived version promoted to Production — atomic)
```

### 8.6 Infrastructure Integration

| Component | Runtime | Notes |
|---|---|---|
| **Training** | Python worker `apps/ml-trainer/` | Not supported in n8n; long-running (5–30 min) |
| **Orchestration** | n8n cron + HTTP to Python worker | n8n = control plane, Python = data plane |
| **Inference** | FastAPI co-located with BERTopic (per 005) | Reuse existing Python+FastAPI container |
| **Drift monitoring** | Evidently AI inside Python worker | Hourly prediction drift, daily feature drift |
| **Registry** | MLflow + Postgres backend + S3/local artifacts | Reuse Postgres |
| **Feature store** | Postgres (Option A) | `training_feature_snapshots` + views on `performance_metrics` |
| **Drift ledger** | Postgres `drift_events` table | Queryable from dashboards, FK to retrain jobs |

**New n8n workflow — `drift_detection_tick`**:
```
Cron */30 min
  → POST http://ml-trainer:8080/drift/check
  → Python worker runs Evidently Reports on:
    (a) performance_metrics (last 24h vs last 7d baseline) — feature drift
    (b) training_feature_snapshots (ŷ last 24h vs model-trained-on baseline) — prediction drift
    (c) training_feature_snapshots where labelLandedAt IS NOT NULL (last 14d vs prior 90d) — label drift
  → Emits drift_events rows with severity
  → If CRITICAL: Slack alert + action='retrain_queued'
Cron weekly Sun 03:00 UTC
  → Read queued drift_events + schedule floor
  → POST http://ml-trainer:8080/train
  → Register model in MLflow, promote to Staging (shadow), then canary, then Production
```

### 8.7 Dead-Ends This Iteration

- NannyML docs (ReadTheDocs 403, blog URL 404) — use GitHub/PyPI for future NannyML citations.
- LightGBM ReadTheDocs (403) — use GitHub README.
- MLflow model-registry page (empty JS render) — use GitHub or Python docstrings.

---

## 9. 4-Channel Feedback Loop to L3 Content Lab (Q4, iter-4)

### 9.1 Terminology Bridge — L3 "Channels as Cadences" vs L7 "Channels as Dimensions"

006-content-lab's §9 declared a "4-channel feedback architecture" but used the term for four **update cadences** (Few-Shot Exemplars per-gen / Template Selection weekly / Prompt Parameter Tuning monthly / Variant Strategy bi-weekly). iter-4 defines L7's four **signal dimensions** as the raw ingredients those cadences consume. Both concepts are preserved; the handoff contract carries **signal dimensions**; the **cadences** are downstream consumers in L3.

### 9.2 Four Signal Dimensions (Goodhart-Grounded)

| # | Channel (Signal Dimension) | Measures | Dominant Metrics | Feeds L3 Cadence |
|---|---|---|---|---|
| 1 | **Engagement** | Active interaction intent per impression | TK `likes+comments+shares+favorites`; IG `total_interactions`; FB `reactions+shares+comments`; YT `likes+comments` | Few-Shot Exemplars, Template Selection |
| 2 | **Retention** | Watch-time + drop-off shape | YT `audienceRetention` curve + `avgViewPercentage`; IG `reels_skip_rate` + `ig_reels_avg_watch_time`; FB `post_video_retention_graph`; TK derived heuristic | Prompt Parameter Tuning, Variant Strategy |
| 3 | **Completion** | Full-watch + loop behavior | FB `post_video_complete_views_30s`; YT `avgViewPercentage≥0.95`; IG derived `avg_watch_time / video_duration`; TK derived | Template Selection, Variant Strategy |
| 4 | **Conversion** | Downstream intent — saves, redistributes, follows, profile visits | IG `saved` + Dec-2025 `reposts` + Marketing-only `profile_visits`; FB `shares` + follower-delta; TK `share_count` + `favorites_count`; YT `subscribersGained` | Prompt Parameter Tuning, Variant Strategy |

**Why 4, not 3 or 5** — Goodhart's Law mitigation: "use multiple, diverse metrics rather than single targets" [SOURCE: https://en.wikipedia.org/wiki/Goodhart's_law]. 3 dimensions (merging Retention+Completion) loses the hook-vs-payoff distinction L3 prompt tuning needs. 5 dimensions (adding Reach/Distribution) lets the model optimize for the platform algorithm's current boosting pattern — which itself drifts (iter-3). 4 orthogonal channels resist any single reward hack.

### 9.3 Signal Aggregation

**Time windows per channel (early = leading indicator; stable = Thompson posterior update):**

| Channel | Early | Stable |
|---|---|---|
| Engagement | T+24h | T+7d |
| Retention | T+1h–T+24h | T+7d |
| Completion | T+24h | T+7d |
| Conversion | T+48h | T+30d |

**Normalization — percentile-rank within matched cohort** (not z-score, not raw):
```
channel_score = percentile_rank(metric_value, cohort=
  platform=same AND niche=same AND account_tier=same
  AND pollAgeBucket=same AND last_90_days)
```
Percentile-rank is robust to power-law outliers (viral content distribution) and naturally lives in `[0, 1]` for Thompson posterior compatibility.

**Multi-platform — per-(variant, platform) matrix (NOT collapsed):**
```json
"platforms": {
  "tiktok":    { "engagement": 0.82, "retention": null, "completion": 0.65, "conversion": 0.40 },
  "instagram": { "engagement": 0.55, "retention": 0.70, "completion": 0.60, "conversion": 0.85 }
}
```
L3 Thompson arm = `(variant_id, platform)`. Platform collapse destroys per-platform adaptation signal.

**Optional aggregate rollup** for niche-level cadences: impression-share-weighted average (skip null / missing platforms).

**Outlier handling**: 0.95 clamp per dimension (anti-viral-distortion); 500-impression gate below which `insufficient_data=true`; viral-anomaly flag logs `DriftEvent(driftKind=PREDICTION)` so iter-3's drift detector sees outliers as drift signals rather than noise.

### 9.4 Canonical L7FeedbackEnvelope (Handoff Contract)

```json
{
  "schema_version": "1.0",
  "feedback_id": "cuid",
  "emitted_at": "2026-04-17T14:32:00Z",
  "content_id": "cuid", "variant_id": "cuid", "concept_id": "cuid", "trend_id": "cuid",
  "model_version": "viral-gbdt-v2.3.1",
  "time_window": "T+24h" | "T+48h" | "T+7d" | "T+30d",
  "signal_stability": "early" | "stable",
  "platforms": { /* per-platform dim scores + raw metric breakdown */ },
  "aggregate_score": { "engagement": 0.72, "retention": 0.70, "completion": 0.63, "conversion": 0.59 },
  "platform_breakdown": { /* raw metric values per platform */ },
  "quality_flags": {
    "viral_anomaly": false,
    "rage_engagement_suspected": false,
    "bot_traffic_suspected": false,
    "clickbait_suspected": false,
    "insufficient_data": false,
    "algorithmic_boost_detected": false
  },
  "drift_status": {
    "prediction_drift_active": false,
    "feature_drift_active": false,
    "performance_drift_active": false,
    "latest_drift_event_id": null
  },
  "ready_for_thompson_update": false,
  "thompson_update_recommended_weights": { "engagement": 0.25, "retention": 0.30, "completion": 0.25, "conversion": 0.20 }
}
```

**Invariants:**
- Per-dimension scores ∈ `[0, 1]` after percentile-rank + 0.95 clamp.
- `null` when platform-native metric unavailable (e.g., TikTok retention is always null — iter-1 Gap #1).
- `ready_for_thompson_update = true` iff `time_window = "T+7d"` AND all four dims non-null AND no CRITICAL `quality_flag` fired.
- `thompson_update_recommended_weights` default-weights Retention highest (hook quality = strongest Thai TikTok/IG viral predictor — 71% decide in first 1–3s per 006).

**Prisma storage** — new `L7FeedbackEnvelope` model with `@@unique` on `feedbackId`, `@@index` on `(contentId, timeWindow)` and `(readyForThompson, emittedAt)`. Idempotent by `feedbackId`; L3 marks `consumedByL3At = now()` after Thompson update.

### 9.5 Thompson Sampling Update Rules

**Primary citation**: Chapelle & Li 2011 NeurIPS, "An Empirical Evaluation of Thompson Sampling" [SOURCE: https://proceedings.neurips.cc/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf]

**Arm granularity**: `(variant_id, platform)` — per §9.3 multi-platform argument.

**Update rule — Beta-Binomial with `impressions_decile` virtual-trial scaling:**
```
composite = w_eng × engagement_agg + w_ret × retention_agg
          + w_comp × completion_agg + w_conv × conversion_agg
impressions_decile = floor(log10(impressions))
α_{t+1} = α_t + composite × impressions_decile
β_{t+1} = β_t + (1 - composite) × impressions_decile
```
Beta-Binomial fractional update (not binarized Bernoulli) preserves the continuous signal from percentile-rank; `impressions_decile` prevents single viral posts from swamping the posterior.

**Cold-start**:
- New variant: `Beta(1, 1)` (uniform, per Chapelle & Li).
- Proven exemplar (top-10% per 006 Channel A): `Beta(3, 1)` informative prior.
- Forced exploration while `cumulative_impressions < 100`: bypass Thompson and force ≥1 pull per 24h (aligns with L3's 20% ε-greedy budget, 006:553).

**Cadence**:
- Per-post (primary): on envelope with `readyForThompson=true` (T+7d stable window).
- Weekly batch (safety net): Sun 04:00 UTC, co-scheduled with L3-Feedback-Aggregator.
- Monthly recalibration (meta-learning): recalibrate `thompson_update_recommended_weights` from 30d Spearman(dim, long-tail `views_168h`).

### 9.6 Vanity-Metric Guardrails (5 Flags)

[SOURCE: Goodhart's Law mitigation — multiple diverse metrics, https://en.wikipedia.org/wiki/Goodhart's_law]

If any CRITICAL flag fires, envelope emitted with `readyForThompson=false`.

| Flag | Signature | Action |
|---|---|---|
| `rage_engagement_suspected` | eng ≥ 0.80 AND ret ≤ 0.40 AND conv ≤ 0.30 AND (sentiment_neg ≥ 0.60 OR comments/(likes+shares) ≥ 0.40) | Skip posterior update; log DriftEvent(CORRELATION); do NOT boost similar-hook variants in Channel A |
| `bot_traffic_suspected` | impressions_T+24h/T+1h ≥ 100× AND engagement_T+24h/T+1h ≤ 5× AND step-function growth | Skip update; flag `insufficient_data=true`; log for human review |
| `clickbait_suspected` | `(1 - reels_skip_rate) ≥ 0.80` AND completion ≤ 0.25 AND end-segment engagement ratio ≤ 0.30 | Penalize retention contribution (clamp ret ≤ 0.30); KEEP envelope (learn as negative hook example) |
| `algorithmic_boost_detected` | platform ∈ {tiktok, instagram} AND FYP_share ≥ 0.70 AND creator_followers ≤ 10k | Down-weight platform contribution 0.5× in rollup; keep update |
| `multi_dim_sanity_gate` | max(dims) ≥ 0.95 AND count(d < 0.30) ≥ 3 | Skip update; log DriftEvent(CORRELATION) "single-dim anomaly" — structural Goodhart guard |

### 9.7 Integration Ripples

**`performance_metrics` → channels** (iter-2 § 7.2 schema columns map):
- `watchTimeMs`, `avgViewDurationMs`, `retentionCurve`, `skipRate3s` → Retention
- `completionRate`, `retentionCurve` → Completion
- `likes`, `reactions`, `comments` → Engagement (comments also feeds Rage detector)
- `shares`, `saves` → Conversion
- `views`, `reach`, `impressions` → cohort denominators only

**Drift ripple (answers iter-3's open question 5: "reset or quarantine?")** — **QUARANTINE, not reset**:
```
drift_events(severity=CRITICAL, kind ∈ {PREDICTION, PERFORMANCE})
  → L7FeedbackEnvelope.drift_status.prediction_drift_active = true
  → L3 pauses Thompson posterior updates
  → L3 widens ε-greedy: 0.20 → 0.40
  → Until drift_events.resolvedAt IS NOT NULL
```
Historical arm data preserved for post-drift rollback comparison; reset would destroy it.

**n8n workflow additions**: `L7-Feedback-Emitter` (new, cron */1h aligned with pollAgeBucket transitions) feeds `l7_feedback_envelopes` table; existing `L3-Feedback-Aggregator` (006:614) is modified to consume from that table instead of querying raw `performance_metrics`. Total L7-owned n8n workflows: 3 (ingestion polling + drift_detection_tick + L7-Feedback-Emitter).

### 9.8 Dead-Ends This Iteration

- `arxiv.org/abs/2001.07426` — wrong paper (causal effects, not bandits). For delayed-feedback bandit citation, use Vernade et al. 2017 or Grover et al. 2018 in a future iteration if needed.
- Instagram Platform Insights overview page — index only; always use media-insights reference page directly.
- `reels_skip_rate` exact endpoint NOT on media-insights reference page (iter-1 cited it as Dec 2025 release) — Q4.open-1 for implementation phase.

---

## 10. Prompt Tuning Automation (Q5, iter-5)

### 10.1 Prompt Parameter Registry — Tunable vs Locked

Per-stage tunable surfaces across the L3 5-stage prompt chain (Structural / Hook / Arc / CTA / Delivery). The **lock-list is a hard-safety boundary** that no automated tuner may modify — compliance, brand voice, pipeline contracts, platform ToS.

| Stage | Auto-Tunable | Locked (human-only) |
|---|---|---|
| **Structural** | temperature [0.3–0.9], top_p [0.7–1.0], section-ratio weights, duration soft-bounds | Hard duration cap per platform, brand-voice anchors, legal disclaimer slots |
| **Hook** | hook_type_weights (question/contrarian/statistic/story-in-3s), emotional_tone_weights (curiosity/surprise/outrage/humor), few_shot_count [3–12] | Clickbait blacklist, profanity filter, defamation guards, Thai royal-speech restriction set |
| **Arc** | arc_pattern_weights, pacing_profile, beat-count target | Factual-claim verification slots, accessibility caption floor |
| **CTA** | cta_intensity [0.2–0.9], cta_type_weights (follow/save/share/comment/watch-again), cta_placement | Platform-compliance language, subscribe-language policy |
| **Delivery** | xml_tag_nesting_depth [2–4], tag-name aliases (whitelisted), JSON optional-field inclusion | Required schema fields (content_id, variant_id, tts_engine, voice_id, segment_timestamps), Thai particles, safety metadata |

**Prisma storage** — `PromptTemplateVersion` model with `stage`, `versionTag` (semver), `parentVersionId` (lineage), `isLocked`, `parametersJson`, `systemPromptBody`, `fewShotExemplarRefs[]`, `mlflowRunId`, `lifecycleState` (PROPOSED | SHADOW | CANARY | PRODUCTION | ARCHIVED | REVERTED). Full schema: iter-5 §A.2.

### 10.2 Three-Layer Experiment Separation (Anti-Confound)

Prompt experiments are confounded by content/trend experiments unless randomized at different units:

| Layer | Object | Randomization Unit | Sampler | Cadence |
|---|---|---|---|---|
| **L3a Content** | Creative variant (9 per concept) | `(concept_id, variant_id, platform)` | Beta-Binomial Thompson (iter-4) | Per-post |
| **L3b Template** | Prompt template version per stage | `(stage, template_version_id)` | Meta-bandit Thompson (new) | Per-generation |
| **L3c Parameter** | Parameter vector inside a template | Hyperparameter grid | OPRO-style score-guided sampler | Weekly |

**Cohort matching for L3b A/B** — require ≥60% cohort overlap in `(niche, platform, age_bucket)` between v1 and v2 populations; bilateral within-concept sampling preferred; otherwise stratify by `(niche, trend_velocity, platform, account_tier)` with proportional allocation.

**Sample size & tests** — success metric = L7FeedbackEnvelope.aggregate_score composite (percentile-rank [0,1]). Power analysis: ≥126 envelopes per arm for Δ=0.05 at σ=0.20 (α=0.05, power=0.80). **Dual-test**: Welch's t-test (p<0.05) OR Bayesian A/B (Beta prior, P(v2>v1)≥0.95), AND no channel z-regresses >1σ.

**Guardrail veto** (from iter-4 §E, reused at prompt-experiment level):
```
reject_v2 if any:
  rage_flag_rate_v2 - v1 > 0.05
  clickbait_flag_rate_v2 - v1 > 0.05
  bot_flag_rate_v2 - v1 > 0.03
  any channel z-score regression > -1σ
```

### 10.3 Nested Thompson-Thompson Meta-Bandit

**Architecture**:
```
Meta-bandit (L3b, per stage)
  arms = PromptTemplateVersion with lifecycleState IN (CANARY, PRODUCTION)
  reward = composite score aggregated over envelopes generated by this template
  algorithm = Beta-Binomial Thompson (consistent family with iter-4 inner bandit)
      │ selects template for generation
      ▼
Inner bandit (L3a, per-(variant, platform), iter-4)
  reward = composite from L7FeedbackEnvelope
  algorithm = Beta-Binomial with impressions_decile scaling
```

**Thompson chosen over UCB1** because of (a) consistency with iter-4's inner bandit, (b) better delayed-feedback behavior [INFERENCE: Vernade 2017 / Grover 2018 delayed-feedback Thompson variants more mature than delayed-UCB], (c) natural cold-start via Beta(1,1).

**Credit-attribution rule** (prevents double-counting): each envelope carries `variant_id`, which joins to `variant.stage_prompt_version_ids[]`. Both inner (variant) and meta (stage, template_version) posteriors observe the **same reward with the same impressions_decile weight** — they partition the arm space differently, not divide the reward.

**CRITICAL-flag filter**: envelopes with any CRITICAL quality_flag (iter-4 §E) do NOT contribute to meta-level posterior. Structural reward-hacking defense at prompt level — rage-bait prompts cannot get posterior credit even if composite is high.

**Per-stage independence**: each of 5 stages runs its own meta-bandit (Structural / Hook / Arc / CTA / Delivery). Prevents joint-failure poisoning the whole chain and respects sequential stage selection.

### 10.4 Safety Rails — Canary, Auto-Revert, Circuit Breaker

**Rollout state machine** (mirrors iter-3 MLflow pattern):

| Phase | Traffic | Duration | Success gate | Failure gate |
|---|---|---|---|---|
| SHADOW | 0% (offline eval) | 24h | ≥50 synthetic scores | eval error / schema mismatch |
| CANARY | 5% | 72h | Composite ≥ PROD − 0.02, no flag regression, no guardrail CRITICAL | Composite drop > 0.05 OR flag regression |
| PRODUCTION (partial) | 25% | 7d | ≥126 envelopes, Welch p<0.05 OR Bayesian P(win)≥0.95, all 4 channels hold | Composite drop > 0.05 in any 48h window |
| PRODUCTION (full) | 100% | permanent | meta-bandit posterior mean > prior PROD by ≥0.02 | auto-revert on D.2 triggers |

**Auto-revert triggers** (atomic swap, previous ARCHIVED promoted to PROD):
1. Single-channel z-regression > 1σ over 48h.
2. Composite drop > 0.05 over 7d vs prior PROD.
3. `rage_flag_rate` or `clickbait_flag_rate` increase > 0.05 absolute over 48h.
4. `drift_events.severity=CRITICAL` (PREDICTION or PERFORMANCE) from iter-3.
5. Multi-dim sanity-gate (iter-4 §E.5) > 10% of envelopes over 48h.

Reverted version locked from re-promotion for **14 days** (cool-down; prevents oscillation).

**Circuit breaker** — `L3_AUTO_TUNE_FROZEN` feature flag pauses ALL meta-bandit updates, ALL new promotions, and holds current PROD indefinitely. Triggers: (a) manual operator, (b) drift coupling (§10.5), (c) auto-activated when quality-flag rate > 2x baseline for 24h.

### 10.5 Drift Coupling Policy

| Upstream Signal | Prompt-Tuning Action |
|---|---|
| `drift_events.severity=CRITICAL` (PREDICTION, PERFORMANCE) | Freeze meta-bandit; no new promotions; current PROD stays |
| `drift_events.severity=CRITICAL` (FEATURE, LABEL) | Reduce canary 5%→1%, extend window 72h→168h, otherwise continue |
| `drift_events.severity=CRITICAL` (CORRELATION) | Full freeze (LLM-dimension rubric breakdown) |
| Quality-flag spike (rage/clickbait/bot > 2x baseline) | Quarantine affected stage; force-revert latest CANARY in that stage |
| Multi-dim sanity failure spike | Widen ε 0.10→0.30; do NOT freeze |
| `L3_AUTO_TUNE_FROZEN` manual | Full freeze |

**Rationale**: during L2 drift, envelope composites reflect a world L2 no longer models accurately. Meta-bandit updates based on stale composites converge on a local optimum that will not survive drift resolution, and risk amplification loops (drifting L2 → biased envelopes → biased prompt selection → content targeting biased signal → more drift). Correct recovery order: L2 retrains, L2 new model passes canary, THEN prompt auto-tuner resumes with fresh signal. Parallelism is an anti-pattern.

**Resumption**: on `drift_events.resolvedAt IS NOT NULL` + post-drift model in PROD:
1. Clear quarantine flags.
2. **Keep meta-bandit posteriors** (quarantine-not-reset, same doctrine as iter-4).
3. Widen ε to 0.30 for first 7d to re-explore.
4. Regression test: compare current PROD prompts' composite under NEW model vs pre-drift. If Δ > 0.1 degradation, downgrade to CANARY.

### 10.6 MLflow Integration — Prompts As First-Class Artifacts

Extends iter-3 §8.5 MLflow state machine from models to prompts:

```
MLflow experiment tree:
  viral-ops/
  ├── models/viral-gbdt    (iter-3)
  └── prompts/
      ├── structural
      ├── hook
      ├── arc
      ├── cta
      └── delivery
```

Each `PromptTemplateVersion.mlflowRunId` stores:
- **Params**: `parametersJson` (temperature, weights, few-shot count)
- **Artifacts**: `systemPromptBody` text, `fewShotExemplarRefs` blob, rendered messages JSON
- **Metrics**: rolling composite, per-channel means, flag rates, sample size, posterior α/β
- **Tags**: `l2_model_version`, `lifecycleState`, `parent_version_tag`, `stage`

**Reproducibility triple** (joined at envelope consumption time):
```
(l2_model_version, l3_prompt_version_chain, l3_code_sha)
```
Answers: "which model + which prompt chain + which code produced this content?" — lineage guarantee extended from model layer (iter-3) to prompt layer (iter-5).

**Lock-list fingerprint** — SHA-256 of locked-portion text. Auto-tuner-generated versions with fingerprint mismatch are **aborted at serialization** (structural lockout enforcement).

### 10.7 n8n Workflow — L3-Prompt-Tuner (new, 7th L3 workflow)

```
Schedule: Cron 0 4 * * * (daily 04:00 UTC, offset 1h from L3-Feedback-Aggregator Sun 03:00 UTC)
Event triggers:
  - drift_events.severity=CRITICAL (immediate pause/resume)
  - quality_flag spike > 2x baseline (immediate quarantine)

Steps:
  1. Check L3_AUTO_TUNE_FROZEN → exit if frozen
  2. Query recent L7FeedbackEnvelopes since last run WHERE readyForThompson=true AND no CRITICAL flag
  3. Join to variant.stage_prompt_version_ids (5 stages)
  4. Update Beta(α,β) posterior per (stage, template_version_id) with composite × impressions_decile
  5. Check promotion criteria (§10.4) for each CANARY → promote or enqueue human review
  6. Check auto-revert triggers on current PROD
  7. Emit L3PromptTuneEvent rows for audit
  8. Slack alert on promotions/reverts/freezes
  9. Sync to MLflow
```

**Total L7/L3 workflow count after iter-5**: 3 L7-owned (polling, drift_detection_tick, L7-Feedback-Emitter) + 7 L3-owned (5 from 006 + L3-Prompt-Tuner new + AV pipeline) = **10 total workflows**.

**Decision: new workflow (not extension)** — separation of concerns (L3-Feedback-Aggregator stays content-focused), different cadence (hourly vs daily), independent failure domain.

### 10.8 Meta-Concerns & Layered Mitigations

**Prompt-level Goodhart** [SOURCE: https://arxiv.org/abs/2209.13085, Pan et al. reward-hacking framing; https://en.wikipedia.org/wiki/Goodhart%27s_law]:
- **Outrage convergence** — mitigated by iter-4 §E.1 rage flag + meta-bandit CRITICAL-flag exclusion + quarterly human-review sampling [deferred to implementation].
- **Clickbait drift** — mitigated by iter-4 §E.3 clickbait flag + long-tail T+30d secondary signal [deferred].
- **Vanity convergence** — mitigated by iter-4 §E.5 multi-dim sanity gate + §10.4 channel non-regression gate. Structurally robust.

**Model collapse / diversity loss** (L3 generates → L2 scores → L7 envelopes → L3 meta-bandit → L3 generates more narrowly):
- **Forced exploration floor** — ε-greedy at 10% baseline, 30% on drift.
- **Exemplar diversity quota** — ≥30% few-shot exemplars must come from outside the top-10% performer pool.
- **Trend novelty injection** — demote prompts that only score on low-trend-velocity established trends.
- **Human exemplar injection** — quarterly operator-curated exemplars with minimum-use quota.

**Thai linguistic nuance erosion** [SOURCE: MEMORY.md project_thai_voice_pipeline — PyThaiNLP mandatory, 60+ Thai particles]:
- **Locked particles list** — the auto-tuner cannot alter particle selection logic; only expression around particles is tunable.
- **Formality register locked** — hard-coded brand policy, read-only to auto-tuner.
- **Thai-linguist quarterly review** — 50 auto-generated output sample across stages; >10% QoQ drop auto-activates L3_AUTO_TUNE_FROZEN.
- **PyThaiNLP validator gate** — pre-canary: generate 20 sample outputs, require ≥95% Thai-grammatical parse rate; failures block promotion.

### 10.9 Citation Framework — DSPy / OPRO / PromptBreeder Applicability

| Paper | Citation | Applies To |
|---|---|---|
| **DSPy** (Khattab et al. 2023) | [SOURCE: https://arxiv.org/abs/2310.03714] | L3 pipeline architecture as DSPy modules; BootstrapFewShot for few-shot exemplar selection; MIPRO/COPRO joint-optimization of parameters + exemplars. Phase 3. |
| **OPRO** (Yang et al. 2023) | [SOURCE: https://arxiv.org/abs/2309.03409] | L3c parameter-sweep: meta-prompt loop "solution+score" history; reported 8% GSM8K / up to 50% BBH. Phase 2. |
| **PromptBreeder** (Fernando et al. 2023) | [SOURCE: https://arxiv.org/abs/2309.16797] | Evolutionary proposer for new PROPOSED versions via co-evolution of task-prompts + mutation-prompts. Phase 4. |
| **Pan et al. 2022** (reward hacking) | [SOURCE: https://arxiv.org/abs/2209.13085] | Grounds §10.8 meta-concerns — imperfect-proxy framing. |

**Phased rollout**: Phase 1 MVP (manual prompt versions + meta-bandit on 2–3 human-authored per stage) → Phase 2 OPRO parameter sweep → Phase 3 DSPy BootstrapFewShot → Phase 4 PromptBreeder evolutionary proposer. Guardrails layered strongest-first; never skip phases.

### 10.10 Open Items (Implementation-Phase)

- **Q5.open-1**: DSPy hyperparameters (BootstrapFewShot max_bootstrapped_demos, MIPRO num_candidates, COPRO temperature) — fetch full PDF or GitHub repo.
- **Q5.open-2**: OPRO iteration budget, temperature, meta-prompt concrete example — fetch Google DeepMind OPRO repo.
- **Q5.open-3**: PromptBreeder population size, mutation operators, fitness formula — fetch DeepMind PromptBreeder repo.
- **Q5.open-4**: Pan et al. + Krakovna et al. specific reward-hacking taxonomy labels — full PDF.
- **Q5.open-5**: Nested-bandit formal convergence guarantees (Slivkins 2019, Lattimore & Szepesvári 2020) — implementation can proceed on Thompson+Thompson consistent-family composition.
- **Q5.deferred-1**: L7-Prompt-Quality-Review human-sampling workflow — future work.
- **Q5.deferred-2**: Exact Thai-linguist sampling cadence + PyThaiNLP rule-set — ties to 003-thai-voice-pipeline implementation.

---

## 11. Open Questions (Progress)

- [x] **Q1: Platform analytics API specs** — ANSWERED with caveats (TikTok Business branch confirmed dead-end).
- [x] **Q2: Ingestion pipeline architecture** — ANSWERED with caveats (YouTube SLA-beyond-48h and BullMQ-vs-Temporal deferred).
- [x] **Q3: GBDT retraining triggers + drift detection** — ANSWERED with caveats (NannyML CBPE citation pending, HP-search frequency deferred, feature-schema versioning deferred).
- [x] **Q4: 4-channel feedback to L3** — ANSWERED with caveats (reels_skip_rate exact endpoint, Thai comment-sentiment pipeline availability, organic follower-delta attribution, monthly-recalibration window choice all deferred to implementation).
- [x] **Q5: Prompt tuning automation** — ANSWERED with caveats (DSPy/OPRO/PromptBreeder hyperparameter depth deferred to implementation; nested-bandit formal convergence citation deferred; L7-Prompt-Quality-Review human-sampling workflow scoped as future; Thai-linguist cadence and PyThaiNLP rule-set tied to 003 implementation).

**All 5 key questions resolved. Research phase converged.**

## 12. Iteration Log

| Iter | Focus | newInfoRatio | Status |
|------|-------|--------------|--------|
| 1 | Q1 platform analytics API specs | 0.85 | insight |
| 2 | Q2 ingestion pipeline architecture + Prisma schema + BUC-formula correction | 0.80 | insight |
| 3 | Q3 GBDT retraining + drift detection — 4-axis taxonomy, hybrid triggers, MLflow shadow/canary state machine, Postgres feature store, drift_events ledger | 0.80 | complete |
| 4 | Q4 4-channel feedback to L3 — Engagement/Retention/Completion/Conversion with Goodhart grounding, percentile-rank cohort normalization, per-(variant,platform) Thompson arms, Beta-Binomial update with impressions_decile scaling, 5 vanity-metric guardrails, drift-to-Thompson quarantine-not-reset, L7FeedbackEnvelope canonical schema | 0.80 | complete |
| 5 | Q5 prompt tuning automation — PromptTemplateVersion registry with lifecycle + lock-list, 3-layer experiment separation (L3a/L3b/L3c), cohort-matched A/B with Welch+Bayesian dual-test, nested Thompson-Thompson meta-bandit with credit attribution, SHADOW/CANARY/PROD state machine + auto-revert + 14d cool-down, L3_AUTO_TUNE_FROZEN circuit breaker, MLflow prompt namespace with reproducibility triple + lock-list fingerprint, drift coupling policy matrix, L3-Prompt-Tuner 7th L3 workflow, meta-concerns (Goodhart/model-collapse/Thai-erosion) with layered mitigations, phased MVP→OPRO→DSPy→PromptBreeder rollout | 0.85 | complete |
| 6 | **GAP CLOSURE + registry seal** — TikTok Business API third-pass DEFINITIVE dead-end; DSPy v3.1.3 + MIPROv2 concrete hyperparameters (auto light/medium/heavy, demos=4, Bayesian 3-step); Thai cohort extensions (thai_formality + code_switch_level axes, 60+ particles lock-list, English-loanword cap); 5-layer loop stability via cadence-separation + circuit-breaker triad; scale sanity (TikTok 250/day bottleneck = 3× headroom, 10× reconfigurable, Postgres 10-year storage); explicit Q1–Q5 registry resolution | 0.82 | complete |

---

## 13. Gap-Closure Addendum (Iteration 6)

### 13.1 TikTok First-Party Analytics — FINAL DECISION

**CONFIRMED STRUCTURAL DEAD END**: Three-pass verification (iter-1, iter-2, iter-6) confirms TikTok does NOT expose first-party Creator/Business video analytics via a public developer API as of April 2026. `business-api.tiktok.com/portal/docs` returns only a stub banner.

**L7 TikTok strategy (locked)**:
- Primary: TikTok Research API (`POST /v2/research/video/query/`, `research.data.basic` scope, 1,000 req/day, ~250 active posts/day).
- Fallback: Login Kit v2 `video.list` for own-video metadata (same aggregate metrics, no retention curve).
- Channel 2 (Retention) returns `NULL` for TikTok with `quality_flag: retention_unavailable_tiktok`. Channels 1/3/4 operate normally.

### 13.2 Prompt Optimizer Hyperparameter Validation

| Paper | viral-ops Phase | Validated Depth (iter-6) | Key Hyperparameters |
|---|---|---|---|
| **OPRO** (Yang 2023, arxiv 2309.03409) | **Phase 2 entry** | Repo entrypoint `optimize_instructions.py`, quickstart `--dataset="gsm8k" --task="train"`; hyperparameters in source, not README | Defer iteration budget / temperature / meta-prompt template to implementation phase |
| **DSPy** (Khattab 2023, arxiv 2310.03714) | **Phase 3** | Version 3.1.3 (Feb 5 2026); full optimizer list: GEPA, BetterTogether, BootstrapFewShot, BootstrapFewShotWithRandomSearch, BootstrapFinetune, BootstrapRS, COPRO, Ensemble, InferRules, KNN, KNNFewShot, LabeledFewShot, **MIPROv2**, SIMBA; 20/80 train/val split recommendation | **MIPROv2**: `auto` ∈ {light, medium, heavy}; `max_bootstrapped_demos=4`, `max_labeled_demos=4` defaults; 3-step Bayesian: bootstrap → propose → optimize; 0-shot mode when both demos=0; `auto="light"` is the recommended entry point |
| **PromptBreeder** (Fernando 2023, arxiv 2309.16797) | **Phase 4** (deferred) | arXiv PDF binary not extractable via WebFetch; abstract-level coverage stands | Population size, mutation operators, fitness formula remain Q5.open-3; extract from community reference implementations during Phase 4 implementation work |

**Phased rollout order stands**: MVP (manual 2–3 versions/stage + meta-bandit) → OPRO parameter sweep → DSPy MIPROv2 → PromptBreeder evolutionary proposer.

### 13.3 Thai-Specific Cohort Extensions (REFINES §4, §10.4)

For Thai-language content, the percentile-rank cohort key (iter-4 §B.2) is **extended** with two axes:

1. **`thai_formality` ∈ {polite (ผม/ดิฉัน/คุณ), colloquial (ฉัน/คุณ), informal (กู/มึง/เรา), slang (555, อิอิ)}** — required axis when `language=th`.
2. **`code_switch_level` ∈ {low_0_to_10pct, medium_11_to_30pct, high_31pct_plus}** — tertiary axis applied only when cohort size permits (≥60% overlap rule from iter-5 §B.2). Falls back to coarser `thai_formality` stratification if cohort overlap insufficient.

**Lock-list extensions** (additive to iter-5 §10.6 / §10.8):
- **60+ Thai particles catalogue** (ครับ/ค่ะ, นะ, เลย, จัง, สิ, ล่ะ, มั้ง, แหละ, อ่ะ, เออ, เฮ้ย, อุ๊ย, etc.) — auto-tuner cannot alter particle selection; only expression around particles is tunable.
- **Textbook-formal avoid-list** (ท่าน, กรุณา, อนึ่ง, ทั้งนี้) — auto-tuner cannot raise weights on these (iter-5 §H.3 robotic-AI failure mode; sources from 003-thai-voice-pipeline/research/research.md §7).
- **Max English-loanword density per variant**: `english_loanword_pct ≤ 1.5 × cohort baseline` (hard ceiling; prevents "English as viral hack" drift).

**PyThaiNLP validator refinement** (iter-5 §H.3): validator must check **particle presence ratio ≥ 1 per 3 sentences** in addition to ≥95% grammatical parse rate. Enforces conversational register.

**Few-shot exemplar cultural matching**: for Thai content, ≥70% of few-shot exemplars must come from the same `thai_formality` cohort (enforced via existing iter-5 §A.1 tunable `few_shot_selection_policy`). No new primitive needed.

### 13.4 Five-Layer Loop Stability

**Cadence-separation principle** (grounds stability):

| Layer | Update Cadence | Role |
|---|---|---|
| L7 ingestion | hourly | fastest — raw metric collection |
| Thompson (L3a content) | per-envelope | sub-hourly, driven by ingestion |
| Meta-bandit (L3b/L3c prompt) | daily (cron 0 4 * * *) | smoothing |
| GBDT retraining (L2) | weekly floor + drift-ceiling | label-latency-aware |
| Prompt canary→PROD | 72h + 7d gate | statistical-significance window |
| Prompt auto-revert cool-down | 14d | oscillation prevention |

Each downstream layer updates **slower** than its upstream, providing anti-amplification damping. [CITATION grounding: timescale-separation in hierarchical RL (Sutton & Barto §17; Bertsekas ADP nested-policy stability) — formal convergence citation deferred to implementation.]

**Circuit-breaker triad** (composes iter-3 + iter-4 + iter-5 primitives):
1. **Quarantine-not-reset** — posterior history preserved on drift (iter-4 §F.2, iter-5 §F.3).
2. **14d cool-down** after revert — prevents prompt flapping (iter-5 §D.2).
3. **L3_AUTO_TUNE_FROZEN** circuit breaker — cuts feedback circuit when upstream is unstable (iter-5 §D.3).

**Amplification-risk assessment**: all 4 high-risk modes (Thompson oscillation, meta-bandit flipping, GBDT-drift stale tuning, cohort-matching failure) are LOW residual; only content-L2-label collapse is MEDIUM (mitigated by forced exploration 10% + exemplar diversity 30% + trend novelty + human quarterly per iter-5 §H.2).

### 13.5 Scale Sanity

- **TikTok is the bottleneck** (iter-2 budget): 1,000 req/day → ~250 active posts/day.
- **Current capacity**: 50 pieces/day × 7-day tracking window = 350 steady-state content_ids across all platforms (~88/platform). **3× headroom** before TikTok saturates.
- **10× reconfigurable**: drop T+1h poll window → 2-window cadence (T+6h, T+7d) doubles tracking to ~500/platform.
- **Call volume steady-state**: ~4,200 calls/day across all platforms; TikTok utilization ~26% of 1,000-req budget.
- **Storage**: ~29,400 `performance_metrics` rows/week = 2.3GB/year; 10-year retention ~23GB (Postgres-comfortable; Feast/Tecton migration at 50M rows = ~30 years away).
- **Architecture break-points**: 2,500 active content_ids simultaneously (TikTok saturation) OR 50M `performance_metrics` rows (feature-store threshold).

### 13.6 Final Open Items (Implementation-Phase Only)

All research-phase gaps closed. Remaining items (explicitly deferred, do NOT block convergence):

- **Q5.open-3**: PromptBreeder population/mutation/fitness (Phase 4 community-reference extraction).
- **Q5.open-5**: Nested-bandit formal convergence guarantees (implementation proceeds on Thompson+Thompson consistent-family composition).
- **003-thai-voice-pipeline dependencies**: Thai comment-sentiment pipeline availability + PyThaiNLP rule-set details (003 implementation spec).
- **Calibration**: monthly Thompson recalibration window choice (implementation calibration phase).

### 13.7 Registry Seal — Q1–Q5 Resolution Summary

| Question | Primary Iteration | Refined At | Status |
|---|---|---|---|
| Q1 Platform analytics APIs | iter-1 | iter-2, iter-6 | RESOLVED |
| Q2 Ingestion pipeline | iter-2 | iter-6 | RESOLVED |
| Q3 GBDT retraining + drift | iter-3 | — | RESOLVED |
| Q4 4-channel feedback L7→L3 | iter-4 | iter-6 | RESOLVED |
| Q5 Prompt tuning automation | iter-5 | iter-6 | RESOLVED |

All 5 questions registry-sealed via `question_resolution` records appended to `deep-research-state.jsonl` at iteration 6.

---

*Last updated: Iteration 6, 2026-04-17 — CONVERGENCE SEALED*

## 14. Convergence Report

- **Stop reason**: converged (all 5 key questions registry-sealed + quality guards passed + agent STOP recommendation)
- **Total iterations**: 6 of 15 budget (40% used)
- **Questions answered**: 5 / 5
- **Remaining questions**: 0
- **Last 3 iteration summaries**:
  - run 4 (Q4 4-channel feedback to L3): newInfoRatio 0.80, status insight
  - run 5 (Q5 prompt tuning automation): newInfoRatio 0.85, status complete
  - run 6 (gap-closure + Q1–Q5 seal): newInfoRatio 0.82, status complete
- **Convergence threshold**: 0.05 (not tripped by decay — session stopped on full question coverage + quality gates, not diminishing returns)
- **Coverage**: 148 key findings across 6 iterations; ≥4 sources per primary question; ≥1 concrete implementation pattern per question; no TOC-only findings
- **Quality guards passed**: ✓ all
- **Graph convergence decision**: STOP_ALLOWED (coverage-graph aligned with inline agent recommendation)

### Session Lineage

- Session ID: `afdd77c9-4f63-4333-8740-2175433f0041`
- Parent session: null (fresh start)
- Generation: 1
- Started: 2026-04-16T20:09:45Z

### Stop Reasons Enum Compliance

Stop reason `converged` is a valid STOP_REASONS enum member: [converged, maxIterationsReached, blockedStop, stuckRecovery, error, manualStop, userPaused].
