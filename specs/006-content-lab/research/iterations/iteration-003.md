# Iteration 3: L1/L2 Data Feeding into Script Generation & Script Quality Evaluation

## Focus
Investigated Q5 (How L1 trend data and L2 viral scores feed into script generation prompts) and Q9 (How to evaluate script quality before sending to production). These questions are the natural bridge between the variant/testing framework (Q3/Q4, iteration 2) and the production pipeline (Q6/Q7/Q8, future iterations). Q5 defines the **input contract** -- how upstream data enters the generation pipeline. Q9 defines the **output gate** -- how scripts are assessed before entering production.

## Findings

### Q5: L1/L2 Data Feeding into Script Generation Prompts

#### 1. Structured Context Injection Template (XML Block Pattern)
The L2 Viral Brain output should be injected into the L3 script generation prompt chain using a structured XML context block placed **at the top of the prompt** (before instructions, examples, and query). Anthropic docs confirm queries at the end improve response quality by up to 30% with complex multi-document inputs.

**Complete Context Injection Schema:**
```xml
<trend_context>
  <trend>
    <keyword>ลองของใหม่</keyword>
    <platform>tiktok</platform>
    <region>TH</region>
    <velocity_class>SURGING</velocity_class>
    <velocity_score>0.72</velocity_score>
    <lifecycle_stage>growth</lifecycle_stage>
    <freshness_score>0.85</freshness_score>
    <hours_since_detection>6</hours_since_detection>
    <source_signals>
      <google_trends velocity="0.68" />
      <tiktok_hashtag posts="12400" growth_rate="0.81" />
      <youtube views_acceleration="0.45" />
    </source_signals>
  </trend>
  <viral_assessment>
    <composite_score>0.78</composite_score>
    <content_quality>0.82</content_quality>
    <trend_freshness>0.85</trend_freshness>
    <niche_fit>0.70</niche_fit>
    <timing_bonus>0.65</timing_bonus>
    <decision>PRODUCE_NOW</decision>
  </viral_assessment>
  <top_hooks>
    <hook type="curiosity" score="4.5" rank="1">ทำไมทุกคนถึงลอง...</hook>
    <hook type="question" score="4.2" rank="2">เคยลองยัง?</hook>
    <hook type="shock" score="3.8" rank="3">ผลลัพธ์ที่ไม่มีใครคาดคิด</hook>
  </top_hooks>
  <niche>lifestyle</niche>
  <target_audience>Thai Gen Z, 18-25</target_audience>
  <related_trends>
    <trend keyword="ของใหม่น่าลอง" velocity="RISING" />
    <trend keyword="รีวิวตรงๆ" velocity="EMERGING" />
  </related_trends>
</trend_context>
```

**Key design decisions:**
- XML over JSON for prompt context: LLMs parse XML tags more reliably in instruction-following contexts (Anthropic docs explicitly recommend XML tag structuring for prompt content separation)
- `source_signals` included per-source to enable the LLM to weight its creative decisions (e.g., if TikTok signal is strongest, lean into TikTok-native formats)
- `related_trends` enables cross-trend content that references adjacent trending topics
- `hours_since_detection` enables freshness-aware scripting ("this trend just dropped" vs. "everyone's talking about")

[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/chain-prompts -- "Long context prompting" section, XML structuring, document-first ordering]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- Composite Viral Potential Score formula, multi-source freshness model]

#### 2. Three-Gate Freshness Validation Before Generation
Not every trend that passes L2 scoring should enter L3 generation. A freshness validation gate prevents wasted generation on stale or declining trends:

**Gate 1: Lifecycle Stage Gate**
- ALLOW: `emergence`, `growth`, `peak`
- BLOCK: `decay`, `saturation`, `dead`
- Implementation: Simple DB query -- `WHERE lifecycle_stage IN ('emergence', 'growth', 'peak')`

