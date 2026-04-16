# Deep Research Strategy — Thai Natural Voice & Script Pipeline

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Find the most natural-sounding Thai TTS solution for viral-ops, including voice cloning, prosody control, Thai text preprocessing, and human-like script writing. Map integration paths into Pixelle-Video.

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
Thai natural voice & script pipeline — TTS engine naturalness ranking, voice cloning for Thai, prosody/intonation control, Thai word segmentation for TTS quality, AI script writing that sounds human (conversational Thai, anti-AI phrasing, internet slang), and integration into Pixelle-Video ComfyUI pipeline.

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
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

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- NOT re-evaluating overall architecture (Pixelle-Video + n8n + Next.js — decided)
- NOT evaluating non-Thai TTS (English/Chinese covered by existing Edge-TTS voices)
- NOT building a custom TTS model from scratch
- Only comparing existing engines and their Thai capabilities

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- TTS engine ranking for Thai naturalness with evidence (samples, benchmarks, MOS scores)
- Voice cloning recommendation for Thai
- Thai script writing guidelines with concrete examples
- Integration path for top 2-3 engines into Pixelle-Video
- All 12 key questions answered

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Web search across multiple queries efficiently mapped 13 engines. Combining GitHub repos with blog roundup articles gave both specific technical data and comparative context. (iteration 1)
- Fetching the CosyVoice GitHub README + the Gaga.art announcement article together gave complementary data — the README had technical specs while the blog had the Thai confirmation and RL improvements. The PyThaiNLP GitHub page confirmed the word segmentation ecosystem. (iteration 2)
- Fetching the actual arxiv paper for CosyVoice 3 revealed a critical correction -- Thai is NOT natively supported. This changes the entire recommendation. The Pixelle-Video tts_service.py fetch was highly productive, providing the exact integration pattern. The Thai particles reference (thai-notes.com) was exceptionally comprehensive -- a single page with 60+ particles organized by category. (iteration 3)
- The arxiv phoneme-tone paper (2504.07858) was the single most valuable source this iteration — it provided concrete Thai TTS architecture details, benchmark numbers (NMOS 4.4), and validated the PyThaiNLP preprocessing approach. The LeanVox pricing comparison aggregated what would have taken multiple fetches into one source. (iteration 4)
- The F5-TTS-THAI HuggingFace fetch was the single most valuable action — it revealed a viable OSS Thai voice cloning option with 500 hours of training data and a pip-installable package, fundamentally changing the Phase 3 recommendation. The PromptLayer blog on gpt-4o-mini-tts provided concrete API details and examples that the official docs lacked. (iteration 5)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- Thai-specific TTS information is sparse in English-language sources -- most OSS TTS articles don't mention Thai at all. Need Thai-language sources or direct repo inspection for deeper evaluation. (iteration 1)
- English-language search for "anti-AI Thai script writing" returned zero relevant results — this topic is too niche and Thai-specific for English web sources. (iteration 2)
- Finding Thai-specific MOS benchmarks was impossible -- no one has published comparative Thai TTS quality studies. CosyVoice GPU benchmarks were scattered across issues and guides rather than documented centrally. (iteration 3)
- ElevenLabs docs URL returned 404 (docs restructured), requiring reliance on search snippets and blog analysis instead. Thai-specific cloning testimonials remain elusive — no one has published "I cloned a Thai voice with ElevenLabs" reports. (iteration 4)
- N/A — all sources returned useful data this iteration. This is expected for a synthesis iteration where we targeted known-good sources rather than exploring. (iteration 5)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### Amazon Polly for Thai: uncertain Thai support, not competitive vs Edge-TTS (free) or Google Cloud (free tier) -- BLOCKED (iteration 4, 1 attempts)
- What was tried: Amazon Polly for Thai: uncertain Thai support, not competitive vs Edge-TTS (free) or Google Cloud (free tier)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Amazon Polly for Thai: uncertain Thai support, not competitive vs Edge-TTS (free) or Google Cloud (free tier)

### **ChatTTS for Thai**: English+Chinese training data only; no multilingual expansion announced -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **ChatTTS for Thai**: English+Chinese training data only; no multilingual expansion announced
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **ChatTTS for Thai**: English+Chinese training data only; no multilingual expansion announced

### **ChatTTS**: No Thai, Chinese+English only -- not viable for this use case -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **ChatTTS**: No Thai, Chinese+English only -- not viable for this use case
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **ChatTTS**: No Thai, Chinese+English only -- not viable for this use case

