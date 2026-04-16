# Iteration 1: Platform Analytics API Specs (Q1)

## Focus

Map the CURRENT (April 2026) working API specs for performance analytics across TikTok, YouTube, Instagram, and Facebook. Deliver a platform-by-platform comparison covering endpoints, metrics, auth, rate limits, latency, retention curves, gaps, and account-type limitations. Prior research (`004-platform-upload-deepdive`) already covers upload mechanics; this iteration establishes the READ side of the feedback loop.

## Actions Taken

1. **Read state files** — `deep-research-config.json`, `deep-research-strategy.md`, `deep-research-state.jsonl`. Confirmed lifecycle `new`, progressive synthesis enabled, machine-owned sections reducer-governed. No exhausted approaches to avoid.
2. **WebFetch — YouTube Analytics Reports Query** `https://developers.google.com/youtube/analytics/reference/reports/query` — endpoint, metrics, scopes, latency, doc last updated 2026-01-15.
3. **WebFetch — Facebook Page Insights** `https://developers.facebook.com/docs/graph-api/reference/v21.0/insights` — endpoint, video metrics, permissions, deprecation notice.
4. **WebSearch (tiktok domain-filtered)** — located canonical Research API URL after initial 404.
5. **WebSearch (facebook domain-filtered)** — located canonical Instagram Graph API v25 insights URL.
6. **WebFetch — TikTok Research API Query Videos** `https://developers.tiktok.com/doc/research-api-specs-query-videos/` — endpoint, 25 video fields, scope, client-credentials flow.
7. **WebFetch — TikTok API v2 Rate Limits** `https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit` — public rate-limit page (incomplete; only 3 endpoints listed).
8. **WebFetch — Instagram Media Insights (v25)** `https://developers.facebook.com/docs/instagram-platform/reference/instagram-media/insights/` — per-media-type metric inventory, deprecations, permission model.
9. **WebFetch — Instagram API Updates Dec 2025** `https://developers.facebook.com/blog/post/2025/12/03/instragram-api-updates/` — 5 new insights metrics, IG Media Deleting API, Trial Reels.
10. **CocoIndex search** — FAILED (daemon `PermissionError: [WinError 5]` on Windows pipe creation). Added to "Ruled Out" this iteration; no existing viral-ops code references retrieved. Fallback: rely on memory packet references from `004-platform-upload-deepdive`.

## Findings (Grouped by Platform)

### TIKTOK

