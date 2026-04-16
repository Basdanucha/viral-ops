# L1 Trend Layer + L2 Viral Brain -- Research Synthesis

> Progressive synthesis from deep research iterations. Updated after each iteration.

---

## 1. Trend Data Sources (L1 Layer)

### Source Viability Matrix (as of 2026)

| Source | Status | Thai Support | Rate/Quota | Verdict |
|--------|--------|-------------|------------|---------|
| **YouTube Data API v3** | Fully functional | `regionCode=TH` | 10,000 units/day free, 1 unit/call | PRIMARY -- best official API |
| **pytrends** (Google Trends) | Functional, rate-limited | `geo='TH'` | ~1,400 requests before throttle | PRIMARY -- rising/top queries |
| **TikTok Creative Center** | Free, no auth for most | Region filter available | Unofficial, scraping-based | SECONDARY -- via Apify actor |
| **snscrape** | DEAD for our needs | N/A | N/A | ELIMINATED -- never supported TikTok/YT |

### YouTube Data API v3 (Confirmed Ready)
- **Endpoint**: `videos.list(chart='mostPopular', regionCode='TH', videoCategoryId=N)`
- **Response**: snippet (title, desc, tags), statistics (views, likes, comments), contentDetails, topicDetails
- **Limits**: maxResults 1-50 per call, 1 unit quota cost, 10,000 units/day free
- **Efficiency**: Can fetch up to 500,000 trending video records per day within free quota
- **No deprecation notices** as of 2026

### pytrends / Google Trends (Fully Researched -- Q2 ANSWERED)
- **Key methods for L1**:
  - `realtime_trending_searches(pn, cat, count)` -- real-time trends with story summaries
  - `trending_searches(pn='thailand')` -- hot daily searches by region
  - `today_searches(pn)` -- today's trending searches
  - `related_queries()` -- returns BOTH `rising` and `top` related terms (critical for trend expansion)
  - `related_topics()` -- related topics with rising/top split
  - `interest_over_time()` -- time-series volume for trend velocity measurement
  - `interest_by_region(resolution)` -- geographic breakdown
- **Geo-filtering**: `geo='TH'` for Thailand (ISO 3166-1 alpha-2). Category filtering via `cat=N` (integer IDs from `categories()` method).
- **Google property filter** (`gprop`): `''` (web), `'youtube'`, `'images'`, `'news'`, `'froogle'` -- **`gprop='youtube'` gives YouTube-specific trend data through Google Trends**
- **Timeframe options**: `'now 1-H'` (last hour), `'now 4-H'` (4 hours), `'today 1-m'` (30 days), `'today 3-m'` (90 days), `'today 5-y'` (default)
- **Rate limits**: NO built-in rate limit in pytrends. Google server-side throttling returns 429 errors. Exponential backoff via `Retry` handles 429/500/502/504. Empirical safe range: ~10-20 requests/minute without proxies.
- **CRITICAL**: pytrends repo **ARCHIVED April 17, 2025** (read-only). Use `pytrends-modern` fork for production (proxy rotation, cookie refresh, maintained code).
- **n8n polling strategy**: `trending_searches(pn='thailand')` every 2h via cron. Use `interest_over_time()` as secondary signal for trend velocity. `gprop='youtube'` complements YouTube Data API.

### TikTok Trend Discovery (Q3 -- FULLY ANSWERED)
- **Creative Center** (`ads.tiktok.com/business/creativecenter`): 7 data categories via Apify actor:
  1. **Trending Hashtags** -- hashtag_id, hashtag_name, publish_cnt, video_views, rank, rank_diff_type, trend[] time-series, country_info, is_promoted
  2. **Trending Videos** -- id, item_id, title, cover (thumbnail URL), duration, item_url, country_code, region
  3. **Trending Songs** -- song_id, title, author, rank, rank_diff, trend[] time-series, duration, cover, if_cml (commercial flag), related_items[]
  4. **Trending Creators** -- user_id, nick_name, avatar_url, follower_cnt, liked_cnt, tt_link, items[] (recent videos with vv, liked_cnt, create_time)
  5. **Top Ads** -- available via Apify actor (materials array)
  6. **Keywords** -- keyword insights, related videos, related keywords and hashtags
  7. **Creative Patterns** -- creative insights, top products
- **Filters**: Region (Thailand = "TH"), Industry category (optional), time period (`period` = "7", "30", or "120" days). Pagination via page + limit params.
- **Access**: Apify actor handles auth/cookie management automatically.
- **Apify actor** (`doliz/tiktok-creative-center-scraper`): $0.002 per item. At 100 hashtags + 20 videos per 2h poll = ~$0.24/day.
- **Self-hosted alternative**: `tiktok-discover-api.vercel.app` -- UNRELIABLE (returned 404 on multiple endpoint patterns in iteration 5). Not recommended for production.
- **Research API**: Academic-only. NOT suitable for commercial use.

