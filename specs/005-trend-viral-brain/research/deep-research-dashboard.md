---
title: Deep Research Dashboard
description: Auto-generated reducer view over the research packet.
---

# Deep Research Dashboard - Session Overview

Auto-generated from JSONL state log, iteration files, findings registry, and strategy state. Never manually edited.

<!-- ANCHOR:overview -->
## 1. OVERVIEW

Reducer-generated observability surface for the active research packet.

<!-- /ANCHOR:overview -->
<!-- ANCHOR:status -->
## 2. STATUS
- Topic: L1 Trend Layer + L2 Viral Brain — snscrape multi-platform scraping, pytrends Google Trends, TikTok Trends API, YouTube trending API, BERTopic clustering, LLM-as-judge 6-dimension scoring rubric, hook variant generation, GBDT model training requirements, Thai trend detection, real-time trend freshness validation
- Started: 2026-04-17T19:30:00Z
- Status: INITIALIZED
- Iteration: 5 of 20
- Session ID: dr-005-trend-viral-brain
- Parent Session: none
- Lifecycle Mode: new
- Generation: 1
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | Survey trend data sources — snscrape status, pytrends capabilities, TikTok trend APIs, YouTube Data API v3 trending | data-sources | 0.88 | 4 | complete |
| 2 | pytrends advanced config (rate limits, methods, geo, polling), TikTok Creative Center deep dive (data fields, filters, Apify actor), BERTopic Thai+English multilingual config + online learning | data-sources | 0.83 | 6 | complete |
| 3 | Trend freshness/velocity scoring model (Q6), LLM-as-judge 6-dimension rubric design (Q7), Hook variant generation system (Q8) | intelligence-layer | 0.80 | 5 | complete |
| 4 | GBDT model training pipeline (Q9), Scoring calibration & feedback loop (Q10), Thai-specific NLP/patterns (Q11) | intelligence-layer | 0.80 | 5 | complete |
| 5 | n8n orchestration L1->L2->L3 workflow chain design (Q12) + TikTok Creative Center JSON response schema completion (Q3) | orchestration | 0.90 | 5 | complete |

