# Iteration 4: 4-Channel Feedback Loop from L7 to L3 Content Lab (Q4)

## Focus

Close the gap left open by `006-content-lab/research/research.md` §9: the 4-channel feedback architecture is declared but the handoff format, aggregation rules, Thompson Sampling update rules, and vanity-metric guardrails are not specified. This iteration MUST:

1. Decompose each of the 4 channels precisely (what signals feed each, and why 4 — not 3 or 5).
2. Define signal aggregation: time windows, normalization, multi-platform combination, outlier handling.
3. Specify the canonical JSON handoff schema L7 → L3 (per content_id, variant_id).
4. Specify Thompson Sampling posterior update rules (priors, success definition, cadence, cold-start).
5. Define vanity-metric guardrails (rage engagement, bot traffic, clickbait, algorithmic boost distortion).
6. Integrate with Q1-Q3 outputs (`performance_metrics`, `drift_events`, n8n workflow topology).

Prior context (do NOT re-derive):
- 4-channel architecture labels: **Few-Shot Exemplars (per-gen) / Template Selection (weekly) / Prompt Parameter Tuning (monthly) / Variant Strategy (bi-weekly)** — NOTE: this is the L3 spec's four *feedback frequencies*, NOT the four *signal dimensions* used by this iteration. The dispatch context defines the four **signal dimensions** as Engagement / Retention / Completion / Conversion. The two must be bridged in this iteration.
- 3x3 variant expansion in L3 produces 9 variants per trend [SOURCE: 006-content-lab/research/research.md:230–257]
- Thompson Sampling already chosen as L3's post-production testing framework [SOURCE: 006:194]
- `performance_metrics` schema (iter-2) + `drift_events` schema (iter-3) + `training_feature_snapshots` schema (iter-3) provide the data substrate
- Engagement benchmarks per platform (TikTok 2.80%, IG Reels 0.65%, YT Shorts 0.30–0.40%) [SOURCE: 006:216–224]

## Actions Taken

1. **Read state**: iter-003.md, 006-content-lab/research/research.md, and research/research.md §§1–8 — confirmed the terminology bridge (L3's "four channels" = four *update cadences*; L7's "four channels" this iteration = four *signal dimensions*). Decision: preserve both; rename L7's to **four feedback signal dimensions** and L3's to **four update cadences**. The handoff contract carries signal dimensions; the update cadences consume them.
2. **WebFetch — Wikipedia Thompson Sampling primer** `https://en.wikipedia.org/wiki/Thompson_sampling` — confirmed Beta-Bernoulli posterior mechanism and sampling-then-argmax algorithm. Wikipedia is thin on formula depth; switched to primary source (Chapelle & Li 2011 NeurIPS PDF) for the update rule and cold-start recommendation.
3. **WebFetch — Chapelle & Li 2011 NeurIPS paper** `https://proceedings.neurips.cc/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf` — confirmed (a) Beta(α, β) sufficient statistics with α = successes + α₀, β = failures + β₀; (b) canonical pseudocode `θ_i ~ Beta(α_i, β_i); pull argmax θ_i; update`; (c) **Beta(1,1) uniform prior** for cold-start; (d) "highly competitive" vs UCB / epsilon-greedy.
4. **WebFetch — Wikipedia Goodhart's Law** `https://en.wikipedia.org/wiki/Goodhart's_law` — confirmed Strathern's 1997 formulation, Campbell's Law (1969), and the canonical mitigation strategy: **"use multiple, diverse metrics rather than single targets"** — this is the theoretical grounding for the 4-channel decomposition itself (no single metric should drive Thompson posterior updates).
5. **WebFetch — Instagram Platform Insights overview** `https://developers.facebook.com/docs/instagram-platform/insights` — index page; deferred metric definitions to the media-insights reference.
6. **WebFetch — Instagram Media Insights reference** `https://developers.facebook.com/docs/instagram-platform/reference/instagram-media/insights` — confirmed exact metric names: `ig_reels_avg_watch_time` ("average amount of time spent playing the reel"), `ig_reels_video_view_total_time` ("total amount of time the reel was played, including replays"), `saved`, `total_interactions` (likes + saves + comments + shares − unlikes − unsaves − deleted comments). `reels_skip_rate` is NOT on this reference page — iter-1 cited it as a Dec 2025 release, so the exact reference lives elsewhere; flag as **Q4.open-1** (trust iter-1's citation; verify exact endpoint in implementation phase).

**Budget**: 3 reads + 5 WebFetches + 3 writes = 11 tool calls. Under cap.

---

## Findings

### A. THE 4-CHANNEL DECOMPOSITION (Signal Dimensions, Not Cadences)

**Terminology clarification (load-bearing):**
- **L3's "four channels"** in `006-content-lab/research/research.md` §9 = four *feedback update cadences* (per-generation exemplars, weekly templates, monthly prompt params, bi-weekly variant strategy).
- **L7's "four channels"** defined this iteration = four *signal dimensions* that feed all of the above cadences. Signal dimensions are the raw ingredients; cadences are the consumers.

| # | Channel (Signal Dimension) | What It Measures | Feeds Which L3 Cadences | Dominant Platform Metric |
|---|---|---|---|---|
| **1** | **Engagement** | Active interaction intent per impression | Few-Shot Exemplars (per-gen), Template Selection (weekly) | TikTok `likes+comments+shares+favorites`; IG `total_interactions`; FB `reactions+shares+comments`; YT `likes+comments` |
| **2** | **Retention** | How much of the video was watched + drop-off shape | Prompt Parameter Tuning (monthly), Variant Strategy (bi-weekly) | YT `audienceRetention` curve, `avgViewPercentage`; IG `reels_skip_rate` (3s gate) + `ig_reels_avg_watch_time`; FB `post_video_retention_graph`, `post_video_avg_time_watched`; TikTok — none directly (derived from `video_duration` / avg view heuristic) |
| **3** | **Completion** | Full-watch and loop behavior (algorithm-amplification signal) | Template Selection (weekly), Variant Strategy (bi-weekly) | FB `post_video_complete_views_30s`; YT derived `avgViewPercentage ≥ 0.95`; IG derived `avg_watch_time / video_duration`; TikTok derived completion ratio (if exposed) |
| **4** | **Conversion** | Downstream intent — saves, shares to others, follows, CTA clicks | Prompt Parameter Tuning (monthly), Variant Strategy (bi-weekly) | IG `saved`, `shares`, Dec-2025 `reposts` + `profile_visits` (Marketing API, ads only); FB `shares`, new-follower delta; TikTok `share_count`, `favorites_count`; YT `subscribersGained` |

#### Why 4 (not 3 or 5) — Goodhart-Grounded Justification

**Why not 3**: collapsing Retention and Completion into one metric (e.g., "watch-time") hides the distinction between *partial-but-attentive* viewing (good hook, weak payoff) and *full-loop* viewing (strong hook AND payoff). L3 needs these separately: retention informs hook prompts; completion informs CTA/ending prompts.

**Why not 5**: a fifth "Reach/Distribution" channel (impressions, algorithmic boost) is tempting but is an **upstream platform decision**, not a content-quality signal. Including it invites the model to optimize for the algorithm's current boosting pattern — which is itself drifting (cf. iter-3's drift taxonomy). Reach belongs in `performance_metrics` as context, not as a Thompson Sampling update channel.

