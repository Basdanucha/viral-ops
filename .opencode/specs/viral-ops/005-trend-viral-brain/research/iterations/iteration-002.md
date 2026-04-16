# Iteration 2: pytrends Advanced Config, TikTok Creative Center Deep Dive, BERTopic Thai+Multilingual

## Focus
Deep dive into three remaining data source and processing questions from iteration 1:
- Q2: pytrends advanced usage -- rate limits, real-time vs daily, geo-filtering Thailand, polling strategy
- Q3: TikTok Creative Center -- data fields, scraping mechanics, Apify actor, freshness
- Q5: BERTopic -- Thai+English mixed text, embedding model selection, online/incremental learning

## Findings

### Finding 1: pytrends Rate Limiting and Methods (Q2)
**pytrends has NO built-in rate limit -- it relies on Google's server-side throttling.** The library implements exponential backoff via `Retry` for HTTP 429/500/502/504 errors but does not enforce any requests-per-minute cap. Google's own enforcement returns `"You have reached your quota limit"` errors.

Key methods for viral-ops L1:
- `realtime_trending_searches(pn, cat, count)` -- real-time trends with story summaries
- `trending_searches(pn)` -- hot daily searches by region
- `today_searches(pn)` -- today's trending searches
- `related_queries()` -- returns BOTH `rising` and `top` related terms (critical for trend expansion)
- `related_topics()` -- related topics with rising/top split
- `interest_over_time()` -- time-series volume data for trend velocity measurement
- `interest_by_region(resolution)` -- geographic breakdown

Geo-filtering: `geo='TH'` works (standard ISO 3166-1 alpha-2). Category filtering via `cat=N` (integer IDs fetched from `categories()` method). The `gprop` parameter filters by Google property: `''` (web), `'youtube'`, `'images'`, `'news'`, `'froogle'` (shopping) -- **youtube gprop is directly useful for L1**.

**IMPORTANT: The pytrends GitHub repository was ARCHIVED on April 17, 2025 (read-only).** This means no future updates. The `pytrends-modern` fork (identified in iteration 1) becomes the recommended path for proxy rotation and maintained code.

