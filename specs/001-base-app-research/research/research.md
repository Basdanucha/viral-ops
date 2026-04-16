# viral-ops: Definitive Architecture Document

> Final convergence synthesis from 13 research iterations (April 2026). All 27 key questions answered. Architecture ready for implementation.

---

## 1. Executive Summary

**viral-ops** is an AI-driven viral content lifecycle platform that automates the full pipeline from trend discovery through content production, multi-platform distribution, affiliate monetization, and performance-driven feedback loops. It supports two entry paths -- trend-driven (Path A) and product-driven (Path B) -- converging into a shared production-distribution-feedback backbone.

**The stack** runs as three localhost services on Windows for Phase 1 (solo-use):
- **Dashboard**: next-saas-stripe-starter (Next.js 14 App Router, Auth.js v5, Prisma, PostgreSQL) on `:3000`
- **Orchestrator**: n8n (self-hosted, SQLite state) on `:5678`
- **Video Engine**: Pixelle-Video (FastAPI, ComfyUI, Edge-TTS) on `:8000`

**Key architectural decisions:**
1. n8n eliminates the need for any job queue (BullMQ, pg-boss, Inngest) in the dashboard
2. Pixelle-Video provides a built-in FastAPI REST API with 9 routers -- no wrapper needed
3. Multi-channel identity flows through a single n8n pipeline with dynamic channel config injection from DB
4. Intelligence layers (Trend, Viral Brain, Content Lab, Feedback) are n8n-orchestrated workflows calling LLM and analytics APIs
5. All platforms handle shopping/affiliate separately from content upload -- no unified cart pin approach exists

---

## 2. Complete Technology Stack

```
LAYER              COMPONENT                    VERSION/DETAIL          LICENSE          PORT
-----------------------------------------------------------------------------------------------
DASHBOARD          next-saas-stripe-starter     Next.js 14 App Router   MIT              :3000
  Framework        Next.js                      14.x                    MIT
  Language         TypeScript                   5.x                     Apache 2.0
  ORM              Prisma                       5.x                     Apache 2.0
  Database         PostgreSQL                   16.x                    PostgreSQL
  Auth             Auth.js (NextAuth v5)        5.x                     ISC
  UI Components    ShadCN UI                    latest                  MIT
  Charts           Tremor                       3.x                     Apache 2.0
  CSS              Tailwind CSS                 3.x                     MIT
  Email            Resend                       (cloud service)         --

ORCHESTRATOR       n8n                          1.x                     Sustainable Use   :5678
  Runtime          Node.js                      18+                     MIT
  State            SQLite                       (bundled)               Public Domain
  Install          npx n8n                      (Phase 1)               --

VIDEO ENGINE       Pixelle-Video                0.1.15+                 Apache 2.0       :8000
  API              FastAPI                      0.100+                  MIT
  TTS              Edge-TTS                     (Microsoft cloud)       MIT client
  Image Gen        ComfyUI                      latest                  GPL-3.0 (separate process)
  Cloud GPU        RunningHub                   (optional service)      --
  LLM              GPT-4 / DeepSeek / Ollama    (configurable)          varies
  Composition      FFmpeg                       (bundled)               LGPL-2.1

UPLOAD LAYER
  TikTok           TikTokAutoUploader           latest                  MIT
  YouTube          YouTube Data API v3          (Google service)         --
  Instagram        Meta Graph API               v21.0                   --
  Facebook         Facebook Video API           v21.0                   --

SHOPPING/AFFILIATE
  Instagram        Product Tagging API          (Meta Graph API)        --
  TikTok           TikTok Shop Affiliate API    (Partner Center API)    --
  YouTube          Manual (YouTube Studio)       --                      --
  Facebook         Meta Commerce Manager        (shared with IG)        --

INTELLIGENCE
  Trend Scraping   snscrape                     latest                  --
  Google Trends    pytrends                     latest                  MIT
  Topic Clustering BERTopic                     (or TF-IDF fallback)    MIT
  Viral Scoring    LLM-as-judge (Phase 1)       GPT-4/DeepSeek          --
  ML Model         GBDT (Phase 2)               LightGBM/XGBoost       MIT

PRODUCT DISCOVERY (Path B)
  TikTok Shop      Affiliate APIs               (GA 2024)               --
  Shopee           Public API v4                (Thailand)              --
  Lazada           Open Platform API            REST                    --
  Affiliate Net    Involve Asia / AccessTrade   (Lazada deep links)     --
```

**License audit**: Entire stack permissively licensed (MIT + Apache 2.0). No AGPL. ComfyUI (GPL-3.0) runs as separate process communicating via API -- GPL does not infect calling software. n8n Sustainable Use License allows free self-hosted use; only restricts offering n8n as managed SaaS.

---

## 3. Full Architecture Diagram