**Goodhart grounding**: per the canonical mitigation strategy — "use multiple, diverse metrics rather than single targets" [SOURCE: https://en.wikipedia.org/wiki/Goodhart's_law] — 4 orthogonal dimensions resist gaming that any single dimension would invite. Engagement-only would boost rage-bait; retention-only would boost slow openers; completion-only would boost short filler; conversion-only would boost clickbait. Combined, a variant must survive all four gates.

### B. SIGNAL AGGREGATION RULES

#### B.1 Time-Window Semantics

Each channel has two observation windows: an **early** window (used for leading-indicator decisions) and a **stable** window (used for Thompson posterior updates).

| Channel | Early Window | Stable Window | Reason |
|---|---|---|---|
| Engagement | T+24h | T+7d | Engagement velocity peaks in first 24h on Thai TikTok/IG (Thai 24–48h lifecycle, 005); stable value solidifies by T+7d |
| Retention | T+1h–T+24h | T+7d | Retention curve shape is mostly stable by T+24h (most plays happen early); use T+7d for final label |
| Completion | T+24h | T+7d | Algorithm-boost loops (TikTok FYP) happen in first 24–72h; stable label at T+7d |
| Conversion | T+48h | T+30d | Saves/follows/profile-visits have longer tails than engagement; T+30d captures the decay |

**L3 consumption**: the per-generation cadence (Few-Shot Exemplars) reads **early-window** values within 24h of post-publication; the weekly/bi-weekly/monthly cadences read **stable-window** values.

#### B.2 Normalization (Per-Platform, Per-Vertical, Per-Account-Tier Baseline)

Raw metrics are incomparable across platforms (TikTok 2.80% vs YT Shorts 0.35% baseline engagement rates [SOURCE: 006:216]). Normalize each dimension to a **percentile-rank within a matched cohort**:

```
channel_score(content_id, dim) = percentile_rank(
  metric_value,
  cohort = posts WHERE platform = <same>
    AND niche = <same>
    AND account_tier = <same>  -- micro/mid/macro segmented by follower count
    AND pollAgeBucket = <same> -- T+1h, T+24h, T+7d cohort for same-age comparison
    AND metricDate BETWEEN last_90_days
)
```

**Why percentile-rank vs z-score**:
- Thai viral content is power-law distributed (few mega-hits distort z-score means and stdevs).
- Percentile-rank is robust to outliers — a 10M-view post maps to 99th percentile whether it's 5x or 50x the 98th percentile; z-score would shove the 98th below the mean.
- Thompson Sampling needs probability-calibrated rewards in `[0, 1]`. Percentile-rank gives this natively. [INFERENCE: probability calibration requirement from 006:137 Thompson Sampling prior design]

**Per-platform-per-vertical baseline** — required because TikTok's 2.80% engagement baseline vs YT's 0.35% means a 0.5% engagement post is a 99th-percentile YT success and a 2nd-percentile TikTok failure. The cohort filter captures this.

#### B.3 Multi-Platform Combination

When one `content_id` has posts across TikTok + IG + FB + YT, L3 consumes a **per-platform-per-dimension matrix**, NOT a single collapsed score:

```json
{
  "content_id": "...",
  "variant_id": "...",
  "platforms": {
    "tiktok":    { "engagement": 0.82, "retention": null, "completion": 0.65, "conversion": 0.40 },
    "instagram": { "engagement": 0.55, "retention": 0.70, "completion": 0.60, "conversion": 0.85 },
    "youtube":   { "engagement": 0.30, "retention": 0.75, "completion": 0.70, "conversion": 0.20 },
    "facebook":  { "engagement": 0.45, "retention": 0.65, "completion": 0.55, "conversion": 0.35 }
  },
  "aggregate_score": { /* optional rollup, see below */ }
}
```

**Why per-platform (not average)**: Thompson Sampling in L3 operates **per-platform-per-variant** because adaptation logic (platform-specific hook, duration, CTA per 006:396) produces platform-specific variants. A variant that wins on TikTok may flop on YT; averaging destroys this signal.

**Optional aggregate rollup** for template-selection cadence (which operates at niche-level, platform-agnostic): weighted average by the variant's intended-primary-platform impression share.

```
aggregate[dim] = Σ_p (platform_impressions[p] × score[p][dim]) / Σ_p platform_impressions[p]
```

Missing platforms contribute 0 weight (skip; don't zero-fill — that would penalize platforms the variant wasn't published to).

#### B.4 Outlier Handling (Anti-Viral-Noise)

Single viral hits distort feedback. Clamp the contribution of any single post to the Thompson posterior:

- **Max percentile cap**: any dimension score > 0.95 contributes as 0.95 to the success count (prevents "that one post hit #1 trending" from dominating 100 other posts' signal).
- **Viral-detection rule**: if `views > 10× median_of_cohort` for 2+ age buckets, flag `quality_flags.viral_anomaly = true` and still update Thompson posterior, but log a `DriftEvent` with `driftKind = PREDICTION` so Q3's drift detector sees the outlier as a prediction-drift signal instead of noise.
- **Minimum impressions gate**: do NOT compute Thompson-updating scores for posts with fewer than 500 impressions (TikTok/IG early-feed sample size, per 006:198). Below 500, the percentile-rank is statistically meaningless — mark as `insufficient_data` and skip posterior update.

### C. CANONICAL JSON HANDOFF SCHEMA (L7 → L3)

Full contract. One envelope per `(content_id, variant_id, time_window)` tuple posted to L3's `/api/l7-feedback` endpoint:

```json
{
  "schema_version": "1.0",
  "feedback_id": "cuid",
  "emitted_at": "2026-04-17T14:32:00Z",
  "content_id": "cuid",
  "variant_id": "cuid",
  "concept_id": "cuid",
  "trend_id": "cuid",
  "model_version": "viral-gbdt-v2.3.1",
  "time_window": "T+24h",
  "signal_stability": "early",
  "platforms": {
    "tiktok":    { "engagement": 0.82, "retention": null, "completion": 0.65, "conversion": 0.40, "impressions": 14500 },
    "instagram": { "engagement": 0.55, "retention": 0.70, "completion": 0.60, "conversion": 0.85, "impressions": 8200 }
  },
  "aggregate_score": {
    "engagement": 0.72, "retention": 0.70, "completion": 0.63, "conversion": 0.59
  },
  "platform_breakdown": {
    "tiktok":    { "likes": 820, "comments": 45, "shares": 180, "favorites": 92, "view_count": 14500, "video_duration": 28 },
    "instagram": { "likes": 410, "comments": 22, "shares": 38, "saved": 120, "reposts": 15,
                   "ig_reels_avg_watch_time": 11200, "ig_reels_video_view_total_time": 91840000,
                   "reels_skip_rate": 0.18, "total_interactions": 590, "impressions_or_reach": 8200 }
  },
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
  "thompson_update_recommended_weights": {
    "engagement": 0.25, "retention": 0.30, "completion": 0.25, "conversion": 0.20
  }
}
```

Key contract invariants:
- **Per-dimension scores are in `[0, 1]`** (percentile-rank normalized, clamped to 0.95 for anti-viral).
- **`null` when platform-native metric unavailable** (e.g., TikTok `retention` is null because TikTok Research API exposes no retention curve, iter-1 Gap #1).
- **`ready_for_thompson_update = true` only when `time_window = "T+7d"`** AND all four dimensions have non-null aggregate values AND no `quality_flags` CRITICAL flag is set.
- **`thompson_update_recommended_weights`** are L7's suggested per-dimension weights; L3 MAY override. Defaults weight Retention highest because hook quality is the strongest viral predictor on Thai TikTok/IG [INFERENCE: 006:220 "71% of viewers decide in first 1–3 seconds"].

#### Storage Model (Prisma schema addition)

```prisma
model L7FeedbackEnvelope {
  id                    String    @id @default(cuid())
  feedbackId            String    @unique
  emittedAt             DateTime  @default(now())
  contentId             String
  variantId             String
  conceptId             String?
  trendId               String?
  modelVersion          String
  timeWindow            FeedbackWindow  // T_24H | T_48H | T_7D | T_30D
  signalStability       SignalStability // EARLY | STABLE
  platformsJson         Json      @db.JsonB
  aggregateScoreJson    Json      @db.JsonB
  platformBreakdownJson Json      @db.JsonB
  qualityFlagsJson      Json      @db.JsonB
  driftStatusJson       Json      @db.JsonB
  readyForThompson      Boolean   @default(false)
  recommendedWeightsJson Json     @db.JsonB
  consumedByL3At        DateTime?
  @@index([contentId, timeWindow])
  @@index([variantId, timeWindow])
  @@index([readyForThompson, emittedAt])
  @@map("l7_feedback_envelopes")
}

enum FeedbackWindow { T_24H T_48H T_7D T_30D }
enum SignalStability { EARLY STABLE }
```

The envelope is the canonical unit of L7 → L3 communication. L3 queries `WHERE readyForThompson = true AND consumedByL3At IS NULL` for posterior updates and marks `consumedByL3At = now()` on success. Idempotent by `feedbackId` unique constraint.

### D. THOMPSON SAMPLING POSTERIOR UPDATE RULES

#### D.1 Arm Definition

Per L3's 3x3 variant expansion [SOURCE: 006:230–257], each (concept × hook) pair is a candidate variant. The Thompson Sampling arm is `(variant_id, platform_id)` — per the multi-platform-per-variant decision in §B.3.

#### D.2 Beta-Bernoulli Update Rule (Canonical)

[SOURCE: Chapelle & Li 2011, NeurIPS — https://proceedings.neurips.cc/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf]

Each arm maintains `Beta(α, β)` posterior:
```
α_t = α_0 + successes_so_far
β_t = β_0 + failures_so_far
```
Sample `θ ~ Beta(α, β)` at selection time; pull `argmax_i θ_i`; observe reward `r ∈ {0, 1}`; increment α or β.

**Success definition for L3 per-post update** (key design choice):

Composite success probability derived from the 4 channel scores using L7's recommended weights:
```
composite = w_eng × engagement_agg + w_ret × retention_agg + w_comp × completion_agg + w_conv × conversion_agg
success_probability = composite  // already in [0,1] by construction (percentile-rank)
```

Then treat this as a **Beta-Binomial** update where `success_probability` is the realized rate, not a binary outcome:
```
α_{t+1} = α_t + success_probability × impressions_decile
β_{t+1} = β_t + (1 - success_probability) × impressions_decile
```

`impressions_decile = floor(log10(impressions))` so that a post with 10k impressions contributes 4 "virtual trials" to α+β, and a post with 100k contributes 5. This prevents a single viral post from swamping the posterior while still letting higher-volume posts carry more weight.

**Why Beta-Binomial not pure Beta-Bernoulli**: content rewards are inherently rate metrics (% of viewers engaged), not single click/no-click events. Pure Bernoulli would require binarizing the composite at some threshold (say 0.5) and losing calibration. Beta-Binomial with fractional updates preserves the composite's continuous signal while keeping posterior conjugacy.

#### D.3 Cold-Start (New Variant, < 100 Impressions)

[SOURCE: Chapelle & Li 2011 — Beta(1, 1) uniform prior recommendation]

- **New variant prior**: `Beta(1, 1)` — uniform, maximum exploration.
- **Force exploration**: for each new variant with `cumulative_impressions < 100`, bypass Thompson posterior and force at least 1 pull per 24h until threshold crossed. This is consistent with L3's 20% epsilon-greedy exploration budget [SOURCE: 006:553].
- **Informative prior (optional)**: if the concept comes from a proven top-10% exemplar (Channel A, 006:523), use `Beta(3, 1)` to bias toward exploitation without blocking exploration.

#### D.4 Update Cadence

| Cadence | Trigger | Source of Scores | Action |
|---|---|---|---|
| **Per-post (end of lifecycle)** | L7 emits envelope with `readyForThompson = true` (T+7d window + all 4 dims present + no CRITICAL flag) | Stable-window scores | Beta-Binomial update; single envelope per arm |
| **Batch weekly** | Cron Sun 04:00 UTC (co-scheduled with L3-Feedback-Aggregator from 006:604) | All `readyForThompson=true AND consumedByL3At IS NULL` envelopes | Reconciliation pass: catch envelopes that were generated mid-week but not yet consumed |
| **Monthly recalibration** | Cron 1st of month | Aggregate past 30d stable envelopes | Recalibrate `thompson_update_recommended_weights` based on which dim has the highest Spearman correlation with long-tail `views_168h` |

Per-post update is primary; weekly batch is safety-net; monthly recalibration is meta-learning (L3's "Prompt Parameter Tuning" cadence from 006:518).

### E. VANITY-METRIC GUARDRAILS (Reward-Hacking Prevention)

[SOURCE: Goodhart's Law mitigation — https://en.wikipedia.org/wiki/Goodhart's_law — "use multiple, diverse metrics rather than single targets"]

Set `quality_flags.*` booleans; if any CRITICAL flag fires, the envelope is emitted with `readyForThompson = false` and the offending variant is NOT pulled into posterior updates for this window.

#### E.1 Rage Engagement Detection

**Signature**: high Engagement + low Retention + low Conversion + comment-sentiment tilts negative.
```
rage_engagement_suspected =
  engagement_agg >= 0.80
  AND retention_agg <= 0.40
  AND conversion_agg <= 0.30
  AND (comment_sentiment_negative_ratio >= 0.60  // if NLP pipeline available
       OR (if NLP unavailable) comments / (likes + shares) >= 0.40)
```
Action: log `DriftEvent` with `driftKind = CORRELATION`, keep the envelope but set `readyForThompson = false`. Do NOT boost similar-hook variants in Channel A (Few-Shot Exemplars).

#### E.2 Bot Traffic / Impression Anomaly

**Signature**: sudden impression spike without proportional engagement velocity change.
```
bot_traffic_suspected =
  (impressions_T+24h / impressions_T+1h) >= 100×
  AND (engagement_count_T+24h / engagement_count_T+1h) <= 5×
  AND (impressions_growth_rate seems step-function not sigmoidal)
```
Action: flag `bot_traffic_suspected = true` AND `insufficient_data = true`; skip posterior update for this envelope. Log to `drift_events` for human review.

#### E.3 Clickbait-and-Switch

**Signature**: high first-3s survival (good hook) + collapsing retention + low completion.
```
clickbait_suspected =
  (1 - reels_skip_rate) >= 0.80            // 80%+ survive the 3-second hook
  AND completion_rate <= 0.25              // only 25% finish
  AND engagement_count_at_end_segment / engagement_count_at_hook <= 0.30
```
Action: flag + penalize the **retention channel contribution** (set `retention_agg = min(retention_agg, 0.30)` before percentile-ranking). Do NOT set `readyForThompson = false` — we still want to learn from clickbait as negative-example for hook prompts.

#### E.4 Algorithmic Boost Distortion (TikTok FYP, IG Explore)

**Signature**: impression velocity anomaly from algorithmic surfaces dominates organic reach.
```
algorithmic_boost_detected =
  platform in ("tiktok", "instagram")
  AND fyp_impressions_share >= 0.70          // if exposed by API
  AND creator_follower_count <= 10_000        // small creator getting boost
```
Action: flag + down-weight this platform's contribution to the aggregate rollup (§B.3) by 0.5×. Do NOT skip Thompson update — boosted posts are still content signal, just weaker — but normalize against the boost.

#### E.5 Multi-Dimensional Sanity Gate (Catch-All Goodhart Guard)

A single dimension cannot exceed 0.95 if the other three are all < 0.30:
```
if max(dim_scores) >= 0.95 AND count(d for d in dim_scores if d < 0.30) >= 3:
   readyForThompson = false
   log DriftEvent CORRELATION "single-dim anomaly"
```
This is the structural Goodhart guard: no single metric can drive the update.

### F. INTEGRATION WITH Q1-Q3

#### F.1 `performance_metrics` Columns → Channels

[SOURCE: iter-2 §7.2 schema]

| performance_metrics column | Feeds Channel | Notes |
|---|---|---|
| `views`, `reach`, `impressions` | (context only, not a channel) | Cohort matching & denominators for percentile-rank |
| `watchTimeMs`, `avgViewDurationMs` | Retention + Completion | Retention = `avgViewDurationMs / videoDurationMs`; Completion = `avgViewPercentage` or derived |
| `completionRate` | Completion | Primary input |
| `skipRate3s` | Retention (hook quality) | `1 - skipRate3s = hook_survival_3s` |
| `likes`, `reactions` | Engagement | Per-platform weighted (TikTok like ≠ IG like ≠ FB reaction) |
| `comments` | Engagement (plus sentiment-optional input to Rage flag) | Always enters engagement; may also enter Rage detector |
| `shares` | Conversion | Shares = intent to redistribute = highest-value engagement |
| `saves` | Conversion | Save intent |
| `retentionCurve` (JSONB) | Retention + Completion | Drop-off shape analysis for Channel 2, full-loop detection for Channel 3 |

#### F.2 Drift Ripple from GBDT (iter-3) to L3 Thompson Sampling

When iter-3's `drift_events` fires with `severity = CRITICAL`, the envelope flow adapts:

```
drift_events (severity = CRITICAL, driftKind IN (PREDICTION, PERFORMANCE))
    └─→ L7FeedbackEnvelope: drift_status.prediction_drift_active = true
          └─→ L3 receives envelope, sees drift flag
                └─→ L3 action: freeze Thompson posterior updates (pause exploitation)
                     + increase ε in ε-greedy from 0.20 → 0.40 (force exploration)
                     until drift_events.resolvedAt IS NOT NULL
```

Rationale: when the L2 scorer drifts, the basis on which L3 chose variants is stale; continuing to update Thompson posteriors would reinforce a stale optimum. Quarantine the Thompson posterior (stop updates, not reset) and widen exploration to rebuild the signal. Do NOT reset arms — we keep historical data as reference for the post-drift rollback comparison.

This answers iter-3's Recommended Next Focus question 5 ("does concept drift on GBDT trigger a Thompson-arm reset, or is it quarantined to model-world only?"): **quarantine, not reset.**

#### F.3 n8n Workflow Integration (+1 new workflow vs iter-2)

The existing 5 n8n workflows in 006 (L3-Content-Generator, L3-Script-Generator, L3-Content-Calendar, L3-Retry-Failures, L3-Feedback-Aggregator) are joined by ONE new workflow on the L7 side:

**`L7-Feedback-Emitter`** (new, owned by 007):
```
Cron */1 h (aligned with pollAgeBucket transitions)
  → Query performance_metrics WHERE (T+24h | T+48h | T+7d | T+30d) just landed
  → For each content_id:
      - compute per-dim percentile-rank scores (§B.2)
      - combine platforms (§B.3)
      - apply guardrails (§E)
      - apply drift-status ripple (§F.2)
  → UPSERT L7FeedbackEnvelope row
  → POST to L3 /api/l7-feedback (the existing L3-Feedback-Aggregator then consumes from l7_feedback_envelopes table on its weekly cron)
```

L3-Feedback-Aggregator (existing, from 006:614) is modified to read from `l7_feedback_envelopes` WHERE `readyForThompson = true AND consumedByL3At IS NULL` instead of querying raw `performance_metrics` directly. This creates clean L7/L3 boundary with one canonical contract table.

**Total L7 workflows** (007 integration): `drift_detection_tick` (iter-3 §8.6) + `L7-Feedback-Emitter` (this iteration) + the ingestion-side polling cron (iter-2 §7.1) = **3 L7-owned n8n workflows** feeding the existing 5 L3 workflows.

### G. CITATIONS (verified this iteration)

- **Thompson Sampling formal mechanism + Beta conjugacy** — [SOURCE: https://en.wikipedia.org/wiki/Thompson_sampling] — mechanism confirmed; formula depth deferred to primary source.
- **Chapelle & Li 2011, "An Empirical Evaluation of Thompson Sampling", NeurIPS** — [SOURCE: https://proceedings.neurips.cc/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf] — Beta(α, β) update rule, Beta(1,1) cold-start prior, canonical pseudocode, empirical superiority vs UCB and epsilon-greedy. This is the primary Thompson Sampling citation for viral-ops.
- **Goodhart's Law mitigation — "use multiple, diverse metrics rather than single targets"** — [SOURCE: https://en.wikipedia.org/wiki/Goodhart's_law] — theoretical grounding for why 4 orthogonal channels outperform any single composite metric. Covers Strathern 1997 formulation and Campbell's Law (1969).
- **Instagram Reels media-level metrics** — [SOURCE: https://developers.facebook.com/docs/instagram-platform/reference/instagram-media/insights] — confirmed exact metric names: `ig_reels_avg_watch_time`, `ig_reels_video_view_total_time`, `saved`, `total_interactions`. `reels_skip_rate` (Dec 2025 release per iter-1) is NOT on this reference page — flagged as Q4.open-1 for implementation-phase verification.
- **Instagram Platform Insights overview** — [SOURCE: https://developers.facebook.com/docs/instagram-platform/insights] — index only.
- **006-content-lab 4-channel + Thompson Sampling declaration** — [SOURCE: 006-content-lab/research/research.md:194–224, 513–558]
- **007 iter-1 platform API table + Dec-2025 IG metrics** — [SOURCE: 007/research/iterations/iteration-001.md:§3–5]
- **007 iter-2 performance_metrics schema + rate-limit budget** — [SOURCE: 007/research/iterations/iteration-002.md:§B–F]
- **007 iter-3 drift_events schema + drift-to-training propagation** — [SOURCE: 007/research/iterations/iteration-003.md:§A–F]

---

## Open Questions

- **Q4.open-1**: The exact IG Graph API endpoint + field name for `reels_skip_rate` (Dec 2025 release per iter-1 cite) is not on the `insights` reference page returned this iteration. Defer exact-endpoint verification to the implementation phase (Prisma field already provisioned via `skipRate3s` in iter-2 schema; contract can ingest regardless of name).
- **Q4.open-2**: Comment-sentiment NLP pipeline for Rage-Engagement detection (§E.1) — does viral-ops have a Thai-language sentiment model? If PyThaiNLP ships sentiment, use it; if not, the NLP-unavailable fallback (comments/(likes+shares) ratio) is already specified. Verify in implementation phase.
- **Q4.open-3**: Follower-delta attribution — how do we know a profile-visit or new-follower arose from a specific post vs organic growth? Instagram Marketing API exposes `profile_visits` for ad-driven only (iter-1 §3.4). For organic attribution, consider a per-post UTM-style tracker or accept "aggregate per-day follower delta / posts that day" as a coarse proxy. Defer precise attribution logic to implementation.
- **Q4.open-4**: Does the monthly `thompson_update_recommended_weights` recalibration (§D.4) risk overfitting to recent-window variance? Consider an ablation (30d vs 90d window) in the implementation phase. Not a research blocker.

## Ruled Out (this iteration)

- **3-dimension decomposition** (Engagement + Retention + Conversion, collapsing Completion into Retention): ruled out — loses the full-loop-vs-partial-watch distinction that L3 prompt tuning needs (hook prompts vs CTA prompts target different parts of the retention curve).
- **5-dimension decomposition** (adding Reach/Distribution): ruled out — Reach is an upstream platform decision, not a content-quality signal. Admitting it as a Thompson channel invites optimization against the algorithm's current boosting pattern, which is itself drifting (iter-3).
- **Single composite scalar** (one number per post): ruled out on Goodhart grounds — violates "multiple diverse metrics" mitigation; enables single-dimension reward hacking (rage engagement, clickbait, bot traffic).
- **Z-score normalization**: ruled out — power-law distribution of viral content makes z-score non-robust to outliers; percentile-rank is robust and already in `[0,1]` for Thompson posterior compatibility.
- **Pure Beta-Bernoulli with threshold binarization** (binarize composite at 0.5, then update as Bernoulli): ruled out — loses the continuous signal that percentile-rank gives; Beta-Binomial with fractional updates preserves calibration required by 006:137 Thompson Sampling priors.
- **Reset Thompson arms on GBDT drift**: ruled out — destroys historical signal needed for post-drift rollback comparison; quarantine (pause updates, widen ε) is strictly better.
- **Single-platform rollup** (one score per content_id, platform-agnostic): ruled out for posterior updates — platform-specific variants flop differently; preserves per-(variant, platform) arm granularity.
- **Collapsing L7's "4 signal dimensions" into L3's "4 update cadences" as a single concept**: ruled out — they are orthogonal; signal dimensions are ingredients, cadences are consumers. Terminology bridged but kept distinct.

## Dead Ends (promote to strategy)

- **arxiv.org/abs/2001.07426** — turned out to be a causal-effects paper, not a delayed-feedback bandits paper. Dead end for the specific citation hunt; general delayed-feedback bandit literature (Vernade et al. 2017, Grover et al. 2018) would be better sources if deeper feedback-delay analysis is needed in iteration 5 or 6.
- **Instagram Platform Insights overview page** — index only, defers to media-level reference pages. Always fetch the specific media-insights reference in future iterations.

## Sources Consulted

- https://en.wikipedia.org/wiki/Thompson_sampling (mechanism confirmed; depth thin)
- https://proceedings.neurips.cc/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf (Chapelle & Li 2011, primary Thompson Sampling reference)
- https://en.wikipedia.org/wiki/Goodhart's_law (mitigation grounding)
- https://developers.facebook.com/docs/instagram-platform/insights (index)
- https://developers.facebook.com/docs/instagram-platform/reference/instagram-media/insights (IG Reels metrics)
- .opencode/specs/viral-ops/006-content-lab/research/research.md §§3–9 (4-channel architecture, Thompson Sampling, exploration budget, engagement benchmarks)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-001.md §§3–5 (platform APIs, Dec 2025 IG metrics)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-002.md §§B–F (performance_metrics schema, rate-limits)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-003.md §§A–F (drift taxonomy, drift_events schema, training_feature_snapshots)

## Assessment

- **New information ratio**: raw = `(9 new + 0.5 × 3 refinements) / 12 = 0.875`; conservative = **0.80** after discounting the `reels_skip_rate` exact-endpoint gap (Q4.open-1) and the arXiv dead-end cost.
- **Simplicity bonus**: +0 — no prior-iteration contradiction resolved; instead, a new terminology bridge was added (L3's "channels" vs L7's "channels") that could be mistaken for contradiction but is actually orthogonal concepts.
- **Net findings (this iteration)**:
  1. Terminology bridge: L3 cadences vs L7 signal dimensions
  2. 4-channel decomposition with Goodhart-grounded why-4 justification
  3. Early vs stable time-window semantics per dimension
  4. Percentile-rank normalization with cohort matching (platform × niche × account_tier × age bucket)
  5. Per-(variant, platform) Thompson arm granularity + optional aggregate rollup
  6. Outlier handling (0.95 clamp, 500-impression gate, viral-anomaly flag)
  7. Canonical L7FeedbackEnvelope schema (JSON + Prisma model)
  8. Beta-Binomial (not pure Bernoulli) update rule with `impressions_decile` virtual-trial scaling
  9. Cold-start with Beta(1,1) + forced exploration under 100 impressions
  10. 5 vanity-metric guardrails (rage, bot, clickbait, algo-boost, multi-dim sanity gate)
  11. GBDT-drift ripple to Thompson: quarantine-not-reset policy (answers iter-3's open question)
  12. L7-Feedback-Emitter n8n workflow (6th L3-integrated workflow, 3rd L7-owned)
- **Questions addressed**: Q4 fully.
- **Questions answered**: Q4.
- **Final newInfoRatio**: **0.80**.

## Reflection

- **What worked and why**: Starting from 006's 4-channel declaration and treating it as under-specified rather than re-deriving it gave this iteration a clear gap to close. The terminology-bridge move (distinguishing L3 "channels as cadences" from L7 "channels as dimensions") prevented a contradiction that would have blocked later iterations. Grounding the 4-channel justification in Goodhart's Law mitigation turned "why 4 not 3 or 5" from arbitrary into principled.
- **What didn't work and why**: The Wikipedia Thompson Sampling article was too shallow for formula-level citation — had to escalate to the NeurIPS 2011 PDF. Root cause: Wikipedia ML primers are summaries, not references. Lesson: for algorithm citation depth, go directly to the canonical paper.
- **What I would do differently**: The arXiv 2001.07426 fetch was a miss — URL guessing for a delayed-feedback-bandits paper without verifying the title first. Next time, use a search-first pattern (e.g., `site:arxiv.org delayed feedback thompson sampling`) before guessing paper IDs.

## Recommended Next Focus

**Iteration 5 (Q5): Prompt Tuning Automation.** Specifically, how does the monthly `thompson_update_recommended_weights` recalibration (§D.4) propagate into L3's prompt-generation templates? What is the closed-loop between:
1. L7 correlation analysis (which dim correlates best with long-tail views_168h) →
2. L3 prompt parameter adjustment (temperature, few-shot count, XML structure tweaks) →
3. New script-generation cycles →
4. Back to L7 measurement

Specifically design:
- **(a)** Concrete prompt-parameter registry: what's tunable? (temperature, few-shot count per concept, CTA template weights, hook-type weights, emotional-tone weights)
- **(b)** A/B harness for prompt changes at the *generation* level (not the content level) — how do we evaluate a prompt change without confounding with trend shifts?
- **(c)** Safety rails: when to promote a prompt change (monthly cadence vs triggered by variant-performance delta), when to revert (Spearman drop), canary cohort definition
- **(d)** Integration with MLflow experiment tracking from iter-3 — do prompt versions register alongside model versions?
- **(e)** n8n workflow: 7th L3 workflow (L3-Prompt-Tuner) or extend L3-Feedback-Aggregator?
- **(f)** Thompson-sampling meta-bandit on prompt variants themselves (meta-level bandit on top of content-level bandit)

**Secondary**: Explore whether the drift-triggered `ε-greedy widen to 0.40` (§F.2) should also pause prompt-tuning automation (to avoid amplifying L2's drift into L3's prompt drift). [INFERENCE: yes, most likely — but verify in iter-5.]

---

## Graph Events (for JSONL record)

```
nodes:
- channel/engagement
- channel/retention
- channel/completion
- channel/conversion
- aggregation/percentile_rank
- aggregation/per_platform_matrix
- aggregation/optional_rollup_by_impression_share
- window/early_T_24h
- window/stable_T_7d
- window/conversion_T_30d
- handoff/L7FeedbackEnvelope
- arm/variant_id_x_platform
- update/beta_binomial
- update/impressions_decile_scaling
- coldstart/beta_1_1_uniform
- coldstart/beta_3_1_proven_exemplar
- coldstart/forced_exploration_under_100_impressions
- guardrail/rage_engagement
- guardrail/bot_traffic
- guardrail/clickbait
- guardrail/algorithmic_boost
- guardrail/multi_dim_sanity_gate
- ripple/drift_to_thompson_quarantine
- workflow/L7_feedback_emitter

edges:
- performance_metrics --feeds--> channel/engagement
- performance_metrics --feeds--> channel/retention
- performance_metrics --feeds--> channel/completion
- performance_metrics --feeds--> channel/conversion
- channel/* --normalized_by--> aggregation/percentile_rank
- aggregation/percentile_rank --combined_by--> aggregation/per_platform_matrix
- aggregation/per_platform_matrix --packaged_into--> handoff/L7FeedbackEnvelope
- guardrail/* --attached_to--> handoff/L7FeedbackEnvelope
- handoff/L7FeedbackEnvelope --consumed_by--> arm/variant_id_x_platform
- arm/variant_id_x_platform --updates_posterior_via--> update/beta_binomial
- coldstart/beta_1_1_uniform --initializes--> arm/variant_id_x_platform
- drift_events(CRITICAL) --triggers--> ripple/drift_to_thompson_quarantine
- ripple/drift_to_thompson_quarantine --pauses--> update/beta_binomial
- ripple/drift_to_thompson_quarantine --widens_epsilon--> L3/epsilon_greedy(0.20 → 0.40)
- workflow/L7_feedback_emitter --emits--> handoff/L7FeedbackEnvelope
```
