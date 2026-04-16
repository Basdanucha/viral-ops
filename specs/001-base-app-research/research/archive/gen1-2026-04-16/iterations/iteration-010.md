# Iteration 10: Content Lab A/B Testing + Feedback Loop Analytics APIs

## Focus
Investigating Q24 (Content Lab A/B testing for short-form video) and Q25 (Feedback Loop analytics APIs per platform). These are the final two intelligence-layer questions needed to complete the viral-ops pipeline architecture.

## Findings

### Finding 1: A/B Testing Methodology for Short-Form Video Hooks

**There is no native A/B testing feature on TikTok, YouTube Shorts, or Instagram Reels** for organic content. Unlike YouTube long-form (which has thumbnail A/B testing via "Test & Compare"), short-form platforms provide no split-test tooling. The industry-standard approach is **sequential variant testing**:

1. **Hook-only variants** (recommended for Phase 1): Same script body, different opening 3 seconds. This isolates hook effectiveness. Post variant A, wait 48 hours for algorithmic distribution to stabilize, then post variant B. Compare retention curves.
2. **Full script variants**: Different angles on the same topic. Higher variance, harder to attribute performance differences to a single factor.
3. **Visual style variants**: Same script, different image generation prompts / visual treatment. Tests visual appeal independently.

**The 48-hour rule**: New Shorts/TikToks receive an algorithmic boost in the first 48 hours. Performance data stabilizes after this window, making it the minimum wait time before comparing variants.

**Statistical significance**: With organic content, true A/B testing is impossible because you cannot control the audience. Instead, use **directional signals** from multiple variant pairs (5-10 pairs minimum) to identify patterns. A single pair comparison is anecdotal, not statistical.

**Optimal variant count**: 2 variants per test (A/B, not A/B/C). More variants dilute the signal because each additional post has independent algorithmic distribution. The Viral Brain already generates 3-5 hook variants and selects top 2 via LLM scoring (from iteration 9), which maps perfectly to this 2-variant testing approach.

**Key metric for comparison**: Watch-through rate (completion rate) is the single most important metric across all three platforms. A 30-second video with 70% completion outperforms a 60-second video abandoned at 15 seconds. For hooks specifically, **3-second retention rate** is the primary A/B comparison metric.

