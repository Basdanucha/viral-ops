# Iteration 9: Intelligence Layers — Trend Layer + Viral Brain

## Focus
Pivoting from the completed infrastructure stack (iterations 1-8) to the intelligence layers that differentiate viral-ops from "just another AI video generator." Two areas investigated: (1) Trend Layer -- how to scrape/monitor trending content across platforms, and (2) Viral Brain -- how to score viral potential of content ideas (hook strength, curiosity gap, novelty, retention prediction).

## Findings

### Finding 1: TikTok Creative Center — Trend Data Source (No Official API, Scraping Required)

TikTok Creative Center (ads.tiktok.com/business/creativecenter) is the richest source of trend data: trending hashtags, top videos, popular songs, top creators, with multi-country and multi-industry filtering. However, **there is no official public API** for Creative Center data. Access requires either:

- **Scraping**: Third-party scrapers exist (Apify actors like `doliz/tiktok-creative-center-scraper` and `novi/tiktok-trend-api`) but these are commercial SaaS, not OSS
- **TikTok Research API**: Academic/research access only, requires institutional affiliation, not viable for commercial SaaS
- **TikTok Business API**: Requires advertiser account, provides ad performance data but not public trend discovery data

For viral-ops Phase 1, the practical approach is a lightweight custom scraper targeting Creative Center's web interface, or using the Apify marketplace actors (pay-per-result model, starting at ~$0.25/1000 results).

