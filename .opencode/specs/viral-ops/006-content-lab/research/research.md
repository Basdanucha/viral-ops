# Content Lab (L3) -- Research Synthesis

> Progressive synthesis from deep research iterations. Updated after each iteration.

---

## 1. LLM Script Generation Architecture

### Prompt Chain Design (5-Stage Pipeline)

Script generation uses a multi-stage prompt chain, NOT a single monolithic prompt. Each stage has a narrow objective and can be independently quality-gated.

**Pipeline:**
```
L2 Output (trend + hooks + viral_score)
    |
    v
[Stage 1: Concept Expansion] -- 3-5 concept angles from trend signal
    |
    v
[Stage 2: Script Drafting] -- Full script with timing markers
    |
    v
[Stage 3: Variant Generation] -- 2-3 hook/CTA variations per script
    |
    v
[Stage 4: Quality Self-Evaluation] -- LLM self-scores against rubric
    |
    v
[Stage 5: TTS Adaptation] -- Reformat for voice pipeline (spec 003)
```

### Prompting Techniques Applied

| Technique | Where Used | Implementation |
|-----------|-----------|----------------|
| XML tag structuring | All stages | `<trend_context>`, `<instructions>`, `<examples>`, `<output_format>` |
| Few-shot calibration | Stages 1-3 | 3-5 top-performing scripts rotated per niche, refreshed monthly from L7 data |
| Role-based system prompt | All stages | Thai content strategist persona, dynamically adjusted per niche + platform |
| Structured JSON output | Stage 2-5 | Enforced schema with hook, body_segments (timestamped), CTA, metadata |
| Chain-of-thought | Stage 4 | Self-evaluation reasons before scoring |
| Temperature tuning | Per stage | Creative (0.7-0.9) for expansion/variants, Precise (0.0-0.3) for evaluation |

### Model Selection

| Model | Role | Rationale |
|-------|------|-----------|
| GPT-4o-mini | Primary generator (all stages) | Fast, cheap ($0.15/1M), good Thai, strong structured output |
| DeepSeek-V3 | Fallback for pure-Thai scripts | Strong multilingual, lower cost, needs benchmarking |
| Claude Sonnet/Haiku | Quality evaluation (Stage 4) | Different model family reduces systematic bias in self-evaluation |

### Context Injection Format (Q5 -- ANSWERED)

L1/L2 data injected as structured XML at top of prompt (Anthropic docs: queries at end improve response quality by up to 30%):
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

**Design decisions:** XML over JSON (LLMs parse XML more reliably for prompt context); per-source signals included to weight creative decisions; `related_trends` enables cross-trend content; `hours_since_detection` enables freshness-aware scripting.

### Three-Gate Freshness Validation

Before generation, validate trend freshness to prevent wasted API calls on stale trends:

| Gate | Check | Block Condition |
|------|-------|----------------|
| **Lifecycle** | `lifecycle_stage` | BLOCK if `decay`, `saturation`, `dead` |
| **Velocity Recency** | Re-check velocity vs L2-time | BLOCK if velocity dropped below +0.05 since L2 scoring, OR `hours_since_detection > 36` |
| **Duplicate Content** | Existing scripts for same trend+niche+platform | BLOCK if active content exists (unless new viral_score is 0.15+ higher) |

### L2 Score-to-Prompt Parameter Mapping

L2 scores actively control generation parameters, not just passive context:

| L2 Signal | Generation Parameter | Logic |
|-----------|---------------------|-------|
| `composite >= 0.85` | 5 variants, immediate priority | SURGING -- max production effort |
| `composite 0.70-0.84` | 3 variants, high priority | Standard PRODUCE_NOW |
| `composite 0.50-0.69` | 1 variant, normal priority | CONSIDER -- exploratory |
| `hook_strength >= 4` | Use L2 hook directly as seed | Skip L3 hook generation |
| `velocity = SURGING` | Temperature 0.6 | Hot trend needs reliable execution |
| `velocity = EMERGING` | Temperature 0.9 | Emerging trend rewards experimentation |

### Dynamic Few-Shot from L7 Performance Data

Few-shot examples selected algorithmically from top performers:
1. Query published scripts in same niche + platform with L7 performance data
2. Sort by `actual_views / expected_views` ratio (over-performers first)
3. Select 3 diverse examples (different hook_types, durations, tones) from top 5 of last 30 days
4. Include performance metrics with each example for the LLM to learn what success looks like
5. **Cold-start**: Manually curated Thai viral scripts until organic data accumulates

---

## 2. Thai Viral Script Structures

### 4-Beat Script Anatomy

All Thai short-form scripts follow a 4-beat structure, scaled by duration:

**15-second (TikTok primary):**
| Beat | Time | Purpose | Thai Pattern |
|------|------|---------|-------------|
| Hook | 0:00-0:03 | Stop the scroll | Question/shock + particle (นะ/เลย) |
| Setup | 0:03-0:07 | Context + tension | Problem or relatable situation |
| Payoff | 0:07-0:12 | Value delivery | Solution, reveal, or punchline |
| CTA | 0:12-0:15 | Action prompt | จัดไป / กดติดตาม / คอมเมนต์บอกหน่อย |

**30-second:** Hook (0-3s) > Setup (3-10s) > Development (10-20s) > Payoff (20-27s) > CTA (27-30s)

