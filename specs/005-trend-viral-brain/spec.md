# Spec: L1 Trend Layer + L2 Viral Brain

## Requirements
<!-- DR-SEED:REQUIREMENTS -->
Deep dive research into the Trend Discovery (L1) and Viral Brain Intelligence (L2) layers for viral-ops — covering multi-platform trend scraping tools, trend clustering, viral scoring with LLM-as-judge, hook variant generation, and GBDT model training for content optimization. Focus on tools that actually work in 2026 and Thai market considerations.

## Scope
<!-- DR-SEED:SCOPE -->
- snscrape status and alternatives for multi-platform scraping (TikTok, YouTube, IG, FB, X)
- pytrends / Google Trends API — capabilities, rate limits, Thailand geo-filtering
- TikTok Trends discovery — Creative Center API, Research API, trending hashtags/sounds
- YouTube Data API v3 trending endpoint — quota, categories, geo
- BERTopic clustering — Thai+English handling, real-time/online learning
- Trend freshness & velocity measurement — lifecycle modeling, timing windows
- LLM-as-judge 6-dimension scoring rubric — exact prompt design, calibration
- Hook variant generation — template system, A/B testing integration
- GBDT model — feature engineering, LightGBM vs XGBoost, training pipeline
- Scoring calibration via feedback loop from Layer 7
- Thai-specific NLP and viral content patterns
- n8n workflow orchestration for L1→L2→L3 pipeline

## Open Questions
All 12 questions answered across 5 autonomous iterations.

## Research Context
Deep research **complete**. Canonical findings in `research/research.md` (580+ lines).

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Research Findings Summary (5 iterations, 12 questions)

### L1 Trend Data Sources (Confirmed for 2026)
| Source | Tool | Schedule | Data | Rate Limit |
|--------|------|----------|------|-----------|
| Google Trends | pytrends-modern | Every 4h | Rising queries, related topics, geo='TH' | Server-side throttling only |
| TikTok Trends | Creative Center + Apify | Every 2h | Hashtags, videos, songs, creators (region filtered) | Apify pay-per-event |
| YouTube Trending | Data API v3 | Every 3h | mostPopular chart, regionCode=TH, 50/page | 1 unit/req, 10K/day |
| ~~snscrape~~ | **DEAD** | — | — | — |
| Twitter/X | **DROPPED** | — | — | Too hostile to scrapers |

### L1 Clustering
- **BERTopic** with `paraphrase-multilingual-MiniLM-L12-v2` (Thai+English)
- Online learning via `.partial_fit()` with IncrementalPCA + MiniBatchKMeans
- Phase 0 fallback: TF-IDF + cosine similarity (lighter, no microservice needed)
- Deployed as **standalone FastAPI microservice** (n8n Code Node cannot host persistent Python)

### L2 Viral Brain Scoring
| Dimension | Weight | Scale |
|-----------|--------|-------|
| Hook Strength | 0.25 | 1-5 categorical |
| Emotional Trigger | 0.20 | 1-5 categorical |
| Storytelling | 0.15 | 1-5 categorical |
| Visual Potential | 0.15 | 1-5 categorical |
| CTA Effectiveness | 0.15 | 1-5 categorical |
| Audio Fit | 0.10 | 1-5 categorical |

- **Changed from gen1**: 0-10 → 1-5 scale, separate prompt per dimension (not mega-prompt)
- **Model**: GPT-4o-mini primary ($0.15/1M input), DeepSeek fallback for Thai
- **Composite**: content_quality(0.40) + trend_freshness(0.35) + niche_fit(0.15) + timing(0.10)

### L2 GBDT Model (Phase 2)
- **LightGBM** for production (500+ videos), XGBoost for cold-start (100-500)
- **38-feature vector**: LLM scores + trend features + temporal + content metadata + historical
- **Target**: `log(views_168h / followers)` — normalized viral performance
- **Training**: Optuna hyperparameter tuning, temporal train/test split

### Key Architecture Decisions
1. **snscrape REMOVED** — dead, never supported TikTok/YouTube
2. **Scoring 1-5 not 0-10** — categorical integers more reliable for LLM judges
3. **BERTopic as microservice** — persistent Python state required
4. **Thai trend lifecycle 24-48h** — faster than global (72-120h), tighter production window
5. **7 hook categories** — question, statistic, controversy, emotion, curiosity, relatable, shock
6. **Drift detection** — PSI >0.20, KL >0.10, Spearman <0.20 triggers retrain

### Ruled Out
- snscrape (dead), WangchanBERTa (Thai-only), TikTok Research API (academic-only), Twitter/X (too hostile)
<!-- END GENERATED: deep-research/spec-findings -->
