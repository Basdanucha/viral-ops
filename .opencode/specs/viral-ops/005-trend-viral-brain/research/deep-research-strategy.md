# Deep Research Strategy - Session Tracking

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Deep dive into L1 Trend Discovery + L2 Viral Brain for viral-ops — covering multi-platform trend scraping, trend clustering, viral scoring intelligence, hook generation, and ML model training for content optimization.

### Usage
- **Init:** Orchestrator creates this file with topic, key questions, known context
- **Per iteration:** Agent reads Next Focus, writes iteration evidence, reducer refreshes machine-owned sections
- **Mutability:** Mutable — analyst-owned sections stable, machine-owned sections rewritten by reducer

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
L1 Trend Layer + L2 Viral Brain — snscrape multi-platform scraping (status? alternatives?), pytrends Google Trends API, TikTok Trends/Creative Center API, YouTube Data API v3 trending, BERTopic clustering for trend grouping, LLM-as-judge 6-dimension scoring rubric, hook variant generation, GBDT model training requirements (LightGBM/XGBoost), Thai trend detection, real-time trend freshness validation.

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
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

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- Content production pipeline (covered in spec 002 + 003)
- Upload/distribution mechanics (covered in spec 004)
- Shopping/affiliate integration (Layer 6)
- Analytics API integration details (Layer 7 — only feedback loop design is in scope)
- Implementation code (research only)

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- All 12 questions answered with actionable details
- snscrape status confirmed (alive/dead/alternatives identified)
- BERTopic Thai configuration documented
- LLM scoring rubric with exact prompt template created
- GBDT feature engineering list defined
- Trend freshness model described

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Direct GitHub repo fetching gave authoritative snscrape status. Web search provided comprehensive pytrends and YouTube API details. Multiple independent sources confirmed each finding. (iteration 1)
- Fetching pytrends source code directly gave authoritative method signatures and parameter details. BERTopic official docs had comprehensive online learning examples. Multiple independent sources confirmed multilingual model recommendations. (iteration 2)
- Web search for each question independently yielded highly relevant 2025-2026 sources. The LLM-as-judge field has matured significantly with clear best practices. Trend velocity is a well-established concept with transferable frameworks. (iteration 3)
- Web search yielded strong results for all three question areas. The GBDT comparison literature is mature with clear consensus favoring LightGBM for production use. Drift detection literature has consolidated around Evidently AI and statistical test approaches. PyThaiNLP documentation is comprehensive and its social media domain tools are directly applicable. (iteration 4)
- The Apify actor page provided the exact JSON schemas that were missing from prior iterations. WebSearch for n8n sub-workflow patterns yielded authoritative docs links. Synthesizing the orchestration design from all prior iteration findings (velocity, scoring, hooks, GBDT, calibration) into a concrete n8n workflow chain was the most productive action -- it forced integration of all 11 prior answers into a cohesive system. (iteration 5)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- snscrape issue #1037 didn't show maintainer response (GitHub rendering limitation in WebFetch). Would need to check via `gh` CLI for full thread. (iteration 1)
- Apify actor API page was sparse -- the public docs do not expose full input/output schemas. The TikTok Creative Center page required login for full data access, limiting what could be extracted from the public page. (iteration 2)
- Trendtracker article lacked exact mathematical formulas -- had to synthesize the velocity formula from the conceptual framework combined with pytrends data structure knowledge from iteration 2. This is acceptable as the formula is straightforward rate-of-change calculation. (iteration 3)
- The PeerJ PDF was 403-blocked (common for academic PDFs). The ApXML article rendered without body content (JavaScript-heavy SPA). Both were mitigated by extracting key information from search result snippets and cross-referencing with other sources. (iteration 4)
- The tiktok-discover-api.vercel.app free API is down (404 on all attempted endpoints). This confirms it is not suitable for production. The n8n sub-workflow docs page rendered only navigation structure, not content details, but the WebSearch results provided sufficient context. (iteration 5)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### **Binary viral classification for GBDT**: Loses too much information versus regression. A continuous prediction (log-normalized) provides richer signal for ranking content ideas. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Binary viral classification for GBDT**: Loses too much information versus regression. A continuous prediction (log-normalized) provides richer signal for ranking content ideas.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Binary viral classification for GBDT**: Loses too much information versus regression. A continuous prediction (log-normalized) provides richer signal for ranking content ideas.

### **Float scoring scales for LLM-as-judge**: Research strongly favors categorical integers (1-5). Float scores produce inconsistent, harder-to-calibrate results. Ruled out 0-10 scale from gen1 in favor of 1-5. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Float scoring scales for LLM-as-judge**: Research strongly favors categorical integers (1-5). Float scores produce inconsistent, harder-to-calibrate results. Ruled out 0-10 scale from gen1 in favor of 1-5.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Float scoring scales for LLM-as-judge**: Research strongly favors categorical integers (1-5). Float scores produce inconsistent, harder-to-calibrate results. Ruled out 0-10 scale from gen1 in favor of 1-5.

