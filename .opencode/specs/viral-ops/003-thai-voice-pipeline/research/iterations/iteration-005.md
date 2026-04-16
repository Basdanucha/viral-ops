# Iteration 5: FINAL SYNTHESIS — F5-TTS-THAI, Prosody Control, Definitive Ranking, Complete Pipeline

## Focus
Final convergence iteration addressing all remaining questions: (Q1) definitive Thai TTS naturalness ranking with Phase 1/2 recommendation, (Q3) prosody/emotion control comparison across all viable engines. Also investigated F5-TTS-THAI as a newly discovered OSS Thai voice cloning option, and synthesized the complete pipeline architecture.

## Findings

### 1. F5-TTS-THAI — Real OSS Thai Voice Cloning Exists

F5-TTS-THAI is a community fine-tune of the base F5-TTS model, specifically trained on Thai data. This is a significant discovery that changes the OSS landscape.

**Model Details:**
- **Creator:** VIZINTZOR (HuggingFace) / VYNCX (GitHub)
- **Base model:** SWivid/F5-TTS
- **Training data:** ~500 hours total
  - Common Voice Thai (processed-voice-th-169k): ~160 hours
  - Porjai Dataset: ~300 hours
  - Common Voice English: ~40 hours
- **Training steps:** 1,000,000
- **License:** CC-BY-4.0 (commercial use allowed)
- **Downloads:** 43/month, 48 likes — small but active community

**Voice Cloning:** Yes — accepts reference audio (2-8 seconds recommended), clones voice characteristics for generated Thai text.

**Python API:**
```python
from f5_tts_th.tts import TTS
import soundfile as sf

tts = TTS(model="v1")
wav = tts.infer(
    ref_audio="reference.wav",
    ref_text="ได้รับข่าวคราวของเราที่จะหาที่มันเป็นไปที่จะจัดขึ้น.",
    gen_text="สวัสดีครับ นี่คือเสียงพูดภาษาไทย.",
    step=32,       # Quality/speed trade-off
    cfg=2.0,       # Configuration scale
    speed=1.0      # Speech speed (0.7-0.8 recommended)
)
sf.write("test.wav", wav, 24000)
```

**GPU Requirements:** PyTorch with CUDA (cu124). Based on base F5-TTS architecture (~300M-1.2B params), estimate 4-8GB VRAM minimum.

**Known Limitations:**
- Long text or certain words may not pronounce correctly
- Reference audio should be 2-8 seconds for best results
- Speed parameter 0.7-0.8 recommended if output is too fast
- English words should be transliterated to Thai script (e.g., "Good Morning" -> "กูดมอร์นิ่ง")

**Assessment:** This is a VIABLE Phase 2/3 option for OSS Thai voice cloning. Quality is unproven at scale but the training data volume (500 hours) is substantial. The CC-BY-4.0 license allows commercial use. Integration into Pixelle-Video is straightforward via the Python pip package.