**Complete JSON Schema -- Trending Hashtags:**
```json
{
  "hashtag_id": "string",
  "hashtag_name": "string",
  "country_info": { "id": "string", "value": "string", "label": "string" },
  "is_promoted": "boolean",
  "trend": [{ "time": "unix_timestamp", "value": "usage_count" }],
  "publish_cnt": "number (total posts)",
  "video_views": "number (total views)",
  "rank": "number",
  "rank_diff_type": "number (rank movement)"
}
```

**Complete JSON Schema -- Trending Creators:**
```json
{
  "tcm_id": "string", "user_id": "string", "nick_name": "string",
  "avatar_url": "URL", "country_code": "string",
  "follower_cnt": "number", "liked_cnt": "number",
  "tt_link": "TikTok profile URL", "tcm_link": "Creative Center URL",
  "items": [{ "item_id": "string", "cover_url": "URL", "tt_link": "URL",
              "vv": "video_views", "liked_cnt": "number", "create_time": "unix_timestamp" }]
}
```

**TikTok CC to `trends` Table Mapping:**
| TikTok CC Field | `trends` Column | Transformation |
|----------------|-----------------|----------------|
| `hashtag_name` | `keyword` | Strip `#` prefix if present |
| `"tiktok"` | `platform` | Hard-coded constant |
| `"TH"` | `region` | From input parameter |
| `publish_cnt` | `interest_score` | Normalize to 0-100 |
| `trend[]` delta | `velocity_score` | Compute rate-of-change from time-series |
| First seen | `discovered_at` | `NOW()` on first insert |
| Lifecycle stage | `status` | Derived from velocity_score thresholds |

### snscrape (Eliminated)
- **Status**: Functionally unmaintained. 5.3k stars but Twitter scraping broken since June 2023.
- **Critical gap**: NEVER supported TikTok or YouTube. Gen1 mention was misleading.
- **Decision**: Remove from viral-ops architecture entirely. Replace with platform-specific APIs above.

---

## 2. Intelligence Layer (L2 Viral Brain)

### Trend Freshness & Velocity Model (Q6 ANSWERED)

**Velocity Formula (from pytrends `interest_over_time()` data):**
```
velocity = (current_period_avg - previous_period_avg) / previous_period_avg
```
Where periods are configurable: 7-day vs 7-day for stable trends, 24h vs 24h for fast-moving trends.

**Classification Thresholds:**

| Velocity Score | Classification | Content Action |
|---------------|----------------|----------------|
| > +0.50 | SURGING (+3) | Immediate production -- highest priority |
| +0.20 to +0.50 | RISING (+2) | Queue for next production cycle |
| +0.05 to +0.20 | EMERGING (+1) | Monitor, prepare concepts |
| -0.05 to +0.05 | STABLE (0) | Maintain existing content only |
| -0.20 to -0.05 | DECLINING (-1) | Do not start new content |
| -0.50 to -0.20 | FADING (-2) | Archive trend |
| < -0.50 | DEAD (-3) | Remove from active tracking |

**Trend Lifecycle Stages:**
1. **Emergence** (velocity > +0.20, strength < 30) -- weak signal, fast growth. Scout phase.
2. **Growth** (velocity > +0.20, strength 30-70) -- gaining momentum. Best window for content creation (48-72h production window).
3. **Peak** (velocity -0.05 to +0.05, strength > 70) -- high volume, flat momentum. Last viable production window.
4. **Decay** (velocity < -0.05, strength > 30) -- declining interest. Do not invest new production.
5. **Saturation** (velocity < -0.20, strength < 30) -- trend over. Archive.

**Multi-Source Freshness Score (composite):**
```
freshness_score = (
    0.40 * google_velocity_normalized +    # pytrends interest_over_time delta
    0.30 * tiktok_hashtag_growth_rate +    # TikTok Creative Center post count delta
    0.20 * youtube_view_velocity +          # YouTube trending video view acceleration
    0.10 * recency_bonus                    # hours since first detection (newer = higher)
)
```
Each component normalized to 0.0-1.0. Weights reflect source reliability: Google Trends is most stable, TikTok hashtag growth is fastest signal, YouTube provides validation.

### LLM-as-Judge Scoring Rubric (Q7 ANSWERED)

**Scale**: 1-5 categorical integer (NOT 0-10 or float). Research strongly favors this. Each score level has explicit definition per dimension.

**6 Dimensions with Weights:**

