# Iteration 3: Trend Freshness/Velocity (Q6), LLM-as-Judge Scoring (Q7), Hook Variant Generation (Q8)

## Focus
Three L2 Viral Brain questions that move from data ingestion (iterations 1-2) to intelligence and content generation: how to measure trend momentum for timing, how to score viral potential with LLMs, and how to generate hook variants from trends.

## Findings

### Finding 1: Trend Velocity Scoring Model (Q6)
**Trend velocity can be quantified as the rate of change in trend strength over time, scored on a -3 to +3 scale.**

The industry-standard approach (Trendtracker, Trendible) uses a **Trend Change metric**: the monthly rate of change of trend strength over a rolling window, scored between -3 (fast decrease) to +3 (fast increase). For viral-ops, this maps directly to pytrends `interest_over_time()` data.

**Proposed viral-ops velocity formula using pytrends data:**
```
velocity = (current_period_avg - previous_period_avg) / previous_period_avg
```
Where periods are configurable (e.g., 7-day vs 7-day, or 24h vs 24h for fast-moving trends).

**Classification thresholds for viral-ops:**

| Velocity Score | Classification | Content Action |
|---------------|----------------|----------------|
| > +0.50 | SURGING (+3) | Immediate production -- highest priority |
| +0.20 to +0.50 | RISING (+2) | Queue for next production cycle |
| +0.05 to +0.20 | EMERGING (+1) | Monitor, prepare concepts |
| -0.05 to +0.05 | STABLE (0) | Maintain existing content only |
| -0.20 to -0.05 | DECLINING (-1) | Do not start new content |
| -0.50 to -0.20 | FADING (-2) | Archive trend |
| < -0.50 | DEAD (-3) | Remove from active tracking |

**Lifecycle model (ROESI framework adapted for viral-ops):**
1. **Emergence** (velocity > +0.20, strength < 30) -- weak signal, fast growth. Scout phase.
2. **Growth** (velocity > +0.20, strength 30-70) -- gaining momentum. Best window for content creation.
3. **Peak** (velocity -0.05 to +0.05, strength > 70) -- high volume, flat momentum. Last viable production window.
4. **Decay** (velocity < -0.05, strength > 30) -- declining interest. Content already produced may still perform but do not invest new production.
5. **Saturation** (velocity < -0.20, strength < 30) -- trend is over. Archive.

**Multi-source freshness score (composite):**
```
freshness_score = (
    0.40 * google_velocity_normalized +    # pytrends interest_over_time delta
    0.30 * tiktok_hashtag_growth_rate +    # TikTok Creative Center post count delta
    0.20 * youtube_view_velocity +          # YouTube trending video view acceleration
    0.10 * recency_bonus                    # hours since first detection (newer = higher)
)
```
Where each component is normalized to 0.0-1.0 range. The weights reflect source reliability: Google Trends is most stable, TikTok hashtag growth is fastest signal, YouTube provides validation, recency prevents stale trends.

**Timing window**: Content created within the Growth phase (velocity > +0.20) has the highest viral potential. The "Velocity Playbook" (Yotpo, 2026) emphasizes that velocity tells trajectory, not just current status -- critical for forward-looking content decisions. Industry guidance suggests a 48-72h production window from trend detection to publish for optimal performance.

