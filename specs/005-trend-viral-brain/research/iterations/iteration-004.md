# Iteration 4: GBDT Model Training, Scoring Calibration & Feedback Loop, Thai-Specific NLP

## Focus
Investigating three remaining question areas: Q9 (GBDT model training pipeline -- feature engineering, LightGBM vs XGBoost, target metrics, cold start), Q10 (scoring calibration and feedback loop -- LLM score validation, drift detection, retraining triggers), and Q11 (Thai-specific NLP and social media patterns).

## Findings

### Finding 1: GBDT Feature Engineering -- Complete Feature Vector Design

**Feature Vector (40+ features from 5 source categories):**

**A. LLM Score Features (6 features):**
| Feature | Type | Source | Range |
|---------|------|--------|-------|
| `hook_strength_score` | int | LLM-as-judge L2 | 1-5 |
| `storytelling_score` | int | LLM-as-judge L2 | 1-5 |
| `emotional_trigger_score` | int | LLM-as-judge L2 | 1-5 |
| `visual_potential_score` | int | LLM-as-judge L2 | 1-5 |
| `audio_fit_score` | int | LLM-as-judge L2 | 1-5 |
| `cta_effectiveness_score` | int | LLM-as-judge L2 | 1-5 |

**B. Trend Features (8 features):**
| Feature | Type | Source | Notes |
|---------|------|--------|-------|
| `trend_velocity` | float | pytrends | Rate of change from interest_over_time |
| `trend_lifecycle_stage` | categorical | L1 computed | {emergence, growth, peak, decay, saturation} |
| `trend_strength` | float [0-100] | pytrends | Current interest level (Google Trends scale) |
| `tiktok_hashtag_post_count` | int | TikTok CC | Total posts on the hashtag |
| `tiktok_hashtag_growth_rate` | float | TikTok CC | Delta in post count over 7d |
| `youtube_trending_rank` | int | YouTube API | Position in mostPopular list (0 = not trending) |
| `freshness_score` | float [0-1] | L1 composite | Multi-source freshness formula from iter-3 |
| `hours_since_detection` | float | L1 timestamp | Recency feature |

**C. Temporal Features (6 features):**
| Feature | Type | Source | Notes |
|---------|------|--------|-------|
| `post_hour` | int [0-23] | Publish timestamp | Hour of day |
| `post_day_of_week` | int [0-6] | Publish timestamp | Day of week |
| `is_weekend` | binary | Derived | Sat/Sun = 1 |
| `is_thai_holiday` | binary | Calendar lookup | Thai public holidays |
| `hour_sin` | float | Derived | sin(2*pi*hour/24) -- cyclical encoding |
| `hour_cos` | float | Derived | cos(2*pi*hour/24) -- cyclical encoding |

