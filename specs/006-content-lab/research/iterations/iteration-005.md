# Iteration 5: Thai TTS Integration & L7 Feedback Loop Influence on Script Generation

## Focus
Investigated Q8 (How to integrate script generation with the Thai voice pipeline for automated voice-over -- script format for TTS, pronunciation hints, pacing markers, PyThaiNLP preprocessing) and Q10 (How performance data from L7 feedback loop influences future script generation -- prompt tuning, template selection, few-shot example curation from top performers, reinforcement signals). Q8 validates and extends the TTS directives designed in iteration 4's handoff schema against actual API specifications. Q10 closes the generation-to-performance feedback cycle by designing how L7 analytics flow back into L3 prompt engineering.

## Findings

### Q8: Thai TTS Integration -- Script-to-Voice Pipeline

#### 1. Complete TTS Directive Contract Between L3 and L4

The iteration 4 handoff schema defined TTS fields per segment (tts_engine, voice_id, speed_multiplier, emotion, pronunciation_hints). Cross-referencing with the actual ElevenLabs API specification and spec 003's VoiceConfig schema reveals the directive contract must be engine-aware, since each engine accepts fundamentally different control parameters.

**Validated ElevenLabs API parameters (from official docs):**
- `voice_settings.stability` (float, default 0.5): Lower = more emotional range, higher = more consistent
- `voice_settings.similarity_boost` (float, default 0.75): Adherence to original voice
- `voice_settings.style` (float, default 0): Style exaggeration -- amplifies speaker characteristics, increases latency if non-zero
- `voice_settings.use_speaker_boost` (boolean, default true): Boosts similarity at computational cost
- `speed` (float, default 1.0): Delivery rate multiplier
- `language_code` (optional, ISO 639-1): Enforce language for model and normalization -- CRITICAL for Thai: set `language_code: "th"` to prevent language detection errors on short segments
- `pronunciation_dictionary_locators` (array, max 3): References to pronunciation dictionaries (not inline SSML) -- this is how ElevenLabs handles pronunciation correction
- `apply_text_normalization`: `"auto"` | `"on"` | `"off"` -- controls number/abbreviation expansion
- `seed` (int, 0-4294967295): Enables deterministic audio generation for reproducible results
- `model_id`: Default `eleven_multilingual_v2`; also available `eleven_flash_v2_5` (3x faster, 32 langs)

**Key correction to iteration 4 schema:** The `pronunciation_hints` field with inline IPA notation is NOT natively supported by ElevenLabs. Instead, ElevenLabs uses `pronunciation_dictionary_locators` -- pre-uploaded dictionaries of word-to-phoneme mappings. The L3 handoff should specify BOTH: inline IPA hints for engines that support SSML phoneme tags (Edge-TTS, potentially CosyVoice) AND dictionary references for ElevenLabs.

