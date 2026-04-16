# Iteration 5: n8n Orchestration (Q12) + TikTok Creative Center Schema Completion (Q3)

## Focus
This iteration addresses the final two unanswered questions:
1. **Q12**: Complete n8n workflow orchestration design -- how L1 triggers L2, how L2 triggers L3, cron schedules, workflow chaining, data flow through DB tables.
2. **Q3 completion**: TikTok Creative Center actual JSON response schemas from the Apify actor, filling the gap left by iterations 1-2.

## Findings

### Finding 1: TikTok Creative Center -- Complete JSON Response Schemas (Q3 COMPLETION)

The Apify actor `doliz/tiktok-creative-center-scraper` provides structured JSON output for all 5 TikTok CC categories. Schemas confirmed from the Apify actor documentation page:

**Trending Hashtags Response Schema:**
```json
{
  "hashtag_id": "string",
  "hashtag_name": "string",
  "country_info": { "id": "string", "value": "string", "label": "string" },
  "is_promoted": "boolean",
  "trend": [{ "time": "number (unix timestamp)", "value": "number (usage count)" }],
  "publish_cnt": "number (total post count)",
  "video_views": "number (total views)",
  "rank": "number (position in top list)",
  "rank_diff_type": "number (rank movement indicator)"
}
```

**Trending Videos Response Schema:**
```json
{
  "country_code": "string",
  "cover": "string (thumbnail URL)",
  "duration": "number (seconds)",
  "id": "string",
  "item_id": "string",
  "item_url": "string (TikTok video URL)",
  "region": "string",
  "title": "string (video caption/description)"
}
```

**Trending Songs Response Schema:**
```json
{
  "author": "string",
  "clip_id": "string",
  "country_code": "string",
  "cover": "string (album art URL)",
  "duration": "number (seconds)",
  "if_cml": "boolean (commercial music library flag)",
  "is_search": "boolean",
  "link": "string (sound page URL)",
  "on_list_times": "number|null (times appeared on trending list)",
  "promoted": "boolean",
  "rank": "number",
  "rank_diff": "number",
  "rank_diff_type": "number",
  "related_items": [{ "item_id": "number", "cover_uri": "string (URL)" }],
  "song_id": "string",
  "title": "string (song title)",
  "trend": [{ "time": "number (unix timestamp)", "value": "number (usage count)" }],
  "url_title": "string"
}
```

**Trending Creators Response Schema:**
```json
{
  "tcm_id": "string",
  "user_id": "string",
  "nick_name": "string",
  "avatar_url": "string (URL)",
  "country_code": "string",
  "follower_cnt": "number",
  "liked_cnt": "number",
  "tt_link": "string (TikTok profile URL)",
  "tcm_link": "string (Creative Center profile URL)",
  "items": [{
    "item_id": "string",
    "cover_url": "string (URL)",
    "tt_link": "string (video URL)",
    "vv": "number (video views)",
    "liked_cnt": "number",
    "create_time": "number (unix timestamp)"
  }]
}
```

**Input Parameters (per category):**
- Hashtags: `hashtags_country`, `hashtags_industry` (optional), `hashtags_period` ("7"|"30"|"120"), `hashtags_new_to_top_100` (boolean), `hashtags_search`, `hashtags_page`, `hashtags_limit`
- Videos: `videos_country`, `videos_period`, `videos_order_by`, `videos_page`, `videos_limit`
- Songs: `popular_country`, `popular_period`, `popular_new_to_top_100`, `popular_approved_for_business_use`, `popular_search`, `popular_page`, `popular_limit`
- Creators: `creators_country`, `creators_audience_country`, `creators_followers` (range), `creators_sort_by`, `creators_search`, `creators_page`, `creators_limit`

**Pricing**: $0.002 per item across all categories. At 100 hashtags + 20 videos per poll = ~$0.24/day if polling every 2h.