[SOURCE: https://www.trendtracker.ai/blog-posts/whats-rising-whats-fading-how-to-interpret-trend-velocity]
[SOURCE: https://trendible.co/tools/trend-velocity/]
[SOURCE: https://www.yotpo.com/blog/google-trends-seo-strategy/]

### Finding 2: LLM-as-Judge 1-5 Scoring Scale with Analytic Rubric (Q7)
**Integer 1-5 scale strongly preferred over 0-10 or float scores. Each dimension evaluated independently with separate prompts.**

Key design principles from Monte Carlo Data and academic research:
- **1-5 categorical integer scale** is strongly preferred. Float scores produce inconsistent results. "LLM-as-judge does better with a categorical integer scoring scale with a very clear explanation" (Monte Carlo Data, 2025).
- **Separate evaluation per dimension** -- LLMs are "much more effective when given clear, single objective tasks." Avoid combining all 6 dimensions into one mega-prompt.
- **Few-shot calibration**: Include 1-2 examples maximum. Research shows performance declines with 3+ examples.
- **Step decomposition**: Break subjective assessments into reasoning steps before scoring.

**Recommended 6-dimension rubric for viral-ops (1-5 scale each):**

| Dimension | Weight | What It Measures |
|-----------|--------|------------------|
| Hook Strength | 0.25 | First 3 seconds -- does it stop the scroll? |
| Storytelling | 0.15 | Narrative arc, pacing, payoff |
| Emotional Trigger | 0.20 | Emotional activation (surprise, curiosity, FOMO, humor) |
| Visual Potential | 0.15 | Visual richness, B-roll opportunity, thumbnail appeal |
| Audio Fit | 0.10 | Trending sound alignment, voiceover clarity, music match |
| CTA Effectiveness | 0.15 | Clear action, urgency, engagement prompt |

**Updated total: weighted sum produces 1.0-5.0 range** (instead of gen1's 0-60 range from 0-10 x 6). The 1-5 scale is simpler to calibrate and aligns with LLM-as-judge best practices.

**Prompt template structure:**
```
System: You are an expert short-form video content evaluator specializing in TikTok and YouTube Shorts viral potential.

Evaluate the following content concept on {DIMENSION_NAME} only.

## Scoring Scale:
- 5 = Exceptional: {dimension-specific criteria for 5}
- 4 = Strong: {dimension-specific criteria for 4}
- 3 = Adequate: {dimension-specific criteria for 3}
- 2 = Weak: {dimension-specific criteria for 2}
- 1 = Poor: {dimension-specific criteria for 1}

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
{
  "dimension": "{DIMENSION_NAME}",
  "score": <integer 1-5>,
  "reasoning": "<2-3 sentences explaining score>",
  "improvement_suggestion": "<specific suggestion if score < 4>"
}
```

**Model selection for viral-ops:**
- **Phase 1 primary**: GPT-4o-mini -- cost-effective ($0.15/1M input), fast, good structured output. Suitable for high-volume scoring.
- **Phase 1 calibration**: GPT-4o or Claude Sonnet for generating reference scores (judge the judges).
- **Thai content consideration**: DeepSeek-V3 as alternative -- strong multilingual capability, lower cost. Needs benchmarking against GPT-4o-mini on Thai content specifically.

**Calibration approach:**
1. Human-score 50 content concepts across all 6 dimensions (gold standard set)
2. Run LLM judge on same 50 concepts
3. Calculate Cohen's Kappa for inter-rater agreement (target: kappa > 0.6 = substantial agreement)
4. Adjust rubric descriptions where disagreement is highest
5. Store calibration set as few-shot examples (pick 1-2 best-aligned examples per dimension)

[SOURCE: https://www.montecarlodata.com/blog-llm-as-judge/]
[SOURCE: https://www.evidentlyai.com/llm-guide/llm-as-a-judge]
[SOURCE: https://www.langchain.com/articles/llm-as-a-judge]

### Finding 3: Hook Variant Generation System (Q8)
**7 hook categories with template-driven generation, 3-5 variants per trend, 48h A/B testing window.**

**Hook categories for short-form viral content (2025-2026 industry standard):**

1. **Question Hook** -- Poses a question viewers cannot resist answering. "Did you know 90% of Thai creators make this mistake?"
2. **Statistic/Shock Hook** -- Opens with a surprising number. "This trend got 50M views in 3 days."
3. **Controversy/Contrarian Hook** -- Challenges conventional wisdom. "Stop doing X -- here is why it is killing your reach."
4. **Curiosity Gap Hook** -- Creates information asymmetry. "I found the secret that top Thai creators use and it changed everything."
5. **Emotional Hook** -- Triggers strong emotion (fear, joy, nostalgia). "This will make you rethink everything about..."
6. **Pattern Interrupt Hook** -- Unexpected visual/audio element. "Wait -- watch what happens at 0:03."
7. **Authority/Social Proof Hook** -- Leverages credibility or numbers. "After 1,000 videos, here is what actually works."

**Generation approach (trend + topic -> 3-5 hooks):**
```
Input: {trend_name}, {topic}, {niche}, {emotional_angle}

For each hook category (pick 3-5 most relevant to the topic):
  Template: "[Category] hook for {topic} in context of {trend_name}"
  
  Generate variant using LLM with:
  - Constraint: max 15 words (first 3 seconds of video)
  - Language: Thai or English based on target audience
  - Emotional target: derived from trend sentiment analysis
  - Platform optimization: TikTok (direct, casual) vs YouTube (slightly longer, SEO-aware)
```

**A/B testing integration with Content Lab (L3):**
- Generate 3-5 hook variants per trend+topic combination
- L2 Viral Brain scores each variant using Hook Strength dimension (1-5)
- Top 2-3 scoring hooks passed to Content Lab for production
- Content Lab produces 2-3 versions (same content body, different hooks)
- Platform posts are scheduled with 48h measurement window
- After 48h, L7 Analytics feeds back actual performance (views, completion rate, engagement)
- Performance data feeds into GBDT training set (Phase 2)

**Thai hook patterns (specific structural patterns that perform well):**
- **Particle emphasis**: Thai hooks often end with emphatic particles (นะ, เลย, จริงๆ) for emotional punch
- **Code-switching**: Mix Thai + English for trending terms. "ทำไม [English trend term] ถึงได้ viral ขนาดนี้"
- **Direct address**: ใช้คำว่า "คุณ" or "เธอ" for personal engagement
- **Numeric anchoring**: Numbers perform well in Thai hooks just as in English. "3 สิ่งที่..."

**Critical metric**: 71% of viewers decide within the first 3 seconds whether to keep watching. Hooks must be 15 words or fewer to fit within this window.

[SOURCE: https://www.marketingblocks.ai/50-viral-hook-templates-for-ads-reels-tiktok-or-captions-2026-frameworks-examples-ai-prompts-included/]
[SOURCE: https://virvid.ai/blog/ai-shorts-script-hook-ultimate-guide-2026]
[SOURCE: https://www.submagic.co/blog/best-hooks-for-tiktok-and-instagram]
[SOURCE: https://joinbrands.com/blog/youtube-shorts-best-practices/]

### Finding 4: LLM-as-Judge Pitfalls and Reliability (Q7 supplementary)
**LLM judges produce garbage ~10% of the time. Mitigation: re-run on low scores, use panel averaging.**

Key reliability concerns:
- "One in every ten tests spits out absolute garbage" -- inherent LLM unreliability (Monte Carlo Data)
- **Panel of judges**: Research shows averaging scores from multiple LLM runs improves accuracy. For viral-ops, run each dimension evaluation 2x and average (cost: 12 LLM calls per content concept for 6 dimensions x 2 runs).
- **Anomaly detection**: Flag scores where 2 runs differ by >= 2 points on 1-5 scale -- these need human review or a 3rd LLM run.
- **Stratified sampling**: Not every content concept needs full 6-dimension evaluation. Quick pre-filter: score Hook Strength only (cheapest, most predictive). Only concepts scoring >= 3 on hook proceed to full evaluation.
- **Cost model**: GPT-4o-mini at $0.15/1M input tokens. A typical content concept evaluation (6 dimensions x 2 runs) uses ~3000 tokens input = $0.00045 per concept. At 100 concepts/day = $0.045/day. Extremely affordable.

[SOURCE: https://www.montecarlodata.com/blog-llm-as-judge/]
[INFERENCE: cost calculation based on GPT-4o-mini pricing and estimated token usage per evaluation prompt]

### Finding 5: Composite Viral Score Formula (Q7 integration)
**Proposed final viral score combining trend freshness with content quality.**

```
viral_potential = (
    0.40 * content_quality_score +     # LLM-as-judge weighted 6-dimension score (1-5)
    0.35 * trend_freshness_score +     # Multi-source velocity composite (0-1)
    0.15 * niche_fit_score +           # How well topic fits creator's niche (0-1)
    0.10 * timing_bonus                # Optimal posting time alignment (0-1)
)
```

This produces a 0-1 range score that determines L2's recommendation to L3 Content Lab:
- >= 0.70: "PRODUCE NOW" -- high priority
- 0.50-0.69: "CONSIDER" -- queue for review
- < 0.50: "SKIP" -- below threshold

[INFERENCE: based on combining Q6 freshness model with Q7 scoring rubric into unified decision framework]

## Ruled Out
- **Float scoring scales for LLM-as-judge**: Research strongly favors categorical integers (1-5). Float scores produce inconsistent, harder-to-calibrate results. Ruled out 0-10 scale from gen1 in favor of 1-5.
- **Single mega-prompt for all 6 dimensions**: LLMs perform better with single-objective tasks. Multi-dimension prompts lead to criterion conflation and halo effects.

## Dead Ends
- None this iteration. All approaches were productive.

## Sources Consulted
- https://www.montecarlodata.com/blog-llm-as-judge/ -- LLM-as-judge best practices, templates, pitfalls
- https://www.evidentlyai.com/llm-guide/llm-as-a-judge -- comprehensive LLM judge guide
- https://www.langchain.com/articles/llm-as-a-judge -- calibration with human corrections
- https://www.trendtracker.ai/blog-posts/whats-rising-whats-fading-how-to-interpret-trend-velocity -- trend velocity interpretation
- https://trendible.co/tools/trend-velocity/ -- trend velocity scoring tool
- https://www.yotpo.com/blog/google-trends-seo-strategy/ -- Google Trends velocity playbook 2026
- https://www.marketingblocks.ai/50-viral-hook-templates-for-ads-reels-tiktok-or-captions-2026-frameworks-examples-ai-prompts-included/ -- 50+ viral hook templates
- https://virvid.ai/blog/ai-shorts-script-hook-ultimate-guide-2026 -- viral hook guide 2026
- https://www.submagic.co/blog/best-hooks-for-tiktok-and-instagram -- 75 TikTok/Instagram hooks
- https://joinbrands.com/blog/youtube-shorts-best-practices/ -- YouTube Shorts best practices 2026

## Assessment
- New information ratio: 0.80
- Questions addressed: Q6, Q7, Q8
- Questions answered: Q6 (trend freshness/velocity model complete), Q7 (LLM-as-judge rubric designed), Q8 (hook variant generation system designed)

## Reflection
- What worked and why: Web search for each question independently yielded highly relevant 2025-2026 sources. The LLM-as-judge field has matured significantly with clear best practices. Trend velocity is a well-established concept with transferable frameworks.
- What did not work and why: Trendtracker article lacked exact mathematical formulas -- had to synthesize the velocity formula from the conceptual framework combined with pytrends data structure knowledge from iteration 2. This is acceptable as the formula is straightforward rate-of-change calculation.
- What I would do differently: For Q7, could fetch the Autorubric paper (arxiv.org/html/2603.00077v2) for more academic rigor on rubric design. This is a refinement opportunity for a future iteration if needed.

## Recommended Next Focus
1. **Q9: GBDT model training** -- feature engineering from 6-dimension LLM scores + trend features + temporal features, LightGBM vs XGBoost comparison, training pipeline design, target metric selection (views? engagement rate? completion rate?)
2. **Q10: Scoring calibration & feedback loop** -- how L7 analytics feeds back into L2 scoring, score drift detection, retraining triggers for both LLM rubric and GBDT model
3. **Q3 completion**: Still need TikTok Creative Center JSON response schemas from `tiktok-discover-api` endpoints