**60-second:** Hook (0-3s) > Context (3-10s) > Body 1 (10-25s) > Body 2 (25-40s) > Climax (40-52s) > CTA (52-60s)

### Thai Viral Elements

**Humor patterns (highest viral potential):**
- Slapstick/situational comedy
- Self-deprecating humor (มุขตัวเอง)
- Pranking format (แกล้ง)
- Exaggerated reactions (โอ้โห / อ้าว / ตายแล้ว)

**Language techniques:**
- Thai-English code-switching for bilingual audiences
- Emphatic particles at hook endings: นะ, เลย, จริงๆ, มากๆ
- Direct address: คุณ/เธอ for personal connection
- Numeric anchoring: "3 สิ่งที่..." / "5 เหตุผลที่..."

**Emotional triggers (ranked for Thai market):**
1. ฮา (humor) -- strongest, fastest spread
2. สงสาร (sympathy) -- strong sharing behavior
3. ดราม่า (drama) -- high engagement, comment-heavy
4. ตกใจ (shock) -- stop-scroll power
5. FOMO / กลัวตกเทรนด์ -- drives immediate action

**Dynamic slang dictionary:** Must be refreshed from L1 trend data. Core entries: 555, ปัง, แซ่บ, จัดไป, คือดีมาก, แม่, สาย.

### Platform-Specific Adaptations (Preliminary)

| Element | TikTok | YouTube Shorts | IG Reels |
|---------|--------|---------------|----------|
| Hook style | Pattern interrupt, visual | Question, informational | Aesthetic, aspirational |
| Duration sweet spot | 15-30s | 30-60s | 15-30s |
| CTA style | Follow + duet challenge | Subscribe + comment | Save + share to Stories |
| Audio dependency | High (trending sounds) | Medium (voice-first) | Medium (music + voice) |

---

## 3. A/B Testing Framework for Content Variants

### Two-Phase Testing Architecture

Testing operates in two distinct phases to minimize production waste:

**Phase 1 -- Pre-Production (LLM-as-Judge)**
- Score all script variants with the 6-dimension rubric from L2 (Hook Strength 0.25, Emotional Trigger 0.20, Storytelling 0.15, Visual Potential 0.15, CTA 0.15, Audio Fit 0.10)
- **Gate threshold**: composite score >= 3.5/5.0 passes to production
- Use a DIFFERENT model family for evaluation vs generation (GPT-4o-mini generates, Claude Haiku evaluates) to reduce systematic bias
- Cost: negligible (~$0.005 per evaluation batch)

**Phase 2 -- Post-Production (Platform Audience via Thompson Sampling)**
- TikTok shows every video to 500-1,000 test users initially -- this IS the test environment
- Model each variant type's engagement as Beta(successes + 1, trials - successes + 1)
- Thompson Sampling balances exploration (new variants) vs exploitation (proven winners)
- Starts showing convergence at 10-20 observations per arm
- Rolling 7-day engagement windows for continuous learning
- Superior to classical A/B testing for content: no fixed sample sizes needed, works within Thai 24-48h trend lifecycle

### Seven Variant Dimensions

| Dimension | Options | Impact |
|-----------|---------|--------|
| Hook type | 7 categories (question, statistic, controversy, emotion, curiosity, relatable, shock) | HIGHEST -- 71% of viewers decide in first seconds |
| Emotional tone | 7 triggers (humor, sympathy, drama, shock, inspiration, FOMO, nostalgia) | HIGH -- drives sharing behavior |
| Script length | 15s / 30s / 60s | HIGH -- platform-specific sweet spots |
| CTA style | Soft ask, direct command, urgency, question redirect, community invite | MEDIUM -- affects conversion |
| Visual format | Talking head, voiceover+B-roll, text overlay, green screen | MEDIUM -- niche-dependent |
| Opening audio | Music-first, voice-first, sound effect, silence-then-voice | MEDIUM -- platform-dependent |
| Language register | Formal Thai, casual Thai with particles, Thai-English code-switch | MEDIUM -- audience-dependent |

**Testing strategy**: Test the top 2 dimensions (hook type x emotional tone) via the 3x3 matrix. Other dimensions vary at lower frequency.

### Platform Engagement Benchmarks (2026)

| Metric | TikTok | IG Reels | YouTube Shorts | Success Threshold |
|--------|--------|----------|----------------|-------------------|
| Engagement rate | 2.80% | 0.65% | 0.30-0.40% | Above platform avg |
| Completion target | ~70% | ~50% | ~50% | Platform-specific |
| Save rate | >2% = 3.4x FYP boost | >1.5% | N/A | >2% (TikTok) |
| Decision window | First 1-3 seconds | First 1-3 seconds | First 1-3 seconds | 71% decide here |

---

## 4. Multi-Variant Generation from Single Trend Signal

### Variant Expansion Tree

```
Trend Signal (from L2: trend + hooks + viral_score)
  |
  v
Stage 1: Concept Expansion (1 LLM call, temp 0.7-0.9)
  ├── Concept A (e.g., humor angle)
  ├── Concept B (e.g., shock/controversy angle)
  └── Concept C (e.g., educational/how-to angle)
       |
       v (3 parallel calls)
Stage 2: Hook Generation (1 call per concept, 3 hooks each)
  ├── Hook 1 (question hook)
  ├── Hook 2 (statistic hook)
  └── Hook 3 (relatable hook)
       |
       v (9 parallel calls)
Stage 3: Script Body (1 call per concept+hook combo, temp 0.3-0.5)
  └── 9 complete script candidates
       |
       v (1 batch call)
Stage 4: Quality Gate (batch evaluation, different model)
  └── 4-6 scripts pass (>= 3.5/5.0 composite)
       |
       v
Stage 5: TTS Adaptation (for passing scripts only)
  └── 3-4 production-ready scripts
```