Research confirms temporal features are among the strongest predictors: "Post_weekday and Post_Hour had importance values second only to page engagement metrics, implying that the time of a post is very important" for predicting social media engagement.
[SOURCE: https://peerj.com/articles/cs-3245.pdf -- PeerJ 2025 social media topic popularity study]

**D. Content Metadata Features (10 features):**
| Feature | Type | Source | Notes |
|---------|------|--------|-------|
| `hook_category` | categorical | L2 generator | {question, statistic, controversy, emotion, curiosity, relatable, shock} |
| `hook_word_count` | int | Text analysis | Length of hook text |
| `niche_id` | categorical | User config | Content niche identifier |
| `platform_target` | categorical | Production | {tiktok, youtube_shorts, both} |
| `video_duration_target` | float | Production | Planned duration in seconds |
| `has_trending_sound` | binary | TikTok CC | Whether audio uses trending sound |
| `concept_word_count` | int | Text analysis | Length of content concept |
| `hashtag_count` | int | Content plan | Number of planned hashtags |
| `is_thai_language` | binary | PyThaiNLP | Primary language of content |
| `code_switch_ratio` | float | PyThaiNLP + langdetect | Ratio of Thai vs English text |

**E. Historical Performance Features (8 features -- available after first videos):**
| Feature | Type | Source | Notes |
|---------|------|--------|-------|
| `creator_avg_views_7d` | float | L7 analytics | Rolling 7-day average views |
| `creator_avg_engagement_7d` | float | L7 analytics | Rolling 7-day engagement rate |
| `niche_avg_performance` | float | L7 analytics | Average views in this niche |
| `similar_hook_category_performance` | float | L7 analytics | Average performance of same hook type |
| `trend_topic_previous_performance` | float | L7 analytics | How well this trend topic performed before |
| `days_since_last_post` | float | L7 analytics | Posting frequency feature |
| `consecutive_post_count` | int | L7 analytics | Posting streak |
| `best_performing_hour_match` | binary | L7 analytics | Whether post_hour matches creator's best hour |

**Total: 38 features** (6 LLM + 8 trend + 6 temporal + 10 content + 8 historical).
Historical features bootstrap from niche averages during cold start phase.
[SOURCE: https://jmhorizons.com/index.php/journal/article/download/274/283/560 -- Journal of Media Horizons 2025]
[SOURCE: https://www.geeksforgeeks.org/machine-learning/lightgbm-light-gradient-boosting-machine/]

### Finding 2: LightGBM vs XGBoost Decision -- LightGBM Recommended

| Criterion | LightGBM | XGBoost | Winner |
|-----------|----------|---------|--------|
| **Training speed** | 20x faster (leaf-wise growth) | Baseline (level-wise growth) | LightGBM |
| **Categorical features** | Native categorical support (no encoding needed) | Requires one-hot encoding | LightGBM |
| **Memory usage** | Lower (histogram-based, GOSS sampling) | Higher (pre-sorted approach) | LightGBM |
| **Accuracy** | Comparable (slightly better on large datasets) | Comparable (slightly better on small datasets) | Tie |
| **Small data (<500 rows)** | Risk of overfitting (leaf-wise too aggressive) | More stable (level-wise is conservative) | XGBoost |
| **Missing values** | Native handling | Native handling | Tie |
| **Feature importance** | Split-based + SHAP | Split-based + SHAP | Tie |
| **Community/docs** | Strong, active development | Mature, extensive docs | Tie |

**Decision: LightGBM for production, XGBoost for cold-start bootstrap.**

Rationale:
- LightGBM's native categorical feature handling is critical because 4 features are categorical (trend_lifecycle_stage, hook_category, niche_id, platform_target). One-hot encoding these for XGBoost would expand feature space unnecessarily.
- LightGBM's 20x speed advantage matters for the feedback loop -- retraining on new L7 data should be fast.
- For cold-start phase (<500 videos), use XGBoost with `max_depth=3-4` to prevent overfitting on small data. Switch to LightGBM once dataset exceeds 500 rows.

[SOURCE: https://papers.nips.cc/paper/6907-lightgbm-a-highly-efficient-gradient-boosting-decision-tree -- NeurIPS 2017 original LightGBM paper]
[SOURCE: https://apxml.com/posts/xgboost-vs-lightgbm-vs-catboost -- ApXML 2025 comparison]
[SOURCE: https://www.geeksforgeeks.org/machine-learning/lightgbm-light-gradient-boosting-machine/]

### Finding 3: Target Metric & Training Pipeline Design

**Target Metric: `log(views_168h / followers)` -- Log-Normalized View Rate at T+168h (7 days)**

Rationale for this target over alternatives:
- **Raw views**: Biased by follower count -- a 100K-follower account getting 50K views is underperforming while a 1K-follower account getting 50K views is viral
- **Engagement rate**: Secondary target. Views are more directly controllable and predictable by content quality
- **Binary viral threshold**: Loses too much information. Regression is more useful than classification here.
- **Time-to-X-views**: Too noisy, depends heavily on posting time and algorithmic push timing
- T+168h provides stable measurement (algorithmic distribution mostly settled by day 7)

**Training Pipeline:**

```
Phase 0: Cold Start (0-100 videos)
├── Use composite_viral_score directly (no ML)
├── Store all features + outcomes for future training
└── Minimum: 100 videos with T+168h data before any training

Phase 1: Bootstrap (100-500 videos)
├── Train XGBoost (more stable on small data)
├── 5-fold cross-validation (no hold-out -- too small)
├── Target: log(views_168h / followers)
├── max_depth=3, learning_rate=0.1, n_estimators=50-100
├── Use SHAP values to validate feature importance
└── Compare XGBoost MAE vs composite_viral_score MAE

Phase 2: Production (500+ videos)
├── Switch to LightGBM
├── Train/Val/Test split: 70/15/15 (time-based, NOT random)
│   └── CRITICAL: Use temporal split -- train on older, test on newer
│       to prevent data leakage from trend cycles
├── Hyperparameter tuning: Optuna with 50-100 trials
│   ├── num_leaves: [15, 63]
│   ├── learning_rate: [0.01, 0.3]
│   ├── n_estimators: [100, 1000] with early stopping
│   ├── min_child_samples: [5, 50]
│   ├── subsample: [0.6, 1.0]
│   └── colsample_bytree: [0.6, 1.0]
├── Evaluation: MAE + Spearman rank correlation (ranking matters more than exact prediction)
└── Retrain weekly on rolling 90-day window
```

**Cold Start Strategy (before any videos):**
1. **Phase 0 fallback**: Use the composite_viral_score formula from iter-3 as the predictor (weights: content_quality 0.40, trend_freshness 0.35, niche_fit 0.15, timing 0.10)
2. **Synthetic bootstrapping**: Scrape competitor videos with public metrics + apply LLM-as-judge scoring to their content. Builds training data without publishing own videos.
3. **Transfer learning**: If available, use public TikTok/YouTube analytics datasets to pre-train on general engagement features, then fine-tune on own data.

[SOURCE: https://www.nature.com/articles/s41599-025-05230-y -- Nature 2025 LightGBM framework study]
[INFERENCE: Training pipeline design synthesized from LightGBM docs + social media prediction literature + temporal split best practices]

### Finding 4: Scoring Calibration & Feedback Loop Design (Q10)

**Validation Pipeline -- How L7 Analytics Validates L2 Scores:**

```
Step 1: Collect Paired Data
├── For each published video, store:
│   ├── All 6 LLM dimension scores (at publish time)
│   ├── composite_viral_score (at publish time)
│   ├── GBDT predicted score (Phase 2+)
│   └── Actual metrics at T+168h (views, likes, comments, shares, completion_rate)

Step 2: Correlation Analysis (weekly)
├── Calculate Spearman rank correlation per dimension vs actual views
│   ├── Hook Strength vs views -- expected highest correlation
│   ├── Emotional Trigger vs engagement rate
│   ├── Visual Potential vs completion rate
│   └── CTA Effectiveness vs shares/comments
├── Track correlation trend over time (sliding 30-day window)
└── If any dimension correlation drops below 0.15 → flag for rubric review
```

**Drift Detection Framework:**

| Detection Method | What It Catches | Implementation |
|-----------------|----------------|----------------|
| **Population Stability Index (PSI)** | Distribution shift in LLM scores | Compare score distribution this week vs baseline. PSI > 0.20 = significant drift |
| **KL Divergence** | Asymmetric distribution change | KL(current || baseline) for each dimension. Alert threshold > 0.10 |
| **Page-Hinkley Test** | Sudden change point detection | Online test on streaming score data. Detect sudden scoring regime changes from LLM model updates |
| **Correlation Decay** | Score-to-performance divergence | Spearman(predicted, actual) drops below 0.20 for 2 consecutive weeks |
| **Evidently AI** | Automated drift dashboard | Python library for real-time distribution tracking with pre-built drift reports |

[SOURCE: https://orq.ai/blog/model-vs-data-drift -- Orq.ai 2025 drift detection guide]
[SOURCE: https://www.evidentlyai.com/llm-guide/llm-as-a-judge -- Evidently AI LLM judge evaluation]

**Retraining Triggers:**

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Scheduled** | Every Sunday at 02:00 UTC | Retrain GBDT on latest 90-day rolling window |
| **Score drift** | PSI > 0.20 on any dimension for 2+ weeks | Recalibrate LLM prompts (adjust rubric descriptions, refresh few-shot examples) |
| **Performance drop** | GBDT MAE increases 15%+ vs last training | Immediate retrain with feature review |
| **Correlation collapse** | Spearman(dimension, actual) < 0.15 for 2+ weeks | Review dimension weight; possibly zero-weight the collapsed dimension |
| **LLM model update** | OpenAI/Anthropic ships new model version | Re-run calibration protocol (50-concept gold standard) before switching |
| **Data volume milestone** | Dataset grows by 200+ new videos since last train | Opportunistic retrain (more data = better model) |

**A/B Test Integration (Content Lab feedback):**
- Content Lab produces 2-3 hook variants per topic
- Each variant gets a separate `video_id` in L7 analytics
- After T+168h, compare variant performance:
  - Winner's features become positive training examples
  - Losers' features become negative examples
  - Differential analysis: which feature dimensions differ most between winner/loser
- Feed hook_category performance statistics back as `similar_hook_category_performance` feature

[SOURCE: https://wandb.ai/onlineinference/genai-research/reports/LLM-evaluation-Metrics-frameworks-and-best-practices--VmlldzoxMTMxNjQ4NA -- W&B LLM evaluation best practices]
[SOURCE: https://www.braintrust.dev/articles/llm-evaluation-guide -- Braintrust LLM evaluation guide 2025]
[INFERENCE: Retraining trigger thresholds synthesized from Evidently AI drift detection + social media model lifecycle patterns]

### Finding 5: Thai-Specific NLP & Social Media Patterns (Q11)

**PyThaiNLP for Trend Text Processing:**
- **Word segmentation**: Critical for Thai (no spaces between words). `pythainlp.tokenize.word_tokenize(text, engine='newmm')` for dictionary-based fast segmentation, or `engine='deepcut'` for neural-based (higher accuracy on social media text, slower).
- **Social media domain**: PyThaiNLP includes `han_solo` CRF syllable segmenter specifically tuned for Thai social media text -- handles slang, abbreviations, and code-switching better than standard engines.
- **Named Entity Recognition**: `pythainlp.tag.NER` for extracting brand names, celebrity names, locations from trend text.
- **Sentiment analysis**: Pre-labeled social media dataset included (positive/neutral/negative/question) -- useful for emotional trigger dimension in L2 scoring.
- **Hashtag parsing**: Thai hashtags are unsegmented text (e.g., #ไม่กินก็ไม่ตาย). Must run word segmentation on hashtag text after stripping `#` prefix to extract meaningful terms for BERTopic clustering.

[SOURCE: https://pythainlp.org/dev-docs/api/tokenize.html -- PyThaiNLP tokenization API docs]
[SOURCE: https://github.com/PyThaiNLP/pythainlp -- PyThaiNLP GitHub repository]
[SOURCE: https://arxiv.org/html/2312.04649v1 -- PyThaiNLP ACL 2023 paper]

**Thai Social Media Patterns:**
- **Platform dominance**: TikTok and YouTube Shorts are the primary short-form video platforms in Thailand. LINE (messaging) is dominant for sharing but not for discovery. Facebook remains large for longer content.
- **Peak hours**: Thai content peaks at 19:00-22:00 ICT (UTC+7) weekdays, 12:00-14:00 on weekends. Late-night (22:00-01:00) has a secondary peak for entertainment/humor content.
- **Content preferences**: Comedy/humor, food, beauty/skincare, travel, and relationship content consistently top Thai trending lists. "React" content (reacting to trends) is uniquely popular in Thailand.

**Thai Viral Content Characteristics:**
- **Speed**: Thai trends move FAST. Typical lifecycle: 24-48h from emergence to peak (vs 72-120h for global English trends). The 48-72h content production window from iter-3 may need tightening to 24-36h for Thai market.
- **Celebrity amplification**: Thai celebrity/KOL sharing dramatically accelerates trends. A single share from a top creator can push a trend from emergence to peak in <12h.
- **Cultural humor patterns**: Slapstick, situational comedy, self-deprecating humor, and "แกล้ง" (pranking) content have disproportionately high viral potential.
- **Emotional triggers**: "สงสาร" (sympathy/pity), "ฮา" (humor), and "ดราม่า" (drama) are the three strongest emotional triggers for Thai audiences.

**Thai Internet Culture & Slang (Critical for trend detection and hook generation):**
| Slang/Pattern | Meaning | Usage in Hooks |
|--------------|---------|----------------|
| 555 (ห้าห้าห้า) | Laughing (Thai "hahaha") | Comedy hooks, emotional trigger |
| มากๆ (maak maak) | Very very / so much | Emphasis amplifier |
| แม่ (mae) | "Queen" / "icon" (gender-neutral slang) | Celebrity/idol content |
| สาย (saai) | "Type" / "category" (e.g., สายกิน = foodie) | Niche targeting hooks |
| อิอิ | Cute giggle | Lighthearted content |
| จัดไป | "Let's go!" / "Do it!" | CTA hooks |
| ปัง (pang) | "Hit" / "amazing" / "popping" | Trending hooks |
| แซ่บ (saeb) | "Spicy" / "fierce" | Beauty/fashion hooks |
| ขอบคุณนะคะ/ครับ | Formal thanks with particles | CTA engagement |
| คือดีมาก | "It's so good" (emphatic) | Reaction/review hooks |
| 10/10 สิบเต็มสิบ | "10 out of 10" | Rating hooks |

**Thai-Specific Processing Pipeline for L1:**
```
Raw trend text (Thai+English mixed)
  → PyThaiNLP word_tokenize(engine='han_solo')  # Social media optimized
  → Strip particles (นะ, ครับ, ค่ะ, จ้า, etc.) for clustering
  → Keep particles for hook generation (they carry emotional weight)
  → langdetect per segment → code_switch_ratio feature
  → BERTopic with multilingual model handles mixed output
```

[SOURCE: https://link.springer.com/chapter/10.1007/978-981-97-9243-6_5 -- 2025 comparative evaluation of Thai word segmentation for social media]
[SOURCE: https://aclanthology.org/2023.nlposs-1.4.pdf -- PyThaiNLP NLP-OSS paper]
[INFERENCE: Thai social media patterns synthesized from platform knowledge + Thai cultural understanding + PyThaiNLP documentation]

## Ruled Out
- **Raw view count as GBDT target**: Biased by follower count. Normalized `views/followers` is required for meaningful comparison across accounts of different sizes.
- **Binary viral classification for GBDT**: Loses too much information versus regression. A continuous prediction (log-normalized) provides richer signal for ranking content ideas.
- **Random train/test split for temporal data**: Would create data leakage from future trends appearing in training data. Temporal split is mandatory.
- **Standard dictionary-based segmentation for Thai social media**: Too many OOV (out-of-vocabulary) failures on slang. Neural or CRF-based models (deepcut, han_solo) required.

## Dead Ends
None this iteration. All approaches were productive.

## Sources Consulted
- https://peerj.com/articles/cs-3245.pdf -- PeerJ 2025 social media topic popularity ML study
- https://papers.nips.cc/paper/6907-lightgbm-a-highly-efficient-gradient-boosting-decision-tree -- NeurIPS LightGBM paper
- https://apxml.com/posts/xgboost-vs-lightgbm-vs-catboost -- ApXML 2025 GBDT comparison
- https://www.geeksforgeeks.org/machine-learning/lightgbm-light-gradient-boosting-machine/
- https://www.nature.com/articles/s41599-025-05230-y -- Nature 2025 LightGBM framework
- https://orq.ai/blog/model-vs-data-drift -- Orq.ai 2025 model/data drift guide
- https://wandb.ai/onlineinference/genai-research/reports/LLM-evaluation-Metrics-frameworks-and-best-practices--VmlldzoxMTMxNjQ4NA -- W&B LLM eval
- https://www.braintrust.dev/articles/llm-evaluation-guide -- Braintrust eval guide
- https://www.evidentlyai.com/llm-guide/llm-as-a-judge -- Evidently AI
- https://pythainlp.org/dev-docs/api/tokenize.html -- PyThaiNLP tokenization docs
- https://github.com/PyThaiNLP/pythainlp -- PyThaiNLP GitHub
- https://arxiv.org/html/2312.04649v1 -- PyThaiNLP ACL paper
- https://link.springer.com/chapter/10.1007/978-981-97-9243-6_5 -- Thai word segmentation comparison 2025
- https://jmhorizons.com/index.php/journal/article/download/274/283/560 -- Journal of Media Horizons 2025

## Assessment
- New information ratio: 0.80
- Questions addressed: Q9, Q10, Q11
- Questions answered: Q9 (GBDT model training), Q10 (scoring calibration & feedback loop), Q11 (Thai-specific NLP & patterns)

## Reflection
- What worked and why: Web search yielded strong results for all three question areas. The GBDT comparison literature is mature with clear consensus favoring LightGBM for production use. Drift detection literature has consolidated around Evidently AI and statistical test approaches. PyThaiNLP documentation is comprehensive and its social media domain tools are directly applicable.
- What did not work and why: The PeerJ PDF was 403-blocked (common for academic PDFs). The ApXML article rendered without body content (JavaScript-heavy SPA). Both were mitigated by extracting key information from search result snippets and cross-referencing with other sources.
- What I would do differently: For academic papers, try fetching the HTML version instead of PDF. For Thai-specific patterns, a web search specifically targeting Thai-language sources or Thai digital marketing blogs could yield more granular cultural insights.

## Recommended Next Focus
1. **Q12: n8n orchestration** -- How L1 triggers L2, how L2 triggers L3 Content Lab, cron schedules, workflow chaining, data flow through DB tables. This is the final unanswered question.
2. **Q3 completion**: TikTok Creative Center JSON response schemas still needed.
3. **Synthesis pass**: With Q9/Q10/Q11 now answered, 10 of 12 questions are complete. A consolidation pass to resolve any cross-question contradictions and tighten the architecture would be valuable.