[SOURCE: https://joinbrands.com/blog/youtube-shorts-best-practices/]
[SOURCE: https://driveeditor.com/blog/trends-short-form-video-hooks]
[SOURCE: https://autofaceless.ai/blog/short-form-video-statistics-2026]

### Finding 2: Content Lab Architecture for Variant Testing

Based on the sequential testing methodology, Content Lab operates as an n8n workflow layer sitting between Viral Brain and Distribution:

**Workflow design**:
```
Viral Brain scores topic → generates 3-5 hook variants → LLM selects top 2
  → Content Lab creates "test pair" record in DB
  → Variant A enters Production pipeline → Distribution (post to platforms)
  → n8n schedules "post Variant B" trigger at T+48h
  → Variant B enters Production → Distribution
  → n8n schedules "compare" trigger at T+96h (48h after B posted)
  → Feedback Loop pulls metrics for both → Content Lab determines winner
```

**DB schema extension** (adds to iteration 6 schema):
```sql
-- Content Lab variant tracking
CREATE TABLE content_variants (
  id UUID PRIMARY KEY,
  parent_topic_id UUID REFERENCES topics(id),
  variant_label VARCHAR(10),          -- 'A', 'B'
  hook_text TEXT,                      -- The hook script text
  hook_score DECIMAL(5,2),            -- Viral Brain LLM score
  status VARCHAR(20) DEFAULT 'pending', -- pending, published, measured, winner, loser
  published_at TIMESTAMPTZ,
  measured_at TIMESTAMPTZ,
  retention_3s DECIMAL(5,4),          -- 3-second retention rate
  completion_rate DECIMAL(5,4),       -- Watch-through rate
  engagement_rate DECIMAL(5,4),       -- (likes+comments+shares)/views
  total_views INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ab_tests (
  id UUID PRIMARY KEY,
  topic_id UUID REFERENCES topics(id),
  variant_a_id UUID REFERENCES content_variants(id),
  variant_b_id UUID REFERENCES content_variants(id),
  status VARCHAR(20) DEFAULT 'running', -- running, complete, inconclusive
  winner_id UUID REFERENCES content_variants(id),
  confidence_note TEXT,               -- "directional" or "strong" based on view count
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Winner selection criteria**:
- Primary: higher 3-second retention rate
- Secondary: higher completion rate
- Tertiary: higher engagement rate
- Minimum views threshold: 500 views per variant before comparison (below this, mark "inconclusive")

[SOURCE: iteration 9 findings on Viral Brain variant generation]
[INFERENCE: based on sequential testing methodology + existing DB schema from iteration 6]

### Finding 3: YouTube Analytics API — Comprehensive Metric Access

The YouTube Analytics API provides the richest programmatic analytics access of all four platforms. Key details:

**Endpoint**: `reports.query` via YouTube Analytics API (part of Google API ecosystem)

**Available metrics** (exact API field names):
- **Views & Watch Time**: `views`, `estimatedMinutesWatched`, `averageViewDuration`, `engagedViews`
- **Audience Retention**: `audienceWatchRatio`, `relativeRetentionPerformance`, `startedWatching`, `stoppedWatching`, `totalSegmentImpressions`
- **Engagement**: `likes`, `dislikes`, `comments`, `shares`, `subscribersGained`, `subscribersLost`, `videosAddedToPlaylists`, `videosRemovedFromPlaylists`
- **Revenue**: `estimatedRevenue`
- **Demographics**: `viewerPercentage`

**Shorts-specific limitations**:
- No dedicated Shorts API endpoint — same `reports.query` for all content types
- **No CTR metric for Shorts** (no thumbnail click decision in swipe feed)
- **Completion rate** replaces CTR as the primary engagement signal
- **Swipe-away rate** is visible in YouTube Studio but NOT available via API
- Shorts don't count toward monetization watch hours
- Shorts impressions counted only when video appears in Shorts feed

**Data freshness**: YouTube updates analytics with ~24-48 hour delay. Some metrics (views) update faster than others (audience retention curves).

**Rate limits**: Standard Google API quotas — 10,000 units/day default. `reports.query` costs 1 unit per call. Sufficient for pulling analytics for hundreds of videos daily.

**Authentication**: OAuth 2.0 with `youtube.readonly` scope. n8n has a built-in YouTube node that handles OAuth.

[SOURCE: https://developers.google.com/youtube/analytics/metrics]
[SOURCE: https://miraflow.ai/blog/youtube-shorts-analytics-2026-how-to-read-graphs]
[SOURCE: https://fluxnote.io/guides/youtube-shorts-analytics-2026]

### Finding 4: TikTok Analytics API — Available But Limited

TikTok's analytics access is more fragmented than YouTube's:

**API surfaces** (multiple, confusing):
1. **Content Posting API**: Used for uploading (iteration 6). Returns basic `video_id` but NOT analytics.
2. **TikTok Business API** (via Business Center): Returns video stats, audience data, engagement metrics for connected business accounts. Requires developer approval.
3. **TikTok Research API**: Academic-only, already ruled out (iteration 9).
4. **TikTok Studio (Desktop)**: Provides retention curves but NO API access — manual viewing only.

**Available metrics via Business API**:
- Video-level: `views`, `impressions`, `reach`, `average_watch_time`, `completion_rate`, `audience_retention`
- Account-level: `follower_growth`, `profile_views`
- **NOT available**: Creator Fund/Creativity Program earnings, demographic data via direct API

**Key limitations**:
- Analytics data lags 24-48 hours behind real-time
- Rate limits enforced but specific numbers not publicly documented — must implement exponential backoff
- No batch retrieval for multiple videos in a single call — must iterate per video
- Retention curve data available in TikTok Studio UI but not confirmed via API

**Third-party aggregation**: Phyllo (https://www.getphyllo.com/) provides a unified API across 10+ platforms, handling token lifecycle, webhooks, and data normalization. Could simplify the multi-platform analytics pipeline significantly for a solo developer, but adds a dependency and cost.

**n8n integration**: No built-in TikTok Analytics node. Must use HTTP Request node with manual OAuth token management.

[SOURCE: https://www.getphyllo.com/post/introduction-to-tiktok-api]
[SOURCE: https://influenceflow.io/resources/master-tiktok-analytics-in-2026-the-ultimate-tutorial-guide-for-creators-businesses/]
[SOURCE: https://agencyanalytics.com/blog/tiktok-analytics]

### Finding 5: Instagram & Facebook Insights APIs

**Instagram Insights** (via Meta Graph API):

Endpoints:
- `GET /<MEDIA_ID>/insights` — media-level metrics
- `GET /<ACCOUNT_ID>/insights` — account-level metrics

Available Reels metrics: `impressions`, `reach`, `engagement`, `comments_count`, `likes`, `shares`, `saves`, `plays`, `total_interactions`

Limitations:
- User-level metrics stored for **90 days maximum**
- Media-level metrics have longer retention but exact limit undocumented
- Data freshness not specified but typically 24h delay
- Rate limits: Standard Meta Graph API limits (200 calls/user/hour for app-level, 4800 calls/24h for page-level)

**Facebook Reels** (via Video API):
- Uses same Meta Graph API infrastructure as Instagram
- Shared OAuth via Meta Business Suite
- Metrics: `video_views`, `reach`, `engagement`, `shares`
- Already confirmed in iteration 6 that Facebook and Instagram share authentication

**n8n integration**: No built-in Instagram/Facebook Insights node. HTTP Request node with Meta Graph API OAuth tokens.

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-facebook-login/insights/]
[SOURCE: iteration 6 findings on Meta shared authentication]

### Finding 6: Feedback Loop Pipeline Architecture — Analytics Ingestion to Viral Brain Retraining

**Ingestion schedule** (n8n cron workflow):
- **T+6h after publish**: First metrics pull — early signal (enough for initial distribution assessment)
- **T+48h**: Second pull — stabilized metrics (algorithmic boost period over). This is the primary data point for A/B test comparison.
- **T+168h (7 days)**: Final pull — long-tail performance. Used for Viral Brain retraining data.

**Data freshness per platform**:
| Platform | Delay | Best Pull Timing |
|----------|-------|-------------------|
| YouTube | 24-48h | T+48h, T+168h |
| TikTok | 24-48h | T+48h, T+168h |
| Instagram | ~24h | T+24h, T+48h, T+168h |
| Facebook | ~24h | T+24h, T+48h, T+168h |

**Metrics to store** (maps to `platform_analytics` table from iteration 6):
```
video_id, platform, pulled_at,
views, impressions, reach,
avg_watch_time, completion_rate, retention_3s,
likes, comments, shares, saves,
engagement_rate (computed: interactions/views)
```

**Retraining pipeline** (from iteration 9, now with concrete data flow):
- **Features**: `hook_text` + `viral_score_llm` (6 dimensions) + `platform` + `niche` + `time_of_day` + `day_of_week`
- **Target variables**: `actual_views` (log-scaled), `actual_retention_3s`, `actual_engagement_rate`
- **Model**: GBDT (Gradient Boosted Decision Trees, validated by MLLM-VAU paper)
- **Training trigger**: Every 100 new videos with T+168h metrics, OR weekly scheduled
- **Minimum data**: ~500 videos with complete metrics before first GBDT training (LLM-as-judge continues as primary scorer until then)
- **Execution**: Python script called via n8n Code node or separate FastAPI endpoint on Pixelle-Video service
- **Output**: Updated scoring weights that augment (not replace) LLM-as-judge scores

**Architecture flow**:
```
n8n Cron (every 6h)
  → For each published video without final metrics:
    → HTTP Request to each platform's analytics API
    → Store in platform_analytics table
    → If T+48h data available for A/B test pair:
      → Trigger Content Lab comparison workflow
    → If T+168h data available:
      → Mark as "training-ready" in DB
  → If training_ready_count >= 100 (or weekly trigger):
    → Trigger retraining workflow
    → Python script reads training data from DB
    → Trains GBDT model
    → Stores model weights in /models/ directory
    → Updates Viral Brain scoring endpoint
```

[INFERENCE: based on platform data freshness findings + iteration 9 MLLM-VAU retraining architecture + iteration 6 DB schema]
[SOURCE: https://developers.google.com/youtube/analytics/metrics]
[SOURCE: https://www.getphyllo.com/post/introduction-to-tiktok-api]

## Ruled Out
- **Native A/B testing on short-form platforms**: None of the three platforms (TikTok, YouTube Shorts, Instagram Reels) offer built-in A/B testing for organic short-form content. Sequential variant testing is the only viable approach.
- **Real-time analytics ingestion**: All platforms have 24-48h data delay, making real-time feedback impossible. Minimum practical polling interval is every 6 hours.
- **Swipe-away rate via YouTube API**: Visible in YouTube Studio UI but not available via the Analytics API.

## Dead Ends
- **Native platform A/B testing for organic short-form video**: This is a fundamental platform limitation, not a missing feature. None of the platforms have incentive to add this because their recommendation algorithms control distribution, making controlled experiments impossible for organic content.

## Sources Consulted
- https://developers.google.com/youtube/analytics/metrics (YouTube Analytics API official docs)
- https://developers.facebook.com/docs/instagram-platform/instagram-api-with-facebook-login/insights/ (Instagram Insights API)
- https://www.getphyllo.com/post/introduction-to-tiktok-api (TikTok API comprehensive guide by Phyllo)
- https://joinbrands.com/blog/youtube-shorts-best-practices/ (YouTube Shorts A/B testing methodology)
- https://driveeditor.com/blog/trends-short-form-video-hooks (Hook trends and testing approaches)
- https://autofaceless.ai/blog/short-form-video-statistics-2026 (Short-form video statistics 2026)
- https://influenceflow.io/resources/master-tiktok-analytics-in-2026-the-ultimate-tutorial-guide-for-creators-businesses/ (TikTok Analytics 2026)
- https://agencyanalytics.com/blog/tiktok-analytics (TikTok Analytics tools overview)
- https://miraflow.ai/blog/youtube-shorts-analytics-2026-how-to-read-graphs (YouTube Shorts-specific analytics)
- https://fluxnote.io/guides/youtube-shorts-analytics-2026 (YouTube Shorts analytics guide)

## Assessment
- New information ratio: 0.83
- Questions addressed: Q24, Q25
- Questions answered: Q24, Q25

## Reflection
- What worked and why: WebSearch for platform-specific analytics API documentation returned high-quality authoritative results. The YouTube Analytics API metrics page was the single highest-value source — it provides exact API field names that are immediately actionable for n8n HTTP Request node configuration. Combining multiple search results for A/B testing methodology provided a comprehensive picture despite no single source covering the full topic.
- What did not work and why: The calculatecreator.com TikTok guide returned a socket error. The Instagram Insights doc page was sparse on Reels-specific metrics — the full API reference would have been better but the key endpoint structure was confirmed.
- What I would do differently: For the Instagram/Facebook APIs, fetching the full Graph API reference page for media insights rather than the overview would yield exact Reels metric names. The TikTok Business API docs at developers.tiktok.com would be the definitive source but may require authentication to view.

## Recommended Next Focus
With Q24 and Q25 now answered, all intelligence-layer questions (Q22-Q25) are addressed. Recommended next: Q26 (Product Discovery / Path B — affiliate catalog scanning, TikTok Shop product search API, product relevance scoring) to complete the full pipeline coverage, or a convergence synthesis iteration to consolidate all intelligence layer findings (Q22-Q25) into the definitive architecture.