| Dimension | Weight | What It Measures |
|-----------|--------|------------------|
| Hook Strength | 0.25 | First 3 seconds -- does it stop the scroll? |
| Storytelling | 0.15 | Narrative arc, pacing, payoff |
| Emotional Trigger | 0.20 | Emotional activation (surprise, curiosity, FOMO, humor) |
| Visual Potential | 0.15 | Visual richness, B-roll opportunity, thumbnail appeal |
| Audio Fit | 0.10 | Trending sound alignment, voiceover clarity, music match |
| CTA Effectiveness | 0.15 | Clear action, urgency, engagement prompt |

**Key Design Principles:**
- Separate evaluation per dimension (NOT one mega-prompt for all 6)
- Few-shot calibration: 1-2 examples max (performance declines at 3+)
- Step decomposition: reasoning before scoring
- JSON structured output per evaluation

**Prompt Template:**
```
System: You are an expert short-form video content evaluator 
specializing in TikTok and YouTube Shorts viral potential.

Evaluate the following content concept on {DIMENSION_NAME} only.

## Scoring Scale:
- 5 = Exceptional: {dimension-specific criteria}
- 4 = Strong: {dimension-specific criteria}
- 3 = Adequate: {dimension-specific criteria}
- 2 = Weak: {dimension-specific criteria}
- 1 = Poor: {dimension-specific criteria}

## Example:
Concept: "{example concept}"
Score: {example score}
Reasoning: "{example reasoning}"

## Content to Evaluate:
Topic: {topic}
Hook: {hook_text}
Concept: {concept_description}
Target Niche: {niche}
Trend Context: {trend_name}, velocity={velocity_score}

Respond in JSON:
{"dimension": "{DIMENSION_NAME}", "score": <int 1-5>, 
 "reasoning": "<2-3 sentences>", "improvement_suggestion": "<if score < 4>"}
```

**Model Selection:**
- Phase 1 primary: GPT-4o-mini ($0.15/1M input, fast, good structured output)
- Phase 1 calibration: GPT-4o or Claude Sonnet (judge the judges)
- Thai content: DeepSeek-V3 as alternative (strong multilingual, lower cost -- needs benchmarking)

**Reliability Mitigations:**
- Run each dimension 2x and average (~10% garbage rate per run)
- Flag scores where 2 runs differ by >= 2 points for human review
- Pre-filter: score Hook Strength only first; only concepts >= 3 proceed to full evaluation
- Cost: ~$0.045/day at 100 concepts/day with GPT-4o-mini

**Calibration Protocol:**
1. Human-score 50 concepts across all 6 dimensions (gold standard)
2. Run LLM judge on same 50 concepts
3. Calculate Cohen's Kappa (target > 0.6 = substantial agreement)
4. Adjust rubric descriptions where disagreement is highest
5. Store best-aligned examples as few-shot calibration set

### Hook Variant Generation (Q8 ANSWERED)

**7 Hook Categories:**
1. **Question Hook** -- "Did you know 90% of Thai creators make this mistake?"
2. **Statistic/Shock Hook** -- "This trend got 50M views in 3 days."
3. **Controversy/Contrarian Hook** -- "Stop doing X -- here is why it is killing your reach."
4. **Curiosity Gap Hook** -- "I found the secret that top Thai creators use."
5. **Emotional Hook** -- "This will make you rethink everything about..."
6. **Pattern Interrupt Hook** -- "Wait -- watch what happens at 0:03."
7. **Authority/Social Proof Hook** -- "After 1,000 videos, here is what actually works."

**Generation Flow:**
- Input: trend_name + topic + niche + emotional_angle
- LLM generates 3-5 hooks (pick most relevant categories per topic)
- Constraint: max 15 words (must fit in first 3 seconds -- 71% of viewers decide in 3s)
- L2 scores each variant using Hook Strength dimension
- Top 2-3 hooks passed to L3 Content Lab for production

**A/B Testing Integration:**
- Content Lab produces 2-3 versions (same body, different hooks)
- 48h measurement window per variant
- L7 Analytics feeds back actual performance
- Performance data feeds GBDT training (Phase 2)

**Thai Hook Patterns:**
- Particle emphasis: emphatic particles (นะ, เลย, จริงๆ) for emotional punch
- Code-switching: "ทำไม [English trend term] ถึงได้ viral ขนาดนี้"
- Direct address: "คุณ" or "เธอ" for personal engagement
- Numeric anchoring: "3 สิ่งที่..." (numbers work across languages)

### Composite Viral Potential Score