### Efficiency

| Approach | LLM Calls | Cost per Trend |
|----------|-----------|----------------|
| Naive (full chain per variant) | 45 | ~$0.045 |
| Optimized (shared scaffolding) | 14 | ~$0.014 |
| **Reduction** | **69%** | **69%** |

Key: Stages 1-2 are shared scaffolding (run once/few times). Only Stage 3 needs full per-variant execution.

### Production Volume

- **Generate**: 9 script candidates per trend (3 concepts x 3 hooks)
- **Pass quality gate**: 4-6 scripts (~50-65% pass rate)
- **Produce to video**: Top 3-4 (production bottleneck is video creation)
- **Publish**: 2-3 across platforms (staggered per spec 004 schedule)
- **Cost**: ~$0.01-0.02 per trend for full variant generation (negligible)

### Ruled Out Approaches (Iteration 2)
- **Classical frequentist A/B testing**: Needs 30,000+ observations per variant -- incompatible with Thai 24-48h trend lifecycle
- **Full factorial testing across all 7 dimensions**: Produces hundreds of combinations -- unmanageable for production capacity

---

## 5. Script Quality Evaluation Before Production (Q9 -- ANSWERED)

### Two-Layer Quality Gate Architecture

Scripts pass through two complementary evaluation layers before entering production:

**Layer 1: Structural Self-Evaluation (fast, cheap, catches obvious issues)**
The generating LLM evaluates its own output on 5 binary/categorical checks:

| Check | Pass Criteria | Fail Action |
|-------|--------------|-------------|
| Hook Presence | Exists, <= 15 words, in first 3s | Regenerate hook only |
| Duration Compliance | Matches target +/- 2s | Trim or expand body |
| CTA Presence | CTA in final segment | Append CTA |
| Thai Language Quality | Natural particles, no garbled Thai | Regenerate full script |
| JSON Schema Valid | Matches defined schema | Retry with stricter instructions |

Cost: ~$0.002 per evaluation. Layer 1 gates Layer 2 to save API calls.

**Layer 2: 6-Dimension Viral Potential Scoring (independent LLM-as-Judge)**
Reuses L2 Viral Brain's rubric from spec 005, adapted for complete scripts:
- Hook Strength (0.25), Emotional Trigger (0.20), Storytelling (0.15), Visual Potential (0.15), CTA Effectiveness (0.15), Audio Fit (0.10)
- **One dimension per prompt** (research confirms this outperforms multi-dimensional single-prompt)
- Each dimension scored 2x and averaged (~10% garbage rate per single run)
- Use **different model family** for Layer 2 vs generation (reduces 10-25% self-enhancement bias)
- Chain-of-Thought evaluation: reasoning in `<reasoning>` tags BEFORE scoring (Prometheus pattern: 0.897 Pearson correlation)

### Reject/Revise/Accept Decision Thresholds

| Composite Score | Decision | Action |
|----------------|----------|--------|
| >= 4.0 | **ACCEPT** | Send to L4 production queue |
| 3.5 - 3.9 | **REVISE** | Feed lowest-scoring dimension suggestions back to generation |
| 3.0 - 3.4 | **REVISE_ONCE** | One attempt, then REJECT if still < 3.5 |
| < 3.0 | **REJECT** | Discard, try different concept angle |

- Max 2 revision attempts per script (diminishing returns beyond)
- Track `revision_count` in content table

### Cost Per Trend (3 variants)

| Step | Cost |
|------|------|
| Generation (3 scripts x 5 stages) | $0.045 |
| Layer 1 self-eval (3 scripts) | $0.006 |
| Layer 2 scoring (3 x 6 dims x 2 runs) | $0.036 |
| Revisions (avg 1 per 3 scripts) | $0.041 |
| **Total per trend** | **~$0.13** |

At 10-20 trends/day = $1.30-$2.60/day total generation + evaluation cost.

---

## 6. Script-to-Production Handoff Format (Q6 -- ANSWERED)

### AV Two-Column Model for Automated Pipeline

Professional video production uses a two-column Audio-Visual format (audio left, visuals right). For L3's automated pipeline, this translates into a structured JSON schema where each segment carries parallel `audio` and `visual` objects.

**Key principle:** Machine-parseable JSON for n8n/L4 automation. Human readability secondary.

### Complete Handoff JSON Schema

Each script handed to L4 includes:
- **Top-level metadata:** script_id, trend_id, variant_id, platform, target_duration_s, quality_score, quality_decision
- **Segments array:** 4 segments mapping to the Thai 4-beat structure (Hook/Problem/Solution/CTA), each containing:
  - Timing: `start_s`, `end_s`, `duration_s`
  - Audio: `voiceover_text`, `tts_engine`, `voice_id`, `speed_multiplier`, `emotion`, `pronunciation_hints[]`, `background_music{}`, `sfx[]`
  - Visual: `shot_type`, `camera_movement`, `subject`, `b_roll_suggestion{}`, `text_overlay{}`, `transition_in/out`
