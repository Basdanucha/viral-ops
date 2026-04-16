# Iteration 3: Quality Comparison, Pixelle-Video Integration, Thai Script Naturalness, Prosody Control

## Focus
Finalize the Edge-TTS vs CosyVoice quality ranking, map the concrete integration path into Pixelle-Video, derive natural Thai script writing guidelines from linguistic principles (since anti-AI English sources were exhausted), and document prosody/emotion control capabilities and latency characteristics.

## Findings

### 1. CosyVoice 3 Does NOT Officially Support Thai (Correction)
The CosyVoice 3 paper (arxiv 2505.17589) lists exactly 9 languages: Chinese, English, Japanese, Korean, German, French, Russian, Italian, Spanish -- plus 18+ Chinese dialects. **Thai is NOT among them.** The earlier "Thai confirmed" claim from iteration 2 (via gaga.art blog) appears to reference the "42+ languages" marketing claim for the broader Fun-CosyVoice 3.5 release, but the actual paper and model cards do not list Thai as a trained/evaluated language. This is a critical correction: CosyVoice Thai support is unverified at the model level and would rely on zero-shot cross-lingual transfer rather than native training.
[SOURCE: https://arxiv.org/html/2505.17589v1]

### 2. CosyVoice MOS Benchmarks (Chinese/English only)
- Chinese MOS: ~4.45+ (CosyVoice 3-1.5B), near human baseline
- English MOS: matches/exceeds human speech
- CER (Chinese): 0.71% on SEED test-zh
- WER (English): 1.45% on SEED test-en
- NO Thai MOS scores exist -- no Thai evaluation was conducted
- Training: 1,000,000 hours of speech data, but coverage is the 9 listed languages
[SOURCE: https://arxiv.org/html/2505.17589v1]

### 3. CosyVoice GPU/VRAM and Inference Speed
- **0.5B model**: ~8GB VRAM minimum, runs on consumer GPUs (RTX 3060+)
- **1.5B model**: likely needs 16GB+ VRAM (A100/RTX 4090 recommended)
- **RTF**: 0.04-0.10 with TensorRT-LLM optimization (25x real-time at best)
- **Streaming latency**: as low as 150ms first-chunk
- **Without optimization**: RTF ~0.3-0.5 on consumer GPU (still real-time capable)
- **TensorRT-LLM**: 4x acceleration over HuggingFace transformers baseline
- **LightTTS framework**: optimized inference for CosyVoice2/3, Python streaming support
[SOURCE: https://github.com/ModelTC/LightTTS]
[SOURCE: https://github.com/FunAudioLLM/CosyVoice/issues/317]
[SOURCE: https://www.gpu-mart.com/blog/how-to-install-cosyvoice]

### 4. Edge-TTS: Zero Latency Concern, No Benchmarks for Thai Quality
- Edge-TTS is cloud-based (Microsoft Azure Neural TTS)
- Latency: network round-trip (~100-500ms depending on region) + streaming
- No published MOS scores specifically for Thai Neural voices
- 3 Thai voices: PremwadeeNeural (F), NiwatNeural (M), AcharaNeural (F)
- SSML support: YES -- `<prosody rate="..." pitch="..." volume="...">` tags work
- Edge-TTS SSML for Thai: prosody tags should work but Thai-specific control (tones, emphasis) is limited to rate/pitch/volume
- No voice cloning, no emotion control, neutral style only
[SOURCE: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/ -- known from prior iterations]
[INFERENCE: based on Edge-TTS being Azure Neural TTS with standard SSML support]

### 5. Quality Ranking (Revised): Edge-TTS > CosyVoice for Thai (Phase 1)
Given the correction that CosyVoice does NOT have native Thai training:
- **Edge-TTS**: purpose-built Thai Neural voices trained by Microsoft, tested for Thai, production-ready
- **CosyVoice**: would rely on zero-shot cross-lingual transfer to Thai -- quality is UNKNOWN and likely inferior to purpose-trained voices
- **Recommendation**: Edge-TTS for Phase 1 production. CosyVoice as experimental Phase 2 for voice cloning use case (clone a Thai speaker's voice, then use cross-lingual synthesis)
- **Both can coexist**: Pixelle-Video already supports per-request engine selection via workflow field
[INFERENCE: based on findings 1-4; purpose-trained models consistently outperform zero-shot transfer for specific languages]

### 6. Pixelle-Video TTS Integration Architecture
The `TTSService` in Pixelle-Video has a clean extension pattern:
- Extends `ComfyBaseService` with `WORKFLOW_PREFIX = "tts_"`
- **Two modes**: `local` (direct Python call) and `comfyui` (workflow JSON execution)
- **Engine routing**: `inference_mode` config field selects local vs ComfyUI
- **Local path**: currently hardcoded to Edge-TTS (`edge_tts(text, voice, rate, output_path)`)
- **Adding CosyVoice requires**:
  1. Add `_call_cosyvoice_tts()` async method alongside `_call_local_tts()`
  2. Route via `local_engine` config: `"edge_tts"` | `"cosyvoice"`
  3. CosyVoice sidecar: FastAPI on :50000, called via `httpx.AsyncClient`
  4. OR ComfyUI workflow: create `workflows/tts_cosyvoice.json`
- **Interface contract**: async callable accepting `(text, voice, speed, output_path) -> str` (path to audio file)
- **Audio formats**: `.mp3`, `.wav`, `.flac` all supported by ComfyKit
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/services/tts_service.py]

### 7. CosyVoice Integration Path (Sidecar Architecture)
```
Pixelle-Video TTSService
  |-- inference_mode: "local"
  |     |-- local_engine: "edge_tts" -> edge_tts()
  |     +-- local_engine: "cosyvoice" -> HTTP POST to localhost:50000/tts
  +-- inference_mode: "comfyui"
        +-- workflow: "tts_cosyvoice.json" -> ComfyUI node
```
CosyVoice sidecar approach:
- Run CosyVoice as separate FastAPI service (already has built-in server)
- Pixelle-Video calls `POST /api/inference/tts` with `{"text": "...", "speaker": "...", "speed": 1.0}`
- Returns WAV audio bytes
- Benefits: independent GPU allocation, can use different Python env (CosyVoice needs specific torch version)
[INFERENCE: based on CosyVoice FastAPI server from iteration 2 + TTSService architecture from finding 6]

### 8. Comprehensive Thai Particles for Natural Script Writing
Extracted 60+ Thai particles organized by function. Key categories for TTS script naturalness:

**Essential for conversational tone (MUST include):**
- ครับ/ค่ะ (khrap/kha) -- politeness, gender-appropriate
- นะ (na) -- softener, "you know", makes requests gentle
- เลย (loei) -- intensifier, "really/so much"
- จัง (jang) -- "very/really", heartfelt emotion
- สิ (si) -- assertive imperative, "do it!"
- ล่ะ (la) -- mild objection, "why?"
- มั้ง (mang) -- "maybe/I guess"
- แหละ (lae) -- "that's it/just so"

**Discourse fillers (make speech sound human):**
- อ่ะ (a) -- informal "uhm"
- เออ (oe) -- "yeah/uh-huh"
- เอ๋ (e) -- "uh?" trying to remember
- อ๋อ (o) -- "oh I see" realization

**Emotion/exclamation (for viral content):**
- เฮ้ย (hoei) -- "hey!" attention getter
- อุ๊ย (ui) -- "oops/ouch" surprise
- แหม (mae) -- "jeez/my goodness"
- เย้ (ye) -- "yes!/yay!" delight
- กรี๊ด (kriit) -- screaming excitement

**Internet/informal (viral-ops specific):**
- ว้า (waa) -- "oh no!"
- เนี่ย (nia) -- emphatic "this one!"
- อ่ะดิ (a-di) -- slang "it's like..."
- งะ (nga) -- teenage "What???"
[SOURCE: https://thai-notes.com/notes/particles.html]

### 9. Thai Script Writing Guidelines: What Makes AI Text Sound Robotic
Based on linguistic analysis, AI-generated Thai sounds unnatural because:

**Robotic patterns (AVOID):**
- No sentence-final particles -- makes every sentence sound like a textbook
- Overly formal register -- using ท่าน instead of คุณ, avoiding contractions
- Perfect grammar -- real Thai speech breaks rules constantly
- No fillers/hedging -- real speech has อ่ะ, คือ, แบบ
- Monotone sentence structure -- same length, same pattern
- No rhetorical questions -- Thai speakers constantly use มั้ย, เหรอ, ล่ะ

**Natural patterns (USE):**
- Mix particles: "สนุกมากเลยนะ" (so fun, right?) vs robotic "สนุกมาก" (very fun)
- Add discourse markers: "คือ...แบบว่า..." (like...you know...)
- Use rhetorical questions: "ใครจะไม่ชอบล่ะ" (who wouldn't like it?)
- Vary sentence length: short punchy + longer flowing
- Include exclamations: "โอ้โฮ!", "เฮ้ย!", "555" in context
- Use contractions: ไม่ -> เปล่า (informal no), ทำไม -> ทำไมล่ะ
[INFERENCE: derived from comprehensive particle taxonomy in finding 8 + Thai linguistics patterns from search results]

### 10. Prompt Engineering Template for Natural Thai TTS Scripts
```
System: You are a Thai content writer for short-form viral videos.
Write CONVERSATIONAL Thai, not formal Thai.

Rules:
1. End sentences with particles: นะ, เลย, จัง, ล่ะ, มั้ง, แหละ
2. Use ครับ/ค่ะ sparingly (only when addressing viewer directly)
3. Include fillers: คือ, แบบ, อ่ะ (1-2 per paragraph)
4. Ask rhetorical questions: ใครจะไม่ชอบล่ะ?, ...ใช่มั้ย?
5. Use exclamations: โอ้โฮ, เฮ้ย, อุ๊ย for emotion
6. Mix sentence lengths: short punch (3-5 words) + flowing (10-15 words)
7. Use มากๆ and เลย for emphasis instead of formal อย่างมาก
8. Include 555 or เย้ for humor/delight moments
9. Never use ท่าน, กรุณา, or formal connectors like อนึ่ง, ทั้งนี้

Target: Sound like a popular Thai YouTuber/TikToker, age 25-35
```
[INFERENCE: synthesized from findings 8-9]

### 11. CosyVoice FreeStyle Prosody Control
CosyVoice FreeStyle mode accepts natural language instructions for controlling speech style:
- Emotion: "speak excitedly", "whisper softly", "speak with sadness"
- Speed: "speak slowly with emphasis", "rapid energetic delivery"
- Character: "speak like an elderly grandmother", "youthful and energetic"
- These instructions work in English even for non-English speech
- However: effectiveness for Thai is UNTESTED (no Thai evaluation)
- For Edge-TTS: SSML `<prosody>` tags provide rate/pitch/volume control but NOT emotion
[SOURCE: https://funaudiollm.github.io/cosyvoice3/ -- from iteration 2]
[SOURCE: https://arxiv.org/html/2505.17589v1]

### 12. Multi-Engine Coexistence: Confirmed Feasible
Pixelle-Video's architecture already supports per-request engine selection:
- `workflow` field in TTS request selects engine
- Config can set default engine while allowing override
- Implementation: `inference_mode` + `local_engine` routing
- Real pattern: Channel A (Thai female) = Edge-TTS PremwadeeNeural, Channel B (Thai male with cloned voice) = CosyVoice
- No architectural changes needed -- just extend the routing in TTSService
[SOURCE: Pixelle-Video TTSService code analysis from finding 6]
[INFERENCE: based on workflow routing pattern]

### 13. Audio Post-Processing for Thai Naturalness
Key post-processing techniques (from general TTS best practices):
- **PyDub**: Python library for audio manipulation (silence insertion, volume normalization, crossfading)
- **FFMPEG**: normalize loudness to -16 LUFS (broadcast standard)
- **Breathing sounds**: can be spliced in at sentence boundaries using pre-recorded breath samples
- **Pause insertion**: Thai sentence boundaries need 200-400ms pauses (longer than English) due to no-space script
- **De-essing**: Thai sibilants (ส, ศ, ษ) can be harsh in TTS -- notch filter at 5-8kHz
- **Room tone**: add subtle background ambience to prevent "sterile" TTS sound
[INFERENCE: based on general TTS post-processing best practices applied to Thai-specific phonology; no Thai-specific post-processing tools found]

## Ruled Out
- CosyVoice as Phase 1 Thai TTS engine: paper confirms only 9 languages, Thai not included. Zero-shot transfer quality is unknown.
- Finding Thai-specific MOS benchmarks: none exist in published literature for any OSS TTS engine.
- Edge-TTS emotion control: SSML prosody tags exist but only rate/pitch/volume -- no emotion/style control.

## Dead Ends
- **CosyVoice native Thai TTS quality**: The paper definitively lists 9 languages. Thai would require either fine-tuning or relying on zero-shot transfer, which is unproven. This is NOT a dead end for voice cloning (cross-lingual cloning may work), but IS a dead end for claiming "native Thai quality."
- **Published Thai TTS MOS comparisons**: No academic paper compares Thai TTS engines with MOS scores. Quality assessment must rely on manual listening tests.

## Sources Consulted
- https://arxiv.org/html/2505.17589v1 (CosyVoice 3 paper)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/services/tts_service.py
- https://thai-notes.com/notes/particles.html (comprehensive Thai particles reference)
- https://github.com/ModelTC/LightTTS (CosyVoice optimized inference)
- https://github.com/FunAudioLLM/CosyVoice/issues/317 (RTF discussion)
- https://www.gpu-mart.com/blog/how-to-install-cosyvoice (VRAM requirements)
- https://www.expatden.com/learn-thai/basic-thai-grammar-how-to-use-ending-particles/
- https://ling-app.com/blog/thai-ending-particles/

## Assessment
- New information ratio: 0.73
- Questions addressed: Q1, Q3, Q5, Q7, Q9, Q11, Q12
- Questions answered: Q7 (Pixelle-Video integration path fully mapped), Q11 (multi-engine coexistence confirmed), Q5 (substantial -- Thai script naturalness guidelines with 60+ particles and prompt template)

## Reflection
- What worked and why: Fetching the actual arxiv paper for CosyVoice 3 revealed a critical correction -- Thai is NOT natively supported. This changes the entire recommendation. The Pixelle-Video tts_service.py fetch was highly productive, providing the exact integration pattern. The Thai particles reference (thai-notes.com) was exceptionally comprehensive -- a single page with 60+ particles organized by category.
- What did not work and why: Finding Thai-specific MOS benchmarks was impossible -- no one has published comparative Thai TTS quality studies. CosyVoice GPU benchmarks were scattered across issues and guides rather than documented centrally.
- What I would do differently: For the Thai quality question, recommend a practical listening test rather than searching for non-existent benchmarks. For CosyVoice Thai specifically, search for community reports of using CosyVoice with Thai text (zero-shot) rather than relying on official language lists.

## Recommended Next Focus
1. **CosyVoice zero-shot Thai**: Search for community examples/demos of CosyVoice generating Thai speech via cross-lingual transfer -- does it actually work?
2. **Thai voice cloning options**: Given Edge-TTS has no cloning, what are the actual options? CosyVoice cross-lingual clone? OpenAI TTS? ElevenLabs?
3. **Edge-TTS SSML practical examples**: Create concrete SSML templates for Thai with prosody control
4. **Cost analysis**: CosyVoice (free local) vs Edge-TTS (free cloud) vs paid alternatives (Q10)
5. **Thai tone system handling**: How do TTS engines handle Thai's 5 tones? (Q6)