### None this iteration. All approaches were productive. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: None this iteration. All approaches were productive.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None this iteration. All approaches were productive.

### **pytrends (original) for production**: Repository archived April 2025. Use `pytrends-modern` fork for maintained proxy rotation and cookie handling. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **pytrends (original) for production**: Repository archived April 2025. Use `pytrends-modern` fork for maintained proxy rotation and cookie handling.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **pytrends (original) for production**: Repository archived April 2025. Use `pytrends-modern` fork for maintained proxy rotation and cookie handling.

### **Random train/test split for temporal data**: Would create data leakage from future trends appearing in training data. Temporal split is mandatory. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Random train/test split for temporal data**: Would create data leakage from future trends appearing in training data. Temporal split is mandatory.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Random train/test split for temporal data**: Would create data leakage from future trends appearing in training data. Temporal split is mandatory.

### **Raw view count as GBDT target**: Biased by follower count. Normalized `views/followers` is required for meaningful comparison across accounts of different sizes. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Raw view count as GBDT target**: Biased by follower count. Normalized `views/followers` is required for meaningful comparison across accounts of different sizes.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Raw view count as GBDT target**: Biased by follower count. Normalized `views/followers` is required for meaningful comparison across accounts of different sizes.

### **Real-time webhook from data sources to L2**: Data sources (pytrends, Apify, YouTube API) do not support push/webhook notifications. Polling is the only option. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Real-time webhook from data sources to L2**: Data sources (pytrends, Apify, YouTube API) do not support push/webhook notifications. Polling is the only option.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time webhook from data sources to L2**: Data sources (pytrends, Apify, YouTube API) do not support push/webhook notifications. Polling is the only option.

### **Single mega-prompt for all 6 dimensions**: LLMs perform better with single-objective tasks. Multi-dimension prompts lead to criterion conflation and halo effects. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Single mega-prompt for all 6 dimensions**: LLMs perform better with single-objective tasks. Multi-dimension prompts lead to criterion conflation and halo effects.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single mega-prompt for all 6 dimensions**: LLMs perform better with single-objective tasks. Multi-dimension prompts lead to criterion conflation and halo effects.

### **Single monolithic n8n workflow for L1+L2**: Too complex for debugging, n8n performance degrades with 50+ nodes. Sub-workflow pattern is mandatory. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Single monolithic n8n workflow for L1+L2**: Too complex for debugging, n8n performance degrades with 50+ nodes. Sub-workflow pattern is mandatory.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single monolithic n8n workflow for L1+L2**: Too complex for debugging, n8n performance degrades with 50+ nodes. Sub-workflow pattern is mandatory.

### **snscrape as multi-platform scraper for viral-ops**: Definitively eliminated. The platforms we need (TikTok, YouTube) were never supported, and its Twitter support is broken. Should be removed from the architecture. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **snscrape as multi-platform scraper for viral-ops**: Definitively eliminated. The platforms we need (TikTok, YouTube) were never supported, and its Twitter support is broken. Should be removed from the architecture.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **snscrape as multi-platform scraper for viral-ops**: Definitively eliminated. The platforms we need (TikTok, YouTube) were never supported, and its Twitter support is broken. Should be removed from the architecture.

### **snscrape for TikTok/YouTube**: Never supported these platforms at all. Gen1 mention was misleading -- snscrape cannot scrape TikTok or YouTube. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **snscrape for TikTok/YouTube**: Never supported these platforms at all. Gen1 mention was misleading -- snscrape cannot scrape TikTok or YouTube.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **snscrape for TikTok/YouTube**: Never supported these platforms at all. Gen1 mention was misleading -- snscrape cannot scrape TikTok or YouTube.

### **snscrape for Twitter/X**: Broken since June 2023, no fix available. Platform locked behind login wall. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **snscrape for Twitter/X**: Broken since June 2023, no fix available. Platform locked behind login wall.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **snscrape for Twitter/X**: Broken since June 2023, no fix available. Platform locked behind login wall.

### **Standard dictionary-based segmentation for Thai social media**: Too many OOV (out-of-vocabulary) failures on slang. Neural or CRF-based models (deepcut, han_solo) required. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Standard dictionary-based segmentation for Thai social media**: Too many OOV (out-of-vocabulary) failures on slang. Neural or CRF-based models (deepcut, han_solo) required.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Standard dictionary-based segmentation for Thai social media**: Too many OOV (out-of-vocabulary) failures on slang. Neural or CRF-based models (deepcut, han_solo) required.