- **Production directives:** aspect_ratio (9:16), resolution (1080x1920), fps, caption_style, color_grade, asset_sources
- **Platform overrides:** hashtags, captions, platform-specific features (duet/stitch/collab)
- **TTS preprocessing:** PyThaiNLP engine (han_solo), operations (segmentation, particle normalization, transliteration hints), SSML markers

### B-Roll Asset Reference System

Three-tier asset reference hierarchy for L4 automation:
1. **Specific asset ID** -- known stock clip or pre-generated asset
2. **Asset tags + source preference** -- machine-searchable tags for Pexels/Pixabay/AI generation
3. **Natural language description** -- fallback for manual curation

Each B-roll suggestion carries an `importance` field: `required` (cannot produce without), `recommended` (improves quality, can fallback), `optional` (enhancement only).

### TTS Directive Integration

Per-segment TTS fields for direct consumption by spec 003 voice pipeline:

| Field | Purpose | Example |
|-------|---------|---------|
| `tts_engine` | Target engine | elevenlabs, cosyvoice, openai, edge_tts |
| `voice_id` | Voice profile | thai_female_energetic |
| `speed_multiplier` | Speaking rate | 1.1 for hooks, 1.0 for body |
| `emotion` | Style directive | excited, conversational, encouraging |
| `pronunciation_hints[]` | IPA for mispronunciation-prone words | ["ลอง:lɔːŋ"] |

Engine-specific mapping:
- **ElevenLabs:** stability/similarity_boost params for emotion
- **CosyVoice 3.5:** FreeStyle instruction text for emotion + phoneme hints
- **OpenAI TTS:** voice + speed params (limited Thai emotion control)
- **Edge-TTS:** SSML `<prosody>` and `<phoneme>` tags

### Mandatory Caption Layer

80%+ of social media users watch without sound. Captions are a mandatory production element.

- L3 provides clean, segmented voiceover text per segment
- L4 generates TTS audio, gets word-level timestamps from TTS engine
- Word-level timestamps drive karaoke-style caption timing
- L3 does NOT generate caption files (depends on TTS audio timing)
- Caption styling follows platform conventions (TikTok: centered bold, IG: clean minimal, YT: bottom overlay)

---

## 7. Platform-Specific Script Adaptation (Q7 -- ANSWERED)

### Platform Duration & Format Matrix (2026)

| Platform | Duration Range | Optimal Duration | Hook Window | Algorithm Priority |
|----------|---------------|-----------------|-------------|-------------------|
| TikTok | 3-60s | 15-30s | 1-2s | Completion rate + re-watches |
| YouTube Shorts | 15-60s | 30-60s | 2-3s | Click-through + watch time |
| IG Reels | 3-90s | 15-30s | 1-2s | Saves + shares |
| FB Reels | 3-60s | 30-60s | 2-3s | Shares + comments |

**Key insight:** TikTok/IG Reels reward shorter, punchier content (15-30s). YouTube Shorts/FB Reels favor longer, more substantive content (30-60s).

### Platform-Specific 4-Beat Timing Templates

**TikTok 15s:** Hook 1-2s (13%) > Problem 3-4s (27%) > Solution 5-6s (40%) > CTA 2-3s (20%)
**TikTok 30s:** Hook 2-3s (10%) > Problem 7-8s (27%) > Solution 12-13s (43%) > CTA 5-6s (20%)
**YouTube Shorts 60s:** Hook 3-4s (7%) > Problem 15-17s (28%) > Solution 28-30s (50%) > CTA 8-10s (17%)
**IG Reels 15s:** Hook 1-2s (13%) > Problem 3-4s (27%) > Solution 6-7s (47%) > CTA 2-3s (13%)

### Platform-Specific Hook & CTA Strategies

**Hooks:**
| Platform | Best Hook Types | Characteristics |
|----------|----------------|----------------|
| TikTok | Curiosity, Shock, Controversy | Ultra-fast, visual-first, trending audio sync |
| YouTube Shorts | Question, Statistic, Curiosity | Keyword-rich, evergreen framing |
| IG Reels | Emotion, Relatable, Visual reveal | Aesthetic-first, on-brand |
| FB Reels | Relatable, Emotion, Statistic | Familiar-feeling, broader appeal |

**CTAs (Thai):**
| Platform | CTA Type | Thai Phrasing |
|----------|----------|--------------|
| TikTok | Follow + profile visit | "ฟอลโลว์เพื่อดูเพิ่ม!", "ลิงก์อยู่ในไบโอ" |
| YouTube Shorts | Subscribe + comment | "ซับเพื่อไม่พลาด!", "คอมเมนต์บอกหน่อย" |
| IG Reels | Save + share to Stories | "เซฟไว้ก่อน!", "แชร์ให้เพื่อนดู" |
| FB Reels | Share + tag friend | "แท็กเพื่อนที่ต้องดู!", "แชร์เลย!" |

### Multi-Platform Adaptation Pipeline

Generate ONE base script, then adapt per platform (not generate from scratch):

```
Base Script (30s, platform-agnostic)
  +-- [TikTok 15s] Compress, add trending audio, TikTok hashtags
  +-- [TikTok 30s] Keep duration, TikTok hooks/CTA
  +-- [YouTube Shorts 60s] Expand, evergreen framing, keyword hook
  +-- [IG Reels 15s] Compress, polish visuals, branded aesthetic
  +-- [FB Reels 30s] Keep duration, broaden appeal, shareable CTA
```