```
viral_potential = (
    0.40 * content_quality_score +     # LLM-as-judge weighted 6-dim (1-5, normalized to 0-1)
    0.35 * trend_freshness_score +     # Multi-source velocity composite (0-1)
    0.15 * niche_fit_score +           # Topic-niche alignment (0-1)
    0.10 * timing_bonus                # Optimal posting time alignment (0-1)
)
```
Decision thresholds:
- >= 0.70: "PRODUCE NOW" (high priority)
- 0.50-0.69: "CONSIDER" (queue for review)
- < 0.50: "SKIP" (below threshold)

### BERTopic Clustering (Q5 ANSWERED)

**Embedding Model for Thai+English Mixed Text:**
- **Recommended**: `paraphrase-multilingual-MiniLM-L12-v2` -- 50+ languages including Thai, 384 dims, fastest option. Handles code-switched Thai+English text well.
- **Higher quality alternative**: `multilingual-e5-large` (mE5) -- 1024 dims, better cross-lingual similarity but heavier compute.
- **NOT recommended**: `WangchanBERTa` (`airesearch/wangchanberta-base-att-spm-uncased`) -- Thai-only RoBERTa variant pre-trained on 78GB Thai text. Produces garbage embeddings for English tokens. Unsuitable for mixed-language trend clustering.

**Configuration for viral-ops:**
```python
from sentence_transformers import SentenceTransformer
from bertopic import BERTopic

embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
topic_model = BERTopic(embedding_model=embedding_model, language="multilingual")
```

**Topic Representation Tuning:**
- `MaximalMarginalRelevance` (diversity 0.3-0.7) reduces duplicate meaning in topic words
- `KeyBERTInspired` reduces stopword noise (important for Thai particles)
- `ClassTfidfTransformer(reduce_frequent_words=True)` downweights common terms

**Online/Incremental Learning for Real-Time Trends:**
- `.partial_fit()` enables incremental processing per n8n polling cycle
- CANNOT mix with `.fit()` -- must choose online mode from the start
- Required components:
  - `IncrementalPCA(n_components=5)` replaces UMAP
  - `MiniBatchKMeans(n_clusters=50)` replaces HDBSCAN
  - `OnlineCountVectorizer(decay=0.01, delete_min_df=5)` handles vocabulary growth with time-weighted decay
- `decay=0.01` means 1% frequency reduction per iteration -- recent trends naturally weighted higher
- River `DBSTREAM` integration enables automatic detection of emerging topic clusters
- **Key limitation**: Only the most recent batch tracked internally. Old trends fade via decay mechanism -- this aligns well with viral-ops trend lifecycle needs.

```python
from sklearn.cluster import MiniBatchKMeans
from sklearn.decomposition import IncrementalPCA
from bertopic.vectorizers import OnlineCountVectorizer
from bertopic import BERTopic

topic_model = BERTopic(
    embedding_model="paraphrase-multilingual-MiniLM-L12-v2",
    umap_model=IncrementalPCA(n_components=5),
    hdbscan_model=MiniBatchKMeans(n_clusters=50, random_state=42),
    vectorizer_model=OnlineCountVectorizer(decay=0.01, delete_min_df=5),
    language="multilingual"
)

# Each n8n cycle feeds new trend documents
for trend_batch in n8n_trend_batches:
    topic_model.partial_fit(trend_batch)
```

### GBDT Model Training (Q9 ANSWERED)

**Feature Vector: 38 features from 5 categories:**

**A. LLM Score Features (6):** All six dimension scores from LLM-as-judge (hook_strength, storytelling, emotional_trigger, visual_potential, audio_fit, cta_effectiveness) -- int 1-5 each.

**B. Trend Features (8):** trend_velocity (float, pytrends rate-of-change), trend_lifecycle_stage (categorical: emergence/growth/peak/decay/saturation), trend_strength (float 0-100), tiktok_hashtag_post_count (int), tiktok_hashtag_growth_rate (float), youtube_trending_rank (int), freshness_score (float 0-1, composite), hours_since_detection (float).

**C. Temporal Features (6):** post_hour (int 0-23), post_day_of_week (int 0-6), is_weekend (binary), is_thai_holiday (binary), hour_sin/hour_cos (cyclical encoding). Research confirms temporal features are among strongest predictors for social media engagement.

**D. Content Metadata Features (10):** hook_category (categorical, 7 types), hook_word_count, niche_id (categorical), platform_target (categorical: tiktok/youtube_shorts/both), video_duration_target, has_trending_sound (binary), concept_word_count, hashtag_count, is_thai_language (binary), code_switch_ratio (float).

**E. Historical Performance Features (8, after first videos):** creator_avg_views_7d, creator_avg_engagement_7d, niche_avg_performance, similar_hook_category_performance, trend_topic_previous_performance, days_since_last_post, consecutive_post_count, best_performing_hour_match.