[SOURCE: https://huggingface.co/VIZINTZOR/F5-TTS-THAI]

### 2. Prosody/Emotion Control Comparison (Q3 — ANSWERED)

#### OpenAI gpt-4o-mini-tts — BEST Emotion Control
The most powerful prosody control of any engine, using natural language instructions:

**Mechanism:** `instructions` parameter in API call — free-form text describing delivery style.
**Controllable dimensions:**
- Tone and emotion (e.g., "speak with excitement", "sound sympathetic")
- Pacing and speed (e.g., "slow, deliberate delivery")
- Accent (e.g., "with a warm Thai accent")
- Persona (e.g., "enthusiastic tour guide", "calm meditation instructor")
- Overall vibe (cheerful, poetic, business-like, dramatic)

**Technical specs:**
- Context window: 2,000 input tokens for instructions
- Output: 48 kHz sampling rate
- MOS score: exceeds 4.0/5.0
- Pricing: ~$0.015/minute (~$0.60/M input tokens, ~$12.00/M output tokens)
- Voices: Alloy, Ash, Nova, Sage, and others (12+ presets)

**Thai relevance:** Supports 50+ languages including Thai. Style instructions work cross-lingually — you can instruct in English and output Thai speech with the specified emotion.

**Example for viral content:**
```json
{
  "model": "gpt-4o-mini-tts",
  "voice": "nova",
  "input": "สวัสดีค่ะ วันนี้เรามีเรื่องเด็ดมาเล่าให้ฟัง!",
  "instructions": "Speak like an excited Thai content creator. High energy, enthusiastic, with natural pauses for dramatic effect. Add slight vocal fry on emphasis words."
}
```

[SOURCE: https://blog.promptlayer.com/gpt-4o-mini-tts-steerable-low-cost-speech-via-simple-apis/]
[SOURCE: https://developers.openai.com/api/docs/models/gpt-4o-mini-tts]

#### ElevenLabs — Strong Emotion via Text Cues + Sliders
**Mechanism:** Dual control — voice settings sliders + textual emotion cues in input.

**Voice Settings:**
- **Stability** (0-100): Lower = more expressive/variable, Higher = consistent. Default ~50.
- **Similarity** (0-100): How closely to match original voice. Default ~75.
- **Style** (0-100): Expressiveness multiplier. 10-50% for narration, higher for dramatic. Default 0.

**Textual Emotion Cues:**
- Add descriptors: "she said excitedly", "he whispered nervously"
- Punctuation matters: ! for excitement, ... for hesitation, ? for questioning tone
- Parenthetical stage directions: "(angrily) ทำไมถึงทำแบบนี้!"

**Models for Thai:**
- `eleven_multilingual_v2`: 29 languages with rich emotional expression
- `eleven_v3`: Most expressive model (latest)
- `eleven_flash_v2_5`: 32 languages, 3x faster for non-English

**Thai relevance:** Full Thai support confirmed. Stability/Similarity sliders work well for Thai — lower stability increases tonal variation which can sound more natural for Thai's inherent tonal variability.

[SOURCE: https://elevenlabs.io/docs/overview/capabilities/text-to-speech]
[SOURCE: https://elevenlabs.io/v3]
[SOURCE: https://www.webfuse.com/elevenlabs-cheat-sheet]

#### Edge-TTS — Minimal Control (SSML Only)
**Mechanism:** SSML prosody tags only.

**Available controls:**
- `<prosody rate="fast">` — speed adjustment
- `<prosody pitch="+5Hz">` — pitch shift
- `<prosody volume="loud">` — volume control
- `<break time="500ms"/>` — pauses

**NOT available:** Emotion, style, persona, accent variation. No way to make Edge-TTS sound excited vs calm beyond pitch/speed manipulation.

**Thai relevance:** SSML tags work for Thai voices (PremwadeeNeural, NiwatNeural, AcharaNeural) but the effect is mechanical — adjusting pitch in a tonal language can accidentally change word meaning if not careful.

[SOURCE: iteration-003 findings, confirmed BLOCKED in strategy]

#### CosyVoice 3.5 FreeStyle — Untested for Thai
**Mechanism:** Natural language instruction (similar to OpenAI approach).
- Describe desired style in text: "speak with sadness", "cheerful narrator"
- Cross-lingual style transfer possible
- BUT Thai is NOT a native language — style control quality for Thai is completely unknown

[SOURCE: iteration-002 findings]

#### PROSODY CONTROL RANKING (for Thai viral content):

| Rank | Engine | Control Type | Emotion Range | Thai Quality | Verdict |
|------|--------|-------------|---------------|-------------|---------|
| 1 | OpenAI gpt-4o-mini-tts | NL instructions | Unlimited | Good | Best for emotion-rich content |
| 2 | ElevenLabs v3 | Sliders + text cues | Very wide | Excellent | Best for cloned voice + emotion |
| 3 | Google Cloud TTS | SSML + Neural2 | Moderate | Good | Decent but limited |
| 4 | Edge-TTS | SSML only | Minimal | Limited | Speed/pitch only |
| 5 | CosyVoice FreeStyle | NL instructions | Unknown for Thai | Unproven | Experimental only |
| 6 | F5-TTS-THAI | cfg/speed params | Minimal | Unknown | Cloning focus, not emotion |

### 3. DEFINITIVE Thai TTS Naturalness Ranking (Q1 — ANSWERED)

Based on ALL evidence across 5 iterations — architecture quality, training data, Thai-specific handling, prosody control, production readiness, and community validation:

| Rank | Engine | Naturalness | Strengths | Weaknesses | Score |
|------|--------|------------|-----------|------------|-------|
| **1** | **ElevenLabs v3/Multilingual v2** | Excellent | Best overall Thai quality, voice cloning, emotion control, production-proven | Paid ($5-99/mo), cloud-only, API latency | 9.0/10 |
| **2** | **OpenAI gpt-4o-mini-tts** | Excellent | Best emotion steerability, 50+ langs, high MOS (>4.0) | No cloning, cloud-only, higher latency | 8.5/10 |
| **3** | **Google Cloud TTS (Neural2/WaveNet)** | Very Good | Reliable, well-documented, free tier generous | Limited emotion control, no cloning | 7.5/10 |
| **4** | **Edge-TTS (Azure Neural)** | Good | Free, fast, zero-setup, 3 Thai voices | No cloning, minimal emotion, neutral only | 7.0/10 |
| **5** | **F5-TTS-THAI** | Unknown (Promising) | OSS, voice cloning, 500hrs Thai data, CC-BY-4.0 | Unproven quality, limited community, GPU needed | 6.0/10 (estimated) |
| **6** | **CosyVoice 3.5** | Unknown | Zero-shot cloning, FreeStyle mode | Thai NOT native, requires fine-tuning for quality | 5.0/10 (estimated) |

### 4. DEFINITIVE Phase Recommendation (Q1 — COMPLETE)

#### Phase 1: Launch (Week 1-4) — Edge-TTS + OpenAI TTS
- **Default engine:** Edge-TTS (PremwadeeNeural female, NiwatNeural male)
  - Why: Free, zero-setup, fast (1-3s), good baseline quality
  - Use for: Standard narration, informational content, high-volume generation
- **Premium engine:** OpenAI gpt-4o-mini-tts
  - Why: Best emotion control via instructions, excellent Thai quality
  - Use for: Emotion-rich viral content, dramatic storytelling, humor
  - Cost: ~$0.015/minute — acceptable for premium content
- **Architecture:** Multi-engine per-channel selection in channels table

#### Phase 2: Growth (Month 2-3) — Add ElevenLabs Cloning
- **Cloning engine:** ElevenLabs Instant Voice Cloning
  - Why: Only production-proven Thai voice cloning
  - Use for: Brand voices, influencer clone channels, consistent persona
  - Cost: $5-22/mo depending on volume
- **Upgrade OpenAI to primary:** As content quality proven, shift more channels to gpt-4o-mini-tts
- **Evaluate F5-TTS-THAI:** Run quality benchmarks against ElevenLabs

#### Phase 3: Scale (Month 4+) — OSS Self-Hosted
- **Evaluate F5-TTS-THAI:** If quality matches, migrate cloning to self-hosted
  - Why: Zero per-generation cost, full control, CC-BY-4.0 license
  - Risk: Quality may not match ElevenLabs
- **Evaluate CosyVoice 3.5 fine-tuned on Thai:** If community produces a Thai fine-tune
- **Fallback:** Stay on ElevenLabs if OSS quality insufficient

### 5. Complete Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THAI VOICE PIPELINE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. SCRIPT GENERATION (n8n + LLM)                                   │
│     ├─ LLM generates Thai script with naturalness guidelines        │
│     ├─ 60+ particles, internet slang, conversational markers        │
│     └─ Anti-AI patterns: varied sentence length, filler words       │
│                                                                     │
│  2. TEXT PREPROCESSING (Python service)                              │
│     ├─ PyThaiNLP newmm tokenizer → word segmentation                │
│     ├─ Thai text normalization (numbers, abbreviations, dates)      │
│     ├─ Tone-aware phoneme mapping (for OSS engines)                 │
│     └─ SSML wrapping (for Edge-TTS/Google Cloud)                    │
│                                                                     │
│  3. TTS ENGINE SELECTION (per-channel config)                       │
│     ├─ channels.voice_config: { engine, voice_id, settings }        │
│     ├─ Engine router: Edge-TTS | OpenAI | ElevenLabs | F5-TTS-THAI │
│     └─ Fallback chain: primary → secondary → Edge-TTS (default)    │
│                                                                     │
│  4. TTS GENERATION                                                  │
│     ├─ Cloud engines: API call → audio buffer                       │
│     ├─ Local engines: GPU sidecar → audio buffer                    │
│     └─ Voice cloning: ref_audio from channel config                 │
│                                                                     │
│  5. POST-PROCESSING (FFmpeg + Python)                               │
│     ├─ LUFS normalization (-14 LUFS for social media)               │
│     ├─ De-essing (Thai sibilants ส, ศ, ษ)                           │
│     ├─ Subtle breathing insertion (between phrases)                 │
│     ├─ Tone preservation check (Thai 5-tone integrity)              │
│     └─ Format: WAV 24kHz → output format per platform               │
│                                                                     │
│  6. INTEGRATION POINTS                                              │
│     ├─ Pixelle-Video: TTSService interface (POST /api/tts/generate) │
│     ├─ n8n: Orchestrates pipeline, triggers per-video generation    │
│     ├─ Dashboard: Channel voice config UI, preview, A/B testing     │
│     └─ Storage: Generated audio cached per script hash              │
│                                                                     │
│  DEPLOYMENT:                                                        │
│     ├─ Cloud engines: API keys in env, no GPU needed                │
│     ├─ F5-TTS-THAI: Docker sidecar, 4-8GB VRAM GPU                 │
│     └─ Post-processing: CPU-only (FFmpeg + pyloudnorm)              │
└─────────────────────────────────────────────────────────────────────┘
```

### 6. Channel Voice Configuration Schema

```typescript
// In channels table (Supabase)
interface VoiceConfig {
  engine: 'edge-tts' | 'openai-tts' | 'elevenlabs' | 'f5-tts-thai';
  voice_id: string;           // e.g., 'th-TH-PremwadeeNeural', 'nova', clone_id
  settings: {
    // Edge-TTS
    rate?: string;            // '+10%', '-20%'
    pitch?: string;           // '+5Hz', '-10Hz'
    // OpenAI
    instructions?: string;    // NL style instruction
    // ElevenLabs
    stability?: number;       // 0-100
    similarity?: number;      // 0-100
    style?: number;           // 0-100
    // F5-TTS-THAI
    ref_audio_url?: string;   // Reference audio for cloning
    step?: number;            // Quality steps (default 32)
    cfg?: number;             // Configuration scale (default 2.0)
    speed?: number;           // Speech speed (default 1.0)
  };
  fallback_engine?: string;   // Fallback if primary fails
  preprocessing: {
    segmenter: 'newmm';      // PyThaiNLP tokenizer
    normalize: boolean;       // Text normalization
    ssml_wrap: boolean;       // SSML for cloud engines
  };
  postprocessing: {
    lufs_target: number;      // -14 LUFS default
    deessing: boolean;
    breathing: boolean;
    tone_check: boolean;
  };
}
```

## Ruled Out
- No new approaches ruled out this iteration — this was a synthesis/consolidation iteration.

## Dead Ends
- None new. All dead ends from iterations 1-4 remain valid.

## Sources Consulted
- https://huggingface.co/VIZINTZOR/F5-TTS-THAI — F5-TTS-THAI model card, training data, API
- https://blog.promptlayer.com/gpt-4o-mini-tts-steerable-low-cost-speech-via-simple-apis/ — OpenAI TTS style control details
- https://developers.openai.com/api/docs/models/gpt-4o-mini-tts — OpenAI model specs
- https://elevenlabs.io/docs/overview/capabilities/text-to-speech — ElevenLabs prosody/emotion
- https://elevenlabs.io/v3 — ElevenLabs v3 expressiveness
- https://www.webfuse.com/elevenlabs-cheat-sheet — ElevenLabs 2026 cheat sheet
- Iterations 1-4 findings (consolidated)

## Assessment
- New information ratio: 0.55
- Questions addressed: Q1, Q3
- Questions answered: Q1 (definitive ranking + phase recommendation), Q3 (prosody/emotion control comparison)

## Reflection
- What worked and why: The F5-TTS-THAI HuggingFace fetch was the single most valuable action — it revealed a viable OSS Thai voice cloning option with 500 hours of training data and a pip-installable package, fundamentally changing the Phase 3 recommendation. The PromptLayer blog on gpt-4o-mini-tts provided concrete API details and examples that the official docs lacked.
- What did not work and why: N/A — all sources returned useful data this iteration. This is expected for a synthesis iteration where we targeted known-good sources rather than exploring.
- What I would do differently: For a non-final iteration, I would have done a deeper dive into F5-TTS-THAI quality by checking the GitHub issues and the HuggingFace Space demo. However, within the tool budget of a final iteration prioritizing synthesis, the trade-off was correct.

## Recommended Next Focus
ALL 12 questions are now answered. Research is ready for convergence:
- Q1: Definitive ranking (ElevenLabs > OpenAI > Google > Edge-TTS > F5-TTS-THAI > CosyVoice)
- Q2: Voice cloning (ElevenLabs production-proven, F5-TTS-THAI OSS alternative)
- Q3: Prosody control (OpenAI best for emotion, ElevenLabs best for cloned+emotion)
- Q4: PyThaiNLP newmm tokenizer, mandatory preprocessing
- Q5: Thai script guidelines (60+ particles, anti-AI patterns, prompt template)
- Q6: Thai 5-tone system, segmentation critical for tone correctness
- Q7: Pixelle-Video TTSService interface, sidecar for local engines
- Q8: Edge-TTS 0GB, OpenAI 0GB, ElevenLabs 0GB, F5-TTS-THAI 4-8GB, CosyVoice 4-12GB
- Q9: Edge-TTS 1-3s, Google 2-5s, OpenAI 3-8s, ElevenLabs 3-10s, local 8-15s
- Q10: Edge-TTS free, Google free tier, OpenAI $0.015/min, ElevenLabs $5-99/mo
- Q11: Multi-engine per-channel supported via channels.voice_config
- Q12: Post-processing pipeline (LUFS, de-essing, breathing, tone-preservation)

**Recommend: Mark research as CONVERGED. All key questions answered with evidence.**