```
+==============================================================================+
|  VIRAL-OPS Phase 1: Three-Service Localhost (Windows)                        |
|                                                                              |
|  +-------------------------+                                                 |
|  |  DASHBOARD              |                                                 |
|  |  Next.js 14 App Router  |                                                 |
|  |  :3000                  |                                                 |
|  |                         |     POST webhook / REST API                     |
|  |  Pages:                 |------------------------------------+            |
|  |  - Pipeline Status      |                                    |            |
|  |  - Content Calendar     |                                    v            |
|  |  - Platform Analytics   |          +-------------------------+-------+    |
|  |  - Upload Queue         |          |  ORCHESTRATOR                    |    |
|  |  - Channel Management   |          |  n8n :5678                       |    |
|  |  - Account Management   |          |                                  |    |
|  |  - A/B Test Results     |          |  Workflows:                      |    |
|  |  - Trend Dashboard      |          |  - Trend Pipeline (cron 4-6h)    |    |
|  |  - Product Catalog      |          |  - Content Pipeline (on-demand)  |    |
|  |  - Settings/Auth        |<---------+  - Upload per Platform           |    |
|  +-------------------------+ poll     |  - Analytics Fetch (cron 6h)     |    |
|                              status   |  - A/B Test Scheduler            |    |
|                                       |  - Product Discovery (cron 4h)   |    |
|                                       |  - Error Recovery                |    |
|                                       |                                  |    |
|                                       |  State: SQLite                   |    |
|                                       +----------------+-----------------+    |
|                                                        |                      |
|                                           HTTP Request |nodes                 |
|                                                        v                      |
|                                       +-------------------------------+       |
|                                       |  VIDEO ENGINE                  |       |
|                                       |  Pixelle-Video FastAPI :8000   |       |
|                                       |                                |       |
|                                       |  /api/llm     -> LLM           |       |
|                                       |  /api/tts     -> Edge-TTS      |       |
|                                       |  /api/image   -> ComfyUI       |       |
|                                       |  /api/video   -> FFmpeg        |       |
|                                       |  /api/content -> Full pipeline |       |
|                                       |  /api/tasks   -> Job status    |       |
|                                       |  /api/files   -> File I/O      |       |
|                                       |  /api/resources -> Resources   |       |
|                                       |  /api/frame   -> Scene mgmt    |       |
|                                       +-------------------------------+       |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  DATABASE LAYER                                                        |    |
|  |                                                                        |    |
|  |  PostgreSQL (Dashboard)              SQLite (n8n)    Filesystem        |    |
|  |  -- Core Pipeline --                 - workflows     - generated      |    |
|  |  platform_accounts                   - executions      videos         |    |
|  |  content                             - credentials   - audio files    |    |
|  |  platform_publishes                                  - images         |    |
|  |  platform_analytics                                  - ComfyUI        |    |
|  |  upload_queue                                          workflows      |    |
|  |  affiliate_links                                                      |    |
|  |  -- Intelligence --                                                   |    |
|  |  trends                                                               |    |
|  |  products                                                             |    |
|  |  product_score_history                                                |    |
|  |  -- Content Lab --                                                    |    |
|  |  content_variants                                                     |    |
|  |  ab_tests                                                             |    |
|  |  -- Multi-Channel --                                                  |    |
|  |  channels                                                             |    |
|  |  channel_platform_accounts                                            |    |
|  |  channel_persona_history                                              |    |
|  |  -- View --                                                           |    |
|  |  content_calendar                                                     |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  EXTERNAL SERVICES (outbound from n8n)                                 |    |
|  |                                                                        |    |
|  |  Upload:                           Shopping/Affiliate:                 |    |
|  |  - TikTokAutoUploader (local)     - IG Product Tagging API (auto)     |    |
|  |  - YouTube Data API v3            - TikTok Shop Affiliate API (link)  |    |
|  |  - Instagram Graph API            - FB Commerce Manager (partial)     |    |
|  |  - Facebook Video API             - YouTube: manual only              |    |
|  |                                                                        |    |
|  |  Intelligence:                     Product Discovery:                  |    |
|  |  - snscrape (multi-platform)      - TikTok Shop API (search+link)     |    |
|  |  - pytrends (Google Trends)       - Shopee Public API v4              |    |
|  |  - YouTube Data API (trending)    - Lazada Open Platform              |    |
|  |  - TikTok Creative Center (scrape)- Involve Asia (Lazada deep links)  |    |
|  |                                                                        |    |
|  |  Cloud (optional):                 Analytics:                          |    |
|  |  - RunningHub (GPU image gen)     - YouTube Analytics API             |    |
|  |  - OpenAI / DeepSeek (LLM)        - TikTok Business API              |    |
|  |  - Edge-TTS (Microsoft)           - Instagram Insights API            |    |
|  |                                   - Facebook Insights API             |    |
|  +-----------------------------------------------------------------------+    |
+===============================================================================+
```

---

## 4. Complete Database Schema

### 4a. Core Pipeline Tables (Iteration 6)