**LightGBM vs XGBoost Decision:**
- **LightGBM for production (500+ videos)**: 20x faster training, native categorical feature handling (no one-hot encoding needed for 4 categorical features), lower memory.
- **XGBoost for cold-start bootstrap (100-500 videos)**: More stable on small datasets due to level-wise growth (vs LightGBM's leaf-wise which can overfit small data).
- CatBoost considered but LightGBM preferred for speed in retraining loop.

**Target Metric: `log(views_168h / followers)`** -- Log-normalized view rate at T+168h (7 days). Normalizes for account size, uses regression (not binary classification), measured at a stable time horizon.

**Training Pipeline Phases:**
- **Phase 0 (0-100 videos)**: Use composite_viral_score formula directly. No ML. Store all features + outcomes.
- **Phase 1 (100-500 videos)**: Train XGBoost with 5-fold CV, max_depth=3, learning_rate=0.1. Compare against composite_viral_score baseline.
- **Phase 2 (500+ videos)**: Switch to LightGBM. Temporal train/val/test split 70/15/15. Hyperparameter tuning via Optuna (50-100 trials). Retrain weekly on 90-day rolling window.
- **Cold start bootstrapping**: (a) Use composite_viral_score as fallback, (b) Scrape competitor videos and apply LLM scoring for synthetic training data, (c) Transfer learning from public engagement datasets.

### Scoring Calibration & Feedback Loop (Q10 ANSWERED)

**Validation Pipeline (L7 → L2 Feedback):**
1. Store paired data: all 6 LLM scores + composite_viral_score + GBDT prediction + actual T+168h metrics per published video.
2. Weekly Spearman rank correlation per dimension vs actual views/engagement.
3. Track correlation trend on 30-day sliding window.
4. Flag any dimension with correlation < 0.15 for rubric review.

**Drift Detection Methods:**
| Method | Catches | Threshold |
|--------|---------|-----------|
| Population Stability Index (PSI) | Distribution shift in LLM scores | PSI > 0.20 = significant |
| KL Divergence | Asymmetric distribution change | KL > 0.10 per dimension |
| Page-Hinkley Test | Sudden scoring regime change | Online change-point detection |
| Correlation Decay | Score-to-performance divergence | Spearman < 0.20 for 2 weeks |
| Evidently AI | Automated drift dashboard | Pre-built drift reports |

**Retraining Triggers:**
- **Scheduled**: Weekly (Sunday 02:00 UTC), retrain GBDT on 90-day rolling window.
- **Score drift**: PSI > 0.20 for 2+ weeks → recalibrate LLM prompts, refresh few-shot examples.
- **Performance drop**: GBDT MAE increases 15%+ → immediate retrain with feature review.
- **Correlation collapse**: Spearman < 0.15 for 2+ weeks → review and possibly zero-weight the collapsed dimension.
- **LLM model update**: Re-run 50-concept gold standard calibration before switching models.
- **Data milestone**: 200+ new videos since last train → opportunistic retrain.

**A/B Test Integration:**
- Content Lab produces 2-3 hook variants per topic with separate video_ids.
- T+168h comparison: winner's features = positive examples, losers = negative examples.
- Differential analysis feeds back into hook_category performance statistics.

---

## 3. Thai-Specific Considerations (Q11 ANSWERED)

### PyThaiNLP for Trend Text Processing
- **Word segmentation** (critical -- Thai has no spaces): `word_tokenize(text, engine='han_solo')` for social media domain, `engine='deepcut'` for higher accuracy on formal text.
- **Hashtag parsing**: Thai hashtags are unsegmented (e.g., #ไม่กินก็ไม่ตาย). Strip `#`, run word_tokenize, extract meaningful terms for BERTopic.
- **Named Entity Recognition**: `pythainlp.tag.NER` for brand names, celebrities, locations in trend text.
- **Sentiment analysis**: Pre-labeled social media dataset (positive/neutral/negative/question) feeds emotional trigger dimension.
- **Processing pipeline**: Raw text → han_solo tokenize → strip particles (นะ, ครับ, ค่ะ) for clustering → keep particles for hook generation → langdetect per segment → code_switch_ratio feature.

### Thai Social Media Patterns
- **Platform dominance**: TikTok + YouTube Shorts primary for short-form. LINE for sharing (not discovery). Facebook for longer content.
- **Peak hours**: 19:00-22:00 ICT weekdays, 12:00-14:00 weekends. Secondary peak 22:00-01:00 for entertainment/humor.
- **Content preferences**: Comedy/humor, food, beauty/skincare, travel, relationship content dominate. "React" content uniquely popular in Thailand.

### Thai Viral Content Characteristics
- **Speed**: Thai trends move FAST -- 24-48h emergence to peak (vs 72-120h for global English). Production window may need tightening from 48-72h to **24-36h for Thai market**.
- **Celebrity amplification**: Single top-creator share can push trend from emergence to peak in <12h.
- **Humor patterns**: Slapstick, situational comedy, self-deprecating humor, "แกล้ง" (pranking) have disproportionate viral potential.
- **Strongest emotional triggers**: สงสาร (sympathy), ฮา (humor), ดราม่า (drama).

### Thai Internet Slang (For Trend Detection & Hook Generation)
| Slang | Meaning | Hook Usage |
|-------|---------|------------|
| 555 (ห้าห้าห้า) | Laughing ("hahaha") | Comedy hooks |
| มากๆ | Very very / so much | Emphasis amplifier |
| แม่ (mae) | "Queen" / "icon" | Celebrity content |
| สาย (saai) | "Type" / "category" | Niche targeting |
| จัดไป | "Let's go!" / "Do it!" | CTA hooks |
| ปัง (pang) | "Amazing" / "hit" | Trending hooks |
| แซ่บ (saeb) | "Spicy" / "fierce" | Beauty/fashion hooks |
| คือดีมาก | "It's so good" | Reaction/review hooks |

---

## 4. Orchestration (n8n) -- Q12 ANSWERED

### Workflow Architecture Overview

Three main n8n workflows, connected via sub-workflow calls and DB-mediated handoffs:

```
[L1-Trend-Discovery]  ──sub-workflow──>  [L2-Viral-Brain]  ──DB poll──>  [L3-Content-Lab]
   Cron: */2h                              Triggered by L1                  Cron: */30min
                                           + Catch-up: */6h                 Polls content.status='queued'
```

### Workflow 1: L1-Trend-Discovery

**Schedule**: Every 2 hours (Asia/Bangkok timezone)

**Three parallel sub-workflows per source:**

| Sub-Workflow | Cron | Source | Output |
|-------------|------|--------|--------|
| L1-Source-Google-Trends | `0 */4 * * *` (every 4h) | pytrends-modern: `trending_searches(pn='thailand')`, `realtime_trending_searches()`, `interest_over_time()` | keyword, interest_score, velocity_score |
| L1-Source-TikTok-CC | `0 */2 * * *` (every 2h) | Apify actor: `getTrendingHashtag(region=TH, period=7)`, `getTrendingVideos(region=TH)` | hashtag_name, publish_cnt, video_views, trend[] |
| L1-Source-YouTube | `30 */3 * * *` (every 3h) | YouTube Data API v3: `videos.list(chart=mostPopular, regionCode=TH)` | video tags, titles, view counts |

**Post-merge pipeline:**
1. Merge Node: combine all source results (Append mode -- works with partial data)
2. BERTopic Clustering: HTTP POST to Python microservice (`partial_fit()` on new documents)
3. Velocity Classification: apply thresholds (SURGING/RISING/EMERGING/STABLE/DECLINING/FADING/DEAD)
4. Postgres Upsert: `INSERT ... ON CONFLICT (platform, keyword, region) DO UPDATE`
5. IF SURGING or RISING trends found: trigger L2-Viral-Brain via Execute Sub-workflow

### Workflow 2: L2-Viral-Brain

**Trigger**: Execute Sub-workflow Trigger (from L1) OR Schedule Trigger every 6h (catch-up)

**Pipeline per qualifying trend:**
1. Fetch trends WHERE status IN ('emerging','active','peak') AND (scored_at IS NULL OR scored_at < NOW()-6h)
2. Hook Generation: LLM generates 3-5 hooks per trend (7 categories, max 15 words)
3. LLM-as-Judge: 6 dimensions scored separately, each run 2x and averaged (1-5 scale)
4. Composite Score: `viral_potential = 0.40*quality + 0.35*freshness + 0.15*niche + 0.10*timing`
5. GBDT Override (Phase 2, 500+ videos): 38-feature vector prediction replaces composite score
6. Postgres Update: SET viral_score, scored_at, hook_variants (JSONB) on `trends` table
7. IF viral_potential >= 0.70: INSERT into `content` table (status='queued', top 2-3 hooks per trend)
8. Trigger L3-Content-Lab (sub-workflow call for SURGING, or let L3 poll for normal priority)

### Workflow 3: L2 -> L3 Handoff

**Primary mechanism (recommended)**: DB Polling
- L3-Content-Lab runs on its own `*/30min` schedule
- Polls `content` WHERE status='queued' ORDER BY viral_score DESC LIMIT N
- Decoupled from L2 failures -- production resilience

**Supplementary mechanism**: Direct sub-workflow call
- For SURGING trends (viral_potential >= 0.85), L2 directly triggers L3 for immediate production
- Bypasses the 30-minute polling wait

### Data Flow Through DB Tables

```
L1: Sources ──> trends (UPSERT)
L2: trends (READ) ──> LLM Scoring ──> trends (UPDATE viral_score) ──> content (INSERT queued)
L3: content (READ queued) ──> Production ──> content (UPDATE status=producing/published)
L7: Analytics ──> content (UPDATE actual_views) ──> L2 feedback loop (weekly calibration)
```

**`trends` table lifecycle:**
- L1 creates/updates: keyword, platform, region, interest_score, velocity_score, status, discovered_at
- L2 updates: viral_score, scored_at, hook_variants (JSONB)
- Status flow: `emerging` -> `active` -> `peak` -> `declining` -> `dead`

**`content` table lifecycle:**
- L2 creates: trend_id (FK), hook_text, hook_type, viral_score, status='queued'
- L3 updates: status='producing' -> 'review' -> 'published', script_text, channel_id
- L7 updates: actual views/engagement for feedback loop

### Error Handling: Partial Data Strategy

Each data source runs as an isolated sub-workflow. If one source fails, others continue:

| Failure | Impact | Mitigation |
|---------|--------|------------|
| pytrends 429 (rate limit) | No Google Trends velocity | TikTok CC + YouTube continue. Freshness weights adjust: TikTok 0.55, YouTube 0.35, recency 0.10 |
| Apify timeout/billing | No TikTok hashtag data | pytrends + YouTube continue. Freshness: Google 0.55, YouTube 0.35, recency 0.10 |
| YouTube quota exceeded | No YouTube trending | pytrends + TikTok CC continue. Freshness: Google 0.50, TikTok 0.40, recency 0.10 |
| Single source only | Low confidence | Use that source 0.80 + recency 0.20. Apply -0.10 penalty to viral_potential. |

All errors logged to `trend_errors` table + Slack/Discord notification. Daily summary workflow reports: trends discovered, scored, queued, errors.

### BERTopic as Microservice

BERTopic requires persistent Python state (model in memory for `partial_fit()`). n8n Code Node runs JavaScript and is stateless.

**Solution**: Standalone Python FastAPI service
- `POST /cluster`: accepts trend documents, returns cluster assignments
- Loads `paraphrase-multilingual-MiniLM-L12-v2` at startup (~2GB RAM)
- Persists model to disk after each update (crash recovery)
- n8n calls via HTTP Request node

**Phase 0 alternative**: If microservice too heavy for MVP, use TF-IDF + cosine similarity in n8n Code Node. Migrate to BERTopic when trend volume justifies compute cost.

### Cron Schedule Summary

| Workflow | Cron | Frequency | Timezone |
|----------|------|-----------|----------|
| L1 Master (merge + cluster) | `0 */2 * * *` | Every 2h | Asia/Bangkok |
| L1-Google-Trends sub | `0 */4 * * *` | Every 4h | Asia/Bangkok |
| L1-TikTok-CC sub | `0 */2 * * *` | Every 2h | Asia/Bangkok |
| L1-YouTube sub | `30 */3 * * *` | Every 3h | Asia/Bangkok |
| L2-Viral-Brain (catch-up) | `0 */6 * * *` | Every 6h | Asia/Bangkok |
| L3-Content-Lab (poll) | `*/30 * * * *` | Every 30min | Asia/Bangkok |
| Calibration Check (weekly) | `0 2 * * 0` | Sunday 02:00 | UTC |
| GBDT Retrain (weekly) | `0 3 * * 0` | Sunday 03:00 | UTC |

---

## Open Questions -- ALL 12 ANSWERED

- ~~Q1 (snscrape): ANSWERED -- eliminated from architecture~~ (iteration 1)
- ~~Q2 (pytrends): ANSWERED -- rate limits, methods, geo, polling strategy documented~~ (iteration 2)
- ~~Q3 (TikTok Creative Center): ANSWERED -- complete JSON schemas for all categories, Apify actor input/output, field mapping to trends table~~ (iteration 5)
- ~~Q4 (YouTube API): ANSWERED -- endpoint, quota, region filtering confirmed~~ (iteration 1)
- ~~Q5 (BERTopic): ANSWERED -- multilingual embedding model selected, online learning config documented~~ (iteration 2)
- ~~Q6 (Trend freshness & velocity): ANSWERED -- velocity formula, classification thresholds, lifecycle model, multi-source freshness score~~ (iteration 3)
- ~~Q7 (LLM-as-judge scoring rubric): ANSWERED -- 1-5 scale, 6 dimensions with weights, prompt template, model selection, calibration protocol~~ (iteration 3)
- ~~Q8 (Hook variant generation): ANSWERED -- 7 hook categories, generation flow, A/B testing integration, Thai hook patterns~~ (iteration 3)
- ~~Q9 (GBDT model training): ANSWERED -- 38-feature vector, LightGBM for production/XGBoost for cold-start, log(views_168h/followers) target, 3-phase training pipeline~~ (iteration 4)
- ~~Q10 (Scoring calibration & feedback loop): ANSWERED -- PSI/KL/Page-Hinkley drift detection, weekly retraining, A/B test integration, Evidently AI monitoring~~ (iteration 4)
- ~~Q11 (Thai-specific NLP): ANSWERED -- PyThaiNLP han_solo for social media, Thai trend lifecycle 24-48h, peak hours 19-22 ICT, slang dictionary~~ (iteration 4)
- ~~Q12 (n8n orchestration): ANSWERED -- 3 workflow chain (L1->L2->L3), sub-workflow pattern, cron schedules, error handling, BERTopic microservice~~ (iteration 5)

## Architecture Decision: snscrape Replacement
**Decision**: Replace snscrape with a per-platform strategy:
- YouTube trending: YouTube Data API v3 (official, reliable)
- Google trends: pytrends / pytrends-modern (unofficial but functional)
- TikTok trends: Creative Center scraping via Apify (unofficial, needs reliability testing)
- Twitter/X trends: OUT OF SCOPE for viral-ops (platform too hostile to scrapers; focus on TikTok + YouTube + Google Trends)

---

## Questions Summary (All 12 Answered)

- [x] Q1: snscrape DEAD — Twitter broken 2023, TikTok/YouTube NEVER supported. Removed from architecture
- [x] Q2: pytrends-modern — geo='TH', related_queries(), trending_searches(), gprop='youtube'. Original repo archived Apr 2025
- [x] Q3: TikTok Creative Center — 5 categories (hashtags/videos/songs/creators/playlists), Apify actor, JSON schemas documented, maps to trends table
- [x] Q4: YouTube Data API v3 — videos.list(chart=mostPopular, regionCode=TH), 1 quota unit, 10K/day free, maxResults=50
- [x] Q5: BERTopic — paraphrase-multilingual-MiniLM-L12-v2, online learning via .partial_fit(), WangchanBERTa ruled out (Thai-only)
- [x] Q6: Trend freshness — velocity=(current-prev)/prev, lifecycle stages, composite freshness score from multi-source signals
- [x] Q7: LLM-as-judge — 1-5 categorical scale, separate prompt per dimension, 6 weighted dims, GPT-4o-mini primary, calibration protocol
- [x] Q8: Hook generation — 7 categories (question/statistic/controversy/emotion/curiosity/relatable/shock), 3-5 variants, Thai patterns
- [x] Q9: GBDT — LightGBM production (500+ videos), XGBoost cold-start, 38-feature vector, target=log(views_168h/followers), Optuna tuning
- [x] Q10: Calibration — PSI >0.20, KL >0.10, Page-Hinkley, Spearman <0.20 → retrain. Evidently AI monitoring. A/B test feedback
- [x] Q11: Thai — PyThaiNLP han_solo engine, 24-48h trend lifecycle (faster than global), peak 19-22 ICT, 11 slang entries
- [x] Q12: n8n orchestration — L1 Master(2h) → L2 event-triggered + catch-up(6h) → L3 poll(30min), sub-workflows, BERTopic as FastAPI microservice

---

## Convergence Report

- **Stop reason**: all_questions_answered
- **Total iterations**: 5
- **Questions answered**: 12/12
- **Convergence threshold**: 0.05
- **Info ratios**: 0.88 → 0.83 → 0.80 → 0.80 → 0.90

### Key Architectural Decisions
1. **snscrape REMOVED** — replace with per-platform strategy (YouTube API, pytrends, TikTok CC)
2. **Scoring scale 1-5** — changed from gen1's 0-10 (research shows categorical integers more reliable for LLM judges)
3. **Separate prompt per dimension** — LLMs perform better on single-objective scoring tasks
4. **BERTopic as FastAPI microservice** — n8n Code Node cannot host persistent Python models
5. **LightGBM over XGBoost** — faster training, native categorical support, better for production scale
6. **Thai trend lifecycle 24-48h** — production window must be tighter than global (72-120h)
7. **TF-IDF as Phase 0 alternative** — until trend volume justifies BERTopic compute cost
8. **Twitter/X dropped** — platform too hostile to scrapers, not worth the engineering effort

### Next Step
Implementation: `/spec_kit:plan` to design the n8n workflows, BERTopic microservice, LLM scoring prompts, and GBDT training pipeline.
