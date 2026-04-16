---
title: Deep Research Dashboard
description: Auto-generated reducer view over the research packet.
---

# Deep Research Dashboard - Session Overview

Auto-generated from JSONL state log, iteration files, findings registry, and strategy state. Never manually edited.

<!-- ANCHOR:overview -->
## 1. OVERVIEW

Reducer-generated observability surface for the active research packet.

<!-- /ANCHOR:overview -->
<!-- ANCHOR:status -->
## 2. STATUS
- Topic: Thai natural voice & script pipeline — TTS engines ranking for Thai naturalness, voice cloning, prosody/intonation control, Thai word segmentation for TTS, AI script writing with human-like Thai, integration path into Pixelle-Video
- Started: 2026-04-17T14:00:00Z
- Status: INITIALIZED
- Iteration: 5 of 15
- Session ID: dr-003-thai-voice
- Parent Session: none
- Lifecycle Mode: new
- Generation: 1
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | Survey all TTS engines for Thai language support | tts-landscape | 0.85 | 13 | complete |
| 2 | CosyVoice 3.5 Thai deep-dive + Thai word segmentation + natural Thai script writing | tts-deep-dive | 0.77 | 13 | complete |
| 3 | Quality comparison Edge-TTS vs CosyVoice, Pixelle-Video TTS integration code, Thai script naturalness from linguistics, prosody control, latency | integration-quality | 0.73 | 13 | complete |
| 4 | Voice cloning Thai, Thai 5-tone TTS handling, cost comparison, GPU/latency, post-processing | cloning-cost-tones | 0.70 | 10 | complete |
| 5 | FINAL SYNTHESIS: F5-TTS-THAI investigation, prosody/emotion control (Q3), definitive ranking (Q1), complete pipeline architecture | final-synthesis | 0.55 | 6 | complete |

