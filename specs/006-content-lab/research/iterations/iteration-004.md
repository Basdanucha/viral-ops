# Iteration 4: Script-to-Production Handoff Format & Platform-Specific Script Adaptation

## Focus
Investigated Q6 (What format/metadata should scripts include for seamless handoff to L4 production pipeline?) and Q7 (How should scripts be adapted for different platforms?). These questions define the **output contract** of L3: how approved scripts exit the Content Lab and enter L4 Production. Prior iterations defined the input contract (Q5: L1/L2 data injection), quality gates (Q9: two-layer evaluation), and variant generation (Q3/Q4). This iteration completes the L3 pipeline from input to output.

## Findings

### Q6: Script-to-Production Handoff Format

#### 1. Two-Column AV Script Model Adapted for Automated Pipeline
Professional video production uses a two-column Audio-Visual (AV) script format: left column for all audio (dialogue, SFX, music cues) and right column for visuals (shot descriptions, camera angles, B-roll). For L3's automated pipeline, this two-column model should be translated into a structured JSON schema where each segment carries both audio and visual directives simultaneously.

**Key design principle:** The handoff format must be machine-parseable (JSON) for n8n/L4 automation while preserving the AV duality that production teams rely on. Human readability is secondary to machine processability since L4 will be automated.

The StudioBinder AV template adds three critical production metadata fields beyond raw script text:
- **Per-segment duration** ("specific duration for each time" with timer-based pacing)
- **Shot size and camera movement** (wide, medium, close-up + tracking, static, pan)
- **Sound effects and music cues** (labeled "SFX" with hyperlinks to specific assets)

