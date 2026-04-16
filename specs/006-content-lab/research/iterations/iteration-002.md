# Iteration 2: A/B Testing Framework (Q3) and Multi-Variant Generation (Q4)

## Focus
Q3: How should A/B testing work for video content variants before production? Q4: How to efficiently generate multiple content variants from a single trend signal? These questions are the natural next step after establishing the prompt chain architecture (Q1) and Thai script structures (Q2) in iteration 1. Understanding variant testing informs how many variants to produce and how to measure effectiveness, while Q4 addresses the practical mechanics of variant production at scale.

## Findings

### Q3 Findings: A/B Testing Framework for Content Variants

**Finding 1: Two-Phase Testing Architecture (Pre-Production + Post-Production)**
Content variant testing should operate in two distinct phases, not one:
- **Pre-production testing (LLM-as-judge)**: Before any video is produced, script variants are scored by the LLM quality evaluation chain (step 4 from iteration 1). This is cheap, fast, and eliminates weak variants before expensive production. Use the 6-dimension rubric from spec 005 (Hook Strength 0.25, Emotional Trigger 0.20, Storytelling 0.15, Visual Potential 0.15, CTA 0.15, Audio Fit 0.10) as the pre-production gate. Variants scoring below 3.5/5.0 composite are rejected before production.
- **Post-production testing (platform audience)**: TikTok's own algorithm provides built-in A/B testing -- every video is shown to 500-1,000 test users initially and scaled based on engagement signals. The platform itself is the test environment.
[SOURCE: https://autofaceless.ai/blog/short-form-video-statistics-2026]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- LLM-as-judge rubric]

**Finding 2: Thompson Sampling for Multi-Arm Bandit Variant Selection**
Rather than classical A/B testing (fixed sample, p-value), use Thompson Sampling (Bayesian multi-arm bandit) for content variant allocation. This is superior for content because:
- **Exploration-exploitation balance**: Automatically shifts production resources toward winning variants while still testing new ones
- **No fixed sample size required**: Updates beliefs continuously as engagement data arrives
- **Works with small samples**: Starts showing convergence at 10-20 observations per arm (vs 30,000+ for frequentist A/B)
- **Implementation**: Model each variant's engagement rate as Beta(successes + 1, trials - successes + 1). Sample from each distribution, pick the highest sample, produce that variant next. Update after observing engagement.
- **Cold start**: New variant types start with Beta(1,1) uniform prior -- get equal exploration initially
[SOURCE: https://shivendra-su.medium.com/a-b-testing-v-s-thompson-sampling-pro-cons-and-much-more-42df377bdd11]
[SOURCE: https://www.pymc.io/projects/examples/en/latest/causal_inference/bayesian_ab_testing_introduction.html]

**Finding 3: Seven Variant Dimensions for Testing**
Based on the multi-stage prompt chain from iteration 1 and the hook research, these are the testable dimensions for video content variants:
1. **Hook type** (7 categories from spec 005: question, statistic, controversy, emotion, curiosity, relatable, shock)
2. **Emotional tone** (7 triggers from iteration 1: humor, sympathy, drama, shock, inspiration, FOMO, nostalgia)
3. **Script length** (15s / 30s / 60s templates from iteration 1)
4. **CTA style** (soft ask, direct command, urgency/FOMO, question redirect, community invite)
5. **Visual format** (talking head, voiceover+B-roll, text overlay, green screen -- from Q12)
6. **Opening audio** (music-first, voice-first, sound effect, silence-then-voice)
7. **Language register** (formal Thai, casual Thai with particles, Thai-English code-switch)
[INFERENCE: Synthesized from iteration 1 findings (prompt chain stages, Thai script elements) + spec 005 hook categories]

**Finding 4: Platform Engagement Benchmarks for Success Thresholds**
Key metrics for variant success measurement:
- **Completion rate**: 59% of short videos watched 41-80% of duration; 30% achieve >81% watch rate. Target: >50% completion for "passing" variant
- **Save rate**: >2% save rate makes video 3.4x more likely to reach For You page. Brand benchmark: 1.2%
- **Engagement rates by platform**: TikTok 2.80%, IG Reels 0.65%, YouTube Shorts 0.30-0.40%
- **71% of viewers decide in first few seconds** -- hook is the primary variant dimension
- **2026 completion threshold shift**: TikTok now weights ~70% completion rate (up from ~50%) for distribution scaling
[SOURCE: https://autofaceless.ai/blog/short-form-video-statistics-2026]
[SOURCE: https://almcorp.com/blog/short-form-video-mastery-tiktok-reels-youtube-shorts-2026/]

**Finding 5: Pre-Production Statistical Framework**
For pre-production (LLM-scored) testing:
- Generate N variants per trend signal (see Q4 below for optimal N)
- Score each with LLM-as-judge on 6-dimension rubric
- **Gate threshold**: composite score >= 3.5/5.0 passes to production
- **Ranking**: Top K variants (K = production capacity) proceed
- **Confidence calibration**: Use different LLM model for scoring vs generation (GPT-4o-mini generates, Claude Haiku evaluates) to reduce systematic bias -- this was established in iteration 1
- For post-production (audience) testing: Use Thompson Sampling over rolling 7-day engagement windows
- Minimum 10-20 published videos per variant type before drawing conclusions on that variant dimension
[SOURCE: https://www.invespcro.com/blog/calculating-sample-size-for-an-ab-test/]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- LLM-as-judge framework]

### Q4 Findings: Multi-Variant Generation from Single Trend Signal

**Finding 6: Variant Expansion Tree -- Single Trend to Multiple Scripts**
The multi-stage chain from iteration 1 naturally supports variant generation through a tree expansion at stage 1 (Concept Expansion):
```
Trend Signal (from L2)
  └─> Stage 1: Concept Expansion (temp 0.7-0.9)
       ├─> Concept Angle A (e.g., humor angle)
       ├─> Concept Angle B (e.g., shock/controversy)
       └─> Concept Angle C (e.g., educational/how-to)
            └─> Stage 2: Hook Generation (per concept)
                 ├─> Hook Variant 1 (question hook)
                 ├─> Hook Variant 2 (statistic hook)
                 └─> Hook Variant 3 (relatable hook)
                      └─> Stage 3: Script Body (per hook)
                           └─> 1 script per hook (deterministic, temp 0.3-0.5)
                                └─> Stage 4: Quality Gate
                                     └─> Pass/Fail (score >= 3.5)
```
This produces 3 concepts x 3 hooks = 9 script candidates per trend. After quality gate, expect 4-6 to pass (assuming ~50-65% pass rate).
[INFERENCE: Based on iteration 1 prompt chain architecture + concept expansion stage]

**Finding 7: Optimal Variant Count Per Trend -- 3x3 Matrix**
Based on production capacity, quality gate pass rates, and Thompson Sampling convergence requirements:
- **Generate**: 9 script candidates per trend (3 concept angles x 3 hook types)
- **Quality gate**: Expect 4-6 to pass LLM scoring (>= 3.5/5.0)
- **Produce**: Top 3-4 variants per trend (production bottleneck is video creation, not script generation)
- **Publish**: 2-3 variants across platforms (staggered per spec 004 posting schedule)
- **Rationale**: 3 concept angles provides meaningful diversity without diluting focus. 3 hook types per concept tests the most impactful variant dimension (71% of viewers decide in first seconds). Production of 3-4 balances resource usage with testing breadth.
- **Cost**: At GPT-4o-mini $0.15/1M input tokens, generating 9 scripts costs approximately $0.005-0.01 per trend (negligible)
[INFERENCE: Based on iteration 1 cost data + production pipeline capacity from spec 004 + engagement data from web sources]

**Finding 8: Efficient Variant Generation via Constrained Prompt Parameters**
Rather than running the full 5-stage chain 9 times independently, use parameter injection for efficiency:
- Run Stage 1 (Concept Expansion) ONCE with instruction to produce 3 distinct angles
- Run Stage 2 (Hook Generation) ONCE per concept with instruction to produce 3 hook types from the specified 7 categories
- Run Stage 3 (Script Body) independently for each concept+hook combination (9 parallel calls)
- Run Stage 4 (Quality Gate) in batch for all 9 scripts
- **Total LLM calls per trend**: 1 (expansion) + 3 (hooks) + 9 (scripts) + 1 (batch eval) = 14 calls
- vs. naive approach: 9 x 5 = 45 calls (69% reduction)
- Key efficiency: Stage 1 and Stage 2 are shared scaffolding; only Stage 3 needs full per-variant execution
[INFERENCE: Optimization of iteration 1 prompt chain for batch variant generation]

**Finding 9: Multimodal Hook Analysis Dimensions from Research**
The MLLM-VAU framework (academic research on video ad hooks) identifies testable dimensions that map to our variant framework:
- **Visual**: Interactive content, storytelling, visual appeals, humor, celebrity endorsement, product demos -- mapped to our "visual format" dimension
- **Audio**: 8 acoustic features (decibels, jitter, tempo, dynamic pitch, pitch range, power, peak amplitude, shimmer) -- relevant for TTS voice selection in production
- **Text**: ASR transcript + ad copy -- maps to our hook text and script body
- BERTopic clusters creative approaches into 17 coherent topic clusters per vertical -- validates our 7 hook categories as a reasonable granularity
- GBDT models predict conversion from creative features, confirming that hook features are the strongest predictors of downstream performance
[SOURCE: https://arxiv.org/html/2602.22299v1 -- MLLM-VAU framework]

## Ruled Out

- **Classical frequentist A/B testing for content variants**: Requires 30,000+ observations per variant for statistical significance at 95% confidence. Short-form video content rarely achieves this sample size per variant within the Thai trend lifecycle (24-48h). Thompson Sampling with Bayesian updates is strictly superior for this use case.
- **Testing all 7 variant dimensions simultaneously**: A full factorial design across 7 dimensions would produce hundreds of combinations. The 3x3 matrix (concepts x hooks) tests the two highest-impact dimensions while keeping production manageable.

## Dead Ends

None identified this iteration. All approaches were productive.

## Sources Consulted
- https://autofaceless.ai/blog/short-form-video-statistics-2026 (Short-form video statistics 2026 -- completion rates, engagement benchmarks, platform comparisons)
- https://almcorp.com/blog/short-form-video-mastery-tiktok-reels-youtube-shorts-2026/ (Short-form video mastery guide 2026 -- testing allocation, algorithm behavior)
- https://arxiv.org/html/2602.22299v1 (MLLM-VAU -- Multimodal LLM framework for hook analysis in video ads)
- https://shivendra-su.medium.com/a-b-testing-v-s-thompson-sampling-pro-cons-and-much-more-42df377bdd11 (Thompson Sampling vs A/B testing comparison)
- https://www.pymc.io/projects/examples/en/latest/causal_inference/bayesian_ab_testing_introduction.html (Bayesian A/B testing with PyMC -- Beta distribution modeling)
- https://www.invespcro.com/blog/calculating-sample-size-for-an-ab-test/ (A/B testing sample size calculations)
- specs/005-trend-viral-brain/research/research.md (Prior L1+L2 research -- hook categories, LLM-as-judge rubric, viral scoring)
- specs/006-content-lab/research/deep-research-strategy.md (Known context from specs 001, 003, 004, 005)

## Assessment
- New information ratio: 0.72
- Questions addressed: [Q3, Q4]
- Questions answered: [Q3, Q4]

## Reflection
- What worked and why: Combining web search for quantitative engagement benchmarks with the existing spec 005 rubric framework produced a complete testing architecture. The arxiv paper on hook analysis (MLLM-VAU) provided academic validation that hook features are the strongest performance predictors, supporting our decision to make hooks the primary variant dimension. Thompson Sampling literature was well-established and directly applicable to content optimization.
- What did not work and why: The BlogBurst article on Thompson Sampling for social media returned 404 (likely removed or restructured). The first web search returned mostly marketing guides rather than technical testing frameworks -- had to refine to include specific statistical terms (Bayesian, Thompson) to find actionable sources.
- What I would do differently: For future iterations involving statistical methodology, start with academic/technical search terms rather than marketing-oriented queries to reach actionable sources faster.

## Recommended Next Focus
Q5 (L1 trend data and L2 viral scores feeding into script generation prompts) and Q9 (script quality evaluation before production). These naturally follow from Q3/Q4: now that we know WHAT variants to generate and HOW to test them, we need to define the input format (how trend data enters the generation pipeline) and the quality evaluation rubric (how scripts are scored before production). Q5 connects the L2 output to L3 input, while Q9 defines the quality gate that was referenced in this iteration's variant testing framework.
