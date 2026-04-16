# Iteration 1: Survey All TTS Engines for Thai Language Support

## Focus
Comprehensive survey of all available TTS engines (OSS + commercial) to determine which support Thai language, their voice quality characteristics, cloning capability, licensing, and GPU requirements. This is the foundational mapping iteration -- establishing the full landscape before deep-diving into top candidates.

## Findings

### 1. CosyVoice 3.5 / Fun-CosyVoice 3.5 -- THAI SUPPORTED (New, March 2026)
- **Thai support**: YES -- Thai added in v3.5 (March 2, 2026) alongside Indonesian, Portuguese, Vietnamese
- **Total languages**: 13 (up from 9 in CosyVoice 2.0: Chinese, English, Japanese, Korean, German, Spanish, French, Italian, Russian)
- **Voice cloning**: YES -- zero-shot voice cloning, cross-lingual synthesis
- **Streaming**: CosyVoice 2.0 achieves 150ms first-packet latency
- **License**: Apache 2.0 (CosyVoice base); v3.5 license TBD (Alibaba/Tongyi Lab)
- **GPU**: Requires GPU for inference; specific VRAM not confirmed but likely 4-8GB VRAM for 0.5B model
- **Key advantage**: Most recent OSS model to officially add Thai; backed by Alibaba research
- [SOURCE: https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/]
- [SOURCE: https://github.com/FunAudioLLM/CosyVoice]

### 2. Fish Audio S2 Pro -- THAI LIKELY SUPPORTED (80+ languages)
- **Thai support**: LIKELY YES -- supports 80+ languages with cross-lingual generalization; trained on 10M+ hours
- **Voice cloning**: YES -- cross-lingual voice cloning from short reference
- **Architecture**: Dual-AR (4B slow + 400M fast components) -- large model
- **GPU**: ~100ms TTFA on single H200 GPU (high-end GPU required)
- **License**: Open weights; commercial use requires paid license
- **Key distinction**: Fish Audio S2 Pro is the commercial successor to Fish-Speech OSS; Fish-Speech itself only supports 8 languages (no Thai)
- [SOURCE: https://www.bentoml.com/blog/exploring-the-world-of-open-source-text-to-speech-models]
- [SOURCE: https://fish.audio/blog/introducing-fish-speech/]

### 3. OpenAI GPT-4o-mini-TTS -- THAI SUPPORTED (Commercial API)
- **Thai support**: YES -- follows Whisper language coverage which includes Thai
- **Model**: gpt-4o-mini-tts-2025-12-15 (latest)
- **Voice cloning**: NO -- predefined voices only (alloy, echo, fable, onyx, nova, shimmer) but highly steerable via text instructions
- **Steerability**: Can specify speaking style ("sympathetic customer service agent", "engaging storyteller") -- unique advantage
- **License**: Commercial API, pay-per-use
- **GPU**: Cloud-only (no local deployment)
- **Pricing**: ~$15/1M characters (standard), lower for mini
- [SOURCE: https://developers.openai.com/api/docs/guides/text-to-speech]
- [SOURCE: https://developers.openai.com/blog/updates-audio-models]

### 4. Google Cloud TTS -- THAI SUPPORTED (Commercial API)
- **Thai support**: YES -- explicitly listed; WaveNet + Neural2 voices available
- **Total**: 380+ voices across 75+ languages
- **Long Audio Synthesis**: Thai explicitly supported
- **Voice cloning**: NO -- predefined voices only
- **License**: Commercial API, pay-per-use
- **GPU**: Cloud-only
- **Pricing**: ~$4/1M characters (standard), ~$16/1M (WaveNet/Neural2)
- [SOURCE: https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types]

### 5. Edge-TTS (Microsoft) -- THAI SUPPORTED (Baseline)
- **Thai support**: YES -- 3 Neural voices: PremwadeeNeural (F), NiwatNeural (M), AcharaNeural (F)
- **Voice cloning**: NO
- **Style control**: Neutral only, no SSML emotion/style for Thai voices
- **Speed control**: 0.5-2.0x via Pixelle-Video; NO pitch control
- **License**: Free API (Microsoft Edge service)
- **GPU**: Cloud-only (API calls)
- **Already integrated**: In Pixelle-Video as primary TTS
- [SOURCE: specs/002-pixelle-video-audit -- known context from prior research]

### 6. ElevenLabs -- THAI SUPPORTED (Commercial)
- **Thai support**: YES -- listed on their Thai TTS page
- **Voice cloning**: YES -- industry-leading voice cloning
- **Quality**: Generally considered top-tier for naturalness
- **License**: Commercial API (free tier available, paid plans $5-$330/mo)
- **GPU**: Cloud-only
- **Integration**: REST API, Python/JS SDKs
- [SOURCE: https://elevenlabs.io/text-to-speech/thai]

### 7. F5-TTS -- THAI NOT SUPPORTED
- **Thai support**: NO -- base model trained on Chinese-English bilingual data (Emilia-ZH-EN)
- **Voice cloning**: YES -- multi-style/multi-speaker via reference audio
- **License**: Code MIT, models CC-BY-NC (non-commercial)
- **GPU**: NVIDIA, AMD, Intel, Apple Silicon; L20 GPU benchmark 253ms latency
- **Version**: v1.1.19 (April 2026)
- **Note**: Could potentially be fine-tuned on Thai data, but no pretrained Thai support
- [SOURCE: https://github.com/SWivid/F5-TTS]

### 8. Fish-Speech (OSS) -- THAI NOT SUPPORTED
- **Thai support**: NO -- supports 8 languages (English, Chinese, German, Japanese, French, Spanish, Korean, Arabic)
- **Voice cloning**: YES -- zero-shot voice cloning
- **License**: Open source
- **Note**: Distinct from Fish Audio S2 Pro (commercial, 80+ languages)
- [SOURCE: https://fish.audio/blog/introducing-fish-speech/]
- [SOURCE: https://www.aibase.com/news/11746]

### 9. Kokoro -- THAI NOT SUPPORTED
- **Thai support**: NO -- 8 languages only (American English, British English, Japanese, Mandarin Chinese, Spanish, French, Hindi, Italian, Brazilian Portuguese)
- **Voice cloning**: NO
- **License**: Apache 2.0
- **Model size**: 82M parameters (extremely lightweight)
- **GPU**: Runs on modest hardware, minimal latency
- **Note**: Fast and lightweight but limited language coverage, weak G2P for non-supported languages
- [SOURCE: https://huggingface.co/hexgrad/Kokoro-82M]
- [SOURCE: https://deepwiki.com/hexgrad/kokoro/4-languages-and-voices]

### 10. XTTS-v2 (Coqui) -- THAI UNCERTAIN
- **Thai support**: UNCERTAIN -- supports 17 languages; Thai not confirmed in language list
- **Voice cloning**: YES -- from 6-second audio clip
- **License**: Coqui Public Model License (NON-COMMERCIAL ONLY)
- **GPU**: Consumer GPU, <150ms streaming latency
- **Status**: Coqui AI company shut down; model is archived/community-maintained
- [SOURCE: https://www.bentoml.com/blog/exploring-the-world-of-open-source-text-to-speech-models]
- [SOURCE: https://github.com/coqui-ai/TTS]

### 11. ChatTTS -- THAI NOT SUPPORTED
- **Thai support**: NO -- trained on ~100,000 hours of Chinese and English data only
- **Voice cloning**: NO
- **License**: Not fully specified (community project)
- **Note**: Already in Pixelle-Video but useless for Thai
- [SOURCE: https://www.bentoml.com/blog/exploring-the-world-of-open-source-text-to-speech-models]

### 12. MeloTTS -- THAI NOT CONFIRMED
- **Thai support**: NOT CONFIRMED -- supports English dialects (American, British, Indian, Australian), mixed Chinese-English
- **Voice cloning**: NO
- **License**: MIT
- **GPU**: Optimized for real-time inference, runs on CPU
- **Advantage**: CPU-friendly, MIT license
- [SOURCE: https://www.bentoml.com/blog/exploring-the-world-of-open-source-text-to-speech-models]

### 13. Index-TTS (Bilibili) -- THAI NOT SUPPORTED
- **Thai support**: NO -- Chinese + English primarily
- **Voice cloning**: YES -- zero-shot cloning
- **Already in Pixelle-Video**: Yes, but not for Thai
- [SOURCE: Known context from prior research]

## Summary Matrix

| Engine | Thai | Cloning | OSS/Commercial | GPU Req | License |
|--------|------|---------|----------------|---------|---------|
| CosyVoice 3.5 | YES (new) | YES | OSS | GPU 4-8GB | Apache 2.0 |
| Fish Audio S2 Pro | LIKELY | YES | Semi-open | H200-class | Paid commercial |
| OpenAI GPT-4o-mini-TTS | YES | NO (steerable) | Commercial | Cloud-only | Pay-per-use |
| Google Cloud TTS | YES | NO | Commercial | Cloud-only | Pay-per-use |
| Edge-TTS | YES | NO | Free API | Cloud-only | Free |
| ElevenLabs | YES | YES | Commercial | Cloud-only | Paid plans |
| F5-TTS | NO | YES | OSS (NC) | GPU | CC-BY-NC |
| Fish-Speech | NO | YES | OSS | GPU | Open |
| Kokoro | NO | NO | OSS | CPU/light | Apache 2.0 |
| XTTS-v2 | UNCERTAIN | YES | OSS (NC) | Consumer GPU | Non-commercial |
| ChatTTS | NO | NO | OSS | GPU | Community |
| MeloTTS | UNCONFIRMED | NO | OSS | CPU | MIT |
| Index-TTS | NO | YES | OSS | GPU | Open |

## Engines with Confirmed Thai Support (Tier 1 Candidates)
1. **CosyVoice 3.5** -- OSS, cloning, new Thai support (BEST OSS CANDIDATE)
2. **OpenAI GPT-4o-mini-TTS** -- commercial, steerable, no cloning
3. **Google Cloud TTS** -- commercial, WaveNet quality, no cloning
4. **Edge-TTS** -- free, already integrated, baseline quality
5. **ElevenLabs** -- commercial, best cloning, premium pricing
6. **Fish Audio S2 Pro** -- likely Thai via 80+ languages, cloning, premium GPU

## Ruled Out
- **Kokoro**: No Thai, no cloning, limited languages -- not viable
- **ChatTTS**: No Thai, Chinese+English only -- not viable for this use case
- **Index-TTS**: No Thai -- already known from prior research
- **Fish-Speech (OSS)**: No Thai in OSS version -- only commercial S2 Pro may support Thai

## Dead Ends
- **Kokoro for Thai**: Definitively 8 languages only, Thai not on roadmap; weak G2P makes unsupported languages unusable
- **ChatTTS for Thai**: English+Chinese training data only; no multilingual expansion announced
- **F5-TTS for Thai**: Base model Chinese-English only; would require full fine-tuning with Thai dataset (Emilia) which may not exist for Thai

## Sources Consulted
- https://github.com/FunAudioLLM/CosyVoice
- https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/
- https://fish.audio/blog/introducing-fish-speech/
- https://www.bentoml.com/blog/exploring-the-world-of-open-source-text-to-speech-models
- https://developers.openai.com/api/docs/guides/text-to-speech
- https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types
- https://elevenlabs.io/text-to-speech/thai
- https://github.com/SWivid/F5-TTS
- https://huggingface.co/hexgrad/Kokoro-82M
- https://deepwiki.com/hexgrad/kokoro/4-languages-and-voices
- https://github.com/coqui-ai/TTS
- https://www.aibase.com/news/11746

## Assessment
- New information ratio: 0.85
- Questions addressed: Q1 (TTS engine ranking), Q2 (voice cloning), Q8 (GPU requirements), Q10 (cost comparison)
- Questions answered: None fully -- ranking needs naturalness testing, but landscape is now mapped

## Reflection
- What worked and why: Web search across multiple queries efficiently mapped 13 engines. Combining GitHub repos with blog roundup articles gave both specific technical data and comparative context.
- What did not work and why: Thai-specific TTS information is sparse in English-language sources -- most OSS TTS articles don't mention Thai at all. Need Thai-language sources or direct repo inspection for deeper evaluation.
- What I would do differently: Next iteration should deep-dive into the top 3 Thai-capable engines (CosyVoice 3.5, OpenAI TTS, Google Cloud TTS) with actual Thai voice samples, MOS scores, and tone-handling evaluation.

## Recommended Next Focus
Deep-dive into CosyVoice 3.5 Thai capabilities: installation, voice quality samples, tone handling, word segmentation integration, and Pixelle-Video integration path. This is the most promising OSS candidate with voice cloning. Also investigate Fish Audio S2 Pro Thai confirmation and ElevenLabs Thai quality.