[SOURCE: https://elevenlabs.io/docs/api-reference/text-to-speech/convert -- voice_settings parameters, pronunciation_dictionary_locators, language_code, apply_text_normalization, seed, model_id]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 20 -- VoiceConfig interface with engine-specific settings]

#### 2. Engine-Aware TTS Directive Mapping (Corrected and Extended)

The handoff schema's `audio` block per segment should contain a unified directive that L4 maps to engine-specific API calls. Here is the corrected engine mapping:

| Directive Field | ElevenLabs | OpenAI gpt-4o-mini-tts | Edge-TTS | F5-TTS-THAI |
|----------------|------------|----------------------|---------|-------------|
| **Voice selection** | `voice_id` (string) | `voice` (alloy/echo/fable/onyx/nova/shimmer) | `voice` (th-TH-PremwadeeNeural etc.) | `ref_audio` (file path) |
| **Speed** | `speed` (float) | `speed` (0.25-4.0) | SSML `<prosody rate="+20%">` | `speed` (0.7-1.2) |
| **Emotion/Style** | `stability` (low=expressive) + `style` (0-1) | `instructions` (free text, 2000 tokens) | NOT SUPPORTED | NOT SUPPORTED |
| **Pronunciation** | `pronunciation_dictionary_locators[]` (pre-uploaded) | NOT SUPPORTED | SSML `<phoneme alphabet="ipa" ph="...">` | NOT SUPPORTED |
| **Language enforce** | `language_code: "th"` | Automatic | Implicit from voice choice | Implicit from model |
| **Text normalization** | `apply_text_normalization: "on"` | Automatic | Automatic | Manual (PyThaiNLP) |
| **Deterministic output** | `seed` (int) | NOT SUPPORTED | NOT SUPPORTED | NOT SUPPORTED |
| **Quality/model** | `model_id` (multilingual_v2 / flash_v2_5) | `model` (tts-1 / tts-1-hd) | N/A (cloud) | `step` (8-64, higher=better) |

**Design decision:** The L3 handoff carries a unified `tts_directives` object with engine-agnostic fields. L4's TTS dispatch layer maps these to engine-specific API parameters. This keeps L3 engine-independent while L4 handles the translation.

**Revised handoff audio block per segment:**
```json
{
  "voiceover_text": "ทำไมทุกคนถึงลองสิ่งนี้?",
  "tts_directives": {
    "target_emotion": "excited",
    "speed_multiplier": 1.1,
    "expressiveness": 0.7,
    "pronunciation_overrides": [
      {"word": "ไบโอ", "ipa": "bai.oː", "note": "Thai transliteration of 'bio'"}
    ],
    "pause_after_ms": 500,
    "language_code": "th",
    "deterministic_seed": null
  }
}
```

L4 then maps `target_emotion: "excited"` to:
- ElevenLabs: `stability: 0.3, style: 0.6`
- OpenAI: `instructions: "Speak with excited energy, like a Thai content creator revealing a surprising discovery"`
- Edge-TTS: `<prosody rate="+10%" pitch="+5%">` (closest approximation)
- F5-TTS-THAI: No emotion mapping (cloning-focused)

[SOURCE: https://elevenlabs.io/docs/api-reference/text-to-speech/convert -- Emotion via stability/style sliders, no SSML support]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 18 -- Engine-by-engine prosody control comparison]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 8 -- Edge-TTS SSML prosody, CosyVoice FreeStyle]
[INFERENCE: Engine-agnostic directive design synthesized from cross-referencing actual API capabilities across 4 engines; L4 translation layer prevents L3 from needing engine-specific knowledge]

#### 3. PyThaiNLP Preprocessing Integration Point

Spec 003 establishes that PyThaiNLP preprocessing is MANDATORY for all Thai TTS. The question for L3 is: should preprocessing happen in L3 (script generation) or L4 (production)?

**Answer: L4 handles all PyThaiNLP preprocessing, NOT L3.**

Rationale:
1. L3 generates natural Thai text intended for human readability and LLM quality evaluation. Inserting segmentation markers or SSML tags would interfere with quality gate scoring (iteration 3's two-layer evaluation).
2. L4 already runs the TTS pipeline per spec 003 Section 3: Raw Thai text -> PyThaiNLP word_tokenize() -> Number/date normalization -> Abbreviation expansion -> Segmented text -> TTS engine.
3. The handoff schema's `tts_preprocessing` block (from iteration 4) correctly specifies PyThaiNLP configuration at the script level -- this tells L4 HOW to preprocess, without L3 doing it.

**However, L3 SHOULD provide pronunciation overrides for:**
- Thai transliterations of English words (e.g., "ไบโอ" for "bio", "ฟอลโลว์" for "follow")
- Brand names or proper nouns that PyThaiNLP may not segment correctly
- Neologisms or Thai internet slang that may not be in PyThaiNLP's 60K base dictionary (spec 003 notes extending to 100K)

These overrides are specified in `tts_directives.pronunciation_overrides[]` and consumed by L4 to either: (a) add to ElevenLabs pronunciation dictionary, (b) wrap in Edge-TTS SSML phoneme tags, or (c) add to PyThaiNLP custom dictionary before segmentation.

[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 3 -- PyThaiNLP preprocessing pipeline, mandatory for all Thai TTS]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 12 -- Extended tokenizer from 60K to 100K words for modern slang]
[INFERENCE: L3/L4 boundary placed at natural text vs. processed text to preserve quality gate integrity; pronunciation overrides bridge the gap for edge cases]

#### 4. Pacing Markers and Segment-Level Timing Control

The 4-beat Thai script structure (iteration 1) produces segments with target durations. TTS engines generate audio at their natural pace, which may not match the target timing. L3 must provide pacing guidance that L4 uses to adjust:

**Pacing control hierarchy:**
1. **Segment-level `speed_multiplier`**: L3 sets per-segment speed (1.0 = natural, 1.1 = fast for hooks, 0.9 = slower for emotional beats). L4 passes to TTS engine.
2. **Pause directives**: `pause_after_ms` per segment and `pause_between_sentences_ms` (spec 003 recommends 200-400ms between Thai clauses). L4 inserts silence via PyDub.
3. **Post-processing time-stretch**: If TTS output duration differs from target by more than 10%, L4 applies FFMPEG time-stretch (within 0.85x-1.15x to preserve naturalness).
4. **Thai-specific**: Final syllable emphasis (+1-2dB boost per spec 003), particle pausing (natural pause points at particles like krub/ka/na).

**L3's role**: Specify `speed_multiplier`, `pause_after_ms`, and `target_emotion` per segment. L3 does NOT need to calculate exact timing -- that is L4's job after TTS generation.

[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 9 -- Audio post-processing: 200-400ms pauses, Thai-specific optimizations]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md Section 15 -- Post-processing pipeline: LUFS normalization, de-essing, breathing insertion]
[INFERENCE: Three-level pacing control (TTS speed -> silence insertion -> time-stretch) provides robust timing alignment without requiring L3 to predict exact TTS output duration]

### Q10: L7 Feedback Loop Influence on Script Generation

#### 5. Four-Channel Feedback Flow from L7 to L3

Spec 005 defines the L7 -> L2 feedback loop (PSI/KL drift detection, Spearman correlation, weekly retraining). The question is how this extends to L3 script generation. There are four distinct feedback channels:

**Channel A: Few-Shot Example Curation (Direct, Per-Generation)**
- L7 records actual T+168h performance metrics per published video
- Iteration 3 designed dynamic few-shot selection from L7 performance data
- **Implementation**: L3's prompt chain Stage 2 (Script Drafting) receives top-performing scripts as few-shot examples
- **Selection criteria**: Top 10% by `views_168h / followers` in same niche + platform + similar trend velocity
- **Freshness window**: Only scripts from last 30 days (Thai content patterns evolve fast)
- **Data path**: `content` table WHERE status='published' AND actual_views IS NOT NULL ORDER BY (actual_views/channel_followers) DESC LIMIT 3

**Channel B: Template Selection Bias (Weekly, Aggregate)**
- Track which 4-beat timing templates (from iteration 4) correlate with higher performance
- Example: If TikTok 15s consistently outperforms TikTok 30s for comedy niche, shift default template
- **Implementation**: Weekly aggregation query grouping by (platform, niche, template_type) -> update default template selection weights in L3 config
- **Data path**: L7 -> `content_performance` aggregate view -> L3 `template_weights` config

**Channel C: Prompt Parameter Tuning (Monthly, Strategic)**
- L7 Spearman correlation per quality dimension identifies which aspects of scripts actually predict performance
- If "Hook Strength" correlation drops below 0.20, the hook generation prompt needs adjustment
- **Implementation**: Monthly review of dimension-to-performance correlations -> update L3's quality gate thresholds and prompt emphasis
- **Data path**: Spec 005's weekly Spearman correlation -> L3 quality gate threshold adjustment

**Channel D: Variant Strategy Optimization (Bi-weekly, Tactical)**
- L7 A/B test results reveal which variant dimensions (from iteration 2's 7 dimensions) produce the largest performance deltas
- If hook type consistently outperforms tone shifts, allocate more variant budget to hook diversity
- **Implementation**: Bi-weekly analysis of variant pair performance -> update L3's variant generation weights in the 3x3 expansion matrix
- **Data path**: `content` table grouped by variant_id pairs -> performance delta analysis -> L3 variant_dimension_weights

[SOURCE: specs/005-trend-viral-brain/research/research.md Section "Scoring Calibration & Feedback Loop" -- PSI/KL drift, Spearman correlation, retraining triggers]
[SOURCE: specs/005-trend-viral-brain/research/research.md Section "A/B Test Integration" -- 2-3 hook variants per topic, T+168h comparison, differential analysis]
[SOURCE: specs/006-content-lab/research/iterations/iteration-003.md -- Dynamic few-shot selection from L7 performance data, two-layer quality gate architecture]
[INFERENCE: Four-channel model separates feedback by frequency (per-generation / weekly / bi-weekly / monthly) and scope (individual examples / aggregate templates / prompt parameters / variant strategy), matching the different time constants of each feedback signal]

#### 6. Performance-Weighted Few-Shot Example Database

The few-shot example curation (Channel A) requires a dedicated data structure to support efficient retrieval during script generation:

**`script_exemplars` table design:**
```sql
CREATE TABLE script_exemplars (
  id UUID PRIMARY KEY,
  content_id UUID REFERENCES content(id),
  platform VARCHAR(20) NOT NULL,
  niche VARCHAR(50) NOT NULL,
  hook_type VARCHAR(30) NOT NULL,
  template_type VARCHAR(30) NOT NULL,  -- e.g., 'tiktok_15s', 'youtube_60s'
  script_json JSONB NOT NULL,           -- full handoff JSON (from iteration 4 schema)
  performance_score FLOAT NOT NULL,     -- normalized views_168h / followers
  trend_velocity_at_publish FLOAT,      -- trend velocity when published
  quality_gate_score FLOAT,             -- L3 quality score at generation time
  published_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,      -- published_at + 30 days
  embedding VECTOR(384)                  -- for semantic similarity retrieval
);

CREATE INDEX idx_exemplars_lookup ON script_exemplars(platform, niche, hook_type, performance_score DESC);
CREATE INDEX idx_exemplars_freshness ON script_exemplars(expires_at);
```

**Retrieval at generation time:**
1. Match: platform + niche + trend velocity range (similar_velocity +/- 0.15)
2. Rank: by performance_score DESC
3. Limit: top 2 examples (spec 005 notes performance declines at 3+ few-shot examples)
4. Filter: expires_at > NOW() (30-day freshness)
5. Fallback: if no matching exemplars, use static curated examples (cold start)

**Population pipeline:**
- When L7 updates `content.actual_views` (T+168h), trigger INSERT into `script_exemplars` IF performance_score > P75 threshold for that (platform, niche) pair
- Automatic expiry: background job DELETE WHERE expires_at < NOW() runs daily

[SOURCE: specs/005-trend-viral-brain/research/research.md Section "LLM-as-Judge Scoring Rubric" -- Few-shot calibration: 1-2 examples max, performance declines at 3+]
[SOURCE: specs/006-content-lab/research/iterations/iteration-003.md -- Dynamic few-shot selection from L7 performance data]
[INFERENCE: script_exemplars table design combines spec 005's few-shot constraints with iteration 3's dynamic selection concept; 30-day expiry matches Thai content lifecycle speed; vector embedding enables semantic similarity matching when exact (platform, niche, hook_type) matches are sparse]

#### 7. Reinforcement Signal Design for Prompt Tuning

Beyond few-shot examples, L7 performance data should directly influence prompt chain parameters. This requires translating performance outcomes into concrete prompt adjustments:

**Performance-to-prompt mapping:**

| Performance Signal | Prompt Adjustment | Frequency | Mechanism |
|-------------------|------------------|-----------|-----------|
| Top-performing hook types | Increase weight of successful hook categories in Stage 1 | Weekly | Update hook_category_weights in L3 config |
| Underperforming CTAs | Rotate CTA templates, test new CTA patterns | Bi-weekly | Replace bottom-quartile CTA templates |
| Niche-performance correlation | Adjust niche-specific system prompt tone/style | Monthly | Update per-niche role prompt variants |
| Emotion-to-engagement mapping | Shift default emotion targets per segment type | Monthly | Update segment_emotion_defaults in L3 config |
| Duration-performance curve | Adjust default target_duration_s per platform | Bi-weekly | Update platform_duration_defaults |
| Quality score vs actual performance | Recalibrate quality gate thresholds (3.0/3.5/4.0) | Monthly | Shift thresholds based on actual performance distribution |

**Closed-loop calibration protocol:**
1. Weekly: Compute Spearman correlation between L3 quality_gate_score and actual performance (target > 0.30)
2. If correlation < 0.20 for 2 consecutive weeks: flag for quality gate recalibration (align with spec 005's drift detection)
3. Monthly: Review dimension-level correlations. If a dimension (e.g., CTA Effectiveness) has Spearman < 0.15, consider re-weighting or revising that dimension's rubric
4. Quarterly: Full few-shot recalibration -- re-score 50 exemplar scripts with current rubric, compare against actual performance, adjust rubric descriptions

**Implementation as n8n workflow:**
- `L7-Feedback-Aggregator` runs weekly (Sunday 04:00 UTC, after spec 005's GBDT retrain at 03:00)
- Reads from `content` table WHERE actual_views IS NOT NULL AND feedback_processed = false
- Computes aggregate statistics, updates L3 config tables
- Marks processed records

[SOURCE: specs/005-trend-viral-brain/research/research.md Section "Retraining Triggers" -- Weekly retrain, PSI > 0.20 threshold, Spearman < 0.15 dimension review]
[SOURCE: specs/005-trend-viral-brain/research/research.md Section "A/B Test Integration" -- Winner features as positive examples, losers as negative]
[SOURCE: specs/006-content-lab/research/iterations/iteration-003.md -- Reject/Revise/Accept thresholds (3.0/3.5/4.0)]
[INFERENCE: Performance-to-prompt mapping translates quantitative L7 signals into actionable L3 parameter changes; frequency tiers (weekly/bi-weekly/monthly/quarterly) prevent over-fitting to noise while responding to genuine shifts]

#### 8. Cold Start and Bootstrap Strategy for Feedback Loop

The feedback loop requires published content with measured performance. Before enough data accumulates, L3 needs a bootstrap strategy:

**Phase 0 (0-50 published videos): Static exemplars + manual curation**
- Use hand-curated exemplar scripts based on competitor analysis
- Quality gate thresholds at conservative defaults (3.0/3.5/4.0 from iteration 3)
- No automated prompt tuning -- all adjustments manual
- Store ALL generated scripts + performance data for future training

**Phase 1 (50-200 published videos): Semi-automated feedback**
- Enable Channel A (few-shot from top performers) when P75 threshold is calculable
- Enable Channel B (template selection bias) with weekly manual review
- Begin tracking dimension-performance correlations (too early for automated action)
- Confidence intervals wide -- flag all correlations below 0.30 for review

**Phase 2 (200+ published videos): Full automated loop**
- All four channels active
- Automated quality gate recalibration
- Automated template and variant weight adjustments
- Monthly automated prompt parameter tuning
- Quarterly full recalibration cycle

**Data milestone alignment with spec 005:**
- Spec 005's Phase 0 (0-100 videos): composite_viral_score only, no ML
- Spec 005's Phase 1 (100-500 videos): XGBoost cold-start
- L3 feedback loop phases intentionally offset lower (50/200) because L3 benefits from smaller sample sizes than GBDT training -- few-shot examples need only 2-3 good exemplars, not hundreds of training rows

[SOURCE: specs/005-trend-viral-brain/research/research.md Section "GBDT Model Training" -- Phase 0/1/2 training pipeline with video count thresholds]
[INFERENCE: L3 feedback thresholds set lower than L2 GBDT thresholds because few-shot curation requires fewer data points than ML model training; phase alignment ensures L3 feedback starts delivering value before L2's GBDT becomes available]

#### 9. Anti-Stagnation Mechanism: Exploration vs Exploitation

A pure feedback-driven system risks convergence on a local optimum -- producing variants of whatever worked last week. The system needs deliberate exploration:

**Exploration budget:** 20% of generated scripts should deliberately deviate from what the feedback loop recommends:
- Use underexplored hook categories (e.g., if "controversy" hooks are rarely generated, allocate exploration budget to them)
- Test new CTA patterns not yet in the exemplar database
- Try longer/shorter durations than the template default
- Experiment with different tone/register for established niches

**Implementation:** In the 3x3 variant expansion (iteration 2), one of the 9 variants is designated as the "exploration variant" with parameters sampled from underrepresented regions of the variant space.

**Thompson Sampling integration:** Spec 005 and iteration 2 already designed Thompson Sampling for post-production variant selection. The exploration mechanism extends this to pre-production: maintain beta distributions for each variant dimension value, sample from the posterior, but with an epsilon-greedy override (epsilon=0.20) that forces random exploration 20% of the time.

**Tracking exploration outcomes:** The `content` table should track `is_exploration: boolean` so that exploration variants can be analyzed separately. If an exploration variant outperforms exploitation variants, it graduates to the main exemplar pool.

[SOURCE: specs/006-content-lab/research/iterations/iteration-002.md -- Thompson Sampling multi-arm bandit, 3x3 variant expansion model]
[SOURCE: specs/005-trend-viral-brain/research/research.md Section "A/B Test Integration" -- 2-3 hook variants per topic, T+168h comparison]
[INFERENCE: Epsilon-greedy exploration at 20% balances the exploitation signal from feedback loop against creative diversity; Thompson Sampling posterior already encodes uncertainty but benefits from forced exploration in early phases with limited data]

## Ruled Out
- **L3-side PyThaiNLP preprocessing**: Would interfere with quality gate text evaluation. L4 handles all TTS preprocessing.
- **Inline SSML in L3 handoff for all engines**: ElevenLabs does not support SSML. Engine-agnostic directives with L4 translation are strictly better.
- **Real-time per-video prompt tuning**: Individual video performance is too noisy; aggregate signals across cohorts are required for reliable tuning.

## Dead Ends
None identified. All approaches in this iteration were productive. The ElevenLabs API documentation was accessible and confirmed key parameters.

## Sources Consulted
- https://elevenlabs.io/docs/api-reference/text-to-speech/convert (ElevenLabs TTS API: voice_settings, pronunciation_dictionary_locators, language_code, text normalization, seed, model_id, output formats)
- specs/003-thai-voice-pipeline/research/research.md (Complete Thai TTS pipeline: PyThaiNLP preprocessing, engine comparison, VoiceConfig schema, prosody control, post-processing, tone system)
- specs/005-trend-viral-brain/research/research.md (L7 feedback loop: PSI/KL drift detection, Spearman correlation, retraining triggers, A/B test integration, GBDT training phases)
- specs/006-content-lab/research/iterations/iteration-001.md (5-stage prompt chain, Thai 4-beat structure)
- specs/006-content-lab/research/iterations/iteration-002.md (3x3 variant expansion, Thompson Sampling)
- specs/006-content-lab/research/iterations/iteration-003.md (Dynamic few-shot selection, two-layer quality gate, reject/revise/accept thresholds)
- specs/006-content-lab/research/iterations/iteration-004.md (AV handoff JSON schema, TTS directive fields, platform timing templates)

## Assessment
- New information ratio: 0.72
- Questions addressed: Q8, Q10
- Questions answered: Q8, Q10

## Reflection
- What worked and why: Cross-referencing the actual ElevenLabs API documentation against the iteration 4 handoff schema revealed a critical design correction -- ElevenLabs uses pronunciation dictionaries, not inline SSML. This produced a more robust engine-agnostic directive model. The spec 005 feedback loop design (PSI/KL, Spearman, retraining triggers) translated naturally into L3-specific feedback channels, with the key insight being that L3 needs four distinct channels operating at different frequencies to match the different time constants of each feedback signal.
- What did not work and why: The ElevenLabs docs listing page required a second fetch to the specific endpoint page. The initial fetch returned only endpoint names without parameters.
- What I would do differently: For Q11 (n8n orchestration) and Q12 (multi-format output), I should focus on synthesizing the n8n workflow design from spec 005's L1->L2->L3 chain with L3-specific generation orchestration, and investigate format-to-niche mapping patterns.

## Recommended Next Focus
Q11 (n8n content generation orchestration -- daily production volume, batch generation scheduling, content calendar, queue management, n8n workflow design) and Q12 (Multi-format output support -- talking head, voiceover+B-roll, text overlay, green screen, format-to-niche mapping). Q11 requires synthesizing spec 005's n8n workflow chain (L1 2h -> L2 event -> L3 30min poll) with L3-internal generation steps. Q12 addresses the remaining content variety dimension. Together they complete the remaining key questions.