**Changes per adaptation:** duration, segment timing, hook text, CTA text, platform_overrides, caption_style
**Stays the same:** core narrative, B-roll, TTS settings, niche, emotional trigger

**Cost:** ~$0.012 for 4-platform adaptation from 1 base script (1 LLM call each at ~$0.003)
**Total per trend (3 variants x 4 platforms):** ~$0.17 (generation $0.13 + adaptation $0.036)

### Ruled Out
- **Generating platform-specific scripts from scratch:** 70-80% of content is shared; adaptation is strictly more efficient
- **Including caption timing in L3 handoff:** L3 doesn't produce audio; timing depends on L4 TTS output

---

## 8. Thai Voice Pipeline Integration (Q8 -- ANSWERED)

### Engine-Agnostic TTS Directive Contract

The L3 handoff carries a unified `tts_directives` object per segment. L4's TTS dispatch layer translates these to engine-specific API calls, keeping L3 engine-independent.

**Revised audio block per segment:**
```json
{
  "voiceover_text": "Thai text (clean, not preprocessed)",
  "tts_directives": {
    "target_emotion": "excited",
    "speed_multiplier": 1.1,
    "expressiveness": 0.7,
    "pronunciation_overrides": [
      {"word": "transliteration", "ipa": "phonemes", "note": "context"}
    ],
    "pause_after_ms": 500,
    "language_code": "th",
    "deterministic_seed": null
  }
}
```

### Engine-Specific Translation (L4 responsibility)

| Directive | ElevenLabs | OpenAI TTS | Edge-TTS | F5-TTS-THAI |
|-----------|------------|-----------|---------|-------------|
| Emotion | `stability` (low=expressive) + `style` (0-1) | `instructions` (free text, 2000 tok) | NOT SUPPORTED | NOT SUPPORTED |
| Speed | `speed` (float) | `speed` (0.25-4.0) | SSML `<prosody rate>` | `speed` (0.7-1.2) |
| Pronunciation | `pronunciation_dictionary_locators[]` (pre-uploaded) | NOT SUPPORTED | SSML `<phoneme>` tags | NOT SUPPORTED |
| Language | `language_code: "th"` | Automatic | Implicit from voice | Implicit from model |
| Deterministic | `seed` (int) | NOT SUPPORTED | NOT SUPPORTED | NOT SUPPORTED |

**Key correction (from ElevenLabs API docs):** ElevenLabs does NOT support inline SSML or IPA. Pronunciation correction uses pre-uploaded pronunciation dictionaries referenced via `pronunciation_dictionary_locators` (max 3 per request). L4 must maintain a Thai pronunciation dictionary for common mispronunciation-prone words.

### L3/L4 Preprocessing Boundary

L4 handles ALL PyThaiNLP preprocessing (mandatory per spec 003):
```
L3 output (clean Thai text) -> L4 PyThaiNLP segmentation -> TTS engine
```

L3 does NOT insert segmentation markers or SSML tags -- this would interfere with quality gate scoring. L3 DOES provide `pronunciation_overrides` for: Thai transliterations of English words, brand names, and neologisms not in PyThaiNLP's dictionary.

### Three-Level Pacing Control

1. **Segment-level speed_multiplier**: L3 sets per segment (1.1 for hooks, 0.9 for emotional beats)
2. **Pause directives**: `pause_after_ms` per segment + spec 003's 200-400ms inter-clause pauses
3. **Post-processing time-stretch**: L4 applies FFMPEG time-stretch (0.85x-1.15x) if TTS output deviates >10% from target duration

---

## 9. L7 Feedback Loop Influence on Script Generation (Q10 -- ANSWERED)

### Four-Channel Feedback Architecture

| Channel | Frequency | Scope | Data Path |
|---------|-----------|-------|-----------|
| **A: Few-Shot Exemplars** | Per-generation | Individual scripts | Top 10% performers by views/followers -> few-shot in Stage 2 |
| **B: Template Selection** | Weekly | Aggregate patterns | Performance by (platform, niche, template_type) -> template weight config |
| **C: Prompt Parameter Tuning** | Monthly | Dimension correlations | Spearman per quality dimension vs actual performance -> threshold recalibration |
| **D: Variant Strategy** | Bi-weekly | Variant effectiveness | A/B variant pair deltas -> variant_dimension_weights in 3x3 matrix |

### Script Exemplars Database

Performance-weighted exemplar scripts for dynamic few-shot selection:
- **Selection**: Top 10% by `views_168h / followers`, same niche + platform + similar velocity
- **Freshness**: 30-day window (Thai content patterns evolve fast)
- **Limit**: 2 exemplars per generation (performance declines at 3+ few-shot, per spec 005)
- **Cold-start**: Manually curated exemplars until organic data accumulates
- **Embedding**: 384-dim vector for semantic similarity retrieval when exact matches are sparse

### Performance-to-Prompt Mapping

| Signal | Adjustment | Frequency |
|--------|-----------|-----------|
| Top-performing hook types | Increase hook_category_weights | Weekly |
| Underperforming CTAs | Rotate CTA templates | Bi-weekly |
| Duration-performance curve | Adjust default target_duration_s | Bi-weekly |
| Emotion-to-engagement mapping | Shift segment_emotion_defaults | Monthly |
| Quality score vs actual performance | Recalibrate gate thresholds (3.0/3.5/4.0) | Monthly |

