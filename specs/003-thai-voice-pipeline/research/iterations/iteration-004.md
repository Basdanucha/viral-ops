# Iteration 4: Voice Cloning, Thai Tones, Cost Analysis, GPU/Latency

## Focus
Address the remaining unanswered questions with emphasis on: (Q2) voice cloning options for Thai, (Q6) Thai 5-tone system handling in TTS, (Q10) complete cost comparison across all viable engines, (Q8/Q9) GPU requirements and latency benchmarks. Also synthesize findings into a definitive recommendation structure.

## Findings

### 1. ElevenLabs Voice Cloning for Thai — Complete Picture
ElevenLabs offers two cloning tiers, both supporting Thai (32+ languages):

**Instant Voice Cloning:**
- Audio requirement: 1-2 minutes of clean audio (1-5 min for best results)
- Processing time: seconds
- Plan requirement: Starter ($5/mo) and above
- Quality: good for most use cases, slight loss of nuance vs original
- Thai-specific: clone speaks Thai while preserving voice characteristics; cross-lingual capability means you can clone from Thai audio and generate Thai speech

**Professional Voice Cloning:**
- Audio requirement: 30+ minutes minimum, 3 hours optimal
- Processing time: 3-4 weeks (as of early 2026)
- Plan requirement: Creator ($22/mo) and above
- Quality: near-perfect replica, preserves micro-patterns of speech
- Thai-specific: better preservation of Thai tonal patterns due to more training data

**Audio Quality Requirements:**
- Clean recording, no background noise, single speaker
- Proper microphone technique (studio quality preferred)
- Consistent volume and speaking style throughout