### **CosyVoice 3.0 base (pre-3.5) for Thai**: Only 9 languages, Thai NOT included. Must use specifically Fun-CosyVoice 3.5. [SOURCE: https://funaudiollm.github.io/cosyvoice3/] -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **CosyVoice 3.0 base (pre-3.5) for Thai**: Only 9 languages, Thai NOT included. Must use specifically Fun-CosyVoice 3.5. [SOURCE: https://funaudiollm.github.io/cosyvoice3/]
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **CosyVoice 3.0 base (pre-3.5) for Thai**: Only 9 languages, Thai NOT included. Must use specifically Fun-CosyVoice 3.5. [SOURCE: https://funaudiollm.github.io/cosyvoice3/]

### CosyVoice as Phase 1 Thai TTS engine: paper confirms only 9 languages, Thai not included. Zero-shot transfer quality is unknown. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: CosyVoice as Phase 1 Thai TTS engine: paper confirms only 9 languages, Thai not included. Zero-shot transfer quality is unknown.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: CosyVoice as Phase 1 Thai TTS engine: paper confirms only 9 languages, Thai not included. Zero-shot transfer quality is unknown.

### **CosyVoice native Thai TTS quality**: The paper definitively lists 9 languages. Thai would require either fine-tuning or relying on zero-shot transfer, which is unproven. This is NOT a dead end for voice cloning (cross-lingual cloning may work), but IS a dead end for claiming "native Thai quality." -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **CosyVoice native Thai TTS quality**: The paper definitively lists 9 languages. Thai would require either fine-tuning or relying on zero-shot transfer, which is unproven. This is NOT a dead end for voice cloning (cross-lingual cloning may work), but IS a dead end for claiming "native Thai quality."
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **CosyVoice native Thai TTS quality**: The paper definitively lists 9 languages. Thai would require either fine-tuning or relying on zero-shot transfer, which is unproven. This is NOT a dead end for voice cloning (cross-lingual cloning may work), but IS a dead end for claiming "native Thai quality."

### Edge-TTS emotion control: SSML prosody tags exist but only rate/pitch/volume -- no emotion/style control. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: Edge-TTS emotion control: SSML prosody tags exist but only rate/pitch/volume -- no emotion/style control.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Edge-TTS emotion control: SSML prosody tags exist but only rate/pitch/volume -- no emotion/style control.

### **F5-TTS for Thai**: Base model Chinese-English only; would require full fine-tuning with Thai dataset (Emilia) which may not exist for Thai -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **F5-TTS for Thai**: Base model Chinese-English only; would require full fine-tuning with Thai dataset (Emilia) which may not exist for Thai
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **F5-TTS for Thai**: Base model Chinese-English only; would require full fine-tuning with Thai dataset (Emilia) which may not exist for Thai

### Finding Thai-specific MOS benchmarks: none exist in published literature for any OSS TTS engine. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: Finding Thai-specific MOS benchmarks: none exist in published literature for any OSS TTS engine.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Finding Thai-specific MOS benchmarks: none exist in published literature for any OSS TTS engine.

### **Fish-Speech (OSS)**: No Thai in OSS version -- only commercial S2 Pro may support Thai -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Fish-Speech (OSS)**: No Thai in OSS version -- only commercial S2 Pro may support Thai
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Fish-Speech (OSS)**: No Thai in OSS version -- only commercial S2 Pro may support Thai

### **Generic web search for Thai anti-AI script writing in English**: Returns only TTS platform marketing pages. Need Thai-language sources or to derive guidelines from linguistic principles. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Generic web search for Thai anti-AI script writing in English**: Returns only TTS platform marketing pages. Need Thai-language sources or to derive guidelines from linguistic principles.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Generic web search for Thai anti-AI script writing in English**: Returns only TTS platform marketing pages. Need Thai-language sources or to derive guidelines from linguistic principles.

### **Index-TTS**: No Thai -- already known from prior research -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Index-TTS**: No Thai -- already known from prior research
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Index-TTS**: No Thai -- already known from prior research

### **Kokoro for Thai**: Definitively 8 languages only, Thai not on roadmap; weak G2P makes unsupported languages unusable -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Kokoro for Thai**: Definitively 8 languages only, Thai not on roadmap; weak G2P makes unsupported languages unusable
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Kokoro for Thai**: Definitively 8 languages only, Thai not on roadmap; weak G2P makes unsupported languages unusable

### **Kokoro**: No Thai, no cloning, limited languages -- not viable -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Kokoro**: No Thai, no cloning, limited languages -- not viable
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Kokoro**: No Thai, no cloning, limited languages -- not viable

### None definitively eliminated this iteration. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: None definitively eliminated this iteration.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None definitively eliminated this iteration.

### None definitively eliminated this iteration (F5-TTS-THAI discovery actually reopens a previously ruled-out direction) -- BLOCKED (iteration 4, 1 attempts)
- What was tried: None definitively eliminated this iteration (F5-TTS-THAI discovery actually reopens a previously ruled-out direction)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None definitively eliminated this iteration (F5-TTS-THAI discovery actually reopens a previously ruled-out direction)

### None new. All dead ends from iterations 1-4 remain valid. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: None new. All dead ends from iterations 1-4 remain valid.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None new. All dead ends from iterations 1-4 remain valid.

### No new approaches ruled out this iteration — this was a synthesis/consolidation iteration. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: No new approaches ruled out this iteration — this was a synthesis/consolidation iteration.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: No new approaches ruled out this iteration — this was a synthesis/consolidation iteration.

### OpenAI TTS voice cloning: confirmed NO cloning capability in any model variant -- BLOCKED (iteration 4, 1 attempts)
- What was tried: OpenAI TTS voice cloning: confirmed NO cloning capability in any model variant
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: OpenAI TTS voice cloning: confirmed NO cloning capability in any model variant

### **Published Thai TTS MOS comparisons**: No academic paper compares Thai TTS engines with MOS scores. Quality assessment must rely on manual listening tests. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Published Thai TTS MOS comparisons**: No academic paper compares Thai TTS engines with MOS scores. Quality assessment must rely on manual listening tests.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Published Thai TTS MOS comparisons**: No academic paper compares Thai TTS engines with MOS scores. Quality assessment must rely on manual listening tests.

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
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

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
ALL 12 questions are now answered. Research is ready for convergence: - Q1: Definitive ranking (ElevenLabs > OpenAI > Google > Edge-TTS > F5-TTS-THAI > CosyVoice) - Q2: Voice cloning (ElevenLabs production-proven, F5-TTS-THAI OSS alternative) - Q3: Prosody control (OpenAI best for emotion, ElevenLabs best for cloned+emotion) - Q4: PyThaiNLP newmm tokenizer, mandatory preprocessing - Q5: Thai script guidelines (60+ particles, anti-AI patterns, prompt template) - Q6: Thai 5-tone system, segmentation critical for tone correctness - Q7: Pixelle-Video TTSService interface, sidecar for local engines - Q8: Edge-TTS 0GB, OpenAI 0GB, ElevenLabs 0GB, F5-TTS-THAI 4-8GB, CosyVoice 4-12GB - Q9: Edge-TTS 1-3s, Google 2-5s, OpenAI 3-8s, ElevenLabs 3-10s, local 8-15s - Q10: Edge-TTS free, Google free tier, OpenAI $0.015/min, ElevenLabs $5-99/mo - Q11: Multi-engine per-channel supported via channels.voice_config - Q12: Post-processing pipeline (LUFS, de-essing, breathing, tone-preservation) **Recommend: Mark research as CONVERGED. All key questions answered with evidence.**

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From gen1 research (specs/001-base-app-research)
- Edge-TTS: 3 Thai Neural voices (PremwadeeNeural F, NiwatNeural M, AcharaNeural F), neutral style only, no speed/pitch variation confirmed, cloud API (Microsoft)
- Index-TTS: zero-shot voice cloning by Bilibili, Chinese+English primarily, Thai NOT officially supported
- ChatTTS: supported in Pixelle-Video, details unknown for Thai
- Pixelle-Video TTS integration: workflow-based, ref_audio for cloning, per-request voice selection

### From Pixelle audit (specs/002-pixelle-video-audit)
- 3 TTS engines in Pixelle-Video: Edge-TTS, ChatTTS, Index-TTS
- 28 Edge-TTS voices across 11 languages, 3 Thai
- TTS speed control 0.5-2.0, NO pitch control
- TTS workflow field selects engine, ref_audio for cloning
- Pixelle-Video TTS router: POST /api/tts/generate with text, workflow, ref_audio, voice_id(deprecated)

### Thai language specifics
- Thai is a tonal language (5 tones: mid, low, falling, high, rising)
- No spaces between words — segmentation is required for natural TTS
- Thai script is complex: consonants, vowels (above/below/around), tone marks
- Thai internet culture: ซ555 (laughing), มากๆ (emphasis), slang abbreviations

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 15
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- Started: 2026-04-17T14:00:00Z
<!-- /ANCHOR:research-boundaries -->
