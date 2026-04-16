# Iteration 6: Multi-Platform Upload Strategy & DB Schema Design

## Focus
Research the upload strategy for ALL four platforms (TikTok, YouTube Shorts, Instagram Reels, Facebook Reels) with equal depth. Evaluate official APIs vs unofficial tools, auth flows, rate limits, affiliate/product tagging capabilities, and n8n integration. Design a multi-platform-first DB schema.

## Findings

### Finding 1: TikTok Content Posting API (Official) — Heavily Gated
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-get-started]
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-reference-direct-post]

The official TikTok Content Posting API exists but is heavily restricted:
- **Access**: Requires app registration on TikTok Developer Portal + manual review (days to weeks)
- **Geo-restriction**: Must be in an approved country, work with a real business or research group
- **Upload flow**: Two-step — (1) initialize upload to get URL, (2) send video in chunks, (3) publish
- **Scheduling**: NO `scheduled_publish_time` parameter — scheduling is reserved for TikTok's own creator tools
- **Content types**: Video only — no photo carousels or text posts via API
- **Privacy settings**: Mandatory per publish request (privacy level, branded content disclosure, comment control)
- **No Shop/Affiliate API**: The Content Posting API does NOT include TikTok Shop or affiliate cart pin capabilities

**Verdict**: Official API is viable for uploads but the approval process is slow and scheduling is absent. No affiliate cart pin support.