- iterationsCompleted: 5
- keyFindings: 179
- openQuestions: 12
- resolvedQuestions: 0

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 0/12
- [ ] Q1: snscrape status — is it still maintained in 2026? Rate limits? Alternatives (Apify, Nitter, official APIs)? Multi-platform support (TikTok, YouTube, Instagram, Facebook, Twitter/X)?
- [ ] Q2: pytrends / Google Trends — rate limits, real-time vs daily trends, geo-filtering (Thailand), category filtering, rising vs top queries, related topics?
- [ ] Q3: TikTok Trends discovery — official Research API, Creative Center trends API, TikTok Discover page scraping, trending hashtags/sounds, rate limits?
- [ ] Q4: YouTube trending — Data API v3 `videos.list(chart=mostPopular)`, category filtering, geo-filtering (TH), quota cost, trending vs search volume?
- [ ] Q5: BERTopic configuration — Thai+English mixed text handling, optimal parameters, online/incremental learning for real-time trends, topic representation, visualization?
- [ ] Q6: Trend freshness & velocity — how to measure trend momentum (rising/peaking/declining), timing window for content creation, trend lifecycle modeling?
- [ ] Q7: LLM-as-judge scoring rubric — 6 dimensions (hook, storytelling, emotion, visual, audio, CTA), exact prompt design, scoring scale, calibration methodology?
- [ ] Q8: Hook variant generation — how to generate multiple hook variants from a single trend, template system, A/B testing integration with Content Lab?
- [ ] Q9: GBDT model training — feature engineering from 500+ videos, LightGBM vs XGBoost comparison, training pipeline design, what metrics to predict (views? engagement rate?)?
- [ ] Q10: Scoring calibration & feedback loop — how to validate LLM scores against actual performance (L7 feedback), score drift detection, retraining triggers?
- [ ] Q11: Thai-specific considerations — Thai NLP for trend text (PyThaiNLP), Thai social media patterns, Thai viral content characteristics, Thai slang/internet culture trends?
- [ ] Q12: n8n orchestration — how L1 triggers L2, how L2 triggers L3 Content Lab, cron schedules, workflow chaining, data flow through DB tables (trends, content)?

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.80 -> 0.80 -> 0.90
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.90
- coverageBySources: {"ads.tiktok.com":1,"apify.com":3,"apxml.com":2,"arxiv.org":5,"creatify.ai":1,"developers.google.com":2,"developers.tiktok.com":2,"docs.n8n.io":6,"github.com":8,"jmhorizons.com":1,"joinbrands.com":2,"link.springer.com":2,"maartengr.github.io":2,"markaicode.com":1,"n8nautomation.cloud":1,"orq.ai":2,"papers.nips.cc":2,"peerj.com":2,"pypi.org":1,"pythainlp.org":2,"scrapfly.io":1,"thinkpeak.ai":1,"tiktok-discover-api.vercel.app":1,"trendible.co":2,"virvid.ai":2,"wandb.ai":2,"www.braintrust.dev":1,"www.evidentlyai.com":3,"www.geeksforgeeks.org":1,"www.getphyllo.com":1,"www.langchain.com":2,"www.marketingblocks.ai":2,"www.montecarlodata.com":2,"www.nature.com":1,"www.submagic.co":2,"www.trendtracker.ai":2,"www.yotpo.com":2}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
- **snscrape as multi-platform scraper for viral-ops**: Definitively eliminated. The platforms we need (TikTok, YouTube) were never supported, and its Twitter support is broken. Should be removed from the architecture. (iteration 1)
- **snscrape for TikTok/YouTube**: Never supported these platforms at all. Gen1 mention was misleading -- snscrape cannot scrape TikTok or YouTube. (iteration 1)
- **snscrape for Twitter/X**: Broken since June 2023, no fix available. Platform locked behind login wall. (iteration 1)
- **TikTok Research API for commercial use**: Academic-only, requires research plan approval, strict data use policies. (iteration 1)
- **pytrends (original) for production**: Repository archived April 2025. Use `pytrends-modern` fork for maintained proxy rotation and cookie handling. (iteration 2)
- **WangchanBERTa as primary BERTopic embedding**: Thai-only model, cannot handle the English+Thai mixed text common in Thai social media trends. Use multilingual model instead. (iteration 2)
- **WangchanBERTa for mixed-language trend clustering**: Definitively unsuitable -- it's a Thai-only RoBERTa variant that will produce garbage embeddings for English tokens. Not a "try harder" situation; the model architecture lacks English vocabulary. (iteration 2)
- **Float scoring scales for LLM-as-judge**: Research strongly favors categorical integers (1-5). Float scores produce inconsistent, harder-to-calibrate results. Ruled out 0-10 scale from gen1 in favor of 1-5. (iteration 3)
- None this iteration. All approaches were productive. (iteration 3)
- **Single mega-prompt for all 6 dimensions**: LLMs perform better with single-objective tasks. Multi-dimension prompts lead to criterion conflation and halo effects. (iteration 3)
- **Binary viral classification for GBDT**: Loses too much information versus regression. A continuous prediction (log-normalized) provides richer signal for ranking content ideas. (iteration 4)
- **Random train/test split for temporal data**: Would create data leakage from future trends appearing in training data. Temporal split is mandatory. (iteration 4)
- **Raw view count as GBDT target**: Biased by follower count. Normalized `views/followers` is required for meaningful comparison across accounts of different sizes. (iteration 4)
- **Standard dictionary-based segmentation for Thai social media**: Too many OOV (out-of-vocabulary) failures on slang. Neural or CRF-based models (deepcut, han_solo) required. (iteration 4)
- **Real-time webhook from data sources to L2**: Data sources (pytrends, Apify, YouTube API) do not support push/webhook notifications. Polling is the only option. (iteration 5)
- **Single monolithic n8n workflow for L1+L2**: Too complex for debugging, n8n performance degrades with 50+ nodes. Sub-workflow pattern is mandatory. (iteration 5)
- **tiktok-discover-api.vercel.app as production source**: The self-hosted API returned 404 on multiple endpoint patterns during this iteration. The service appears unreliable. Use Apify actor as primary TikTok CC source. (iteration 5)
- **tiktok-discover-api.vercel.app endpoints**: Tried `/api/getTrendingHastag?region=TH` and `/api/trending/hashtag?region=TH` -- both returned 404. The free unofficial API appears down or has changed its URL structure without documentation update. Not viable for production use. (iteration 5)

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
All 12 questions are now answered. Recommended next iteration: **Consolidation and contradiction check** -- review all 5 iteration findings for internal consistency, cross-reference architecture decisions, identify any remaining gaps or contradictions between the orchestration design (Q12) and the individual component designs (Q1-Q11). Compute a final architecture summary.

<!-- /ANCHOR:next-focus -->
<!-- ANCHOR:active-risks -->
## 8. ACTIVE RISKS
- None active beyond normal research uncertainty.

<!-- /ANCHOR:active-risks -->
<!-- ANCHOR:blocked-stops -->
## 9. BLOCKED STOPS
No blocked-stop events recorded.

<!-- /ANCHOR:blocked-stops -->
<!-- ANCHOR:graph-convergence -->
## 10. GRAPH CONVERGENCE
- graphConvergenceScore: 0.00
- graphDecision: [Not recorded]
- graphBlockers: none recorded

<!-- /ANCHOR:graph-convergence -->
