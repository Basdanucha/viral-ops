# Spec: Thai Natural Voice & Script Pipeline

## Requirements
<!-- DR-SEED:REQUIREMENTS -->
Research and design the Thai voice and script pipeline for viral-ops — finding the most natural-sounding TTS engines for Thai, voice cloning capabilities, prosody control, Thai word segmentation for TTS quality, and AI script writing that sounds human (anti-AI phrasing, conversational tone, Thai internet slang). Integration path into Pixelle-Video's ComfyUI pipeline.

## Scope
<!-- DR-SEED:SCOPE -->
- Rank TTS engines by Thai naturalness (Edge-TTS, Kokoro, Fish-Speech, Index-TTS, GPT-4o-mini-TTS, others)
- Evaluate voice cloning for Thai (which engines support it, quality, requirements)
- Research prosody/intonation control for Thai tonal language
- Thai word segmentation tools for TTS preprocessing (PyThaiNLP, deepcut, newmm)
- AI script writing patterns for natural Thai (anti-AI detection, conversational style, slang)
- Integration path: how each TTS option plugs into Pixelle-Video's workflow

## Open Questions
All 12 questions answered across 5 autonomous iterations.

## Research Context
Deep research **complete**. Canonical findings in `research/research.md` (548 lines).

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Research Findings Summary (5 iterations, 12 questions)

### Thai TTS Engine Naturalness Ranking
| Rank | Engine | Score | Thai | Cloning | Cost | Best For |
|------|--------|-------|------|---------|------|----------|
| 1 | **ElevenLabs** | 9.0 | Full | Best | $5-99/mo | Cloned voice persona |
| 2 | **OpenAI TTS** | 8.5 | Full | No | $0.60-2.40/M | Emotion/style control |
| 3 | **Google Cloud** | 7.5 | WaveNet/Neural2 | No | $4-16/M | High quality baseline |
| 4 | **Edge-TTS** | 7.0 | 3 Neural voices | No | Free | Phase 1 default |
| 5 | **F5-TTS-THAI** | 6.0 | Fine-tuned (500h) | Clone (2-8s ref) | Free (OSS) | Self-hosted cloning |
| 6 | **CosyVoice 3.5** | 5.0 | Cross-lingual | Zero-shot | Free (OSS) | Experimental |

**Ruled out**: Kokoro, ChatTTS, Fish-Speech OSS, F5-TTS base, Index-TTS, MeloTTS (no Thai)

### Phase Recommendation
- **Phase 1**: Edge-TTS (free, proven, 3 Thai voices) + OpenAI TTS (emotion control, affordable)
- **Phase 2**: ElevenLabs (voice cloning for per-channel persona)
- **Phase 3**: F5-TTS-THAI self-hosted (full OSS, zero cost at scale)

### Thai Script Writing
- 60+ conversational particles cataloged (นะ, ค่ะ, ครับ, เลย, มั้ย, ล่ะ, สิ, etc.)
- Anti-AI patterns: avoid formal register, add fillers (คือ, แบบ), use internet markers (555, มากๆ)
- LLM prompt template created for natural viral Thai scripts

### Pipeline Architecture
```
Thai script (LLM + persona prompt)
  → PyThaiNLP segmentation (newmm tokenizer)
    → TTS engine (per-channel: Edge-TTS / OpenAI / ElevenLabs / F5-TTS)
      → Post-processing (LUFS normalize, de-ess, breathing, tone-preserve)
        → Output audio file
```

### Key Technical Findings
- Thai word segmentation (PyThaiNLP) is **mandatory** — affects tone correctness at word boundaries
- Thai 5-tone system handled via orthographic inference (commercial) or phoneme-tone encoding (research)
- CosyVoice Thai support **NOT natively confirmed** (9 languages, cross-lingual transfer only)
- F5-TTS-THAI (HuggingFace: VIZINTZOR/F5-TTS-THAI) — community fine-tune with 500h Thai data, CC-BY-4.0
- OpenAI gpt-4o-mini-tts `instructions` parameter (2,000 tokens) = best emotion steerability
- Pixelle-Video integration: TTSService interface mapped, new engines via sidecar FastAPI or custom workflow
<!-- END GENERATED: deep-research/spec-findings -->