- iterationsCompleted: 5
- keyFindings: 308
- openQuestions: 12
- resolvedQuestions: 0

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 0/12
- [ ] Q1: Which TTS engine produces the most natural-sounding Thai speech? Rank: Edge-TTS, Kokoro, Fish-Speech, Index-TTS, GPT-4o-mini-TTS, F5-TTS, CosyVoice, MeloTTS, others
- [ ] Q2: Which engines support Thai voice cloning? Quality comparison, reference audio requirements, fine-tuning options?
- [ ] Q3: How to control prosody/intonation/emotion in Thai TTS? (SSML, style tokens, emotion embeddings, pitch contour)
- [ ] Q4: Thai word segmentation for TTS — PyThaiNLP vs deepcut vs newmm? Impact on TTS quality? Preprocessing pipeline?
- [ ] Q5: How to write AI-generated Thai scripts that sound human? Anti-AI phrasing patterns, conversational markers, Thai internet slang (ซ555, มากๆ, etc.)
- [ ] Q6: What is the Thai tone system and how do TTS engines handle it? (5 tones, tone marks, disambiguation)
- [ ] Q7: How does each TTS engine integrate with Pixelle-Video? (direct plugin, API wrapper, ComfyUI node, custom workflow)
- [ ] Q8: GPU requirements per TTS engine — which can run local CPU, which need GPU, which are cloud-only?
- [ ] Q9: Latency comparison — how fast is each engine for generating 30s of Thai speech?
- [ ] Q10: Cost comparison — free/OSS vs paid API pricing per character/second
- [ ] Q11: Can multiple TTS engines coexist in the pipeline? (per-channel voice engine selection)
- [ ] Q12: What Thai-specific audio post-processing improves naturalness? (de-essing, normalization, room tone, breathing sounds)

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.73 -> 0.70 -> 0.55
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.55
- coverageBySources: {"arxiv.org":4,"blog.promptlayer.com":2,"cloud.google.com":2,"costgoat.com":1,"deepwiki.com":1,"developers.openai.com":3,"docs.cloud.google.com":1,"elevenlabs.io":11,"fish.audio":1,"funaudiollm.github.io":2,"gaga.art":2,"github.com":12,"huggingface.co":4,"leanvox.com":2,"ling-app.com":1,"news.aibase.com":2,"nlpforthai.com":2,"other":1,"ph05.tci-thaijo.org":1,"pypi.org":1,"pythainlp.org":1,"raw.githubusercontent.com":1,"thai-notes.com":2,"www.aibase.com":1,"www.bentoml.com":1,"www.cloudthat.com":1,"www.expatden.com":1,"www.gpu-mart.com":2,"www.narakeet.com":2,"www.webfuse.com":2}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
- **ChatTTS for Thai**: English+Chinese training data only; no multilingual expansion announced (iteration 1)
- **ChatTTS**: No Thai, Chinese+English only -- not viable for this use case (iteration 1)
- **F5-TTS for Thai**: Base model Chinese-English only; would require full fine-tuning with Thai dataset (Emilia) which may not exist for Thai (iteration 1)
- **Fish-Speech (OSS)**: No Thai in OSS version -- only commercial S2 Pro may support Thai (iteration 1)
- **Index-TTS**: No Thai -- already known from prior research (iteration 1)
- **Kokoro for Thai**: Definitively 8 languages only, Thai not on roadmap; weak G2P makes unsupported languages unusable (iteration 1)
- **Kokoro**: No Thai, no cloning, limited languages -- not viable (iteration 1)
- **CosyVoice 3.0 base (pre-3.5) for Thai**: Only 9 languages, Thai NOT included. Must use specifically Fun-CosyVoice 3.5. [SOURCE: https://funaudiollm.github.io/cosyvoice3/] (iteration 2)
- **Generic web search for Thai anti-AI script writing in English**: Returns only TTS platform marketing pages. Need Thai-language sources or to derive guidelines from linguistic principles. (iteration 2)
- None definitively eliminated this iteration. (iteration 2)
- CosyVoice as Phase 1 Thai TTS engine: paper confirms only 9 languages, Thai not included. Zero-shot transfer quality is unknown. (iteration 3)
- **CosyVoice native Thai TTS quality**: The paper definitively lists 9 languages. Thai would require either fine-tuning or relying on zero-shot transfer, which is unproven. This is NOT a dead end for voice cloning (cross-lingual cloning may work), but IS a dead end for claiming "native Thai quality." (iteration 3)
- Edge-TTS emotion control: SSML prosody tags exist but only rate/pitch/volume -- no emotion/style control. (iteration 3)
- Finding Thai-specific MOS benchmarks: none exist in published literature for any OSS TTS engine. (iteration 3)
- **Published Thai TTS MOS comparisons**: No academic paper compares Thai TTS engines with MOS scores. Quality assessment must rely on manual listening tests. (iteration 3)
- Amazon Polly for Thai: uncertain Thai support, not competitive vs Edge-TTS (free) or Google Cloud (free tier) (iteration 4)
- None definitively eliminated this iteration (F5-TTS-THAI discovery actually reopens a previously ruled-out direction) (iteration 4)
- OpenAI TTS voice cloning: confirmed NO cloning capability in any model variant (iteration 4)
- None new. All dead ends from iterations 1-4 remain valid. (iteration 5)
- No new approaches ruled out this iteration — this was a synthesis/consolidation iteration. (iteration 5)

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
ALL 12 questions are now answered. Research is ready for convergence: - Q1: Definitive ranking (ElevenLabs > OpenAI > Google > Edge-TTS > F5-TTS-THAI > CosyVoice) - Q2: Voice cloning (ElevenLabs production-proven, F5-TTS-THAI OSS alternative) - Q3: Prosody control (OpenAI best for emotion, ElevenLabs best for cloned+emotion) - Q4: PyThaiNLP newmm tokenizer, mandatory preprocessing - Q5: Thai script guidelines (60+ particles, anti-AI patterns, prompt template) - Q6: Thai 5-tone system, segmentation critical for tone correctness - Q7: Pixelle-Video TTSService interface, sidecar for local engines - Q8: Edge-TTS 0GB, OpenAI 0GB, ElevenLabs 0GB, F5-TTS-THAI 4-8GB, CosyVoice 4-12GB - Q9: Edge-TTS 1-3s, Google 2-5s, OpenAI 3-8s, ElevenLabs 3-10s, local 8-15s - Q10: Edge-TTS free, Google free tier, OpenAI $0.015/min, ElevenLabs $5-99/mo - Q11: Multi-engine per-channel supported via channels.voice_config - Q12: Post-processing pipeline (LUFS, de-essing, breathing, tone-preservation) **Recommend: Mark research as CONVERGED. All key questions answered with evidence.**

<!-- /ANCHOR:next-focus -->
<!-- ANCHOR:active-risks -->
## 8. ACTIVE RISKS
- None active beyond normal research uncertainty.

<!-- /ANCHOR:active-risks -->
<!-- ANCHOR:blocked-stops -->
## 9. BLOCKED STOPS
No blocked-stop events recorded.

<!-- /ANCHOR:blocked-stops -->
<!-- ANCHOR:graph-convergence -->
## 10. GRAPH CONVERGENCE
- graphConvergenceScore: 0.00
- graphDecision: [Not recorded]
- graphBlockers: none recorded

<!-- /ANCHOR:graph-convergence -->