### Three-Phase Bootstrap

| Phase | Video Count | Feedback Channels | Automation Level |
|-------|------------|-------------------|-----------------|
| Phase 0 | 0-50 | None (static exemplars) | Manual only |
| Phase 1 | 50-200 | A + B with manual review | Semi-automated |
| Phase 2 | 200+ | All four channels active | Fully automated |

L3 thresholds intentionally lower than spec 005's GBDT phases (100/500) because few-shot curation needs fewer data points than ML training.

### Anti-Stagnation: 20% Exploration Budget

To prevent convergence on local optimum:
- 1 of 9 variants in the 3x3 expansion is the "exploration variant"
- Parameters sampled from underrepresented regions (underused hook categories, untested CTA patterns, different durations)
- Epsilon-greedy override (epsilon=0.20) forces random exploration
- Exploration variants tracked via `is_exploration: boolean` in content table
- Outperforming exploration variants graduate to main exemplar pool

---

## Validation Summary (Iteration 7)

All 12 questions validated for internal consistency across 6 iterations (54 total findings). Results:

| Validation Check | Result | Notes |
|-----------------|--------|-------|
| 5-stage chain supports all 6 formats | PASS | Stage 5 conditional on `requires_voiceover` |
| TTS directive format (Q6 vs Q8) | PASS | Iteration 5 corrected iteration 4; canonical schema in Section 8 |
| Variant expansion (Q4) + n8n batch (Q11) | PASS | 70 LLM calls/30min cycle within capacity |
| Quality gate (Q9) + feedback loop (Q10) | PASS | Thresholds static at launch, dynamic after Phase 2 |
| Cost model ($0.17/trend) end-to-end | PASS | Verified: $0.097 generation + $0.036 adaptation |
| Prompt chain I/O completeness | PASS | All 5 stages have defined inputs/outputs across iterations |
| Thai 4-beat anatomy consistency | PASS | Foundation for handoff, timing, TTS, quality gates, all formats |
| Model selection across pipeline | PASS | GPT-4o-mini/DeepSeek/Claude Haiku roles confirmed |
| Cross-iteration contradiction scan | PASS | 0 blocking contradictions; 3 minor tensions resolved |

**Design refinements identified:**
1. Stage 5 (TTS Adaptation) should be conditional on `format.requires_voiceover`
2. research.md Section 6 TTS fields should reference Section 8's corrected engine-agnostic schema
3. Quality gate should include pass rate floor mechanism for Phase 0 (if pass rate < 30% for 24h, temporarily lower ACCEPT threshold by 0.2)

**Few-shot count reconciliation:** Q1 recommends "3-5 examples" for cold-start static curation; Q10 specifies "2 exemplars" for production dynamic selection. Both are correct for their context -- cold-start benefits from diversity (more examples), production benefits from precision (fewer, higher-quality examples per spec 005).

---

## Open Questions

- [x] Q1: LLM prompting strategies -- ANSWERED and VALIDATED (iteration 7): 5-stage prompt chain confirmed across all 6 video formats, model selection (GPT-4o-mini primary + DeepSeek fallback + Claude Haiku for evaluation) consistent with all downstream requirements, cost model ($0.17/trend) verified end-to-end. One refinement: Stage 5 (TTS Adaptation) should be conditional on format.requires_voiceover.
- [x] Q2: Thai script structures -- ANSWERED and VALIDATED (iteration 7): 4-beat anatomy serves as the architectural foundation for handoff schema (segments[]), platform timing templates, TTS per-segment directives, quality gate structural checks, and all 6 video formats. 7 emotional triggers integrated into variant dimensions, quality rubric, and feedback loop. No contradictions found across 6 iterations.
- [x] Q3: A/B testing framework -- ANSWERED: Two-phase (LLM pre-production gate + Thompson Sampling post-production), 7 variant dimensions, 3.5/5.0 gate threshold
- [x] Q4: Multi-variant generation -- ANSWERED: 3x3 expansion tree (concepts x hooks), 14 optimized LLM calls, 4-6 scripts pass quality gate per trend
- [x] Q5: L1/L2 data feeding into generation -- ANSWERED: XML context injection schema, three-gate freshness validation, L2 score-to-parameter mapping, dynamic few-shot from L7 performance
- [x] Q6: Script-to-production handoff -- ANSWERED: AV two-column JSON schema with parallel audio+visual segments, B-roll asset system (3-tier hierarchy), TTS directives (engine-specific mapping), mandatory captions
- [x] Q7: Platform-specific adaptation -- ANSWERED: Platform timing templates (15/30/60s), hook/CTA strategies per platform, multi-platform adaptation pipeline from base script, ~$0.17/trend total
- [x] Q8: Integration with Thai voice pipeline -- ANSWERED: Engine-agnostic TTS directives (L4 translates to engine-specific API calls), ElevenLabs pronunciation_dictionary_locators (not inline SSML), L4 owns PyThaiNLP preprocessing (L3 provides clean text + pronunciation overrides), three-level pacing control (speed -> pause -> time-stretch)
- [x] Q9: Script quality evaluation -- ANSWERED: Two-layer gate (structural self-eval + 6-dim LLM-as-Judge), reject/revise/accept thresholds (3.0/3.5/4.0), CoT evaluation, ~$0.13/trend
- [x] Q10: L7 feedback loop influence -- ANSWERED: Four-channel feedback (few-shot exemplars per-gen / template bias weekly / prompt tuning monthly / variant strategy bi-weekly), script_exemplars table with 30-day freshness, three-phase bootstrap (0-50/50-200/200+), 20% exploration budget for anti-stagnation
- [x] Q11: Content generation cadence via n8n -- ANSWERED: Three-stage L3 master workflow (intake/generation/dispatch), 5 n8n workflows total, daily volume 60-216 scripts, content calendar with P0-P3 priority queue, 2-day minimum buffer, dead-letter queue for error recovery
- [x] Q12: Output format selection and format-to-niche mapping -- ANSWERED: Six video formats (talking_head, voiceover_broll, text_overlay, green_screen, tutorial_demo, ugc_testimonial), format-to-niche mapping matrix (10 niches), automation tiers (30-95%), format allocated within existing 3x3 matrix (not as new dimension), Phase 0 MVP focuses on text_overlay + voiceover_broll (fully automated)