**Gate 2: Velocity Recency Gate**
- Before generating, re-check velocity from L1 data (may have changed since L2 scoring)
- BLOCK if velocity has dropped below +0.05 (STABLE) since L2 assessment
- BLOCK if `hours_since_detection > 36` for Thai market (24-48h lifecycle means trends past 36h are risky)
- Implementation: n8n "IF" node comparing current velocity against L2-time velocity

**Gate 3: Duplicate Content Gate**
- Check `content` table for existing scripts on same `trend_id + niche + platform`
- ALLOW if no prior content, or if prior content has status `rejected` or `failed`
- BLOCK if active content (status `queued`, `producing`, `published`) already exists for this trend-niche-platform combination
- Exception: ALLOW if existing content's viral_score is 0.15+ lower than current assessment (trend has gotten hotter, worth re-scripting)

**Gate validation query (pseudocode):**
```sql
SELECT t.keyword, t.lifecycle_stage, t.velocity_score,
       t.hours_since_detection, c.status, c.viral_score
FROM trends t
LEFT JOIN content c ON t.id = c.trend_id 
  AND c.niche = :niche AND c.platform = :platform
  AND c.status NOT IN ('rejected', 'failed')
WHERE t.id = :trend_id
  AND t.lifecycle_stage IN ('emergence', 'growth', 'peak')
  AND t.velocity_score > 0.05
  AND (t.hours_since_detection < 36 OR t.lifecycle_stage = 'peak')
```

[SOURCE: specs/005-trend-viral-brain/research/research.md -- Trend Lifecycle Stages, velocity classification thresholds]
[INFERENCE: Gate thresholds derived from Thai 24-48h lifecycle (spec 005) applied to production pipeline timing constraints; duplicate gate based on standard content pipeline deduplication patterns]

#### 3. L2 Score-to-Prompt Parameter Mapping
The L2 viral assessment scores should not just be context -- they should actively control generation parameters:

| L2 Signal | Script Generation Parameter | Mapping Logic |
|-----------|---------------------------|---------------|
| `composite_score >= 0.85` | priority = "immediate", variants = 5 | SURGING trend, max production effort |
| `composite_score 0.70-0.84` | priority = "high", variants = 3 | Standard PRODUCE_NOW |
| `composite_score 0.50-0.69` | priority = "normal", variants = 1 | CONSIDER -- single exploratory script |
| `hook_strength_score >= 4` | Use L2's top hook directly as seed | Skip hook generation step, use pre-scored hook |
| `hook_strength_score < 4` | Generate new hooks in L3 | L2 hooks were weak, L3 should explore fresh angles |
| `emotional_trigger_score` | Map to script tone parameter | Score 5 = maximize that emotion; 3-4 = include; 1-2 = deprioritize |
| `visual_potential_score >= 4` | Include B-roll suggestions in script | High visual score means visual scripting is worthwhile |
| `audio_fit_score >= 4` | Flag for trending sound integration | Worth finding matching trending audio |
| `trend.velocity_class = SURGING` | Temperature = 0.6 (less creative risk) | Hot trend needs reliable execution, not experimentation |
| `trend.velocity_class = EMERGING` | Temperature = 0.9 (more creative risk) | Emerging trend rewards experimentation |

This mapping converts L2 intelligence into concrete generation controls rather than treating scores as passive context.

[SOURCE: specs/005-trend-viral-brain/research/research.md -- 6 dimensions with weights, composite score formula, decision thresholds]
[INFERENCE: Parameter mapping design based on the principle that upstream intelligence should actively control downstream behavior, not just inform it; temperature mapping follows creative-vs-reliable task distinction from iteration 1]

#### 4. Few-Shot Example Selection from L7 Performance Data
The context injection should include dynamically-selected few-shot examples from the performance database:

**Selection algorithm:**
1. Query `content` table for published scripts in same `niche + platform` with actual performance data
2. Sort by `actual_views / expected_views` ratio (over-performers first)
3. Filter to top 5 performers from last 30 days
4. Select 3 examples that maximize diversity: different hook_types, different durations, different emotional tones
5. Include each example with its performance metrics:

```xml
<examples>
  <example performance="4.2x_expected_views" hook_type="curiosity" duration="30s">
    <script>...</script>
    <metrics views="145000" engagement_rate="8.2%" shares="3200" />
  </example>
  <!-- 2 more examples -->
</examples>
```

**Cold-start (first 30 days):** Use manually curated Thai viral script examples from competitor analysis. Replace with organic top performers as L7 data accumulates.

[SOURCE: specs/005-trend-viral-brain/research/research.md -- A/B Test Integration section, few-shot calibration protocol]
[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/chain-prompts -- "Use examples effectively" section: 3-5 examples, wrapped in example tags, relevant and diverse]

### Q9: Script Quality Evaluation Before Production

#### 5. Two-Layer Quality Gate Architecture
Script quality evaluation should use TWO complementary layers, not just one:

**Layer 1: LLM Self-Evaluation (fast, cheap, catches obvious issues)**
The same LLM that generated the script (or a different model to reduce self-enhancement bias) evaluates it against a rubric. This is Step 4 in the 5-stage prompt chain from iteration 1.

**Layer 2: Separate LLM-as-Judge (independent, higher-reliability)**
A separate LLM call using the L2 Viral Brain's 6-dimension rubric (already built in spec 005) scores the generated script. This reuses existing infrastructure.

**Why two layers:**
- Research shows LLMs have 10-25% self-enhancement bias (preferring own outputs). Using a second, independent evaluation reduces this.
- Layer 1 catches structural issues (wrong format, missing CTA, off-topic) cheaply.
- Layer 2 provides calibrated viral-potential scoring using the proven 6-dimension rubric.
- Combined, they achieve higher precision than either alone.