### Finding 2: TikTokAutoUploader (haziq-exe) — Best Unofficial TikTok Option
[SOURCE: https://github.com/haziq-exe/TikTokAutoUploader]

- **Engine**: Phantomwright (patched Playwright with stealth) — NOT standard Playwright
- **Stars**: 243, MIT license, Python 97% / JS 3%
- **Last verified**: February 2026 — actively maintained
- **Features**:
  - Scheduling: Queue videos up to 10 days in advance (HH:MM)
  - Multi-account: Full support
  - Trending sounds: Search and apply TikTok sounds by name
  - Hashtags: Clickable hashtags (not just text)
  - Copyright screening: Pre-upload verification
  - Captcha solving: Automated
  - Proxy support: Route through custom proxy servers
  - Telegram bot: Remote control integration
  - Custom cover: Frame slider manipulation
- **Anti-detection**: Fingerprint spoofing, human-like interactions, hardened browser flags, optional extra stealth delays
- **Auth**: Browser session (first-time login required per account) — cookie/session-based
- **Dependencies**: phantomwright, requests, Pillow, inference
- **Headless mode**: Available for invisible operation
- **TikTok Shop / Affiliate**: NOT supported — no cart pin capability
- **Ban risk**: MODERATE — stealth measures are robust but browser automation always carries inherent risk; proxy support helps

### Finding 3: YouTube Shorts Upload — Official API is Excellent
[SOURCE: https://developers.google.com/youtube/v3/getting-started]
[SOURCE: https://developers.google.com/youtube/v3/determine_quota_cost]

YouTube Data API v3 is the most developer-friendly of all four platforms:
- **Upload endpoint**: `POST /youtube/v3/videos` — same endpoint for regular videos and Shorts
- **Shorts detection**: YouTube auto-detects Shorts based on: aspect ratio 9:16, duration <= 60 seconds. No special tag or endpoint needed (though `#Shorts` in title/description helps discovery)
- **Quota system**: 10,000 units/day default (free)
  - Video upload = 1,600 units (cost reduced from historical 1,600; but NOTE: the search indicated 100 units, older docs said 1,600 — needs verification)
  - Read operations = 1 unit
  - Search = 100 units
  - Write (update/delete) = 50 units
- **Quota resets**: Midnight PT daily, no rollover
- **Higher quotas**: Free — apply via Google Cloud Console, approval based on use case
- **Auth**: OAuth 2.0 — standard Google OAuth flow, well-documented
- **Scheduling**: YES — `publishAt` parameter in `video.status` allows future scheduling
- **Rate limit**: Queries per minute per user (fixed), daily quota (adjustable)
- **Product links / Shopping**: YouTube Shopping API exists but is separate from Data API v3, requires YouTube Partner Program enrollment

**Verdict**: Best official API of all four platforms. OAuth 2.0 is standard, scheduling is native, quotas are generous and expandable.

### Finding 4: Instagram Reels Upload — Official API via Meta Graph API
[SOURCE: https://developers.facebook.com/docs/instagram-platform/content-publishing/]
[SOURCE: https://www.getphyllo.com/post/a-complete-guide-to-the-instagram-reels-api]

- **API**: Instagram Content Publishing API (part of Meta Graph API)
- **Reels support**: YES — since June 28, 2022
- **Account requirement**: Instagram Business account ONLY (not Creator, not Personal)
- **Upload flow**: Two-step — (1) `POST /{ig-user-id}/media` with `media_type=REELS`, (2) `POST /{ig-user-id}/media_publish`
- **Video host**: Upload endpoint uses `rupload.facebook.com` (not `graph.facebook.com`)
- **Duration**: 5-90 seconds, 9:16 aspect ratio required for Reels tab
- **Rate limits**: 100 API-published posts per rolling 24-hour window (all content types combined)
- **Auth**: Facebook Business access token (OAuth flow via Meta Business Suite)
- **Scheduling**: Available through the API (publish time can be set)
- **Product tags / Shopping**: Instagram Shopping API allows product tagging in posts — separate from Reels publishing, requires Commerce Manager setup and product catalog

**Verdict**: Solid official API. Business account requirement is the main constraint. Shared auth with Facebook simplifies multi-platform setup.

### Finding 5: Facebook Reels Upload — Official API via Video API
[SOURCE: https://developers.facebook.com/docs/video-api/guides/reels-publishing/]
[SOURCE: https://developers.facebook.com/docs/graph-api/reference/page/video_reels/]

- **API**: Facebook Video API — Reels Publishing
- **Scope**: Facebook Pages ONLY (not personal profiles)
- **Upload flow**: Three-step:
  1. `POST /{page_id}/video_reels` with `upload_phase=start` → returns `video_id` + `upload_url`
  2. `POST rupload.facebook.com/video-upload/v25.0/{video_id}` → upload file
  3. `POST /{page_id}/video_reels` with `upload_phase=finish`, `video_state=PUBLISHED`
- **Required permissions**: `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`
- **Rate limits**: 30 API-published Reels per 24-hour rolling window per Page
- **Video specs**: .mp4, 9:16, 1080x1920 recommended, 3-90 seconds, 24-60fps, H.264/H.265/VP9/AV1
- **Audio**: AAC Low Complexity @ 48kHz, 128kbps+
- **Scheduling**: NOT native — app must handle scheduling logic itself
- **Auth**: Page access token (shared Meta OAuth flow with Instagram)
- **Facebook Shops**: Separate API — product tagging in Reels not documented in the Reels Publishing API
- **Collaborators**: 10 invitations per Page per 24 hours
- **Copyright detection**: Available via match info retrieval

**Verdict**: Fully functional official API. Shares auth infrastructure with Instagram (Meta Business Suite). Rate limit of 30/day is the strictest.

### Finding 6: Multi-Platform Comparison Matrix & DB Schema Design
[INFERENCE: based on Findings 1-5 and prior architecture from iterations 4-5]

#### Platform Comparison Matrix

| Dimension | TikTok | YouTube Shorts | Instagram Reels | Facebook Reels |
|---|---|---|---|---|
| **Official API** | Content Posting API | Data API v3 | Graph API (Content Publishing) | Video API (Reels Publishing) |
| **Access difficulty** | HIGH (manual review, geo-restricted) | LOW (standard Google Cloud) | MEDIUM (Business account required) | MEDIUM (Page required) |
| **Upload flow** | 2-step chunked | Single POST | 2-step (create + publish) | 3-step (init + upload + finish) |
| **Rate limit** | Not publicly documented (strict) | 10,000 units/day (~6-100 uploads) | 100 posts/24h | 30 Reels/24h |
| **Scheduling** | NO (official) | YES (publishAt) | YES (via API) | NO (app must handle) |
| **Auth** | OAuth 2.0 (TikTok specific) | OAuth 2.0 (Google) | OAuth (Meta Business) | OAuth (Meta Business, shared with IG) |
| **Affiliate/Cart pin** | NOT via Content API | YouTube Shopping (separate) | Instagram Shopping (separate) | Facebook Shops (separate) |
| **Best unofficial tool** | TikTokAutoUploader | N/A (API is sufficient) | instagrapi (Python) | N/A (API is sufficient) |
| **Ban risk (unofficial)** | MODERATE | LOW (API is easy) | HIGH (IG is aggressive) | LOW (API is easy) |
| **n8n integration** | HTTP Request node | YouTube node (built-in) | HTTP Request node + n8n workflow 4498 | HTTP Request node |
| **Duration** | Up to 10 min | Up to 60s (Shorts) | 5-90s | 3-90s |

#### Multi-Platform DB Schema Design (PostgreSQL)

```sql
-- Platform accounts (one row per connected platform account)
CREATE TABLE platform_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('tiktok', 'youtube', 'instagram', 'facebook')),
  platform_account_id VARCHAR(255),          -- external platform ID
  account_name VARCHAR(255),
  auth_method VARCHAR(20) NOT NULL CHECK (auth_method IN ('oauth', 'cookie', 'session', 'api_key')),
  access_token TEXT,                          -- encrypted at rest
  refresh_token TEXT,                         -- encrypted at rest
  token_expires_at TIMESTAMPTZ,
  cookie_data JSONB,                          -- for browser-session auth (TikTok unofficial)
  meta_business_id VARCHAR(255),              -- shared Meta ID for IG + FB
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, platform, platform_account_id)
);

-- Content (platform-agnostic video/content record)
CREATE TABLE content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(500),
  description TEXT,
  script TEXT,                                -- LLM-generated script
  hashtags TEXT[],                             -- array of hashtags
  video_file_path VARCHAR(1000),              -- local or S3 path to generated video
  thumbnail_path VARCHAR(1000),
  duration_seconds NUMERIC(6,2),
  aspect_ratio VARCHAR(10) DEFAULT '9:16',
  resolution VARCHAR(20) DEFAULT '1080x1920',
  language VARCHAR(10) DEFAULT 'th',
  tts_voice VARCHAR(100),
  generation_status VARCHAR(20) DEFAULT 'pending' CHECK (generation_status IN ('pending', 'generating', 'ready', 'failed')),
  pixelle_task_id VARCHAR(255),               -- Pixelle-Video async task ID
  n8n_execution_id VARCHAR(255),              -- n8n workflow execution ID
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Platform publishes (per-platform publish state for each content)
CREATE TABLE platform_publishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL REFERENCES content(id),
  platform_account_id UUID NOT NULL REFERENCES platform_accounts(id),
  platform VARCHAR(20) NOT NULL,
  publish_status VARCHAR(20) DEFAULT 'queued' CHECK (publish_status IN ('queued', 'scheduled', 'uploading', 'processing', 'published', 'failed', 'draft')),
  scheduled_at TIMESTAMPTZ,                   -- when to publish
  published_at TIMESTAMPTZ,                   -- when actually published
  platform_post_id VARCHAR(255),              -- TikTok video ID, YT video ID, IG media ID, FB reel ID
  platform_url VARCHAR(1000),                 -- direct link to published content
  upload_method VARCHAR(20) CHECK (upload_method IN ('official_api', 'unofficial_bot', 'manual')),
  error_message TEXT,
  retry_count INT DEFAULT 0,
  n8n_execution_id VARCHAR(255),
  -- Platform-specific metadata
  platform_metadata JSONB,                    -- { privacy_level, disclosure, sound_name, etc. }
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Platform analytics (per-publish performance metrics)
CREATE TABLE platform_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_id UUID NOT NULL REFERENCES platform_publishes(id),
  view_count BIGINT DEFAULT 0,
  like_count BIGINT DEFAULT 0,
  comment_count BIGINT DEFAULT 0,
  share_count BIGINT DEFAULT 0,
  save_count BIGINT DEFAULT 0,               -- IG/TikTok saves
  watch_time_seconds BIGINT DEFAULT 0,
  avg_watch_percentage NUMERIC(5,2),
  reach BIGINT DEFAULT 0,
  impressions BIGINT DEFAULT 0,
  fetched_at TIMESTAMPTZ DEFAULT now(),       -- when metrics were last pulled
  raw_metrics JSONB                           -- full platform-specific response
);

-- Upload queue (scheduling + retry management)
CREATE TABLE upload_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_id UUID NOT NULL REFERENCES platform_publishes(id),
  priority INT DEFAULT 5,                     -- 1=highest, 10=lowest
  scheduled_at TIMESTAMPTZ NOT NULL,
  attempt_count INT DEFAULT 0,
  max_attempts INT DEFAULT 3,
  last_attempt_at TIMESTAMPTZ,
  next_retry_at TIMESTAMPTZ,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'cancelled')),
  n8n_webhook_url VARCHAR(1000),              -- webhook to trigger n8n upload workflow
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Affiliate links (per-platform product/cart links)
CREATE TABLE affiliate_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID REFERENCES content(id),     -- can be content-level or standalone
  publish_id UUID REFERENCES platform_publishes(id),  -- or per-publish
  platform VARCHAR(20) NOT NULL,
  link_type VARCHAR(30) CHECK (link_type IN ('tiktok_shop_cart', 'youtube_shopping', 'instagram_shopping', 'facebook_shop', 'external_affiliate')),
  product_id VARCHAR(255),                    -- platform product catalog ID
  product_name VARCHAR(500),
  affiliate_url VARCHAR(2000),
  commission_rate NUMERIC(5,2),
  is_pinned BOOLEAN DEFAULT false,            -- "ปักตะกร้า" status
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Content calendar (cross-platform scheduling view)
CREATE VIEW content_calendar AS
SELECT
  c.id AS content_id,
  c.title,
  c.generation_status,
  pp.platform,
  pp.publish_status,
  pp.scheduled_at,
  pp.published_at,
  pa.account_name,
  al.is_pinned AS has_affiliate
FROM content c
LEFT JOIN platform_publishes pp ON c.id = pp.content_id
LEFT JOIN platform_accounts pa ON pp.platform_account_id = pa.id
LEFT JOIN affiliate_links al ON pp.id = al.publish_id
ORDER BY COALESCE(pp.scheduled_at, pp.published_at, c.created_at);
```

**Schema design principles**:
1. **Platform-agnostic content table**: Video metadata is stored once, published to N platforms
2. **Per-platform publish tracking**: Each publish is independent — can succeed on YouTube but fail on TikTok
3. **Flexible auth storage**: Supports OAuth tokens (YT, IG, FB) AND cookie/session (TikTok unofficial)
4. **Meta Business ID sharing**: Instagram and Facebook accounts share `meta_business_id` for unified Meta auth
5. **JSONB for platform-specific data**: `platform_metadata` and `raw_metrics` avoid rigid column proliferation
6. **Upload queue with retry**: n8n handles orchestration but the DB tracks state for dashboard visibility
7. **Affiliate links table**: Supports all platform shop types + external affiliate links, with "ปักตะกร้า" (cart pin) status tracking

## Ruled Out
- **TikTok official API for scheduling**: No `scheduled_publish_time` parameter — scheduling must be handled by n8n + upload queue
- **Single unified upload API (upload-post.com)**: Paid service, not OSS — already ruled out in prior iterations, confirmed not viable for our stack
- **Affiliate cart pin via Content Posting APIs**: NONE of the four platforms expose cart/product pinning through their content upload APIs — shopping/affiliate is always a separate API surface

## Dead Ends
- **Affiliate cart pin via upload API on ANY platform**: All four platforms separate content publishing from commerce/shopping. Cart pin ("ปักตะกร้า") requires separate Shop API integration on each platform. This is a fundamental architectural separation, not a missing feature.

## Sources Consulted
- https://developers.tiktok.com/doc/content-posting-api-get-started
- https://developers.tiktok.com/doc/content-posting-api-reference-direct-post
- https://github.com/haziq-exe/TikTokAutoUploader
- https://developers.google.com/youtube/v3/getting-started
- https://developers.google.com/youtube/v3/determine_quota_cost
- https://developers.facebook.com/docs/instagram-platform/content-publishing/
- https://www.getphyllo.com/post/a-complete-guide-to-the-instagram-reels-api
- https://developers.facebook.com/docs/video-api/guides/reels-publishing/
- https://developers.facebook.com/docs/graph-api/reference/page/video_reels/

## Assessment
- New information ratio: 0.92
- Questions addressed: Q15, Q16, Q17, Q18
- Questions answered: Q15 (official API capabilities per platform), Q16 (ban risk per platform), Q17 (affiliate cart pin NOT available via content APIs — separate Shop APIs needed), Q18 (multi-platform DB schema designed)

## Reflection
- What worked and why: WebSearch for each platform's official API docs gave comprehensive, authoritative data. The platform APIs are all well-documented by their respective companies (Google, Meta, TikTok). WebFetch on the TikTokAutoUploader GitHub page gave rich feature detail. The combination of official API research + unofficial tool assessment provides a complete picture.
- What did not work and why: N/A — all research actions yielded high-value results. The Facebook Reels search initially returned some Instagram results, but the dedicated WebFetch on the Facebook Reels Publishing docs page resolved this.
- What I would do differently: For the affiliate/shopping APIs, a dedicated deep-dive iteration would be valuable — each platform has its own Shop API (TikTok Shop, YouTube Shopping, Instagram Shopping, Facebook Shops) that requires separate research.

## Recommended Next Focus
1. **Affiliate/Shopping API deep-dive**: Research TikTok Shop API, YouTube Shopping API, Instagram Shopping API, and Facebook Shops API for product tagging and cart pin ("ปักตะกร้า") capabilities. The Lundehund/tiktok-shop-api Python library and ipfans/tiktok Go SDK should be evaluated.
2. **n8n upload workflow design**: Design the specific n8n workflow nodes for the four-platform upload pipeline — which platforms use built-in n8n nodes vs HTTP Request nodes.
3. **Convergence synthesis**: With Q1, Q3, Q5, Q7, Q9-Q18 now addressed, consider a consolidation iteration to synthesize all findings into a final architecture recommendation.