**TikTok CC to `trends` Table Mapping:**
| TikTok CC Field | `trends` Column | Transformation |
|----------------|-----------------|----------------|
| `hashtag_name` | `keyword` | Strip `#` prefix if present |
| `"tiktok"` (constant) | `platform` | Hard-coded |
| `"TH"` (from input) | `region` | From `hashtags_country` param |
| `country_info.label` | `category` | Map industry filter label |
| `publish_cnt` | `interest_score` | Normalize to 0-100 scale |
| `rank_diff_type` + `trend[]` time-series | `velocity_score` | Compute from trend array delta |
| First seen timestamp | `discovered_at` | `NOW()` on first insert |
| When `velocity_score` < -0.20 | `peak_at` | Mark when trend transitions from growth to decay |
| Computed from lifecycle | `status` | `emerging`/`active`/`peak`/`declining`/`dead` |
| `"hashtag"` / `"video"` / `"sound"` | `trend_type` | Based on which endpoint sourced it |

[SOURCE: https://apify.com/doliz/tiktok-creative-center-scraper]

### Finding 2: n8n Workflow Architecture -- Sub-Workflow Pattern (Q12)

n8n provides two primary mechanisms for workflow chaining:

**A. Execute Sub-Workflow Node:**
- Parent workflow calls child workflow synchronously (waits for completion)
- Data passes via the **Execute Sub-workflow Trigger** node in the child
- Child receives items from parent, processes them, returns results back to parent
- Error in child propagates to parent (can be caught with Error Trigger node)
- Child workflow must be activated and have an Execute Sub-workflow Trigger as its start node

**B. Webhook-Based Chaining (Internal):**
- Parent sends HTTP request to child workflow's webhook URL
- Asynchronous -- parent does not wait for completion
- Useful for fire-and-forget patterns (e.g., L1 notifying L2 of new trends)
- n8n internal webhook URLs: `http://localhost:5678/webhook/{webhook-id}`

**Best Practice -- Split by Concern:**
- n8n docs recommend splitting large workflows into sub-workflows by functional domain
- Schedule Trigger node supports cron expressions (`0 */2 * * *` = every 2 hours)
- Stagger high-frequency schedules across minutes to prevent server overload
- Always include error notification nodes in scheduled workflows
- Set timezone explicitly on all Schedule Trigger nodes (Asia/Bangkok for viral-ops)

[SOURCE: https://docs.n8n.io/flow-logic/subworkflows/]
[SOURCE: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/]

### Finding 3: Complete n8n Workflow Chain Design for L1 -> L2 -> L3 (Q12 -- SYNTHESIZED)

Based on n8n sub-workflow capabilities combined with the L1/L2/L3 architecture from prior iterations, here is the complete orchestration design:

#### Workflow 1: L1-Trend-Discovery (Cron-Triggered)

**Schedule**: `0 */2 * * *` (every 2 hours, UTC+7)
**Timezone**: Asia/Bangkok

```
[Schedule Trigger: */2h]
  |
  +--> [Sub-Workflow: L1-Source-Google-Trends]
  |      |-> pytrends-modern: trending_searches(pn='thailand')
  |      |-> pytrends-modern: realtime_trending_searches(pn='thailand')
  |      |-> For each trend: interest_over_time() for velocity
  |      |-> Return: [{keyword, interest_score, velocity_score, source:'google'}]
  |
  +--> [Sub-Workflow: L1-Source-TikTok-CC]
  |      |-> Apify HTTP API: getTrendingHashtag(region=TH, period=7)
  |      |-> Apify HTTP API: getTrendingVideos(region=TH, period=7)
  |      |-> Extract: hashtag_name, publish_cnt, video_views, trend[]
  |      |-> Return: [{keyword, interest_score, velocity_score, source:'tiktok'}]
  |
  +--> [Sub-Workflow: L1-Source-YouTube]
  |      |-> YouTube Data API: videos.list(chart=mostPopular, regionCode=TH)
  |      |-> Extract: video tags, titles, categories, view counts
  |      |-> Return: [{keyword, interest_score, velocity_score, source:'youtube'}]
  |
  +--> [Merge Node: Combine all source results]
  |
  +--> [Code Node: BERTopic Clustering]
  |      |-> HTTP POST to Python microservice running BERTopic
  |      |-> partial_fit(new_trend_documents)
  |      |-> Returns cluster assignments + topic labels
  |
  +--> [Code Node: Velocity Classification]
  |      |-> Apply velocity thresholds (SURGING/RISING/EMERGING/etc.)
  |      |-> Compute multi-source freshness_score
  |      |-> Determine lifecycle_stage
  |
  +--> [Postgres Node: Upsert to `trends` table]
  |      |-> INSERT ... ON CONFLICT (platform, keyword, region) DO UPDATE
  |      |-> Set status, velocity_score, interest_score, peak_at
  |
  +--> [IF Node: Any SURGING or RISING trends?]
         |
         Yes -> [Execute Sub-Workflow: L2-Viral-Brain (pass trend_ids)]
         No  -> [End: Wait for next cron cycle]
```

**Cron Schedules per Source:**

| Source | Cron Expression | Frequency | Rationale |
|--------|----------------|-----------|-----------|
| Google Trends (pytrends) | `0 */4 * * *` | Every 4h | Rate limit safety (~1,400 requests before throttle). 6 polls/day sufficient for daily trends. |
| TikTok Creative Center | `0 */2 * * *` | Every 2h | Fastest trend cycle (24-48h Thai market). Apify has no strict rate limit. Cost: ~$0.24/day. |
| YouTube Data API | `30 */3 * * *` | Every 3h | 10,000 quota units/day. mostPopular costs 1 unit. 8 polls/day uses <400 units. |

**Staggering**: Google at :00, TikTok at :00 (separate sub-workflow), YouTube at :30 -- prevents overlapping API calls.

**Note**: The L1 master workflow fires every 2h but sub-workflows for each source run on their own staggered schedules. The master merge/cluster step only processes results that have arrived since the last run.

[SOURCE: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/]
[INFERENCE: based on prior iteration findings (velocity thresholds from iter-3, BERTopic from iter-2, source details from iter-1/2) combined with n8n sub-workflow patterns]

#### Workflow 2: L2-Viral-Brain (Triggered by L1 or Schedule)

**Trigger**: Execute Sub-workflow Trigger (called by L1 with trend_ids) OR Schedule Trigger `0 */6 * * *` (every 6h catch-up for missed triggers)

```
[Execute Sub-workflow Trigger OR Schedule Trigger]
  |
  +--> [Postgres Node: Fetch trends WHERE status IN ('emerging','active','peak')
  |     AND velocity_score > 0.05 AND scored_at IS NULL OR scored_at < NOW()-6h]
  |
  +--> [Loop: For each qualifying trend]
  |      |
  |      +--> [Code Node: Generate Hook Variants]
  |      |      |-> LLM call: generate 3-5 hooks per trend
  |      |      |-> Pick from 7 hook categories based on trend topic
  |      |      |-> Constraint: max 15 words per hook
  |      |
  |      +--> [Loop: For each hook variant]
  |      |      |
  |      |      +--> [HTTP Node: LLM-as-Judge Scoring (6 dimensions)]
  |      |      |      |-> 6 parallel API calls (one per dimension)
  |      |      |      |-> Each returns {dimension, score:1-5, reasoning}
  |      |      |      |-> Run each dimension 2x, average scores
  |      |      |
  |      |      +--> [Code Node: Composite Viral Score]
  |      |             |-> weighted_quality = 0.25*hook + 0.15*story + 0.20*emotion
  |      |             |                     + 0.15*visual + 0.10*audio + 0.15*cta
  |      |             |-> normalized_quality = (weighted_quality - 1) / 4  # 0.0-1.0
  |      |             |-> viral_potential = 0.40*quality + 0.35*freshness
  |      |             |                    + 0.15*niche_fit + 0.10*timing
  |      |
  |      +--> [Code Node: Phase 2 GBDT Override (if model exists)]
  |      |      |-> If GBDT model trained (500+ videos):
  |      |      |     build 38-feature vector, predict log(views/followers)
  |      |      |     Use GBDT score as primary, LLM composite as fallback
  |      |      |-> Else: Use composite viral_potential directly
  |      |
  |      +--> [Postgres Node: Update `trends` table]
  |             |-> SET viral_score, scored_at, hook_variants (JSONB)
  |
  +--> [IF Node: Any trends with viral_potential >= 0.70?]
  |      |
  |      Yes -> [Postgres Node: INSERT into `content` table]
  |      |       |-> trend_id, best_hook_text, hook_type, viral_score
  |      |       |-> status = 'queued'
  |      |       |-> Inserts top 2-3 hook variants per qualifying trend
  |      |
  |      +--> [Execute Sub-Workflow: L3-Content-Lab (pass content_ids)]
  |      |       OR
  |      +--> [Webhook: POST to L3 workflow with content_ids]
  |
  |      No  -> [End: No content production needed]
  |
  +--> [Code Node: Scoring Calibration Check (weekly)]
         |-> If day_of_week == 0 (Sunday):
         |     Compute PSI, Spearman correlation, KL divergence
         |     If drift detected: flag for model retrain
```

[INFERENCE: based on LLM scoring rubric (iter-3), GBDT pipeline (iter-4), calibration triggers (iter-4), hook generation (iter-3)]

#### Workflow 3: L2 -> L3 Handoff Design

**Trigger mechanism**: The L2 workflow inserts rows into the `content` table with `status='queued'`, then:

**Option A (Preferred): Sub-Workflow Call**
- L2 calls L3-Content-Lab via Execute Sub-workflow node
- Passes content_ids as input items
- L3 picks up queued items and begins production pipeline
- L2 does NOT wait for L3 completion (production takes hours)
- Use n8n's webhook-based async pattern for this

**Option B: DB Polling**
- L3-Content-Lab has its own Schedule Trigger: `*/30 * * * *` (every 30 min)
- Polls `content` table WHERE status='queued' ORDER BY viral_score DESC
- Picks up top N items per cycle
- More resilient to L2 failures (decoupled)

**Recommended**: Option B (DB polling) for production resilience. Option A as supplementary immediate trigger for SURGING trends (viral_potential >= 0.85).

**Data Flow Through DB Tables:**

```
L1 Trend Discovery                    L2 Viral Brain                       L3 Content Lab
                                                                    
[Sources: pytrends,                   [Reads `trends`]                     [Reads `content`]
 TikTok CC, YouTube]                       |                                    |
       |                              [LLM Scoring]                        [Script Gen]
       v                                   |                                    |
  +----------+                        [Hook Gen]                           [TTS/Video]
  | trends   |<--- UPSERT ---|             |                                    |
  +----------+                |        [Composite Score]                   [Quality Check]
  | id       |                |             |                                    |
  | platform |                |        [GBDT Override]                          |
  | keyword  |                |             |                                    v
  | velocity |                |             v                              +---------+
  | status   |                |    +------------+                          | content |
  +----------+                +--->| trends     |--- viral_score --------->| (updated|
                                   | (updated)  |                          |  status)|
                                   +------------+                          +---------+
                                        |
                                        | IF viral_potential >= 0.70
                                        v
                                   +----------+
                                   | content  |<--- INSERT (queued) ---|
                                   +----------+                        |
                                   | id       |                        |
                                   | trend_id |--- FK to trends.id ----|
                                   | hook_text|
                                   | hook_type|
                                   | viral_score|
                                   | status   |  queued -> producing -> review -> published
                                   +----------+
```

[INFERENCE: based on gen1 DB schema, n8n sub-workflow patterns, and all prior iteration findings]

### Finding 4: Error Handling and Partial Data Strategy (Q12)

**Per-Source Failure Isolation:**
- Each data source runs as a separate sub-workflow
- If pytrends fails (429 rate limit): L1 continues with TikTok CC + YouTube data only
- If Apify fails (actor timeout/billing): L1 continues with pytrends + YouTube data only
- If YouTube API fails (quota exceeded): L1 continues with pytrends + TikTok CC only
- Merge node uses "Append" mode -- works with whatever data arrives

**n8n Error Handling Pattern:**
```
[Sub-Workflow: L1-Source-Google-Trends]
  |
  Success -> [Merge Node]
  Error   -> [Error Trigger Node]
              |-> Log error to monitoring (Slack/Discord notification)
              |-> Return empty array [] to Merge Node (graceful degradation)
```

**Partial Data Scoring:**
- If only 1 of 3 sources returned data, freshness_score weights adjust dynamically:
  - Missing Google Trends: redistribute 0.40 weight to TikTok (0.55) + YouTube (0.35) + recency (0.10)
  - Missing TikTok CC: redistribute 0.30 weight to Google (0.55) + YouTube (0.35) + recency (0.10)
  - If only 1 source: use that source's velocity as 0.80 + recency 0.20
- Mark trend with `data_completeness` field: 3/3, 2/3, or 1/3 sources
- Trends with 1/3 source completeness get a -0.10 penalty on viral_potential (lower confidence)

**Monitoring:**
- n8n built-in execution log tracks all workflow runs
- Dead Letter Queue: failed trend items written to `trend_errors` table for manual review
- Daily summary workflow: count of trends discovered, scored, queued for production, errors

[INFERENCE: based on n8n error handling docs and multi-source architecture design]
[SOURCE: https://docs.n8n.io/flow-logic/subworkflows/]

### Finding 5: BERTopic as Microservice (Architecture Decision for n8n)

BERTopic with `partial_fit()` requires persistent Python state (the topic model must stay loaded in memory between calls). n8n's Code Node runs JavaScript, not Python. Design solution:

**BERTopic Microservice:**
- Standalone Python FastAPI service alongside n8n
- Endpoints: `POST /cluster` (accepts trend documents, returns cluster assignments)
- Loads `paraphrase-multilingual-MiniLM-L12-v2` model at startup
- Keeps BERTopic model in memory, calls `partial_fit()` on each request
- Persists model to disk after each update (recovery on restart)
- n8n calls via HTTP Request node: `POST http://bertopic-service:8000/cluster`

**Why not n8n Code Node:**
- BERTopic + sentence-transformers requires ~2GB RAM and GPU-optional compute
- n8n Code Node has execution timeout limits
- Model must persist between workflow executions (n8n nodes are stateless)
- Separation allows independent scaling and model updates

**Alternative**: If BERTopic microservice is too heavy for MVP, use a simpler TF-IDF + cosine similarity clustering directly in n8n Code Node as Phase 0. Migrate to BERTopic microservice once trend volume justifies it.

[INFERENCE: based on BERTopic requirements from iter-2, n8n architecture constraints]

## Ruled Out
- **Single monolithic n8n workflow for L1+L2**: Too complex for debugging, n8n performance degrades with 50+ nodes. Sub-workflow pattern is mandatory.
- **Real-time webhook from data sources to L2**: Data sources (pytrends, Apify, YouTube API) do not support push/webhook notifications. Polling is the only option.
- **tiktok-discover-api.vercel.app as production source**: The self-hosted API returned 404 on multiple endpoint patterns during this iteration. The service appears unreliable. Use Apify actor as primary TikTok CC source.

## Dead Ends
- **tiktok-discover-api.vercel.app endpoints**: Tried `/api/getTrendingHastag?region=TH` and `/api/trending/hashtag?region=TH` -- both returned 404. The free unofficial API appears down or has changed its URL structure without documentation update. Not viable for production use.

## Sources Consulted
- https://apify.com/doliz/tiktok-creative-center-scraper -- Full input/output schema for TikTok CC scraper
- https://docs.n8n.io/flow-logic/subworkflows/ -- n8n sub-workflow architecture
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/ -- Schedule Trigger node
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.executeworkflow/ -- Execute Sub-workflow node
- https://n8nautomation.cloud/blog/schedule-workflows-in-n8n-cron-jobs-intervals-time-based-triggers -- Best practices
- https://thinkpeak.ai/scheduling-n8n-workflows-with-cron/ -- Cron scheduling patterns
- https://markaicode.com/n8n-cron-jobs-scheduled-automation/ -- 2026 n8n scheduling reference

## Assessment
- New information ratio: 0.90
- Questions addressed: Q3, Q12
- Questions answered: Q3 (COMPLETED), Q12 (ANSWERED)

## Reflection
- What worked and why: The Apify actor page provided the exact JSON schemas that were missing from prior iterations. WebSearch for n8n sub-workflow patterns yielded authoritative docs links. Synthesizing the orchestration design from all prior iteration findings (velocity, scoring, hooks, GBDT, calibration) into a concrete n8n workflow chain was the most productive action -- it forced integration of all 11 prior answers into a cohesive system.
- What did not work and why: The tiktok-discover-api.vercel.app free API is down (404 on all attempted endpoints). This confirms it is not suitable for production. The n8n sub-workflow docs page rendered only navigation structure, not content details, but the WebSearch results provided sufficient context.
- What I would do differently: For the n8n orchestration, I would have started with this question earlier -- it forces architectural integration of all other findings and would have surfaced gaps sooner (e.g., the BERTopic microservice requirement was not obvious until designing the n8n data flow).

## Recommended Next Focus
All 12 questions are now answered. Recommended next iteration: **Consolidation and contradiction check** -- review all 5 iteration findings for internal consistency, cross-reference architecture decisions, identify any remaining gaps or contradictions between the orchestration design (Q12) and the individual component designs (Q1-Q11). Compute a final architecture summary.