[SOURCE: https://apify.com/doliz/tiktok-creative-center-scraper/api]
[SOURCE: https://data365.co/blog/tiktok-trends-api]
[SOURCE: https://developers.tiktok.com/]

### Finding 2: OSS Social Media Scrapers — snscrape (Best) + tiktok-scraper (Stale)

Two notable OSS tools for trend monitoring:

**snscrape** (snscrape.com) — Free, open-source, multi-platform scraper supporting TikTok (hashtags, users, trending), YouTube (search, channels, video metadata), Twitter/X, and Instagram. Actively used for trend monitoring and influencer research. Best OSS option for multi-platform trend signal collection.

**drawrowfly/tiktok-scraper** — 5,000 GitHub stars, MIT license, TypeScript/Node.js. Has a `.trend()` method for scraping trending posts. However, **last updated July 2021** (v1.4.33), with 58 open issues and 27 unmerged PRs. Effectively abandoned. Still useful as architecture reference for how to structure trend scraping, but not production-viable without significant maintenance.

**GitHub curated list**: `cporter202/social-media-scraping-apis` provides a directory of scraping tools across all major platforms — useful as a reference catalog.

For viral-ops: **snscrape is the recommended starting point** for Phase 1 trend signal collection. If it breaks due to platform changes, fall back to Apify marketplace actors.

[SOURCE: https://snscrape.com/]
[SOURCE: https://github.com/drawrowfly/tiktok-scraper — 5,000 stars, MIT, last commit July 2021]
[SOURCE: https://github.com/cporter202/social-media-scraping-apis]

### Finding 3: Trend Pipeline Architecture — Scrape → Cluster → Rank → Trigger

Based on the available tools and viral-ops architecture, the Trend Layer pipeline should be:

```
[Scheduled n8n workflow]
    ↓ (every 4-6 hours)
[Scrape Signals]
    ├── snscrape → TikTok trending hashtags, top videos per niche
    ├── Google Trends (pytrends) → rising queries per topic
    └── YouTube Data API v3 → trending videos per category
    ↓
[Cluster & Deduplicate]
    ├── BERTopic or simple TF-IDF → group related signals into topic clusters
    ├── Deduplicate against DB of already-processed trends
    └── Tag with niche labels (per channel config)
    ↓
[Rank by Momentum]
    ├── Velocity: rate of growth (views/engagement over time)
    ├── Freshness: how new is the trend (hours since first detection)
    ├── Niche fit: relevance to configured channel niches
    └── Saturation: how many creators already covering this
    ↓
[Store + Trigger]
    ├── Write to trends table in PostgreSQL
    ├── Trigger Viral Brain scoring for top-N trends
    └── Dashboard: show trend feed with momentum indicators
```

This integrates with the existing n8n orchestrator architecture from iteration 5. The n8n HTTP Request nodes call snscrape (or a thin Python wrapper) and Google Trends API, then process results through clustering logic.

[INFERENCE: based on n8n architecture (iteration 5), snscrape capabilities (Finding 2), and viral-ops README architecture diagram]

### Finding 4: Hook Retention Benchmarks — Quantitative Data for Viral Brain Scoring

Critical quantitative benchmarks for the "hook strength" dimension of Viral Brain:

**3-Second Hook Retention Tiers** (TikTok-specific, 2025 data):
| Retention | Algorithmic Effect | View Multiplier |
|-----------|-------------------|-----------------|
| < 60%     | Minimal push      | 1.0x baseline   |
| 60-70%    | Moderate visibility | 1.6x          |
| 70-85%    | Optimal reach     | 2.2x            |
| 85%+      | Viral potential   | 2.8x            |

Key statistics:
- **70% of users** decide to continue or scroll within the first 3 seconds
- Videos losing **>35% of viewers in 3 seconds** typically fail to achieve broader reach
- **84.3% of viral TikTok videos in 2025** used specific psychological hook triggers
- YouTube (post-March 2025) counts every loop/replay as additional view — looping structure directly inflates algorithmic signals

These benchmarks provide the calibration data for Viral Brain's hook scoring. A script can be scored by an LLM against these patterns BEFORE video production.

[SOURCE: https://insights.ttsvibes.com/tiktok-first-3-seconds-hook-retention-rate/]
[SOURCE: https://virvid.ai/blog/looping-structure-shorts-retention-2026]

### Finding 5: Academic Framework — MLLM-VAU (Meta, 2026) for Video Ad Hook Analysis

The most relevant academic paper found: **"Decoding the Hook: A Multimodal LLM Framework for Analyzing the Hooking Period of Video Ads"** (Kunpeng Zhang, University of Maryland + Meta Platforms, arxiv 2602.22299v1, 2026).

**Key methodology (MLLM-VAU framework)**:
1. Frame extraction from first 3 seconds using dual sampling strategies
2. Multimodal LLM (Llama) prompt-based vision analysis → generates text reasoning about design methodology
3. BERTopic topic modeling on hook descriptions → clusters hook types
4. Acoustic feature extraction (decibels, jitter, tempo, pitch, shimmer)
5. Gradient Boosting Decision Tree (GBDT) for performance prediction

**Hook type taxonomy** (by industry vertical):
- **Ecommerce**: Interactive content most effective, followed by connection hooks
- **Healthcare**: Product demonstration leads
- **CPG (Consumer Packaged Goods)**: Visual appeals excel
- **Automobile**: Visual appeals + storytelling

**Scale**: Tested on 10k-150k real-world video ads across 5 industry verticals.

**Availability**: "Sample data and all code can be provided upon request" — no public GitHub repo, but the methodology is replicable using open models (Llama, BERTopic, GBDT).

**Relevance to viral-ops**: This framework validates the approach of using LLMs to analyze/score hooks. The key insight is that **hook effectiveness varies by vertical/niche** — viral-ops should configure hook scoring weights per channel niche, not use a universal scoring model.

[SOURCE: https://arxiv.org/html/2602.22299v1]

### Finding 6: Phase 1 Viral Brain — LLM-Based Scoring Without Training Data

For Phase 1 (no historical performance data to train on), the Viral Brain scoring engine should use **LLM-as-judge** with a structured prompt rubric. This avoids the cold-start problem of ML models.

**Proposed Phase 1 Scoring Dimensions** (0-10 each, weighted sum):

| Dimension | Weight | LLM Evaluation Prompt |
|-----------|--------|----------------------|
| Hook Strength | 0.30 | "Rate the opening hook: Does it create immediate curiosity, shock, or promise value in <3 seconds?" |
| Curiosity Gap | 0.20 | "Rate the curiosity gap: Does the viewer NEED to know what happens next? Is the payoff delayed enough?" |
| Novelty | 0.15 | "Rate novelty: How different is this from the top 10 trending videos in this niche?" |
| Retention Structure | 0.15 | "Rate retention architecture: Does this have a loop structure, cliffhangers, or progressive reveals?" |
| Emotional Trigger | 0.10 | "Rate emotional intensity: Does this trigger excitement, outrage, nostalgia, or FOMO?" |
| Platform Fit | 0.10 | "Rate platform fit: Does format, length, and style match {platform} algorithm preferences?" |

**Viral Score** = Weighted sum → 0-100 scale → threshold at 70+ for auto-queue, 50-69 for manual review, <50 reject.

**Hook variant generation**: Use LLM to generate 3-5 hook variants per topic, score each, select top 2 for A/B testing in Content Lab.

**Phase 2 evolution**: Once performance data accumulates (views, retention, CTR per video), fine-tune weights using actual outcomes. Eventually replace LLM scoring with a trained GBDT model (following MLLM-VAU approach).

**Data collection for Phase 2**: Every video published stores: hook_text, viral_score (LLM), actual_views, actual_retention_3s, actual_retention_full, actual_ctr. After ~500 videos, enough data to train a lightweight regression model.

[INFERENCE: based on MLLM-VAU methodology (Finding 5), hook retention benchmarks (Finding 4), and viral-ops architecture (README + iterations 1-8)]

## Ruled Out

- **TikTok Research API for commercial use**: Requires academic/institutional affiliation, explicitly prohibits commercial applications. Not viable for viral-ops.
- **drawrowfly/tiktok-scraper as production tool**: Abandoned since July 2021, will break on current TikTok web interface. Architecture reference only.
- **Medium "Decoding AI Virality" article**: Marketed as "complete guide" but contains no technical depth — no formulas, no academic citations, no OSS tools. Zero research value beyond confirming engagement velocity and emotional resonance as generic dimensions.

## Dead Ends

None this iteration — all research directions produced actionable findings. The pivot from infrastructure to intelligence layers opened entirely new territory.

## Sources Consulted
- https://apify.com/doliz/tiktok-creative-center-scraper/api — Apify TikTok Creative Center scraper
- https://data365.co/blog/tiktok-trends-api — TikTok Trends API overview
- https://developers.tiktok.com/ — TikTok Developer Portal
- https://snscrape.com/ — snscrape multi-platform scraper
- https://github.com/drawrowfly/tiktok-scraper — tiktok-scraper (5k stars, abandoned)
- https://github.com/cporter202/social-media-scraping-apis — curated scraping API list
- https://insights.ttsvibes.com/tiktok-first-3-seconds-hook-retention-rate/ — Hook retention benchmarks
- https://virvid.ai/blog/looping-structure-shorts-retention-2026 — YouTube loop replay scoring
- https://arxiv.org/html/2602.22299v1 — MLLM-VAU framework paper (Meta + UMD, 2026)
- https://medium.com/activated-thinker/decoding-ai-virality-algorithms-the-complete-2025-guide-to-viral-content-seo-b249ac969d7a — Medium viral guide (low value)
- https://scrapfly.io/blog/posts/how-to-scrape-tiktok-python-json — TikTok scraping guide 2026

## Assessment
- New information ratio: 0.92
- Questions addressed: Q22 (Trend Layer), Q23 (Viral Brain)
- Questions answered: Q22 (partially — tools identified, pipeline designed, but Google Trends/pytrends and YouTube Trending details deferred), Q23 (partially — Phase 1 LLM scoring designed, academic framework identified, but no OSS viral scoring model found)

## Reflection
- What worked and why: WebSearch for platform-specific trend APIs + academic papers yielded the highest-value results. The MLLM-VAU paper discovery was the single most valuable find — it validates LLM-based hook analysis with real-world data at Meta scale. The TTS Vibes hook retention data provided concrete benchmarks that make the scoring rubric calibrated rather than arbitrary.
- What did not work and why: The Medium "complete guide" article was clickbait with no technical substance. Generic searches for "viral prediction algorithm open source" return commercial tools (PostEverywhere, Enrich Labs) rather than OSS implementations — the viral prediction space is dominated by proprietary commercial tools.
- What I would do differently: Start with academic paper search (arxiv, Google Scholar) rather than general web search for the Viral Brain component. Academic papers provide reproducible methodology; blog posts provide marketing fluff.

## Recommended Next Focus
Continue intelligence layers: (1) Google Trends integration via pytrends Python library — can it run inside n8n? (2) YouTube Data API v3 trending endpoint details for trend signal collection (3) Content Lab A/B testing methodology (Q24) (4) Feedback Loop analytics APIs (Q25) — how to pull TikTok Analytics, YouTube Analytics, IG Insights back into the system for Viral Brain retraining.