```sql
-- Per-platform authentication and account management
platform_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform VARCHAR(20) NOT NULL,           -- 'tiktok' | 'youtube' | 'instagram' | 'facebook'
  account_name VARCHAR(255) NOT NULL,
  auth_type VARCHAR(20) NOT NULL,          -- 'oauth' | 'cookie' | 'api_key'
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  cookies_json JSONB,                      -- TikTokAutoUploader cookie storage
  meta_business_id VARCHAR(100),           -- Shared between IG + FB
  platform_user_id VARCHAR(100),
  platform_metadata JSONB,                 -- Platform-specific fields
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Platform-agnostic content record (one video = one row)
content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(500) NOT NULL,
  script_text TEXT,
  topic VARCHAR(255),
  niche VARCHAR(100),
  language VARCHAR(10) DEFAULT 'th',
  voice_id VARCHAR(100),
  video_file_path TEXT,
  audio_file_path TEXT,
  thumbnail_path TEXT,
  duration_seconds FLOAT,
  viral_score FLOAT,                        -- From Viral Brain
  score_breakdown JSONB,                    -- 6-dimension breakdown
  generation_metadata JSONB,                -- LLM model, ComfyUI workflow, etc.
  channel_id UUID REFERENCES channels(id),  -- Which channel produced this
  source_trend_id UUID REFERENCES trends(id),
  source_product_id UUID REFERENCES products(id),
  content_path VARCHAR(10),                 -- 'path_a' | 'path_b'
  status VARCHAR(20) DEFAULT 'draft',       -- draft | generating | ready | published | failed
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Per-platform publish state (1 content -> N platform publishes)
platform_publishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL REFERENCES content(id),
  platform_account_id UUID NOT NULL REFERENCES platform_accounts(id),
  platform VARCHAR(20) NOT NULL,
  platform_post_id VARCHAR(255),            -- Platform's ID after upload
  platform_url TEXT,
  status VARCHAR(20) DEFAULT 'pending',     -- pending | uploading | published | failed | removed
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  error_message TEXT,
  retry_count INT DEFAULT 0,
  platform_metadata JSONB,                  -- Platform-specific response data
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Per-publish performance metrics
platform_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_id UUID NOT NULL REFERENCES platform_publishes(id),
  pulled_at TIMESTAMPTZ NOT NULL,           -- When this snapshot was taken
  pull_type VARCHAR(10),                    -- 'early' (T+6h) | 'stable' (T+48h) | 'final' (T+168h)
  views BIGINT DEFAULT 0,
  likes BIGINT DEFAULT 0,
  comments BIGINT DEFAULT 0,
  shares BIGINT DEFAULT 0,
  saves BIGINT DEFAULT 0,
  watch_time_seconds FLOAT,
  avg_watch_duration FLOAT,
  retention_3s FLOAT,                       -- 3-second retention rate
  completion_rate FLOAT,
  engagement_rate FLOAT,
  reach BIGINT,
  impressions BIGINT,
  subscribers_gained INT,
  platform_raw JSONB,                       -- Full raw API response
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Upload scheduling and retry management
upload_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL REFERENCES content(id),
  platform_account_id UUID NOT NULL REFERENCES platform_accounts(id),
  scheduled_at TIMESTAMPTZ NOT NULL,
  priority INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'queued',      -- queued | processing | completed | failed | cancelled
  n8n_execution_id VARCHAR(100),
  retry_count INT DEFAULT 0,
  max_retries INT DEFAULT 3,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Per-platform affiliate/product links
affiliate_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID REFERENCES content(id),
  product_id UUID REFERENCES products(id),
  platform VARCHAR(20) NOT NULL,
  affiliate_url TEXT NOT NULL,
  product_name VARCHAR(500),
  commission_rate FLOAT,
  cart_pin_method VARCHAR(20),              -- 'api_auto' | 'api_partial' | 'manual' | 'pending'
  cart_pin_status VARCHAR(20) DEFAULT 'pending',
  click_count INT DEFAULT 0,
  conversion_count INT DEFAULT 0,
  revenue_total DECIMAL(12,2) DEFAULT 0,
  platform_metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cross-platform scheduling view
CREATE VIEW content_calendar AS
SELECT
  c.id AS content_id, c.title, c.status AS content_status,
  c.channel_id, ch.name AS channel_name,
  pp.platform, pp.scheduled_at, pp.published_at, pp.status AS publish_status,
  pa.account_name
FROM content c
JOIN platform_publishes pp ON pp.content_id = c.id
JOIN platform_accounts pa ON pa.id = pp.platform_account_id
LEFT JOIN channels ch ON ch.id = c.channel_id
ORDER BY COALESCE(pp.scheduled_at, pp.published_at) DESC;
```

### 4b. Intelligence Tables (Iterations 9, 11)

```sql
-- Scraped trend signals with momentum scoring
trends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform VARCHAR(20) NOT NULL,            -- Source platform
  topic VARCHAR(500) NOT NULL,
  hashtags TEXT[],
  cluster_id VARCHAR(100),                  -- BERTopic cluster assignment
  momentum_score FLOAT,                     -- Velocity * freshness * niche_fit * (1 - saturation)
  velocity FLOAT,                           -- Growth rate
  freshness FLOAT,                          -- Recency decay
  niche_fit FLOAT,                          -- Relevance to channel niches
  saturation FLOAT,                         -- Market saturation (higher = worse)
  sample_video_urls TEXT[],
  scraped_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,                   -- Trend expected lifetime
  status VARCHAR(20) DEFAULT 'active',      -- active | expired | used | rejected
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cross-platform product catalog (Path B)
products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform VARCHAR(20) NOT NULL,            -- 'tiktok_shop' | 'shopee' | 'lazada'
  platform_product_id VARCHAR(255) NOT NULL,
  name VARCHAR(500) NOT NULL,
  price DECIMAL(12,2),
  currency VARCHAR(3) DEFAULT 'THB',
  commission_rate FLOAT,
  sales_volume_30d INT,
  rating FLOAT,
  review_count INT,
  category VARCHAR(255),
  image_urls JSONB,
  product_url TEXT,
  cross_platform_group_id UUID,             -- Links same product across platforms
  product_score FLOAT,                      -- Weighted formula score (0-100)
  score_breakdown JSONB,                    -- Per-dimension scores
  last_scraped_at TIMESTAMPTZ,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product score versioning for ML training
product_score_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id),
  score FLOAT NOT NULL,
  score_version INT NOT NULL,
  breakdown JSONB,
  computed_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4c. Content Lab Tables (Iteration 10)

```sql
-- Hook variant tracking for A/B testing
content_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_topic_id UUID,                     -- Links variants of the same topic
  variant_label VARCHAR(10) NOT NULL,       -- 'A' | 'B'
  hook_text TEXT NOT NULL,
  hook_score FLOAT,                         -- LLM-as-judge score
  status VARCHAR(20) DEFAULT 'pending',     -- pending | posted | measured | winner | loser
  published_at TIMESTAMPTZ,
  measured_at TIMESTAMPTZ,
  retention_3s FLOAT,
  completion_rate FLOAT,
  engagement_rate FLOAT,
  total_views BIGINT,
  content_id UUID REFERENCES content(id),   -- Link to actual content record
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- A/B test pair management
ab_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID,
  variant_a_id UUID NOT NULL REFERENCES content_variants(id),
  variant_b_id UUID NOT NULL REFERENCES content_variants(id),
  status VARCHAR(20) DEFAULT 'running',     -- running | completed | inconclusive | cancelled
  winner_id UUID REFERENCES content_variants(id),
  confidence_note TEXT,                     -- "A beats B by 15% on retention_3s, 2100 vs 1800 views"
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4d. Multi-Channel Tables (Iteration 12)