[SOURCE: https://github.com/GeneralMills/pytrends/blob/master/pytrends/request.py]

### Finding 2: pytrends Polling Strategy for n8n (Q2)
Recommended n8n polling strategy based on rate limit behavior:
- **No official rate limit number exists** -- empirical reports suggest ~10-20 requests/minute is safe without proxies
- Use `backoff_factor` parameter in pytrends constructor for automatic retry
- For n8n cron: poll `trending_searches(pn='thailand')` every 2 hours (matching gen1 architecture)
- Use `interest_over_time()` as a secondary signal to measure trend velocity (rising vs declining)
- `gprop='youtube'` can provide YouTube-specific trend data through Google Trends (complementing YouTube Data API)
- The archived status of pytrends means `pytrends-modern` (with proxy rotation via `proxy_list` and cookie refresh) should be used for production

Timeframe options for `build_payload()`:
- `'now 1-H'` -- last hour (real-time)
- `'now 4-H'` -- last 4 hours
- `'today 1-m'` -- last 30 days
- `'today 3-m'` -- last 90 days
- `'today 5-y'` -- last 5 years (default)

[SOURCE: https://github.com/GeneralMills/pytrends/blob/master/pytrends/request.py]
[INFERENCE: based on pytrends source code analysis + gen1 n8n cron schedule of 2h]

### Finding 3: TikTok Creative Center Data Fields and Access (Q3)
TikTok Creative Center (`ads.tiktok.com/business/creativecenter/`) provides **5 trending categories**:
1. **Trending Hashtags** -- name, post count (e.g., "337K Posts"), industry category, rank position, rank change (up/down arrows), "New to top 100" badge
2. **Trending Videos** -- captions, hashtags, creators, sounds, metrics, timestamps
3. **Trending Creators** -- creator profiles with engagement metrics
4. **Trending Songs/Sounds** -- sound usage counts, associated videos
5. **Top Ads** -- best-performing ad creatives by region/vertical

Filter options on the hashtags page:
- **Region**: dropdown with "All regions" default (Thailand available)
- **Industry**: category dropdown for vertical filtering
- **Time period**: URL parameter `period=7` confirmed (7-day window), likely also 30-day and 120-day options
- **Pagination**: 20 items per page with "View More" button

**Access model**: Login required for full functionality. The page shows a "Log in" prompt, suggesting business account authentication is needed for complete data access. However, the public-facing page does render some data before login.

[SOURCE: https://ads.tiktok.com/business/creativecenter/inspiration/popular/hashtag/pc/en]

### Finding 4: Apify TikTok Creative Center Scraper (Q3)
The Apify actor `doliz/tiktok-creative-center-scraper` scrapes all 5 categories (Top Ads, Trending Videos, Trending Creators, Trending Songs, Trending Hashtags). Key details:
- **Pricing**: Pay-per-event model with free trial available
- **Output**: Structured JSON data
- **Categories supported**: All 5 trending types
- **Input schema**: Not fully documented on the API page -- likely accepts region, trending type, and period as parameters
- **Limitation**: Detailed input/output field schemas not exposed on the public API docs page; requires running a test execution to see full output structure

For viral-ops, the Apify actor provides a scraping abstraction layer that handles:
- Authentication/cookie management against TikTok Creative Center
- Region filtering (Thailand)
- Structured JSON output ready for n8n webhook ingestion

Alternative: The `tiktok-discover-api.vercel.app` project exposes a free unofficial API layer over Creative Center endpoints, which could be self-hosted for zero-cost operation.

[SOURCE: https://apify.com/doliz/tiktok-creative-center-scraper/api]
[SOURCE: https://tiktok-discover-api.vercel.app/]

### Finding 5: BERTopic Multilingual Configuration for Thai+English (Q5)
BERTopic supports multilingual topic modeling with specific configuration:

**Embedding model selection for Thai+English mixed text:**
- `paraphrase-multilingual-MiniLM-L12-v2` -- BERTopic's built-in multilingual default (50+ languages, 384 dims). Fastest option.
- `multilingual-e5-large` (mE5) -- higher quality for cross-lingual semantic similarity but heavier (1024 dims)
- `WangchanBERTa` (`airesearch/wangchanberta-base-att-spm-uncased`) -- Thai-specific, pre-trained on 78GB Thai text. Best for Thai-only content but DOES NOT handle English well.

**Recommended approach for viral-ops mixed Thai+English trend text:**
Use `paraphrase-multilingual-MiniLM-L12-v2` as the primary embedding model. It handles Thai, English, and code-switched text (common in Thai social media). WangchanBERTa is overkill for trend clustering since trend texts are short and mixed-language.

Configuration:
```python
from sentence_transformers import SentenceTransformer
from bertopic import BERTopic

embedding_model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
topic_model = BERTopic(embedding_model=embedding_model, language="multilingual")
```

Topic representation can be improved with `MaximalMarginalRelevance` (diversity 0.3-0.7) and `KeyBERTInspired` to reduce stopword noise in Thai.

[SOURCE: https://maartengr.github.io/BERTopic/getting_started/tips_and_tricks/tips_and_tricks.html]
[SOURCE: https://arxiv.org/abs/2101.09635 -- WangchanBERTa paper]

### Finding 6: BERTopic Online/Incremental Learning for Real-Time Trends (Q5)
BERTopic supports online topic modeling via `.partial_fit()` with specific constraints:

**Required components for online mode:**
- `IncrementalPCA(n_components=5)` replaces UMAP for dimensionality reduction
- `MiniBatchKMeans(n_clusters=50)` replaces HDBSCAN for clustering
- `OnlineCountVectorizer(decay=0.01)` handles vocabulary growth with time-weighted decay
- Pre-trained embedding model (no updates needed -- SentenceTransformer stays frozen)

**Critical constraint**: `.partial_fit()` CANNOT be used after `.fit()` -- they use fundamentally different internal state management. Must choose one mode from the start.

**River integration for streaming**: River's `DBSTREAM` clustering can dynamically create new clusters as new data arrives, enabling automatic detection of emerging trend topics without retraining.

**Decay mechanism**: The `decay` parameter (0-1) controls how quickly old topic frequencies diminish. A value of 0.01 means 1% reduction per iteration, keeping recent trends weighted higher. `delete_min_df` removes words below a frequency threshold, preventing matrix bloat.

**Key limitation**: Only the most recent batch of documents is tracked internally. For viral-ops, this means each n8n polling cycle feeds a new batch, and old trend topics naturally fade via decay.

**Recommended viral-ops configuration:**
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

[SOURCE: https://maartengr.github.io/BERTopic/getting_started/online/online.html]

## Ruled Out
- **WangchanBERTa as primary BERTopic embedding**: Thai-only model, cannot handle the English+Thai mixed text common in Thai social media trends. Use multilingual model instead.
- **pytrends (original) for production**: Repository archived April 2025. Use `pytrends-modern` fork for maintained proxy rotation and cookie handling.

## Dead Ends
- **WangchanBERTa for mixed-language trend clustering**: Definitively unsuitable -- it's a Thai-only RoBERTa variant that will produce garbage embeddings for English tokens. Not a "try harder" situation; the model architecture lacks English vocabulary.

## Sources Consulted
- https://github.com/GeneralMills/pytrends/blob/master/pytrends/request.py (archived April 2025)
- https://ads.tiktok.com/business/creativecenter/inspiration/popular/hashtag/pc/en
- https://apify.com/doliz/tiktok-creative-center-scraper/api
- https://tiktok-discover-api.vercel.app/
- https://maartengr.github.io/BERTopic/getting_started/tips_and_tricks/tips_and_tricks.html
- https://maartengr.github.io/BERTopic/getting_started/online/online.html
- https://arxiv.org/abs/2101.09635 (WangchanBERTa paper)
- https://arxiv.org/pdf/2402.03067 (Multilingual BERTopic for short text)

## Assessment
- New information ratio: 0.83
- Questions addressed: Q2, Q3, Q5
- Questions answered: Q2 (pytrends advanced -- rate limits, methods, geo, polling), Q5 (BERTopic Thai+English config + online learning)

## Reflection
- What worked and why: Fetching pytrends source code directly gave authoritative method signatures and parameter details. BERTopic official docs had comprehensive online learning examples. Multiple independent sources confirmed multilingual model recommendations.
- What did not work and why: Apify actor API page was sparse -- the public docs do not expose full input/output schemas. The TikTok Creative Center page required login for full data access, limiting what could be extracted from the public page.
- What I would do differently: For TikTok Creative Center, try fetching the `tiktok-discover-api.vercel.app` endpoints directly to see actual response schemas. For Apify, run a test execution or fetch the README page instead of the API reference.

## Recommended Next Focus
1. **Q3 completion**: Fetch `tiktok-discover-api.vercel.app` API docs to get actual response JSON schemas for trending hashtags/sounds/videos
2. **Q6: Trend freshness & velocity** -- how to measure trend momentum using pytrends `interest_over_time()` data, define rising/peaking/declining states, and set timing windows for content creation triggers
3. **Q7: LLM-as-judge scoring rubric** -- design the 6-dimension prompt template with exact scoring scales