[SOURCE: https://eugeneyan.com/writing/llm-evaluators/ -- Self-enhancement bias: "preferring own-generated outputs with 10-25% win rate boosts"; Panel of LLMs outperforms single evaluator]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- LLM-as-Judge Scoring Rubric with 6 dimensions]

#### 6. Layer 1: Structural Quality Self-Evaluation Rubric
The generating LLM evaluates its own output on 5 binary/categorical checks (fast, deterministic):

| Check | Type | Pass Criteria | Fail Action |
|-------|------|--------------|-------------|
| **Hook Presence** | Binary | Hook exists, <= 15 words, in first 3 seconds | Regenerate hook only |
| **Duration Compliance** | Categorical | Total duration matches target (15/30/60s +/- 2s) | Trim or expand body |
| **CTA Presence** | Binary | CTA exists in final segment | Append CTA |
| **Thai Language Quality** | Categorical | Particle usage natural, no garbled Thai, code-switching appropriate | Regenerate full script |
| **JSON Schema Valid** | Binary | Output matches defined script JSON schema | Retry with stricter schema instructions |

**Implementation:** Add a structured evaluation step at the end of the generation chain:
```
System: You have just generated a video script. Evaluate it against these 5 quality checks.
For each check, respond with PASS or FAIL and a 1-sentence reason.
If any check FAILS, output the specific fix needed.
Output as JSON: {"checks": [{"name": "...", "status": "PASS|FAIL", "reason": "...", "fix": "..."}]}
```

Cost: ~$0.002 per evaluation at GPT-4o-mini rates. Negligible overhead.

[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/chain-prompts -- Prompt chaining for validation steps]
[INFERENCE: Binary/categorical checks designed to catch the most common generation failures identified in iteration 1's script structure research (missing hooks, duration mismatch, CTA absence)]

#### 7. Layer 2: 6-Dimension Viral Potential Scoring (Reuse L2 Rubric)
After Layer 1 passes, apply the **same** L2 LLM-as-Judge rubric from spec 005 to the generated script:

**Scoring dimensions (from spec 005):**
1. Hook Strength (0.25) -- Does the generated hook stop the scroll?
2. Emotional Trigger (0.20) -- Does the script activate the intended emotion?
3. Storytelling (0.15) -- Does the 4-beat structure create a satisfying arc?
4. Visual Potential (0.15) -- Are visual cues rich enough for production?
5. CTA Effectiveness (0.15) -- Will the CTA drive the intended action?
6. Audio Fit (0.10) -- Is the script TTS-ready with natural pacing?

**Key adaptation for L3 (vs L2 usage):**
- In L2, the rubric scores **concepts** (pre-production ideas)
- In L3, the rubric scores **completed scripts** (full text with timing and visual cues)
- L3 scoring criteria should be stricter because more information is available (full script vs. concept summary)
- Use `score one dimension per prompt` pattern (research confirms this outperforms multi-dimensional single-prompt evaluation)

**Scoring implementation:**
- Run each dimension as a separate LLM call (6 calls total)
- Run each dimension 2x and average (spec 005 pattern: ~10% garbage rate per run)
- Flag dimensions where 2 runs differ by >= 2 points for human review
- Use a different model family for Layer 2 than Layer 1 (e.g., if GPT-4o-mini generated, use Claude Haiku for judging -- reduces systematic bias)

[SOURCE: specs/005-trend-viral-brain/research/research.md -- LLM-as-Judge Scoring Rubric, 6 dimensions with weights, reliability mitigations]
[SOURCE: https://eugeneyan.com/writing/llm-evaluators/ -- "scoring one dimension per prompt achieves better performance"; dimension isolation principle; CoT improves accuracy]

#### 8. Reject/Revise/Accept Decision Thresholds
Based on the two-layer evaluation, apply a three-outcome decision:

**Composite quality score calculation:**
```
script_quality = weighted_average(6_dimension_scores)  // 1.0-5.0 scale
```

**Decision thresholds:**

| Composite Score | Decision | Action |
|----------------|----------|--------|
| >= 4.0 | **ACCEPT** | Send to production queue (L4) |
| 3.5 - 3.9 | **REVISE** | Send back to generation with specific improvement instructions from lowest-scoring dimensions |
| 3.0 - 3.4 | **REVISE_ONCE** | One revision attempt. If still < 3.5 after revision, REJECT |
| < 3.0 | **REJECT** | Discard. Log failure reason. Try different concept angle if trend still active |

**Revision loop mechanics:**
1. Identify dimensions scoring below 3
2. Extract `improvement_suggestion` from each low-scoring dimension's evaluation
3. Feed back into generation prompt: "Revise this script to improve {dimension}: {suggestion}"
4. Max 2 revision attempts per script (diminishing returns beyond that)
5. Track revision count in `content` table: `revision_count INT DEFAULT 0`

**Cost analysis (per trend, 3 variants):**
- Generation: 3 scripts x 5 chain stages x ~$0.003 = $0.045
- Layer 1 self-eval: 3 x $0.002 = $0.006
- Layer 2 scoring: 3 x 6 dimensions x 2 runs x ~$0.001 = $0.036
- Revisions (avg 1 per 3 scripts): 1 x $0.003 + $0.038 = $0.041
- **Total per trend: ~$0.13** (well within budget at 10-20 trends/day = $1.30-$2.60/day)

[SOURCE: specs/005-trend-viral-brain/research/research.md -- Quality gate threshold 3.5/5.0 from iteration 2]
[SOURCE: https://eugeneyan.com/writing/llm-evaluators/ -- Prometheus achieved 0.897 Pearson correlation with sequential feedback-then-score CoT; multi-turn evaluation improves reliability]
[INFERENCE: Cost analysis based on GPT-4o-mini pricing ($0.15/1M input) applied to estimated token counts per call; revision loop design based on standard generate-evaluate-refine patterns]

#### 9. Chain-of-Thought Evaluation for Higher Accuracy
Research strongly confirms that Chain-of-Thought (CoT) prompting in the evaluation step significantly improves scoring accuracy. The evaluation prompt should require reasoning BEFORE scoring:

**Pattern:**
```
Evaluate this script on {DIMENSION} using the rubric below.

IMPORTANT: First, write your analysis of the script's strengths and weaknesses 
for this dimension in <reasoning> tags. Then provide your score.

<reasoning>
[Model writes analysis here first]
</reasoning>

Score: [1-5]
Improvement suggestion (if score < 4): [specific actionable suggestion]
```

This "sequential feedback-then-score" pattern (from Prometheus research) achieved 0.897 Pearson correlation with human judgments. Without CoT, LLM evaluators often anchor to superficial features.

Additional accuracy improvements:
- **Rubric specificity**: Research shows "specific criteria had the highest agreement and correlation with human annotators while general criteria had the lowest." Each score level (1-5) per dimension must have explicit Thai-content-specific descriptions.
- **Avoid overthinking instruction**: When evaluating against a reference/rubric, adding "evaluate based on the rubric criteria, don't apply external knowledge" prevents the LLM from injecting its own standards.
- **Position debiasing**: When comparing variants, randomize presentation order (GPT-3.5 shows 50% position bias, Claude 70%).

[SOURCE: https://eugeneyan.com/writing/llm-evaluators/ -- CoT improves accuracy; Prometheus 0.897 correlation; specific criteria > general criteria; position bias statistics; "don't overthink" instruction]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- Calibration Protocol: 50-concept gold standard, Cohen's Kappa > 0.6 target]

## Ruled Out
- **Single-layer evaluation (self-evaluation only)**: LLM self-enhancement bias of 10-25% makes self-evaluation alone unreliable. Two-layer approach with different model families is strictly better.
- **OpenAI Structured Outputs docs**: Returned 403 (authenticated access required). Docs site requires login since restructuring. Not accessible via WebFetch.
- **Full 6-dimension evaluation for every draft**: Running Layer 2 on scripts that fail Layer 1 structural checks wastes API calls. Layer 1 (structural) should gate Layer 2 (quality) to save cost.

## Dead Ends
None identified. All approaches in this iteration were productive.

## Sources Consulted
- https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/chain-prompts (Anthropic prompting best practices -- XML structuring, long context, document ordering, few-shot examples, prompt chaining)
- https://eugeneyan.com/writing/llm-evaluators/ (LLM-as-Judge research synthesis -- scoring patterns, bias mitigation, CoT evaluation, dimension isolation, Prometheus correlation, Panel of LLMs)
- specs/005-trend-viral-brain/research/research.md (L1+L2 research -- composite score formula, LLM-as-Judge rubric, 6 dimensions, trend lifecycle, velocity thresholds, calibration protocol, hook generation)
- specs/006-content-lab/research/iterations/iteration-001.md (Iteration 1 findings -- 5-stage prompt chain, XML context injection, JSON schema, few-shot calibration, model selection, Thai script anatomy)

## Assessment
- New information ratio: 0.72
- Questions addressed: Q5, Q9
- Questions answered: Q5, Q9

## Reflection
- What worked and why: The combination of Anthropic's prompt engineering docs (authoritative on context injection patterns) and Eugene Yan's LLM evaluator research (comprehensive synthesis of evaluation best practices) provided strong dual-source coverage. Building on spec 005's existing 6-dimension rubric was efficient -- reusing L2 infrastructure for L3 quality gating reduces implementation complexity. The three-gate freshness validation emerged naturally from combining spec 005's lifecycle model with practical pipeline concerns.
- What did not work and why: OpenAI Structured Outputs docs returned 403 (consistent with iteration 1 failure -- their docs site now requires authentication). This is a known dead end for WebFetch-based research.
- What I would do differently: For the next iteration focusing on production handoff (Q6) and platform adaptation (Q7), I should look for practical examples of script-to-production metadata formats from open-source video automation tools and TikTok/YouTube creator workflow documentation, rather than relying on general LLM docs.

## Recommended Next Focus
Q6 (Script-to-production handoff format -- shot lists, B-roll suggestions, timing markers, TTS directives, visual cues, asset references) and Q7 (Platform-specific script adaptation -- TikTok vs YouTube Shorts vs IG Reels format differences, optimal lengths, platform-specific hooks and CTAs). These complete the L3 output contract: Q5/Q9 defined how data enters and gets quality-gated; Q6/Q7 define how approved scripts exit L3 for L4 production. Together they close the L3 pipeline from input to output.