```sql
-- Per-channel identity and configuration
channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  niche VARCHAR(100),
  sub_niche VARCHAR(100),
  target_audience TEXT,
  -- Pixelle-Video per-request params
  tts_voice VARCHAR(100),                   -- Maps to /api/tts voice_id param
  tts_workflow VARCHAR(100),                -- TTS workflow selection
  comfyui_workflow VARCHAR(100),            -- Maps to /api/image workflow param
  image_width INT DEFAULT 1080,
  image_height INT DEFAULT 1920,
  -- Persona config
  persona_name VARCHAR(100),
  persona_prompt TEXT,                      -- Full LLM system prompt for this channel
  tone_adjectives TEXT[],                   -- ['playful', 'sarcastic', 'authoritative']
  language_register VARCHAR(20),            -- 'casual' | 'formal' | 'slang'
  forbidden_topics TEXT[],
  preferred_hooks TEXT[],                   -- ['curiosity', 'fear', 'humor', 'controversy']
  -- Scheduling
  posting_frequency JSONB,                  -- {"daily": 2, "platforms": ["tiktok", "youtube"]}
  best_times JSONB,                         -- {"tiktok": "18:00", "youtube": "12:00"}
  timezone VARCHAR(50) DEFAULT 'Asia/Bangkok',
  -- Operations
  brand_rules TEXT,
  monetization_mode VARCHAR(20),            -- 'viral_only' | 'cart_focused' | 'mixed'
  approval_mode VARCHAR(20) DEFAULT 'manual', -- 'auto' | 'manual'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- M:N link between channels and platform accounts
channel_platform_accounts (
  channel_id UUID NOT NULL REFERENCES channels(id),
  platform_account_id UUID NOT NULL REFERENCES platform_accounts(id),
  PRIMARY KEY (channel_id, platform_account_id)
);

-- Persona prompt versioning (correlate changes with performance)
channel_persona_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id),
  persona_prompt TEXT NOT NULL,
  version INT NOT NULL,
  changed_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. 7-Layer Pipeline Flow

### 5a. Path A: Trend-Driven Content

```
LAYER 1: DISCOVERY (Trend Layer)
  n8n Cron (every 4-6h)
    -> snscrape: TikTok Creative Center hashtags, top videos
    -> pytrends: Google Trends rising queries per niche
    -> YouTube Data API v3: trending videos per category
    -> Store raw signals in trends table
    -> BERTopic clustering: group related signals
    -> Deduplicate against existing trends
    -> Rank by momentum: velocity * freshness * niche_fit * (1 - saturation)
    -> Top-N trends pass to Layer 2

LAYER 2: INTELLIGENCE (Viral Brain)
  For each top-N trend:
    -> LLM-as-judge scores against 6 dimensions:
       Hook Strength (0.30) | Curiosity Gap (0.20) | Novelty (0.15)
       Retention Structure (0.15) | Emotional Trigger (0.10) | Platform Fit (0.10)
    -> Generate 3-5 hook variants per trend
    -> Score each variant independently (0-100 weighted sum)
    -> Score >= 70: auto-queue | 50-69: manual review | <50: reject
    -> Top 2 hooks pass to Layer 3

LAYER 3: CONTENT LAB (A/B Testing)
  Sequential variant testing:
    -> Create ab_tests record linking Variant A and Variant B
    -> Variant A: send to Layer 4 (Production) immediately
    -> n8n timer: wait 48h
    -> Variant B: send to Layer 4 (Production)
    -> n8n timer: wait another 48h (T+96h from start)
    -> Pull metrics via Feedback Loop (Layer 7)
    -> Compare: primary = retention_3s, secondary = completion_rate
    -> Minimum 500 views per variant; below = "inconclusive"
    -> Declare winner; log pattern insights

LAYER 4: PRODUCTION (Video Engine)
  Per-channel config injection (from channels table):
    -> n8n loads channel.persona_prompt, tts_voice, comfyui_workflow
    -> POST :8000/api/llm/chat    { prompt: persona_prompt + hook + topic }
       -> Returns: script text + scene descriptions
    -> POST :8000/api/tts/synthesize  { text, voice: channel.tts_voice }
       -> Returns: audio file path + duration
    -> POST :8000/api/image/generate  { prompts[], workflow: channel.comfyui_workflow }
       -> Returns: image file paths (ComfyUI local or RunningHub cloud)
    -> POST :8000/api/video/compose   { audio, images[], captions: true }
       -> Returns: final video file path
    -> INSERT content record + channel association

LAYER 5: DISTRIBUTION (Multi-Platform Upload)
  Per-channel staggered posting (15-30min intervals):
    -> YouTube: Data API v3 upload (built-in n8n node, native scheduling)
    -> TikTok: HTTP Request -> TikTokAutoUploader (Phantomwright, scheduling)
    -> Instagram: HTTP Request -> Meta Graph API (2-step upload)
    -> Facebook: HTTP Request -> Video API (3-step upload)
    -> INSERT platform_publishes per platform
    -> UPDATE upload_queue status

LAYER 6: MONETIZATION (Affiliate/Cart Pin)
  Post-upload, per platform:
    -> Instagram: POST /{media-id}/product_tags (FULLY AUTOMATED)
       Up to 30 tags per Reel, post-publication tagging supported
    -> TikTok: Generate affiliate link via TikTok Shop Affiliate API (PARTIAL)
       Video-product binding requires TikTok Creator Center UI
    -> Facebook: Attempt product tag via Graph API (PARTIAL)
    -> YouTube: Skip (manual tagging in YouTube Studio only)
    -> UPDATE affiliate_links with cart_pin_status