---

## 10. Content Generation Orchestration via n8n (Q11 -- ANSWERED)

### L3 Workflow Topology (5 Workflows)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `L3-Content-Generator` | Cron 30min, 06:00-23:00 ICT | Master: poll trends, dispatch generation, queue output |
| `L3-Script-Generator` | Sub-workflow (per trend) | Execute 5-stage prompt chain + quality gate + adaptation |
| `L3-Content-Calendar` | Cron daily 02:00 ICT | Assign posting slots, manage buffer, priority scheduling |
| `L3-Retry-Failures` | Cron every 2h | Retry failed generations from dead-letter queue |
| `L3-Feedback-Aggregator` | Cron weekly Sun 04:00 UTC | Process L7 data, update exemplars/weights |

### Three-Stage Master Pipeline

```
Stage 1: INTAKE
  |-- Poll trends WHERE status='ready_for_content' AND viral_potential >= 0.70
  |-- Freshness gate: skip decay/saturation/dead lifecycle stages
  |-- Deduplication: skip trends with active content in 'generating' status
  |-- LIMIT 5 per cycle (8 during 19-22 ICT peak hours)

Stage 2: GENERATION (sub-workflow per trend, memory-isolated)
  |-- Context assembly + few-shot retrieval + 5-stage prompt chain
  |-- 3x3 variant expansion + two-layer quality gate
  |-- Platform adaptation + handoff JSON assembly

Stage 3: DISPATCH
  |-- Insert qualified scripts (status: 'queued_for_production')
  |-- Trigger L4 production webhook
  |-- Log generation metrics (cost, duration, variant count)
```

### Daily Production Volume Model

| Scenario | Trends/day | Variants/trend | Platform versions | Total scripts/day | LLM cost/day |
|----------|-----------|---------------|-------------------|-------------------|-------------|
| Conservative | 3 | 5 | 4 | 60 | ~$0.51 |
| Moderate | 6 | 5 | 4 | 120 | ~$1.02 |
| Aggressive | 9 | 6 | 4 | 216 | ~$1.84 |

### Content Calendar & Queue Priority

| Priority | Condition | Action |
|----------|----------|--------|
| P0 (Immediate) | SURGING trend (velocity > +0.50), < 6h old | Bypass calendar, schedule within 2h |
| P1 (High) | RISING trend, viral_potential >= 0.80 | Next available slot |
| P2 (Normal) | Standard generation output | Calendar-scheduled |
| P3 (Backfill) | Evergreen content, moderate scores | Fill gaps in calendar |

Buffer: min 2 days / max 5 days per platform. Below 2 days triggers increased generation frequency.

### Platform Posting Slots

| Platform | Posts/day | Peak Hours (ICT) |
|----------|----------|------------------|
| TikTok | 3-5 | 19-22, secondary 12-14 |
| YouTube Shorts | 1-2 | 18-21 |
| IG Reels | 2-3 | 19-21, morning 07-09 |
| FB Reels | 1-2 | 19-22 |

Staggered: TikTok T+0 -> IG T+20min -> YT T+40min -> FB T+60min (from spec 004).

### Error Handling

- Sub-workflow isolation per trend prevents cascading failures
- LLM 429 rate limits: Wait node + manual retry loop (30s/60s/120s jitter)
- LLM 500/503: IF node switches to fallback model (DeepSeek)
- All quality-gate rejections: logged, trend marked 'generation_failed'
- Dead-letter queue: `content_generation_failures` table, retried every 2h, max 3 retries

### Inter-Layer Workflow Chain (Complete)

```
L1-Master (2h) -> trends table -> L2-Scorer (event) -> viral_potential
  -> L3-Content-Generator (30min poll) -> content table
  -> L4-Production (webhook) -> L5-Publisher (calendar)
  -> L7-Analytics (T+168h) -> L3-Feedback-Aggregator (weekly)
```

---

## 11. Multi-Format Output Support (Q12 -- ANSWERED)

### Six Video Formats