### **tiktok-discover-api.vercel.app as production source**: The self-hosted API returned 404 on multiple endpoint patterns during this iteration. The service appears unreliable. Use Apify actor as primary TikTok CC source. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **tiktok-discover-api.vercel.app as production source**: The self-hosted API returned 404 on multiple endpoint patterns during this iteration. The service appears unreliable. Use Apify actor as primary TikTok CC source.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **tiktok-discover-api.vercel.app as production source**: The self-hosted API returned 404 on multiple endpoint patterns during this iteration. The service appears unreliable. Use Apify actor as primary TikTok CC source.

### **tiktok-discover-api.vercel.app endpoints**: Tried `/api/getTrendingHastag?region=TH` and `/api/trending/hashtag?region=TH` -- both returned 404. The free unofficial API appears down or has changed its URL structure without documentation update. Not viable for production use. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **tiktok-discover-api.vercel.app endpoints**: Tried `/api/getTrendingHastag?region=TH` and `/api/trending/hashtag?region=TH` -- both returned 404. The free unofficial API appears down or has changed its URL structure without documentation update. Not viable for production use.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **tiktok-discover-api.vercel.app endpoints**: Tried `/api/getTrendingHastag?region=TH` and `/api/trending/hashtag?region=TH` -- both returned 404. The free unofficial API appears down or has changed its URL structure without documentation update. Not viable for production use.

### **TikTok Research API for commercial use**: Academic-only, requires research plan approval, strict data use policies. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **TikTok Research API for commercial use**: Academic-only, requires research plan approval, strict data use policies.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok Research API for commercial use**: Academic-only, requires research plan approval, strict data use policies.

### **WangchanBERTa as primary BERTopic embedding**: Thai-only model, cannot handle the English+Thai mixed text common in Thai social media trends. Use multilingual model instead. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **WangchanBERTa as primary BERTopic embedding**: Thai-only model, cannot handle the English+Thai mixed text common in Thai social media trends. Use multilingual model instead.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **WangchanBERTa as primary BERTopic embedding**: Thai-only model, cannot handle the English+Thai mixed text common in Thai social media trends. Use multilingual model instead.

### **WangchanBERTa for mixed-language trend clustering**: Definitively unsuitable -- it's a Thai-only RoBERTa variant that will produce garbage embeddings for English tokens. Not a "try harder" situation; the model architecture lacks English vocabulary. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **WangchanBERTa for mixed-language trend clustering**: Definitively unsuitable -- it's a Thai-only RoBERTa variant that will produce garbage embeddings for English tokens. Not a "try harder" situation; the model architecture lacks English vocabulary.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **WangchanBERTa for mixed-language trend clustering**: Definitively unsuitable -- it's a Thai-only RoBERTa variant that will produce garbage embeddings for English tokens. Not a "try harder" situation; the model architecture lacks English vocabulary.

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
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

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
All 12 questions are now answered. Recommended next iteration: **Consolidation and contradiction check** -- review all 5 iteration findings for internal consistency, cross-reference architecture decisions, identify any remaining gaps or contradictions between the orchestration design (Q12) and the individual component designs (Q1-Q11). Compute a final architecture summary.

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From gen1 research (specs/001-base-app-research)
**Layer 1: Trend Discovery** (high-level from gen1):
- snscrape for multi-platform scraping
- pytrends for Google Trends
- YouTube Data API for trending videos
- BERTopic or TF-IDF fallback for topic clustering
- n8n cron every 2h for Path A (trend-driven)

**Layer 2: Intelligence (Viral Brain)** (high-level from gen1):
- LLM-as-judge scoring: 6 dimensions (hook strength, storytelling, emotional trigger, visual potential, audio fit, CTA effectiveness)
- Phase 1: GPT-4/DeepSeek as scorer (0-10 per dimension, weighted sum)
- Phase 2: GBDT model after ~500 videos with T+168h data
- Features: hook_text + 6 viral dims + platform + niche + time_of_day + day_of_week

**Known gaps:**
- snscrape may be dead/blocked in 2026 (social media platforms have been aggressive with scraping)
- No exact pytrends rate limits documented
- TikTok trends scraping method unclear (no official API mentioned in gen1)
- BERTopic configuration for Thai text not addressed
- LLM scoring prompt not written
- GBDT feature engineering incomplete (only high-level list)
- Trend freshness/velocity not defined (how to tell if a trend is "real" right now)

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 20
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- research/research.md ownership: workflow-owned canonical synthesis output
- Machine-owned sections: reducer controls Sections 3, 6, 7-11
- Canonical pause sentinel: research/.deep-research-pause
- Current generation: 1
- Started: 2026-04-17T19:30:00Z
<!-- /ANCHOR:research-boundaries -->