LAYER 7: FEEDBACK (Analytics Loop)
  n8n Cron pulls at 3 intervals:
    -> T+6h (early signal): Distribution assessment, catch failures
    -> T+48h (stabilized): A/B test comparison (primary data point)
    -> T+168h (7 days): Long-tail performance, retraining data
  Per platform:
    -> YouTube: Analytics API reports.query (views, watchTime, retention, subs)
    -> TikTok: Business API (views, reach, avg_watch_time, completion_rate)
    -> Instagram: Graph API GET /media_id/insights (impressions, reach, saves)
    -> Facebook: Video API metrics (video_views, reach, engagement)
  -> INSERT platform_analytics per pull
  -> T+48h: trigger Content Lab A/B comparison
  -> Every 100 videos with T+168h data: trigger GBDT retraining pipeline
```

### 5b. Path B: Product-Driven Content

```
LAYER 1: DISCOVERY (Product Discovery)
  n8n Cron (every 4h) or on-demand trigger:
    -> TikTok Shop Affiliate API: Search by category + commission rate + keyword
    -> Shopee Public API v4: Product search by keyword + category
    -> Lazada Open Platform: Product listing/search via REST API
    -> Normalize to unified schema: platform, name, price, commission, sales, rating
    -> Dedup: fuzzy name match (Levenshtein < 0.3) + price within 10% + same category
    -> Assign cross_platform_group_id for duplicates
    -> INSERT/UPDATE products table

LAYER 2: INTELLIGENCE (Product Scoring)
  Weighted formula (Phase 1, 0-100):
    -> Commission (0.25): normalize(commission_rate, 1%-30%)
    -> Relevance (0.20): keyword_match_ratio(product, channel.niche)
    -> Trend-fit (0.25): cross-reference with Trend Layer signals
    -> Conversion (0.15): historical rate OR category baseline (cold start = 0.5)
    -> Social proof (0.10): rating * log(review_count + 1)
    -> Visual quality (0.05): has_video + high_res + lifestyle photos
  -> Store score + breakdown in products table
  -> Log to product_score_history for ML training
  -> Score > threshold: generate affiliate link -> Layer 3

LAYER 3: CONTENT LAB (Product Script Templates)
  Select template based on product attributes:
    -> Problem-Solution: "...  [X] ...? ..." (features, target_problem)
    -> Unboxing/Review: "... [PRODUCT] ... [PRICE] ... ..." (comparisons)
    -> Before/After: "... vs ... [PRODUCT]" (before_state, after_state)
    -> Price/Deal: "[PRODUCT] ... [SALE] ... (... [REG])" (sale_price, deadline)
  -> Product images from platform API as ComfyUI img2vid input
  -> Pass to Layer 4

LAYERS 4-7: Same as Path A
  (Production -> Distribution -> Monetization -> Feedback)
  Monetization includes pre-generated affiliate links from product discovery
  Feedback additionally tracks click_count, conversion_count, revenue_total
```

---

## 6. Per-Layer Architecture Detail

### Layer 1: Discovery

| Aspect | Path A (Trend) | Path B (Product) |
|--------|---------------|------------------|
| Service | n8n + snscrape + pytrends + YT API | n8n + TikTok Shop + Shopee + Lazada APIs |
| API Endpoints | snscrape CLI, pytrends Python, YT Data API v3 /search | TikTok Affiliate /product/search, Shopee /item/search, Lazada /products/get |
| n8n Workflow | Cron trigger -> Code node (snscrape) -> HTTP (YT) -> Code (pytrends) -> Postgres (store) | Cron trigger -> HTTP (3 platforms) -> Code (normalize+dedup) -> Postgres (store) |
| DB Tables | trends | products, product_score_history |
| Phase 1 | AUTOMATED (n8n cron every 4-6h) | SEMI-AUTO (n8n cron, Shopee KAM access may be manual) |

### Layer 2: Intelligence

| Aspect | Path A (Viral Brain) | Path B (Product Scoring) |
|--------|---------------------|-------------------------|
| Service | n8n Code node -> LLM API (GPT-4/DeepSeek) | n8n Code node (rule-based formula) |
| API Endpoints | OpenAI /chat/completions or DeepSeek API | Direct computation in n8n |
| n8n Workflow | Receive trend -> Code node builds LLM prompt with rubric -> HTTP to LLM -> Parse score -> Postgres | Receive products -> Code node computes weighted formula -> Postgres |
| DB Tables | content (viral_score, score_breakdown) | products (product_score, score_breakdown), product_score_history |
| Phase 1 | AUTOMATED (LLM-as-judge, 6-dimension rubric) | AUTOMATED (rule-based weighted formula) |
| Phase 2 | GBDT model replaces LLM weights after ~500 videos | GBDT model after ~50 videos with conversion data |

### Layer 3: Content Lab

| Aspect | Path A (A/B Testing) | Path B (Script Templates) |
|--------|---------------------|--------------------------|
| Service | n8n + Pixelle-Video | n8n + Pixelle-Video |
| n8n Workflow | Create test pair -> Post A -> Wait 48h -> Post B -> Wait 48h -> Compare | Select template -> Fill with product data -> Send to Production |
| DB Tables | content_variants, ab_tests | content (template_type in generation_metadata) |
| Phase 1 | SEMI-AUTO (requires minimum 500 views; human reviews inconclusive) | AUTOMATED (template selection is rule-based) |

### Layer 4: Production

| Aspect | Detail |
|--------|--------|
| Service | Pixelle-Video FastAPI on :8000 |
| API Endpoints | /api/llm/chat (script), /api/tts/synthesize (voice), /api/image/generate (visuals), /api/video/compose (final) |
| n8n Workflow | Sequential HTTP Request nodes: LLM -> TTS -> Image -> Video -> Store content record |
| DB Tables | content |
| Per-Channel Config | tts_voice (direct param), comfyui_workflow (direct param), persona_prompt (prepended to LLM prompt by n8n) |
| Phase 1 | FULLY AUTOMATED |

### Layer 5: Distribution

| Aspect | Detail |
|--------|--------|
| Service | n8n -> Platform APIs |
| YouTube | Built-in n8n YouTube node; Data API v3; native scheduling via publishAt |
| TikTok | HTTP Request -> TikTokAutoUploader; Phantomwright stealth; scheduling up to 10 days |
| Instagram | HTTP Request -> Meta Graph API; 2-step upload (create + publish); 100 posts/24h |
| Facebook | HTTP Request -> Video API; 3-step upload (init + upload + finish); 30 Reels/24h |
| Multi-Channel | Staggered posting (15-30min intervals via n8n Wait node) to avoid TikTok behavioral fingerprinting |
| DB Tables | platform_publishes, upload_queue, platform_accounts |
| Phase 1 | FULLY AUTOMATED |

### Layer 6: Monetization

| Aspect | Detail |
|--------|--------|
| Service | n8n -> Shopping/Affiliate APIs |
| Instagram | POST /{media-id}/product_tags; FULLY AUTOMATED; up to 30 tags; requires approved Instagram Shop + Meta Commerce Manager catalog |
| TikTok | Generate affiliate link via TikTok Shop Affiliate API; PARTIAL -- video-product binding in UI |
| Facebook | Shared Meta Commerce Manager catalog; PARTIAL automation |
| YouTube | Manual in YouTube Studio; NO API exists |
| DB Tables | affiliate_links |
| Phase 1 | MIXED (Instagram auto, others partial/manual) |

### Layer 7: Feedback

| Aspect | Detail |
|--------|--------|
| Service | n8n cron -> Analytics APIs |
| YouTube | Analytics API reports.query; 10,000 units/day; built-in n8n node |
| TikTok | Business API; views, impressions, reach, avg_watch_time; exponential backoff required |
| Instagram | Graph API GET /media_id/insights; impressions, reach, plays, shares, saves; 200 calls/user/hour |
| Facebook | Video API; shared Meta auth with Instagram |
| Schedule | T+6h (early), T+48h (stable/A/B), T+168h (long-tail/retrain) |
| Retraining | Every 100 videos with T+168h data; features = hook_text + 6 viral dims + platform + niche + time; GBDT model |
| DB Tables | platform_analytics |
| Phase 1 | SEMI-AUTO (n8n cron; all platforms have 24-48h data delay) |

---

## 7. Multi-Channel Operations

### How Channel Identity Flows Through Every Layer

```
channels table (DB)
    |
    |-- Discovery: trends filtered by channel.niche + channel.preferred_hooks
    |-- Intelligence: Viral Brain uses channel-specific hook preferences for scoring
    |-- Content Lab: A/B tests run per channel (different hooks match different audiences)
    |-- Production:
    |     |-- LLM: n8n prepends channel.persona_prompt to prompt field
    |     |-- TTS: channel.tts_voice passed as voice_id to /api/tts/synthesize
    |     |-- Image: channel.comfyui_workflow passed as workflow to /api/image/generate
    |-- Distribution: staggered 15-30min posting intervals between channels
    |-- Monetization: channel.monetization_mode determines cart pin priority
    |-- Feedback: analytics correlated per channel for persona optimization
