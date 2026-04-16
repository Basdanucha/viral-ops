# Iteration 1: Survey Trend Data Sources (2026 Status)

## Focus
Survey all four primary trend data sources identified in gen1 research to determine which tools are actually usable in 2026: snscrape, pytrends, TikTok APIs, and YouTube Data API v3. This is the foundational inventory iteration before deeper dives into individual tools.

## Findings

### 1. snscrape -- Effectively Dead for Twitter/X, Limited for Other Platforms
- **Repository**: github.com/JustAnotherArchivist/snscrape -- 5.3k stars, 776 forks, NOT archived but functionally unmaintained
- **Supported platforms listed**: Facebook, Instagram, Mastodon, Reddit, Telegram, Twitter, VKontakte, Weibo
- **Critical**: Twitter/X scraping broken since June 2023 (Issue #783, #996) -- Twitter locked behind login wall, no known workaround
- **Issue #1037** ("Question about the future of snscrape") -- user reports project "has been lasting for a few months" in broken state; maintainer response not visible but community sentiment is frustration
- **Python requirement**: 3.8+ (outdated minimum suggests stale maintenance)
- **NOT listed**: TikTok, YouTube -- snscrape never supported these platforms
- **Assessment**: snscrape is NOT viable for viral-ops. Twitter/X broken, TikTok/YouTube never supported. Must use alternatives.
- [SOURCE: https://github.com/JustAnotherArchivist/snscrape]
- [SOURCE: https://github.com/JustAnotherArchivist/snscrape/issues/996]
- [SOURCE: https://github.com/JustAnotherArchivist/snscrape/issues/1037]

### 2. pytrends -- Functional but Rate-Limited, Modern Fork Available
- **Repository**: github.com/GeneralMills/pytrends -- actively maintained, latest PyPI version 4.1.0
- **Rate limits**: No official limit documented. Practical limit ~1,400 sequential requests before throttle. Google blocks excessive requests. Recommended: 60s sleep between requests when rate-limited.
- **Geo-filtering**: Fully supported. Thailand = `geo='TH'`. Sub-regions available (e.g., `TH-10` for Bangkok).
- **Real-time trends**: `trending_searches(pn='thailand')` for real-time; `realtime_trending_searches()` for live trends
- **Key methods**: `interest_over_time()`, `interest_by_region()`, `related_topics()`, `related_queries()`, `trending_searches()`, `suggestions()`
- **Rising vs Top**: `related_queries()` returns both "top" (highest volume) and "rising" (fastest growing) -- critical for trend velocity detection
- **Modern alternative**: `pytrends-modern` (v0.2.5) -- enhanced error handling, automatic retries, rate limit management, proxy rotation, smart backoff
- **Google Trends official API**: Launched 2025, still in alpha with limited endpoints and quotas. 1,500/day quota.
- **Assessment**: pytrends is VIABLE. Core tool for L1. Consider pytrends-modern for production robustness.
- [SOURCE: https://github.com/GeneralMills/pytrends]
- [SOURCE: https://pypi.org/project/pytrends-modern/0.2.4/]
- [SOURCE: https://github.com/GeneralMills/pytrends/issues/523]

### 3. TikTok Trend APIs -- Multiple Access Paths, Creative Center is Best
- **TikTok Research API**: Academic/research only. Must submit research plan for approval. Strict data use limits. NOT suitable for commercial trend discovery.
- **TikTok Creative Center**: Free, no login required for most features. Shows trending hashtags, sounds, creators, videos. Filterable by region and time (7-30 days). This is the primary trend discovery surface.
- **TikTok Developer Portal** (developers.tiktok.com): Offers Hashtag Analytics API, Trending Content API, Display API. Requires app registration.
- **Video Query API**: Available at `developers.tiktok.com/doc/research-api-specs-query-videos/` for querying video data programmatically
- **Third-party scraping**: Apify has a "TikTok Creative Center Scraper" actor for programmatic access to Creative Center data
- **Scrapfly guide**: Documents unofficial API endpoints for TikTok trend scraping
- **TickerTrends**: Third-party API providing TikTok hashtag analytics and time-series data
- **Assessment**: Creative Center (free, no auth) + Apify scraper is the pragmatic path. Research API for academic only. Official Developer APIs require app approval.
- [SOURCE: https://developers.tiktok.com/]
- [SOURCE: https://creatify.ai/blog/tiktok-creative-center]
- [SOURCE: https://apify.com/doliz/tiktok-creative-center-scraper/api]
- [SOURCE: https://scrapfly.io/blog/posts/guide-to-tiktok-api]

### 4. YouTube Data API v3 -- Fully Functional, Low Cost, Best Official API
- **Endpoint**: `videos.list(chart='mostPopular', regionCode='TH')`
- **regionCode**: ISO 3166-1 alpha-2. Thailand = `TH`. Works only with `chart` parameter.
- **videoCategoryId**: Filter by category (default=0 for all). Categories available via `videoCategories.list`.
- **maxResults**: 1-50 per request (default 5)
- **Quota**: 10,000 units/day free. `videos.list` costs only 1 unit per call. Compare: `search.list` costs 100 units.
- **Response parts**: `snippet` (title, description, tags, thumbnails), `statistics` (views, likes, comments), `contentDetails` (duration, definition), `topicDetails` (topic categories)
- **Cost efficiency**: At 1 unit/call with 50 results each, you can fetch 500,000 trending videos per day within free quota
- **No deprecation**: Endpoint fully supported, no deprecation notices
- **Quota increase**: Can apply for higher quota through Google Cloud Console
- **Assessment**: BEST data source for viral-ops. Official, reliable, generous quota, Thai region support.
- [SOURCE: https://developers.google.com/youtube/v3/docs/videos/list]
- [SOURCE: https://developers.google.com/youtube/v3/determine_quota_cost]
- [SOURCE: https://www.getphyllo.com/post/youtube-api-limits-how-to-calculate-api-usage-cost-and-fix-exceeded-api-quota]

## Ruled Out
- **snscrape for Twitter/X**: Broken since June 2023, no fix available. Platform locked behind login wall.
- **snscrape for TikTok/YouTube**: Never supported these platforms at all. Gen1 mention was misleading -- snscrape cannot scrape TikTok or YouTube.
- **TikTok Research API for commercial use**: Academic-only, requires research plan approval, strict data use policies.

## Dead Ends
- **snscrape as multi-platform scraper for viral-ops**: Definitively eliminated. The platforms we need (TikTok, YouTube) were never supported, and its Twitter support is broken. Should be removed from the architecture.

## Sources Consulted
- https://github.com/JustAnotherArchivist/snscrape (repo page + issues #996, #1037, #783)
- https://github.com/GeneralMills/pytrends (repo + issue #523)
- https://pypi.org/project/pytrends-modern/0.2.4/
- https://developers.tiktok.com/ (developer portal)
- https://creatify.ai/blog/tiktok-creative-center (Creative Center guide 2026)
- https://apify.com/doliz/tiktok-creative-center-scraper/api
- https://scrapfly.io/blog/posts/guide-to-tiktok-api
- https://developers.google.com/youtube/v3/docs/videos/list
- https://developers.google.com/youtube/v3/determine_quota_cost
- https://www.getphyllo.com/post/youtube-api-limits-how-to-calculate-api-usage-cost-and-fix-exceeded-api-quota

## Assessment
- New information ratio: 0.88
- Questions addressed: Q1 (snscrape), Q2 (pytrends), Q3 (TikTok APIs), Q4 (YouTube API)
- Questions answered: Q1 (snscrape confirmed dead for our needs), Q4 (YouTube API fully documented)

## Reflection
- What worked and why: Direct GitHub repo fetching gave authoritative snscrape status. Web search provided comprehensive pytrends and YouTube API details. Multiple independent sources confirmed each finding.
- What did not work and why: snscrape issue #1037 didn't show maintainer response (GitHub rendering limitation in WebFetch). Would need to check via `gh` CLI for full thread.
- What I would do differently: For TikTok, a deeper dive into Creative Center scraping mechanics and Apify actor capabilities would yield more actionable implementation details.

## Recommended Next Focus
Deep dive into TikTok Creative Center scraping mechanics (Apify actor, unofficial endpoints, rate limits) and pytrends advanced configuration (proxy rotation, real-time polling strategy, Thailand-specific patterns). These two sources need implementation-level detail since YouTube API is already clear and snscrape is eliminated.