[SOURCE: https://www.studiobinder.com/templates/av-scripts/video-script-template/ -- Two-column AV format, duration timing, shot size, SFX labeling]
[SOURCE: https://www.601media.com/ai-film-workflow-from-script-to-final-cut-no-camera-no-crew/ -- Scene-level decomposition into shots with duration 3-10s, environment+camera+lighting metadata per shot]

#### 2. Complete Script Handoff JSON Schema
Based on the AV model, industry pipeline patterns, and the 5-stage prompt chain output from iteration 1, here is the complete handoff schema:

```json
{
  "script_id": "uuid-v4",
  "version": 1,
  "trend_id": "ref-to-L1-trend",
  "variant_id": "concept_A_hook_curiosity",
  "platform": "tiktok",
  "target_duration_s": 30,
  "language": "th",
  "quality_score": 4.2,
  "quality_decision": "ACCEPT",
  
  "metadata": {
    "niche": "lifestyle",
    "tone": "playful",
    "target_audience": "Thai Gen Z, 18-25",
    "hook_type": "curiosity",
    "emotional_trigger": "FOMO",
    "created_at": "ISO-8601",
    "generation_cost_usd": 0.045,
    "revision_count": 0
  },
  
  "segments": [
    {
      "segment_id": 1,
      "type": "hook",
      "start_s": 0.0,
      "end_s": 3.0,
      "duration_s": 3.0,
      "audio": {
        "voiceover_text": "ทำไมทุกคนถึงลองสิ่งนี้?",
        "tts_engine": "elevenlabs",
        "voice_id": "thai_female_energetic",
        "speed_multiplier": 1.1,
        "emotion": "excited",
        "pronunciation_hints": ["ลอง:lɔːŋ", "สิ่งนี้:sìŋ.níː"],
        "background_music": {
          "type": "trending_audio",
          "mood": "upbeat",
          "volume_db": -12,
          "source": "platform_library"
        },
        "sfx": []
      },
      "visual": {
        "shot_type": "close_up",
        "camera_movement": "quick_zoom_in",
        "subject": "presenter_face_reaction",
        "b_roll_suggestion": null,
        "text_overlay": {
          "text": "ทำไมทุกคนถึงลอง...?",
          "position": "center",
          "style": "bold_pop",
          "animation": "scale_in"
        },
        "transition_in": "cut",
        "transition_out": "cut"
      }
    },
    {
      "segment_id": 2,
      "type": "problem",
      "start_s": 3.0,
      "end_s": 12.0,
      "duration_s": 9.0,
      "audio": {
        "voiceover_text": "เมื่อก่อนเราก็ไม่เชื่อ แต่พอลองแล้ว...",
        "tts_engine": "elevenlabs",
        "voice_id": "thai_female_energetic",
        "speed_multiplier": 1.0,
        "emotion": "conversational",
        "pronunciation_hints": [],
        "background_music": {
          "type": "continue",
          "volume_db": -15
        },
        "sfx": ["whoosh_transition:3.0s"]
      },
      "visual": {
        "shot_type": "medium",
        "camera_movement": "static",
        "subject": "presenter_talking",
        "b_roll_suggestion": {
          "description": "product_unboxing_sequence",
          "asset_tags": ["unboxing", "lifestyle", "product"],
          "source_preference": "stock_or_generated"
        },
        "text_overlay": null,
        "transition_in": "cut",
        "transition_out": "swipe_left"
      }
    },
    {
      "segment_id": 3,
      "type": "solution",
      "start_s": 12.0,
      "end_s": 24.0,
      "duration_s": 12.0,
      "audio": {
        "voiceover_text": "ผลลัพธ์คือ...ดีเกินคาด!",
        "tts_engine": "elevenlabs",
        "voice_id": "thai_female_energetic",
        "speed_multiplier": 1.0,
        "emotion": "enthusiastic",
        "pronunciation_hints": [],
        "background_music": {
          "type": "continue",
          "volume_db": -12
        },
        "sfx": ["sparkle_reveal:12.0s"]
      },
      "visual": {
        "shot_type": "wide_to_close",
        "camera_movement": "dolly_in",
        "subject": "result_reveal",
        "b_roll_suggestion": {
          "description": "before_after_comparison",
          "asset_tags": ["transformation", "reveal"],
          "source_preference": "generated"
        },
        "text_overlay": {
          "text": "ผลลัพธ์จริง!",
          "position": "bottom_center",
          "style": "highlight",
          "animation": "slide_up"
        },
        "transition_in": "swipe_left",
        "transition_out": "cut"
      }
    },
    {
      "segment_id": 4,
      "type": "cta",
      "start_s": 24.0,
      "end_s": 30.0,
      "duration_s": 6.0,
      "audio": {
        "voiceover_text": "ลองเลย! ลิงก์อยู่ในไบโอ",
        "tts_engine": "elevenlabs",
        "voice_id": "thai_female_energetic",
        "speed_multiplier": 1.0,
        "emotion": "encouraging",
        "pronunciation_hints": ["ไบโอ:bai.oː"],
        "background_music": {
          "type": "fade_out",
          "volume_db": -18
        },
        "sfx": ["notification_ding:26.0s"]
      },
      "visual": {
        "shot_type": "medium",
        "camera_movement": "static",
        "subject": "presenter_direct_address",
        "b_roll_suggestion": null,
        "text_overlay": {
          "text": "ลิงก์อยู่ในไบโอ",
          "position": "bottom_center",
          "style": "cta_button",
          "animation": "bounce"
        },
        "transition_in": "cut",
        "transition_out": "fade_black"
      }
    }
  ],
  
  "production_directives": {
    "aspect_ratio": "9:16",
    "resolution": "1080x1920",
    "fps": 30,
    "max_file_size_mb": 500,
    "caption_style": "auto_styled",
    "caption_language": "th",
    "thumbnail_frame_s": 0.5,
    "color_grade": "bright_saturated",
    "total_b_roll_clips_needed": 2,
    "asset_sources": ["pexels", "pixabay", "ai_generated"]
  },
  
  "platform_overrides": {
    "tiktok": {
      "hashtags": ["#ลองของใหม่", "#fyp", "#tiktokthailand"],
      "caption": "ทำไมทุกคนถึงลองสิ่งนี้? 🔥 #ลองของใหม่ #fyp",
      "trending_sound_id": null,
      "duet_enabled": true,
      "stitch_enabled": true
    }
  },
  
  "tts_preprocessing": {
    "engine": "pythainlp",
    "tokenizer": "han_solo",
    "operations": [
      "word_segmentation",
      "particle_normalization",
      "transliteration_hints"
    ],
    "ssml_markers": true,
    "pause_after_hook_ms": 500
  }
}
```

**Design rationale:**
- `segments[]` maps 1:1 to the Thai 4-beat structure (Hook/Problem/Solution/CTA) from iteration 1
- Each segment has parallel `audio` + `visual` objects (AV two-column model)
- `pronunciation_hints` use IPA notation for Thai words that TTS engines commonly mispronounce
- `b_roll_suggestion` includes `asset_tags` for automated stock footage search or AI generation
- `tts_preprocessing` directs PyThaiNLP processing before TTS (mandatory per spec 003)
- `platform_overrides` allows same script to target multiple platforms with minimal changes (feeds into Q7)

[SOURCE: https://www.studiobinder.com/templates/av-scripts/video-script-template/ -- AV two-column model, per-segment timing, shot descriptions, SFX labeling]
[SOURCE: specs/006-content-lab/research/iterations/iteration-001.md -- 5-stage prompt chain, Thai 4-beat structure (Hook/Problem/Solution/CTA), XML/JSON output format]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md -- ElevenLabs primary TTS, PyThaiNLP han_solo tokenizer mandatory, pronunciation hint patterns]
[INFERENCE: Schema design synthesizes professional AV scripting conventions with automated pipeline needs; segment types map to Thai 4-beat structure; TTS preprocessing section derived from spec 003 requirements]

#### 3. B-Roll and Asset Reference System
The handoff format must address asset sourcing for each visual segment. The 2026 AI filmmaking pipeline shows that automated production generates "20-50 variations per shot" and uses AI for visual generation alongside stock footage.

**Asset reference hierarchy for L4:**
1. **Specific asset ID** -- if a known stock clip or pre-generated asset exists, reference it by ID
2. **Asset tags + source preference** -- machine-searchable tags for automated stock search (Pexels, Pixabay APIs) or AI image/video generation
3. **Natural language description** -- fallback for manual curation or advanced AI generation

**Implementation in the schema:**
```json
"b_roll_suggestion": {
  "description": "product_unboxing_sequence",
  "asset_tags": ["unboxing", "lifestyle", "product"],
  "source_preference": "stock_or_generated",
  "specific_asset_id": null,
  "duration_s": 4.0,
  "importance": "recommended"
}
```

**`importance` field values:**
- `required` -- segment cannot be produced without this visual (e.g., product shot for review content)
- `recommended` -- improves quality but can fall back to presenter footage
- `optional` -- enhancement only, production can proceed without it

This importance classification lets L4 automation prioritize asset sourcing and fail gracefully when assets are unavailable.

[SOURCE: https://www.601media.com/ai-film-workflow-from-script-to-final-cut-no-camera-no-crew/ -- AI generates 20-50 shot variations; composite assembly from multiple short clips; parallel asset sourcing]
[INFERENCE: Asset hierarchy designed for graceful degradation in automated pipeline; importance field enables L4 to make production decisions autonomously]

#### 4. TTS Directive Integration with spec 003
The audio portion of each segment must carry complete TTS directives that the Thai voice pipeline (spec 003) can consume directly without additional processing:

**Required TTS fields per segment:**
- `voiceover_text`: Pre-segmented Thai text (PyThaiNLP tokenized)
- `tts_engine`: Target engine (elevenlabs | cosyvoice | openai | edge_tts)
- `voice_id`: Specific voice profile reference
- `speed_multiplier`: Speaking rate (1.0 = natural, 1.1 = slightly fast for hooks)
- `emotion`: Style/emotion directive (maps to ElevenLabs voice settings or CosyVoice FreeStyle instructions)
- `pronunciation_hints[]`: IPA or phonetic hints for words that TTS commonly mispronounces
- `ssml_markers`: Whether to generate SSML wrapping (for engines that support it)
- `pause_after_ms`: Intentional pause after segment (e.g., 500ms pause after hook for dramatic effect)

**Engine-specific adaptation:**
| TTS Engine | Emotion Mapping | Speed Control | Pronunciation |
|-----------|----------------|---------------|---------------|
| ElevenLabs | stability/similarity_boost params | Via `speed` API param | N/A (model handles Thai) |
| CosyVoice 3.5 | FreeStyle instruction text | Via instruction | Phoneme hints via `<phoneme>` |
| OpenAI TTS | `voice` + `speed` params | Via `speed` param | Limited for Thai |
| Edge-TTS | SSML `<prosody>` tags | SSML `rate` attribute | SSML `<phoneme>` tags |

The `tts_preprocessing` block at the script level tells L4 to run PyThaiNLP segmentation before passing text to TTS. This is mandatory for all Thai content per spec 003 findings.

[SOURCE: specs/003-thai-voice-pipeline/research/research.md -- TTS engine ranking, PyThaiNLP han_solo tokenizer mandatory, CosyVoice FreeStyle mode, ElevenLabs voice settings]
[INFERENCE: Engine-specific mapping table synthesized from spec 003 TTS engine capabilities with handoff format requirements]

### Q7: Platform-Specific Script Adaptation

#### 5. Platform Duration and Format Matrix
2026 platform data confirms distinct optimal ranges per platform, with a universal sweet spot of 30-60 seconds. However, each platform rewards different content characteristics:

| Platform | Duration Range | Optimal Duration | Aspect Ratio | Max File Size | Hook Window |
|----------|---------------|-----------------|--------------|---------------|-------------|
| TikTok | 3-60s (up to 10min) | 15-30s | 9:16 | 4GB | First 1-2s |
| YouTube Shorts | 15-60s | 30-60s | 9:16 | N/A (upload) | First 2-3s |
| IG Reels | 3-90s | 15-30s | 9:16 | 4GB | First 1-2s |
| FB Reels | 3-60s (Reels) | 30-60s | 9:16 | 4GB | First 2-3s |

**Key insight:** TikTok and IG Reels reward shorter, punchier content (15-30s), while YouTube Shorts and FB Reels favor slightly longer, more substantive videos (30-60s). This means the 4-beat Thai script structure needs platform-specific duration allocation.

[SOURCE: https://www.opus.pro/blog/short-form-video-strategy-2026 -- "Sweet spot 30-60 seconds", platform-specific tone and content strategy recommendations]
[SOURCE: specs/004-platform-upload -- Platform specs: TikTok 3-60s 9:16 4GB, YouTube Shorts 15-60s, IG Reels 3-90s (from strategy.md known context)]

#### 6. Platform-Specific 4-Beat Timing Templates
The Thai 4-beat structure (Hook/Problem/Solution/CTA) from iteration 1 must be adapted per platform's optimal duration. Here are the timing templates:

**TikTok (15s fast template):**
| Beat | Duration | Allocation | Notes |
|------|----------|-----------|-------|
| Hook | 1-2s | 10-13% | Ultra-fast, visual-first, one sentence max |
| Problem | 3-4s | 20-27% | Quick relatable scenario |
| Solution | 5-6s | 33-40% | Core value delivery |
| CTA | 2-3s | 13-20% | Direct, punchy, "ลองเลย!" style |

**TikTok (30s standard template):**
| Beat | Duration | Allocation | Notes |
|------|----------|-----------|-------|
| Hook | 2-3s | 7-10% | Curiosity or shock hook, trending audio sync |
| Problem | 7-8s | 23-27% | Storytelling with visual proof |
| Solution | 12-13s | 40-43% | Detailed demo or transformation |
| CTA | 5-6s | 17-20% | CTA + social proof + follow prompt |

**YouTube Shorts (60s deep template):**
| Beat | Duration | Allocation | Notes |
|------|----------|-----------|-------|
| Hook | 3-4s | 5-7% | Searchable hook with keyword, evergreen framing |
| Problem | 15-17s | 25-28% | Thorough context, educational angle |
| Solution | 28-30s | 47-50% | Step-by-step, clear takeaway, visual demonstration |
| CTA | 8-10s | 13-17% | Subscribe + comment prompt + preview next video |

**IG Reels (15s aesthetic template):**
| Beat | Duration | Allocation | Notes |
|------|----------|-----------|-------|
| Hook | 1-2s | 7-13% | Visually striking, branded aesthetic |
| Problem | 3-4s | 20-27% | Aspirational framing |
| Solution | 6-7s | 40-47% | Polished reveal, product focus |
| CTA | 2-3s | 13-20% | Subtle CTA, Stories cross-promotion |

**Implementation:** The `target_duration_s` and `platform` fields in the handoff schema drive template selection. Stage 2 (Script Drafting) of the prompt chain receives the platform-specific timing template as a constraint.

[SOURCE: https://www.opus.pro/blog/short-form-video-strategy-2026 -- TikTok: trend-driven casual, YouTube Shorts: searchable evergreen, IG Reels: polished brand aesthetics]
[SOURCE: specs/006-content-lab/research/iterations/iteration-001.md -- Thai 4-beat structure with 15/30/60s templates, Hook/Problem/Solution/CTA anatomy]
[INFERENCE: Duration allocation percentages derived from applying the universal hook-2s/CTA-proportional pattern across platform-specific optimal durations; percentages approximate standard content creator timing conventions]

#### 7. Platform-Specific Hook and CTA Strategies
Each platform's algorithm rewards different hook and CTA behaviors. The script generation prompt must include platform-specific instructions:

**Hook Strategies by Platform:**

| Platform | Best Hook Types | Hook Characteristics | Algorithm Signal |
|----------|----------------|---------------------|-----------------|
| TikTok | Curiosity, Shock, Controversy | Ultra-fast (1-2s), visual-first, trending audio sync, pattern interrupt | Completion rate + re-watches |
| YouTube Shorts | Question, Statistic, Curiosity | Keyword-rich (2-3s), evergreen framing, "How to..." / "3 things..." | Click-through + watch time |
| IG Reels | Emotion, Relatable, Visual reveal | Aesthetic-first (1-2s), on-brand visuals, polished opener | Saves + shares |
| FB Reels | Relatable, Emotion, Statistic | Familiar-feeling (2-3s), broader demographic appeal, nostalgia | Shares + comments |

**CTA Strategies by Platform:**

| Platform | CTA Type | CTA Language (Thai) | Algorithm Boost |
|----------|----------|-------------------|----------------|
| TikTok | Follow + profile visit | "ฟอลโลว์เพื่อดูเพิ่ม!", "ลิงก์อยู่ในไบโอ" | Profile visits drive follower growth |
| YouTube Shorts | Subscribe + comment | "ซับเพื่อไม่พลาด!", "คอมเมนต์บอกหน่อย" | Subscription converts → long-form |
| IG Reels | Save + share to Stories | "เซฟไว้ก่อน!", "แชร์ให้เพื่อนดู" | Saves = algorithm gold |
| FB Reels | Share + tag friend | "แท็กเพื่อนที่ต้องดู!", "แชร์เลย!" | Shares extend reach to friends |

**Implementation in prompt chain:** Stage 2 (Script Drafting) system prompt includes:
```xml
<platform_rules platform="tiktok">
  <hook_style>Ultra-fast visual hook in first 1-2 seconds. Sync with trending audio beat drop. Use pattern interrupt technique.</hook_style>
  <cta_style>Direct CTA: profile visit + follow. Use casual Thai: "ฟอลโลว์เพื่อดูเพิ่ม!"</cta_style>
  <tone>Casual, trend-native, entertainer persona</tone>
  <avoid>Corporate language, slow intros, generic CTAs</avoid>
</platform_rules>
```

[SOURCE: https://www.opus.pro/blog/short-form-video-strategy-2026 -- TikTok trend-driven, YouTube Shorts searchable/evergreen, IG Reels polished/brand, 2-second hook rule, 80%+ watch without sound]
[INFERENCE: Thai CTA phrases synthesized from common Thai social media conventions combined with platform-specific algorithm signals; hook type mapping based on iteration 1's 7 hook categories applied to platform characteristics]

#### 8. Multi-Platform Script Adaptation Pipeline
Rather than generating entirely separate scripts per platform, the efficient approach is: generate ONE base script, then adapt per platform. This aligns with the 3x3 variant model from iteration 2 while adding a platform dimension.

**Adaptation pipeline:**
```
Base Script (30s, platform-agnostic)
    |
    +-- [Adapt: TikTok 15s] → Compress to 15s, add trending audio ref, TikTok hashtags
    |
    +-- [Adapt: TikTok 30s] → Keep duration, add TikTok-specific hooks/CTA
    |
    +-- [Adapt: YouTube Shorts 60s] → Expand to 60s, add evergreen framing, keyword hook
    |
    +-- [Adapt: IG Reels 15s] → Compress to 15s, polish visuals, branded aesthetic
    |
    +-- [Adapt: FB Reels 30s] → Keep duration, broaden demographic appeal, shareable CTA
```

**What changes per adaptation:**
1. `target_duration_s` -- platform-optimal duration
2. `segments[].duration_s` -- rebalanced per timing template
3. `segments[0].audio.voiceover_text` -- hook text adapted per hook strategy
4. `segments[-1].audio.voiceover_text` -- CTA text adapted per CTA strategy
5. `platform_overrides` -- hashtags, captions, platform features
6. `production_directives.caption_style` -- mandatory captions (80%+ silent viewing)

**What stays the same:**
1. Core concept angle and problem/solution narrative
2. Niche and target audience
3. Emotional trigger and tone (within platform range)
4. B-roll suggestions and asset references
5. TTS voice and engine selection

**Cost of adaptation (per platform):**
- 1 LLM call for timing/hook/CTA adaptation: ~$0.003
- For 4 platforms from 1 base script: ~$0.012 additional
- Total per trend (3 base variants x 4 platforms x $0.003): ~$0.036 for platform adaptation
- Combined with generation cost ($0.13/trend from iteration 3): ~$0.17/trend total

[SOURCE: specs/006-content-lab/research/iterations/iteration-002.md -- 3x3 variant expansion model, efficient batch generation (14 calls vs 45 naive), parameter injection pattern]
[SOURCE: https://www.opus.pro/blog/short-form-video-strategy-2026 -- Platform-specific optimization recommendations suggesting adaptation rather than full recreation]
[INFERENCE: Adaptation pipeline extends iteration 2's variant model by adding platform as a dimension; cost estimates based on GPT-4o-mini pricing applied to estimated adaptation token counts]

#### 9. Mandatory Caption Layer
Over 80% of social media users watch videos without sound (2026 data). Captions are not optional -- they are a mandatory production element that must be specified in the handoff format.

**Caption specification in handoff:**
```json
"production_directives": {
  "caption_style": "auto_styled",
  "caption_language": "th",
  "caption_word_highlight": true,
  "caption_position": "bottom_third",
  "caption_font": "noto_sans_thai",
  "caption_max_chars_per_line": 20,
  "caption_timing_source": "tts_alignment"
}
```

**Caption generation approach:**
1. L3 provides the voiceover text per segment (already in handoff schema)
2. L4 generates TTS audio using the voice pipeline (spec 003)
3. TTS engine returns word-level timestamps (ElevenLabs and CosyVoice both support this)
4. Word-level timestamps drive caption timing (karaoke-style word highlighting)
5. Caption styling follows platform conventions (TikTok: centered bold, IG: clean minimal, YT: bottom overlay)

This means L3 does NOT need to generate caption files -- but it MUST provide clean, segmented text that L4 can align with TTS output.

[SOURCE: https://www.opus.pro/blog/short-form-video-strategy-2026 -- "Over 80% of social media users watch videos without sound"; captions directly affect retention rates]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md -- ElevenLabs and CosyVoice both support word-level timestamp output for alignment]
[INFERENCE: Caption generation delegated to L4 because it depends on TTS audio timing which L3 doesn't produce; L3 responsibility is clean text segmentation]

## Ruled Out
- **Generating platform-specific scripts from scratch**: Wasteful when 70-80% of content (core narrative, B-roll, TTS settings) is shared across platforms. Adaptation from a base script is strictly more efficient.
- **Including raw caption timing in L3 handoff**: L3 does not produce audio, so caption timing cannot be determined until L4 generates TTS. L3 provides text; L4 handles timing alignment.

## Dead Ends
None identified. All approaches in this iteration were productive.

## Sources Consulted
- https://www.studiobinder.com/templates/av-scripts/video-script-template/ (Professional AV two-column script format, per-segment timing, shot descriptions, SFX labeling)
- https://www.601media.com/ai-film-workflow-from-script-to-final-cut-no-camera-no-crew/ (AI filmmaking pipeline: scene decomposition, shot metadata, parallel TTS track, 20-50 variations per shot)
- https://www.opus.pro/blog/short-form-video-strategy-2026 (Platform-specific short-form video strategy: optimal durations, hook timing, caption data, platform algorithm preferences)
- specs/006-content-lab/research/iterations/iteration-001.md (5-stage prompt chain, Thai 4-beat structure, XML/JSON output)
- specs/006-content-lab/research/iterations/iteration-002.md (3x3 variant model, batch generation efficiency, parameter injection)
- specs/006-content-lab/research/iterations/iteration-003.md (L1/L2 context injection schema, quality gate thresholds, cost analysis)
- specs/003-thai-voice-pipeline/research/research.md (TTS engine ranking, PyThaiNLP requirements, CosyVoice/ElevenLabs capabilities)
- specs/004-platform-upload (Platform specs: duration ranges, aspect ratios, file sizes -- from strategy.md known context)

## Assessment
- New information ratio: 0.72
- Questions addressed: Q6, Q7
- Questions answered: Q6, Q7

## Reflection
- What worked and why: The StudioBinder AV template provided the foundational two-column model that translated naturally into the JSON handoff schema. Combining this with the 601media AI filmmaking pipeline article (which showed how modern automated pipelines decompose scripts into shot-level metadata) produced a schema that bridges traditional video production conventions with automated pipeline needs. The OpusClip 2026 strategy article provided quantitative platform data (80% silent viewing, 2-second hook window) that directly informed schema design decisions (mandatory captions, platform-specific hook timing). Building on prior iterations (4-beat structure from iter 1, variant model from iter 2, cost analysis from iter 3) was highly efficient.
- What did not work and why: The spec 004 research.md file was not found at the expected path, so platform specs came from the strategy.md known context section (which already summarized spec 004 findings). This was sufficient but prevented deeper cross-referencing with upload API constraints.
- What I would do differently: For the next iteration focusing on Q8 (Thai TTS integration) and Q10 (L7 feedback loop), I should fetch the actual ElevenLabs and CosyVoice API documentation to validate the TTS directive fields in the handoff schema, and look for content performance feedback loop patterns in recommendation system literature.

## Recommended Next Focus
Q8 (Thai TTS integration -- script format for TTS, pronunciation hints, pacing markers, PyThaiNLP preprocessing) and Q10 (L7 feedback loop -- how performance data influences future script generation, prompt tuning, template selection, few-shot example curation). Q8 validates and extends the TTS directives designed in this iteration's handoff schema. Q10 closes the generation-to-performance feedback cycle. Together they address the remaining pipeline integration questions.