```

### TikTok 4-Layer Duplicate Detection (Must-Defeat)

| Detection Layer | What It Catches | How viral-ops Defeats It |
|----------------|----------------|--------------------------|
| Visual Analysis | Scene matching, composition, color | Different comfyui_workflow per channel |
| Audio Fingerprinting | Voice pitch, timing, music | Different tts_voice per channel + different music library |
| C2PA Metadata | File origin, edit history | Each video generated fresh per channel (not copied) |
| Behavioral Analysis | Sync posting, network coordination | Staggered 15-30min intervals + different best_times per channel |

### Single Pipeline Architecture

One n8n workflow handles all channels dynamically:

```
[Cron per channel schedule]
  -> [Postgres: SELECT channels WHERE is_active AND next_post_due]
  -> [Loop over due channels]
      -> [Load channel config: persona, voice, workflow, hooks]
      -> [Prepend channel.persona_prompt to topic]
      -> [POST /api/llm/chat with persona-injected prompt]
      -> [POST /api/tts/synthesize with channel.tts_voice]
      -> [POST /api/image/generate with channel.comfyui_workflow]
      -> [POST /api/video/compose]
      -> [Switch by channel.approval_mode]
          -> auto: [Stagger upload at channel.best_times + 15-30min offset]
          -> manual: [Queue for dashboard review]