- **Endpoint**: `POST https://open.tiktokapis.com/v2/research/video/query/` [SOURCE: https://developers.tiktok.com/doc/research-api-specs-query-videos/]
- **Metrics (25 queryable fields)**: `view_count`, `like_count`, `share_count`, `comment_count`, `favorites_count`, `video_duration`, `create_time`, `region_code`, `hashtag_names`, `hashtag_info_list`, `music_id`, `playlist_id`, `voice_to_text`, `is_stem_verified`, `effect_ids`, `effect_info_list`, `sticker_info_list`, `video_mention_list`, `video_label`, `video_tag`, `video_description`, `username`, `id`. [SOURCE: https://developers.tiktok.com/doc/research-api-specs-query-videos/]
- **Records per request**: default 20, max 100.
- **Auth**: client credentials flow via `/v2/oauth/token/`. Required OAuth scope `research.data.basic`. Research API access is application-gated (must be approved institutional researcher).
- **Rate limits**: 1,000 requests/day → up to 100,000 records/day across the Research API family (video + comments). Public rate-limit page only enumerates 3 generic endpoints at 600 req each (insufficient granularity — see "Ruled Out"). HTTP 429 `rate_limit_exceeded` on overflow; no official retry-after guidance. [SOURCE: https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit, https://developers.tiktok.com/doc/research-api-faq]
- **Retention curves**: NOT available from Research API. No `average_view_percentage`, no per-segment retention. Only aggregate `view_count` + `video_duration`. This is a HARD GAP for L7's retention-curve feedback channel to L3.
- **Latency**: not documented. Empirical community reports (memory from `004-platform-upload-deepdive`) indicate T+1h to T+24h.
- **Creator vs Business**: Research API requires academic/research approval and returns PUBLIC videos only. For first-party Creator/Business account analytics, the Business API / Display API is needed (docs path returned 404 both times — deprecation suspected).
- **2026 Breaking changes**: None surfaced in fetched docs; TikTok Business API overview URL is 404ing [INFERENCE: URL restructuring likely; follow-up needed iteration 2].

### YOUTUBE

- **Endpoint**: `GET https://youtubeanalytics.googleapis.com/v2/reports` [SOURCE: https://developers.google.com/youtube/analytics/reference/reports/query, doc updated 2026-01-15]
- **Metrics**: `views`, `estimatedMinutesWatched`, `averageViewDuration`, `averageViewPercentage`, `subscribersGained`, `likes`, `dislikes`. Additional reports (audienceRetention, impressions, clickThroughRate) available via separate channel/contentOwner report types.
- **Auth (OAuth 2.0 scopes)**:
  - `https://www.googleapis.com/auth/yt-analytics.readonly` — core analytics
  - `https://www.googleapis.com/auth/yt-analytics-monetary.readonly` — revenue/ad metrics
  - `https://www.googleapis.com/auth/youtube.readonly` — now also required by reports.query method
- **Rate limits/quota**: NOT listed on this specific endpoint page [INFERENCE: follows YouTube Data API v3 quota model — 10,000 quota units/day default, per-project; Analytics API costs are typically 1–50 units/call depending on report type. Needs confirmation iteration 2 via `/docs/quota-and-usage`].
- **Access token TTL**: Google OAuth default 3,600s; refresh token non-expiring unless revoked. [INFERENCE: based on Google OAuth 2.0 standard, not stated in endpoint doc].
- **Latency**: "up until the last day for which all metrics in the query are available at the time of the query. The response for a query with the `day` dimension will not contain rows for the most recent days." → practical latency T+24h to T+48h for daily reports; near-real-time via separate `realtime` reports endpoint.
- **Retention curves**: YES — `audienceRetention` report provides elapsed-video-ratio × audienceWatchRatio × relativeRetentionPerformance. This is the richest retention signal across all 4 platforms.
- **Channel owner vs Content owner**: content owner reports restricted to YouTube Partner Program members. `includeHistoricalChannelData` applies to content owner only.
- **2026 changes**: none called out in fetched doc.

### INSTAGRAM (Graph API v25)

- **Endpoint**: `GET /<INSTAGRAM_MEDIA_ID>/insights` [SOURCE: https://developers.facebook.com/docs/instagram-platform/reference/instagram-media/insights/]
- **Metrics by media type (April 2026)**:
  - **Reels**: `views`, `reach`, `total_interactions`, `likes`, `comments`, `shares`, `saved`, `ig_reels_avg_watch_time`, `ig_reels_video_view_total_time`. DEPRECATED: `plays`, `clips_replays_count`, `ig_reels_aggregated_all_plays_count`.
  - **Feed posts**: `views`, `reach`, `likes`, `comments`, `shares`, `saved`, `total_interactions`, `profile_visits`, `profile_activity`, `follows`. DEPRECATED (v22+): `impressions`.
  - **Stories**: `views`, `reach`, `navigation`, `replies`, `shares`, `total_interactions`, `profile_visits`, `profile_activity`, `follows`. DEPRECATED: `impressions`.
  - **Video** category: `video_views` deprecated, no sunset date — migrate to `views`.
- **New Dec 2025 metrics (now available)**: [SOURCE: https://developers.facebook.com/blog/post/2025/12/03/instragram-api-updates/]
  1. `reels_skip_rate` — % of views skipping within first 3s (CRITICAL hook-quality signal for L3 prompt tuning)
  2. `reposts` at media level
  3. `reposts` at account level
  4. `profile_visits` via Marketing API (ad-driven only)
  5. `crossposted_views` + `facebook_views` — cross-platform reach
- **Permissions**:
  - Instagram Login: `instagram_business_basic` + `instagram_business_manage_insights`
  - Facebook Login: `instagram_basic` + `instagram_manage_insights` + `pages_read_engagement`
- **Token TTL**: short-lived User access token (~1h) → exchange for long-lived 60-day token; Page access tokens inherit. [INFERENCE: standard Graph API pattern; not restated in endpoint doc].
- **Rate limits**: Graph API BUC (Business Use Case) — Instagram uses 200 * num_impressions formula per user per hour, throttled via `X-App-Usage` / `X-Business-Use-Case-Usage` headers. [INFERENCE: Graph API platform-wide model; not restated in endpoint doc].
- **Retention curves**: PARTIAL — `ig_reels_avg_watch_time` + `ig_reels_video_view_total_time` give aggregate-only watch time, NOT per-segment retention curves. New `reels_skip_rate` provides a single drop-off gate (first 3s).
- **Business vs Creator**: Insights require Professional account (Business OR Creator). Insights endpoint supports both; Marketing API profile_visits is Business-ad-only.
- **2026 Breaking changes**: `impressions` deprecated for v22+ for post-Jul 2024 media; 4 Reels metrics sunset April 21, 2025 (already inactive in April 2026). IG Media Deleting API new.

### FACEBOOK

- **Endpoint**: `GET /{object-id}/insights/{metric}` or `?metric=m1,m2,...` [SOURCE: https://developers.facebook.com/docs/graph-api/reference/v21.0/insights]
- **Video metrics**: `post_video_views` (plays ≥3s or near-completion), `post_video_views_unique`, `post_video_avg_time_watched` (ms), `post_video_view_time` (total), `post_video_retention_graph` (per-segment % plays — THIS IS FACEBOOK'S RETENTION CURVE), `post_video_complete_views_30s`, `post_impressions*`, `post_reactions_*_total`.
- **Permissions**: `read_insights` + `pages_read_engagement`; Page access token required with ANALYZE task capability.
- **Rate limits**: generic Graph API BUC (same model as Instagram); specific error 80001 "There have been too many calls to this Page account". `since`/`until` restricted to 90-day window in a single call.
- **Token TTL**: Page access tokens can be long-lived (effectively non-expiring if derived from long-lived User token) — [INFERENCE: standard Graph pattern; doc does not restate].
- **Latency**: "Most metrics will update once every 24 hours" → T+24h canonical.
- **Retention curves**: YES — `post_video_retention_graph` provides per-segment retention. Second-best retention curve after YouTube.
- **Pages vs Personal**: Pages only, must have ≥100 likes for insights access. Personal profiles not supported.
- **2026 Breaking change (CRITICAL)**: "By June 15, 2026, a number of the Page Insights metrics will be deprecated for all API versions." → L7 design must pin a specific Graph API version and have a deprecation-watch task in the ingestion pipeline.

### Cross-Platform Comparison Table

| Dimension | TikTok (Research) | YouTube Analytics | Instagram (IG Graph v25) | Facebook (Graph v21) |
|---|---|---|---|---|
| Core endpoint | `/v2/research/video/query/` POST | `/v2/reports` GET | `/{media}/insights` GET | `/{object}/insights` GET |
| Views field | `view_count` | `views` | `views` | `post_video_views` |
| Watch-time field | `video_duration` × implied | `estimatedMinutesWatched`, `averageViewDuration` | `ig_reels_avg_watch_time`, `ig_reels_video_view_total_time` | `post_video_avg_time_watched`, `post_video_view_time` |
| Retention CURVE | NONE (hard gap) | `audienceRetention` report (BEST) | `reels_skip_rate` (first 3s only) | `post_video_retention_graph` |
| Auth scope | `research.data.basic` | `yt-analytics.readonly` (+optional monetary) | `instagram_business_manage_insights` | `read_insights` + `pages_read_engagement` |
| Rate limit | 1,000 req/day + 100k records/day | ~10k quota units/day (inferred) | BUC formula 200*impressions/hr | BUC formula + 90-day since/until window |
| Latency | T+1h to T+24h (undocumented) | T+24h to T+48h (daily dim) | T+24h (inferred) | T+24h explicitly |
| Account types | Research = public only; Business/Creator via 404-ing Business API | Channel owner; Content owner extras need YPP | Professional (Business OR Creator) | Pages only, ≥100 likes |
| 2026 break | Business API URL 404 (investigate) | None surfaced | `impressions` deprecated v22+ | Major deprecation June 15, 2026 |

## Ruled Out (this iteration)

- **CocoIndex codebase search** — daemon failed with `PermissionError: [WinError 5]` on Windows named-pipe creation. Not retrying this iteration. Fallback: use memory packet references and Grep for subsequent lookups.
- **TikTok Business Analytics API via `/doc/tiktok-api-v2-video-query` and `/doc/business-api-overview`** — both returned 404. URL paths appear to have been restructured. Do not retry these exact URLs; instead start from `developers.tiktok.com` root or the Marketing API docs tree in iteration 2.
- **TikTok public rate-limit page as authoritative source** — contains only 3 endpoints at 600 req each and no per-minute granularity. Use Research API FAQ (1,000/day + 100k records/day) as canonical until a better source surfaces.

## Dead Ends

None definitively eliminated yet. "Ruled Out" items are iteration-local setbacks, not structural dead ends.

## Sources Consulted

- https://developers.google.com/youtube/analytics/reference/reports/query (updated 2026-01-15)
- https://developers.facebook.com/docs/graph-api/reference/v21.0/insights
- https://developers.tiktok.com/doc/research-api-specs-query-videos/
- https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit
- https://developers.tiktok.com/doc/research-api-faq (via WebSearch citation — 1,000/day + 100k records/day)
- https://developers.facebook.com/docs/instagram-platform/reference/instagram-media/insights/ (Graph API v25)
- https://developers.facebook.com/blog/post/2025/12/03/instragram-api-updates/
- Memory packet: `project_platform_upload.md` (L2 memory hit on rate limits cross-check)

## Assessment

- **New information ratio**: 0.85
  - 9 findings in cross-platform table are net-new to this spec folder
  - 1 finding (BUC rate-limit headers) is INFERENCE from Graph API family knowledge, counted as partial (0.5)
  - 1 finding (YouTube quota) is INFERENCE, counted as partial (0.5)
  - `(8 fully_new + 2 * 0.5) / 10 = 0.90` → conservative 0.85 for honesty on TikTok 404 gaps
- **Questions addressed**: Q1 (fully)
- **Questions answered**: Q1 marked as answered with caveats (TikTok Business API branch needs iteration 2 follow-up)

## Reflection

- **What worked and why**: Parallel WebFetch against official docs was high signal. Domain-filtered WebSearch (`developers.tiktok.com`, `developers.facebook.com`) successfully rescued 404s within 1 call. Fetching the blog post (`Dec 2025 IG updates`) surfaced `reels_skip_rate` — a CRITICAL L7-to-L3 signal that would have been missed from the reference docs alone. Causal pattern: always fetch BOTH the stable reference page AND the latest release notes.
- **What didn't work and why**: CocoIndex daemon broken on Windows (named-pipe permission). TikTok Business API docs restructured — direct URL guessing failed. Root cause: both are environment/documentation churn issues, not research-methodology failures.
- **What I would do differently**: Iteration 2 should start TikTok discovery from the developers.tiktok.com sitemap or root navigation rather than guessing URL paths. For Graph API rate limits, hit the dedicated `/docs/graph-api/overview/rate-limiting` page directly rather than inferring from the endpoint page.

## Recommended Next Focus

**Iteration 2 (Q2): Ingestion pipeline architecture.** Specifically:
1. Given the 4-platform latency gradient (T+1h to T+48h), what is the optimal polling cadence + storage schema to feed L3 Content Lab?
2. Reconciliation pattern: handle late-arriving metrics (YouTube T+48h for `day` dimension), idempotent upserts on `(content_id, platform_post_id, metric_date)` composite key.
3. Postgres/Prisma schema sketch for `performance_metrics` table — Prisma 7.4 per base-app research; column set for normalized cross-platform metrics (views, watch_time_ms, retention_curve JSONB, engagement_count, reach, impressions, shares, saves, completion_rate, skip_rate_3s).
4. Dead-letter + retry for rate-limit hits (TikTok 1k/day budget is tight — need prioritization).
5. Also resolve 2 carry-overs: (a) exact TikTok Business API endpoints (iteration 2 start URL: developers.tiktok.com root nav), (b) confirm YouTube Analytics quota units per report type.

Secondary: sketch `retention_curve` JSONB canonical shape since YouTube gives full curve, Facebook gives graph, Instagram gives only single-point skip, TikTok gives nothing.