| Format ID | Name | Voiceover | On-Camera | Automation | Est. L4 Cost |
|-----------|------|-----------|-----------|------------|-------------|
| `text_overlay` | Text Overlay / Faceless | No | No | 95% | $0.01-0.02 |
| `voiceover_broll` | Voiceover + B-Roll | Yes | No | 85% | $0.03-0.08 |
| `green_screen` | Green Screen / React | Partial | Optional | 70% | $0.05-0.10 |
| `tutorial_demo` | Tutorial / How-To | Optional | Optional | 60% | $0.05-0.15 |
| `talking_head` | Talking Head | Yes | Yes | 40% | $0.10-0.30 |
| `ugc_testimonial` | UGC / Testimonial | Yes | Yes | 30% | $0.10-0.25 |

### Format-to-Niche Mapping

| Niche | Primary Format | Secondary Format |
|-------|---------------|-----------------|
| Beauty / Fashion | `talking_head` | `tutorial_demo` |
| Tech / Gadgets | `tutorial_demo` | `voiceover_broll` |
| Food / Cooking | `tutorial_demo` | `talking_head` |
| Finance / Crypto | `text_overlay` | `voiceover_broll` |
| Comedy / Entertainment | `talking_head` | `green_screen` |
| Lifestyle / Travel | `voiceover_broll` | `ugc_testimonial` |
| Education / Tips | `text_overlay` | `tutorial_demo` |
| Health / Fitness | `talking_head` | `tutorial_demo` |
| News / Current Events | `green_screen` | `text_overlay` |
| Gaming | `green_screen` | `voiceover_broll` |

**Thai-specific:** Comedy -> `talking_head` with exaggerated expressions; Finance -> `text_overlay` (anonymous preference); Food -> `tutorial_demo`; News -> `green_screen` reaction format.

### Format in Handoff Schema

```json
{
  "format": {
    "format_id": "voiceover_broll",
    "automation_tier": "full",
    "requires_voiceover": true,
    "requires_on_camera": false,
    "broll_density": "high",
    "caption_style": "animated_word",
    "music_role": "background",
    "background_source": null,
    "avatar_config": null
  }
}
```

### Format Allocation in 3x3 Matrix

Format is NOT a new matrix dimension (would produce 54 variants). Instead, allocated within existing 9 slots:
- 5-6 slots: primary format for niche
- 2-3 slots: secondary format
- 1 slot: exploration format (from 20% epsilon-greedy budget)

Thompson Sampling tracks performance at (hook_type, format_id) pair level.

### Automation-First Phased Rollout

| Phase | Formats | Automation | Human Required |
|-------|---------|-----------|---------------|
| Phase 0 (MVP) | `text_overlay`, `voiceover_broll` | Full | None |
| Phase 1 | + `green_screen`, `tutorial_demo` | Mostly | Background sourcing |
| Phase 2 | + `talking_head`, `ugc_testimonial` | Partial | Avatar/creator recording |

---

## Convergence Report

- **Stop reason:** all_questions_answered
- **Total iterations:** 7 (6 evidence + 1 validation)
- **Questions answered:** 12/12
- **Remaining questions:** 0
- **Last 3 iteration summaries:**
  - run 5: Q8+Q10 TTS integration + feedback loop (0.72)
  - run 6: Q11+Q12 n8n orchestration + multi-format (0.72)
  - run 7: VALIDATION Q1+Q2 against full architecture (0.35, thought)
- **Convergence threshold:** 0.05
- **newInfoRatio trend:** 0.78 → 0.72 → 0.72 → 0.72 → 0.72 → 0.72 → 0.35

### Ruled Out Directions (Consolidated)
1. **Single-prompt script generation** — multi-stage chain strictly superior (iter 1)
2. **Generic creative writing role prompts** — Thai market requires Thai-specific cultural expertise (iter 1)
3. **Classical frequentist A/B testing** — incompatible with 24-48h Thai trend lifecycle (iter 2)
4. **Full factorial testing across 7 dimensions** — produces hundreds of unmanageable combinations (iter 2)
5. **Single-layer self-evaluation only** — needs independent LLM-as-Judge to reduce bias (iter 3)
6. **Generating platform-specific scripts from scratch** — 70-80% content shared, adaptation more efficient (iter 4)
7. **Including caption timing in L3 handoff** — depends on L4 TTS audio output (iter 4)
8. **L3-side PyThaiNLP preprocessing** — would interfere with quality gate scoring (iter 5)
9. **Inline SSML for all TTS engines** — ElevenLabs uses pronunciation dictionaries, not SSML (iter 5)
10. **Real-time per-video prompt tuning** — too granular, too noisy (iter 5)
11. **Format as full matrix dimension** — 3x3x6=54 variants is unmanageable (iter 6)
12. **Single monolithic L3 workflow** — sub-workflow isolation needed for per-trend error handling (iter 6)

### Key Architecture Decisions
1. **5-stage prompt chain** — not monolithic prompt
2. **1-5 scoring scale** — from L2, reused in quality gates
3. **3x3 variant expansion** — 3 concepts x 3 hooks = 9 candidates
4. **Two-phase testing** — LLM pre-scoring + Thompson Sampling post-production
5. **Engine-agnostic TTS directives** — L4 translates to engine-specific calls
6. **L4 owns PyThaiNLP** — L3 provides clean text only
7. **One base script → adapt per platform** — not generate per platform
8. **Four-channel feedback** ��� four frequencies, four scopes
9. **20% exploration budget** — epsilon-greedy anti-stagnation
10. **Phase 0 MVP: text_overlay + voiceover_broll** — fully automated formats first