```

---

## 8. Phase 1 MVP Build Plan (6 Sprints, 12 Weeks)

### Sprint 1: Foundation (Week 1-2)
1. Fork next-saas-stripe-starter, strip Stripe billing (not needed for solo-use)
2. Set up Prisma schema with core 6 tables (platform_accounts, content, platform_publishes, platform_analytics, upload_queue, affiliate_links)
3. Install n8n via npx, configure basic webhook
4. Install Pixelle-Video, verify FastAPI starts on :8000
5. Create test workflow: Dashboard button -> n8n -> Pixelle-Video -> video file

### Sprint 2: Content Pipeline (Week 3-4)
1. Build content creation page (topic input, voice selection, style)
2. Build n8n content pipeline workflow (full 4-step: script -> TTS -> image -> video)
3. Build pipeline status page (poll n8n execution status)
4. Add content table population after generation
5. Test end-to-end: topic -> generated video on disk

### Sprint 3: Upload + Distribution (Week 5-6)
1. Build platform account management page (OAuth tokens, TikTok cookies)
2. Build upload queue page (schedule, retry, cancel)
3. Build n8n upload workflows for YouTube (easiest first)
4. Add Instagram + Facebook upload workflows
5. Add TikTok upload via TikTokAutoUploader integration
6. Build content calendar view

### Sprint 4: Affiliate + Analytics (Week 7-8)
1. Instagram product tagging automation (post-upload n8n step)
2. TikTok affiliate link generation
3. Analytics fetch workflows (n8n cron -> platform APIs -> platform_analytics table)
4. Analytics dashboard page (Tremor charts)
5. Polish, error handling, retry logic

### Sprint 5: Trend Layer + Viral Brain (Week 9-10)
1. Add trends table to Prisma schema
2. Build snscrape + pytrends integration (n8n Code nodes)
3. Build trend pipeline workflow (scrape -> cluster -> rank -> store)
4. Build trend dashboard page
5. Implement LLM-as-judge viral scoring (6-dimension rubric)
6. Build scoring result display with per-dimension breakdown

### Sprint 6: Content Lab + Multi-Channel (Week 11-12)
1. Add channels, channel_platform_accounts, channel_persona_history tables
2. Add content_variants, ab_tests tables
3. Build channel management page (persona, voice, workflow config)
4. Implement dynamic channel config injection in n8n pipeline
5. Build A/B test creation and results comparison pages
6. Implement staggered posting with n8n Wait nodes
7. Test multi-channel output differentiation

---

## 9. Phase 2 Roadmap

| Feature | Dependency | Priority | Sprint Est. |
|---------|-----------|----------|-------------|
| GBDT viral scoring model | ~500 videos with T+168h analytics | HIGH | 2 sprints |
| Product Discovery (Path B) | Shopee KAM access + Lazada app key | HIGH | 2 sprints |
| TikTok official API migration | API approval (days-weeks) | MEDIUM | 1 sprint |
| Index-TTS Thai voice cloning | Thai training data / model update | MEDIUM | 1 sprint |
| Product scoring ML model | ~50 product videos with conversion data | MEDIUM | 1 sprint |
| Custom ComfyUI workflow builder | Workflow editor UI | MEDIUM | 2 sprints |
| A/B testing automation improvements | Statistical significance engine | MEDIUM | 1 sprint |
| Multi-tenant (team accounts) | BoxyHQ patterns reference | LOW | 2 sprints |
| YouTube Shopping API (if released) | Google API availability | LOW | 1 sprint |
| Stripe billing (SaaS launch) | Re-enable from boilerplate | LOW | 1 sprint |
| Mobile companion app | React Native | LOW | 3+ sprints |
| Real-time dashboard (WebSocket) | n8n webhook events | LOW | 1 sprint |

---

## 10. Complete Risk Assessment

| # | Risk | Severity | Layer | Likelihood | Impact | Mitigation | Fallback |
|---|------|----------|-------|------------|--------|------------|----------|
| 1 | TikTokAutoUploader ban | MEDIUM | Distribution | MEDIUM | TikTok uploads blocked | Rate-limit (max 3/day/account), apply for official API | Manual TikTok upload via app |
| 2 | Pixelle-Video maturity | MEDIUM-LOW | Production | MEDIUM-LOW | Bugs, breaking changes | Pin version, fork, HTTP API stability | MoneyPrinterTurbo (stock footage) |
| 3 | Platform API changes | LOW-MEDIUM | Dist/Monetization | LOW-MEDIUM | Upload/shopping breaks | n8n workflow editability, JSONB flexibility | Manual upload for affected platform |
| 4 | TikTok duplicate detection | MEDIUM | Multi-Channel | MEDIUM | Reach suppression, account ban | 6-dimension differentiation per channel | Reduce to fewer channels |
| 5 | Trend scraping blocking | MEDIUM | Discovery | MEDIUM | No trend signals | Multiple sources (snscrape + pytrends + YT API), Apify fallback | Manual trend research |
| 6 | LLM scoring inconsistency | LOW-MEDIUM | Intelligence | LOW-MEDIUM | Unreliable viral predictions | Calibration benchmarks, temperature=0, structured output | GBDT migration accelerated |
| 7 | Analytics API data delay | LOW | Feedback | CERTAIN | 24-48h minimum delay | 3-pull schedule already accounts for delay | Acceptable for Phase 1 |
| 8 | SE Asian e-commerce API instability | MEDIUM | Monetization (B) | MEDIUM | Product data gaps | Multi-platform redundancy (3 sources) | Manual product research |

---

## 11. Complete Decision Record

| # | Decision | Options Evaluated | Choice | Rationale | Iteration |
|---|----------|-------------------|--------|-----------|-----------|
| 1 | SaaS boilerplate | BoxyHQ, next-saas-stripe-starter, Open SaaS (Wasp), Saasfly, Cal.com, Documenso, Midday | **next-saas-stripe-starter** | Modern App Router, MIT, clean architecture. Multi-tenancy addable later; migrating from Pages Router is harder. | 1-2 |
| 2 | Video engine | Pixelle-Video, MoneyPrinterTurbo, short-video-maker, TikTok-Forge | **Pixelle-Video** | Only engine with AI-generated visuals (not stock), built-in FastAPI (9 routers), Thai TTS, Windows support, ComfyUI modularity. | 3-4 |
| 3 | Orchestrator | n8n, custom BullMQ, Inngest, Trigger.dev | **n8n (self-hosted)** | Eliminates job queue gap entirely. Visual workflow editor, REST API, scheduling, retry, error handling built-in. | 5 |
| 4 | Thai TTS | Edge-TTS, Index-TTS, ChatTTS | **Edge-TTS (Phase 1)** | 3 Thai Neural voices (PremwadeeNeural, NiwatNeural, AcharaNeural), no GPU, cloud API. Index-TTS for Phase 2+ voice cloning. | 4-5 |
| 5 | TikTok upload | Official Content Posting API, TikTokAutoUploader | **TikTokAutoUploader (Phase 1)** | Official API lacks scheduling, requires gated approval. Unofficial has scheduling, multi-account. Apply for official in parallel. | 6 |
| 6 | UI components | ShadCN UI alone, AdminJS, Refine, ShadCN + Tremor | **ShadCN UI + Tremor** | ShadCN covers all UI primitives; Tremor adds charts/dashboards. Admin frameworks are overkill for custom ops dashboard. | 8 |
| 7 | DB / ORM | Prisma+PG, Drizzle+PG, Prisma+SQLite | **Prisma + PostgreSQL** | Dominant pattern across all boilerplates. JSONB support, mature migrations, type-safe queries. SQLite for n8n only. | 8 |
| 8 | Shopping APIs | OSS wrappers (Lundehund, ipfans, EcomPHP), direct HTTP, unified library | **Direct HTTP via n8n** | All OSS wrappers inadequate. n8n HTTP Request nodes call platform APIs directly. Per-platform automation level varies. | 7 |
| 9 | GPU strategy | Local GPU required, cloud only, split pipeline | **Split (CPU local + cloud GPU)** | TTS/composition CPU-only; image gen via RunningHub cloud. No GPU hardware needed for Phase 1. | 4 |
| 10 | Trend scraping | TikTok Research API, snscrape, drawrowfly/tiktok-scraper, Apify | **snscrape + pytrends + YT API** | TikTok Research API academic-only. drawrowfly abandoned. snscrape is OSS, multi-platform, active. | 9 |
| 11 | Viral scoring | Custom ML model, LLM-as-judge, rule-based | **LLM-as-judge (Phase 1) -> GBDT (Phase 2)** | No training data initially. LLM provides immediate scoring with 6-dimension rubric. Validated by Meta MLLM-VAU paper. | 9 |
| 12 | A/B testing | Native platform A/B, sequential variants, multivariate | **Sequential variant testing** | No platform offers native A/B for organic content. 48h wait between variants for algorithm stabilization. | 10 |
| 13 | Analytics ingestion | Real-time, hourly polling, 3-pull schedule | **3-pull (T+6h, T+48h, T+168h)** | All platforms have 24-48h delay. 3 pulls capture early signal, stable metrics, and long-tail for retraining. | 10 |
| 14 | Product discovery | Single platform, cross-platform aggregation | **TikTok Shop + Shopee + Lazada** | TikTok has most unified API. Cross-platform coverage maximizes product catalog. Fuzzy dedup handles overlaps. | 11 |
| 15 | Multi-channel pipeline | Separate n8n workflows per channel, single dynamic pipeline | **Single pipeline + dynamic config** | Separate workflows scale linearly (N x M). Dynamic config injection via DB lookup is standard multi-brand pattern. | 12 |

---

## 12. Automation Matrix (Phase 1)

| Capability | Status | Notes |
|---|---|---|
| Script generation (LLM) | AUTOMATED | Pixelle-Video /api/llm |
| Thai TTS narration | AUTOMATED | Edge-TTS, 3 Neural voices |
| AI image generation | AUTOMATED | ComfyUI/RunningHub |
| Video composition | AUTOMATED | Pixelle-Video /api/video (FFmpeg) |
| YouTube upload | AUTOMATED | Data API v3, native scheduling |
| Instagram upload | AUTOMATED | Meta Graph API |
| Facebook upload | AUTOMATED | Video API |
| TikTok upload | AUTOMATED | TikTokAutoUploader (unofficial) |
| Instagram cart pin | AUTOMATED | Product Tagging API |
| TikTok affiliate link | SEMI-AUTO | API generates link; pin in UI |
| Facebook cart pin | SEMI-AUTO | Less documented than IG |
| YouTube cart pin | MANUAL | YouTube Studio only |
| Trend scraping | AUTOMATED | snscrape + pytrends + YT API (Sprint 5) |
| Trend clustering | AUTOMATED | BERTopic / TF-IDF (Sprint 5) |
| Viral scoring | AUTOMATED | LLM-as-judge (Sprint 5) |
| A/B test execution | SEMI-AUTO | Sequential posting automated; comparison needs min 500 views (Sprint 6) |
| Analytics collection | SEMI-AUTO | n8n cron; platforms have 24-48h delay |
| GBDT retraining | NOT YET | Phase 2 (~500 videos needed) |
| Product discovery | NOT YET | Phase 2 (requires platform API access) |
| Voice cloning (Thai) | NOT AVAILABLE | Edge-TTS only; Index-TTS Phase 2+ |
| Multi-channel posting | AUTOMATED | Single pipeline + dynamic config (Sprint 6) |

---

## Research Provenance

This document synthesizes findings from 13 research iterations conducted on 2026-04-16:

| Iteration | Focus | Key Deliverables |
|-----------|-------|-----------------|
| 1 | OSS SaaS boilerplate landscape survey | 5 candidates evaluated, comparison matrix |
| 2 | Fork viability deep-dive (BoxyHQ, Open SaaS, next-saas-stripe-starter, Cal.com) | Top 2 finalists, trade-off framework |
| 3 | Video generation engine comparison (Pixelle-Video, MoneyPrinterTurbo, etc.) | Pixelle-Video selected, engine matrix |
| 4 | Pixelle-Video deep-dive (API, Thai TTS, GPU strategy) | 9-router FastAPI discovered, 3 Thai voices confirmed |
| 5 | n8n integration and glue architecture | Three-service localhost diagram, pipeline mapping |
| 6 | Multi-platform upload strategy + DB schema | 4-platform comparison, 6-table schema, TikTokAutoUploader |
| 7 | Shopping/Affiliate API deep-dive (cart pin) | Cart pin automation matrix, IG Product Tagging API |
| 8 | Convergence synthesis (iterations 1-7) | Definitive Phase 1 recommendation, MVP plan, risk assessment |
| 9 | Trend Layer + Viral Brain intelligence | snscrape pipeline, LLM-as-judge rubric, MLLM-VAU validation |
| 10 | Content Lab A/B testing + Feedback Loop analytics | Sequential testing methodology, analytics API comparison, GBDT retraining |
| 11 | Product Discovery (Path B) pipeline | TikTok Shop + Shopee + Lazada APIs, product scoring algorithm |
| 12 | Multi-channel identity + persona management | channels schema, TikTok fingerprinting, single pipeline architecture |
| 13 | Final convergence synthesis | This document -- complete architecture covering all 7 layers |