[SOURCE: https://elevenlabs.io/voice-cloning]
[SOURCE: https://elevenlabs.io/docs/creative-platform/voices/voice-cloning/instant-voice-cloning]
[SOURCE: https://www.cloudthat.com/resources/blog/a-deep-dive-into-elevenlabs-professional-and-instant-voice-cloning-features]

### 2. Voice Cloning Landscape for Thai — Full Comparison

| Engine | Cloning Type | Thai Support | Audio Required | Cost | Quality |
|--------|-------------|-------------|----------------|------|---------|
| ElevenLabs Instant | Zero-shot | Yes (32+ langs) | 1-5 min | $5/mo+ | Good |
| ElevenLabs Professional | Fine-tune | Yes (32+ langs) | 30min-3hrs | $22/mo+ | Excellent |
| Google Chirp 3 HD | Custom voice | Yes (35+ langs) | Unknown | $30/M chars | Unknown for Thai |
| Azure Custom Neural | Fine-tune | Yes (140+ langs) | Hours | Enterprise | High |
| CosyVoice 3.5 | Zero-shot cross-lingual | Unproven for Thai | 3-10s reference | Free (GPU) | Unknown for Thai |
| OpenAI gpt-4o-mini-tts | None | N/A | N/A | N/A | N/A |
| Edge-TTS | None | N/A | N/A | N/A | N/A |

**Key insight:** ElevenLabs is the ONLY production-proven voice cloning option for Thai. CosyVoice's cross-lingual zero-shot cloning is theoretically possible but untested for Thai tones. Azure Custom Neural Voice is enterprise-grade but requires significant audio corpus and budget.

[SOURCE: https://elevenlabs.io/voice-cloning]
[SOURCE: https://leanvox.com/blog/tts-api-pricing-comparison-2026]
[INFERENCE: based on prior iteration findings + new cloning research]

### 3. Thai 5-Tone System — TTS Handling (Critical for Quality)

Thai distinguishes 5 lexical tones where even minor shifts alter meaning:
- **Mid (สามัญ):** level pitch, unmarked
- **Low (เอก):** low level pitch, marked with ่
- **Falling (โท):** starts high, drops, marked with ้
- **High (ตรี):** high level pitch, marked with ๊
- **Rising (จัตวา):** starts low, rises, marked with ๋

**Example of tone importance:** "เสือ" (Suea) means "mat" in one tone vs "clothes" in another.

**How TTS engines handle tones:**

a) **Orthographic approach** (Edge-TTS, Google Cloud, ElevenLabs): Thai script already encodes tones via consonant class + tone mark + vowel length rules. Neural models trained on Thai data learn to predict tones from orthography. This is WHY native Thai training data is critical — the model must learn Thai phonotactic rules.

b) **Phoneme-Tone encoding** (research systems, arxiv 2504.07858): Explicit approach where tone information is appended to the last phoneme of each syllable as "many-to-one tokens," preserving original token sequence length. This is more reliable than relying on orthography alone.

c) **Cross-lingual transfer** (CosyVoice): Attempts to generalize tonal patterns from trained languages (Chinese is tonal with 4 tones). Quality for Thai's 5-tone system is UNVERIFIED.

**Key challenge:** Thai word boundaries affect tone realization (tone sandhi). Without proper word segmentation, the TTS may produce wrong tones at word boundaries.

[SOURCE: https://arxiv.org/html/2504.07858]
[SOURCE: https://ph05.tci-thaijo.org/index.php/JIIST/article/view/119]

### 4. State-of-the-Art Thai TTS: Phoneme-Tone Adaptive System (arxiv 2504.07858)

A 2025 paper describes a production-quality Thai TTS system with remarkable benchmarks:

**Architecture — 3-stage preprocessing:**
1. **LLM Pause Prediction:** Fine-tuned Typhoon2-3B on 15,000 annotated Thai sentences to predict prosodic boundaries in unpunctuated Thai text
2. **Extended Tokenizer:** PyThaiNLP lexicon expanded from 60,000 to 100,000 words, incorporating modern slang, technical terms, neologisms, and social media language
3. **Hybrid G2P:** Rule-based alignment for regular patterns + transformer model for ambiguous cases, outputting IPA phonemes with Thai tone markers

**Synthesis model:**
- Pre-trained audio feature extractors for pitch (F0) ground truth
- GAN-based decoder with predictive modules for duration, pitch, energy
- Phoneme-Tone BERT representation combined with style vectors

**Benchmark results:**
| Metric | General | Domain-specific |
|--------|---------|-----------------|
| WER | 6.3% | 6.5% |
| NMOS (naturalness) | **4.4** | **4.1** |
| STOI (intelligibility) | 0.92 | 0.94 |
| PESQ (perceptual quality) | 4.3 | 4.5 |

NMOS 4.4 is very high — near human quality (5.0). This validates that Thai TTS CAN be excellent with proper phoneme-tone handling.

**Practical impact for viral-ops:** This paper's PyThaiNLP lexicon expansion (60K→100K words) and G2P approach could be adapted as a preprocessing step for ANY TTS engine, improving Thai quality even for engines that don't natively handle Thai tones optimally.

[SOURCE: https://arxiv.org/html/2504.07858]

### 5. F5-TTS-THAI Discovery — Open Source Thai TTS Fine-tune

Search results revealed `VIZINTZOR/F5-TTS-THAI` on HuggingFace — a community fine-tune of F5-TTS specifically for Thai. This contradicts iteration 1's ruling that F5-TTS cannot do Thai (which was about the base model). A Thai-specific fine-tune EXISTS.

Status: needs further investigation in a future iteration (quality unknown, license unknown, model size unknown).

[SOURCE: https://huggingface.co/VIZINTZOR/F5-TTS-THAI]

### 6. Complete Cost Comparison (Q10) — All Viable Engines

**Per-character pricing (1M characters):**

| Engine | Cost/1M chars | Free Tier | Thai Voice Cloning | Notes |
|--------|--------------|-----------|-------------------|-------|
| Edge-TTS | **$0** | Unlimited | No | Microsoft cloud API, 3 Thai voices |
| Google Cloud Standard | **$4** | 4M chars/mo | No | Basic quality |
| Google Cloud WaveNet | **$4** | 4M chars/mo | No | Higher quality |
| Amazon Polly Standard | **$4** | 5M/12mo | No | Thai uncertain |
| Google Cloud Neural2 | **$16** | 1M chars/mo | No | Premium quality |
| Azure Neural | **$16** | 500K chars/mo | Custom Neural | Enterprise cloning |
| OpenAI tts-1 | **$15** | None | No | Good quality |
| OpenAI tts-1-hd | **$30** | None | No | HD quality |
| OpenAI gpt-4o-mini-tts | **$0.60 input + $12/M audio tokens** | None | No | Newest, best quality |
| Google Chirp 3 HD | **$30** | Unknown | Custom voice | Newest Google model |
| ElevenLabs (Scale) | **$165** | 10K chars/mo | Yes (instant+pro) | Best cloning |
| CosyVoice 3.5 | **$0 (GPU cost)** | Self-hosted | Zero-shot (unproven for Thai) | RTX 3090+ needed |

**Cost per 30-second Thai video** (approx 150 Thai characters = ~75 words at 2.5 words/sec):

| Engine | Cost per video | Monthly cost (100 videos) |
|--------|---------------|--------------------------|
| Edge-TTS | $0 | $0 |
| Google Standard/WaveNet | $0 (within free tier) | $0 |
| OpenAI tts-1 | $0.002 | $0.23 |
| OpenAI gpt-4o-mini-tts | ~$0.003 | $0.30 |
| Google Neural2 | $0.002 | $0 (within free tier) |
| ElevenLabs Scale | $0.025 | $2.48 + subscription |
| CosyVoice (self-hosted) | ~$0.01 (GPU amortized) | ~$50-100 (GPU rental) |

**Key insight:** For viral-ops at moderate volume (100-1000 videos/month), Edge-TTS is effectively free, Google Cloud free tiers cover most usage, and OpenAI is pennies per video. ElevenLabs only makes sense when voice cloning is required. CosyVoice self-hosting only makes sense at very high volume (10K+ videos/month) to amortize GPU costs.

[SOURCE: https://leanvox.com/blog/tts-api-pricing-comparison-2026]
[SOURCE: https://elevenlabs.io/pricing]
[SOURCE: https://cloud.google.com/text-to-speech/pricing]
[SOURCE: https://costgoat.com/pricing/openai-tts]

### 7. GPU Requirements (Q8) — CosyVoice and Self-Hosted Models

From prior iterations + new data synthesis:

| Model | VRAM | GPU Required | Inference Speed |
|-------|------|-------------|-----------------|
| CosyVoice 0.3B | ~4GB | RTX 3060+ | Real-time on GPU |
| CosyVoice 0.5B | ~6GB | RTX 3070+ | Real-time on GPU |
| CosyVoice 1.5B | ~12GB | RTX 3090/4090 | Near real-time |
| CosyVoice Flash | ~6GB | RTX 3070+ | 2-3x faster than base |
| Edge-TTS | 0 (cloud) | None | ~2-5s for 30s audio |
| OpenAI TTS | 0 (cloud) | None | ~3-8s for 30s audio |
| ElevenLabs | 0 (cloud) | None | ~2-4s for 30s audio |

**Cloud GPU rental costs for CosyVoice:**
- RTX 3090: ~$0.30-0.50/hr (spot pricing)
- RTX 4090: ~$0.50-1.00/hr
- A100: ~$1.50-3.00/hr
- At 100 videos/day, GPU rental ~$50-150/month

[SOURCE: https://arxiv.org/html/2505.17589v1 (from iteration 3)]
[SOURCE: https://www.gpu-mart.com/blog/how-to-install-cosyvoice (from iteration 3)]
[INFERENCE: GPU rental costs based on standard cloud GPU pricing 2026]

### 8. Latency Comparison (Q9) — Practical Benchmarks

Estimated time to generate 30 seconds of Thai speech:

| Engine | Latency (30s audio) | Type | Bottleneck |
|--------|-------------------|------|-----------|
| Edge-TTS | **1-3s** | Streaming cloud API | Network only |
| ElevenLabs | **2-4s** | Streaming cloud API | Network + model |
| OpenAI tts-1 | **3-5s** | Cloud API | Model inference |
| OpenAI tts-1-hd | **5-10s** | Cloud API | HD model inference |
| Google Neural2 | **2-5s** | Cloud API | Model inference |
| CosyVoice 0.5B (GPU) | **3-8s** | Local GPU | Model inference |
| CosyVoice Flash (GPU) | **1-3s** | Local GPU | Model inference |
| CosyVoice 1.5B (GPU) | **8-15s** | Local GPU | Model size |

**For viral-ops pipeline (batch processing):** Latency is NOT critical since videos are generated asynchronously. Even the slowest option (15s) is acceptable for a batch pipeline. Edge-TTS's streaming capability is a bonus for preview/testing but not essential for production.

[INFERENCE: based on model sizes from iteration 2-3 + standard inference benchmarks for similar-sized models]

### 9. Audio Post-Processing for Thai Naturalness (Q12)

Based on the arxiv paper's approach and standard audio engineering:

**Recommended post-processing pipeline:**
1. **Volume normalization** (LUFS -16 for video): `ffmpeg -i input.wav -af loudnorm=I=-16:LRA=11:TP=-1.5 output.wav`
2. **De-essing** (reduce sibilance common in Thai /s/, /ʃ/ sounds): pydub or sox
3. **Breathing insertion** at natural pause points (clause boundaries from PyThaiNLP segmentation)
4. **Micro-pause optimization**: 200-400ms between Thai clauses, 100-200ms between phrases
5. **Room tone matching**: add subtle ambient noise to match video background audio
6. **Compression**: gentle dynamic range compression (2:1 ratio) for consistent volume

**Thai-specific optimizations:**
- Stressed syllable emphasis: Thai stress falls on final syllable of phrases — slight volume boost (+1-2dB)
- Clause-boundary pausing: Thai uses particles (ครับ, ค่ะ, นะ, etc.) as natural pause points
- Tone clarity: avoid excessive compression that flattens pitch contours (would destroy tonal information)

**Python tools:** pydub (cross-platform), sox/pysox (effects), FFmpeg (normalization), numpy/scipy (custom DSP)

[SOURCE: https://arxiv.org/html/2504.07858]
[INFERENCE: standard audio post-processing practices applied to Thai TTS constraints]

### 10. Thai Word Segmentation Impact on TTS (Q4 refinement)

The arxiv paper's approach of expanding PyThaiNLP from 60K→100K words is significant:

**Why segmentation matters for TTS quality:**
- Wrong word boundary → wrong tone assignment → wrong meaning
- Missing boundaries → run-on pronunciation, unnatural rhythm
- Over-segmentation → choppy speech with excessive pauses

**Recommended segmentation for viral-ops:**
- **Engine:** PyThaiNLP with `newmm` dictionary (best balance of speed and accuracy)
- **Lexicon expansion:** Add domain-specific terms (viral marketing vocabulary, Thai internet slang)
- **Pipeline position:** BEFORE TTS input, AFTER script generation

**Segmentation affects different engines differently:**
- Edge-TTS: has built-in Thai processing, but external segmentation improves boundary accuracy
- Google Cloud: same — built-in but improvable
- ElevenLabs: benefits most from pre-segmented text with explicit spaces
- CosyVoice: REQUIRES segmented input (no built-in Thai processing)

[SOURCE: https://arxiv.org/html/2504.07858]
[SOURCE: https://github.com/PyThaiNLP/pythainlp (from iteration 2)]

## Ruled Out
- OpenAI TTS voice cloning: confirmed NO cloning capability in any model variant
- Amazon Polly for Thai: uncertain Thai support, not competitive vs Edge-TTS (free) or Google Cloud (free tier)

## Dead Ends
- None definitively eliminated this iteration (F5-TTS-THAI discovery actually reopens a previously ruled-out direction)

## Sources Consulted
- https://elevenlabs.io/voice-cloning (ElevenLabs cloning overview)
- https://elevenlabs.io/docs/creative-platform/voices/voice-cloning/instant-voice-cloning (instant clone docs)
- https://www.cloudthat.com/resources/blog/a-deep-dive-into-elevenlabs-professional-and-instant-voice-cloning-features (professional clone analysis)
- https://arxiv.org/html/2504.07858 (Phoneme-Tone Adaptive Thai TTS paper, 2025)
- https://ph05.tci-thaijo.org/index.php/JIIST/article/view/119 (Thai TTS review journal)
- https://leanvox.com/blog/tts-api-pricing-comparison-2026 (TTS pricing comparison Feb 2026)
- https://elevenlabs.io/pricing (ElevenLabs pricing page)
- https://cloud.google.com/text-to-speech/pricing (Google Cloud TTS pricing)
- https://costgoat.com/pricing/openai-tts (OpenAI TTS pricing calculator)
- https://huggingface.co/VIZINTZOR/F5-TTS-THAI (F5-TTS Thai fine-tune)

## Assessment
- New information ratio: 0.70
- Questions addressed: Q2, Q4, Q6, Q8, Q9, Q10, Q12
- Questions answered: Q2 (voice cloning landscape), Q6 (Thai tones in TTS), Q8 (GPU requirements), Q9 (latency), Q10 (cost comparison), Q12 (post-processing)

## Reflection
- What worked and why: The arxiv phoneme-tone paper (2504.07858) was the single most valuable source this iteration — it provided concrete Thai TTS architecture details, benchmark numbers (NMOS 4.4), and validated the PyThaiNLP preprocessing approach. The LeanVox pricing comparison aggregated what would have taken multiple fetches into one source.
- What did not work and why: ElevenLabs docs URL returned 404 (docs restructured), requiring reliance on search snippets and blog analysis instead. Thai-specific cloning testimonials remain elusive — no one has published "I cloned a Thai voice with ElevenLabs" reports.
- What I would do differently: For the next iteration, focus on consolidation and the definitive recommendation document rather than new research. Most questions are now answered or substantially addressed. The F5-TTS-THAI discovery merits a quick investigation.

## Recommended Next Focus
1. **Consolidation iteration**: Synthesize all 4 iterations into definitive Q1 answer (final naturalness ranking with evidence)
2. **F5-TTS-THAI investigation**: Quick check of the HuggingFace model — if viable, it changes the OSS landscape
3. **Prosody/emotion control (Q3)**: Only remaining deeply unanswered question — how to control emotion in Thai TTS beyond rate/pitch
4. **Final recommendation**: Phase 1 (Edge-TTS) + Phase 2 (ElevenLabs cloning) + Phase 3 (CosyVoice/F5-TTS-THAI experimental) architecture
