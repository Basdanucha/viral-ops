# Iteration 2: CosyVoice 3.5 Thai Deep-Dive + Thai Word Segmentation + Natural Thai Script

## Focus
Deep-dive into CosyVoice 3.5 as the top OSS candidate for Thai TTS: confirm Thai support, voice cloning details, instruction mode, GPU requirements, and integration feasibility. Investigate PyThaiNLP word segmentation for TTS preprocessing. Begin mapping natural Thai script writing patterns.

## Findings

### CosyVoice 3.5 — Thai Support Confirmed

1. **Thai is officially supported in Fun-CosyVoice 3.5** (released March 2, 2026 by Alibaba Tongyi Lab). Thai is one of 4 new languages added (Thai, Indonesian, Portuguese, Vietnamese), bringing total to **13 languages**. [SOURCE: https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/] [SOURCE: https://news.aibase.com/news/25834]

2. **Architecture: LLM + Flow Matching hybrid.** CosyVoice 3 uses a large language model (LLM) combined with a chunk-aware flow matching (FM) model for streaming synthesis. A novel speech tokenizer is trained via supervised multi-task learning (ASR, emotion recognition, language ID, audio event detection, speaker analysis). Trained on **1 million hours** of audio across 9+ languages. [SOURCE: https://funaudiollm.github.io/cosyvoice3/]

3. **Voice cloning: 10-20 seconds reference audio sufficient.** Zero-shot voice cloning confirmed. Reference audio specs: WAV format, 16kHz+ sample rate, mono channel, minimal background noise, no gaps >2s, minimum 60% active speech. Cross-lingual cloning supported (clone a voice in one language, synthesize in another). [SOURCE: https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/] [SOURCE: https://github.com/FunAudioLLM/CosyVoice]

4. **FreeStyle instruction mode replaces preset emotion tags.** Instead of fixed labels like `<sad>` or `<angry>`, users describe tone/delivery in natural language sentences. Examples: "Simulate a navigation assistant's cheerful arrival message—light tone" or "Simulate a news journalist asking a guest a question." This is extremely powerful for Thai content — you can describe the exact delivery style per line. [SOURCE: https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/]

5. **Model variants: 0.3B, 0.5B, and 1.5B parameters.** Two deployment variants: `cosyvoice-v3.5-plus` (quality) and `cosyvoice-v3.5-flash` (speed). First-packet latency reduced 35% over v3.0. Rare character error rate dropped from 15.2% to 5.3% (important for Thai's complex script). [SOURCE: https://github.com/FunAudioLLM/CosyVoice] [SOURCE: https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/]

6. **Installation: Python 3.10, Ubuntu recommended, Docker available.** Has FastAPI server, gRPC deployment, and web demo UI. Can run as a standalone service alongside other apps. [SOURCE: https://github.com/FunAudioLLM/CosyVoice]

7. **DiffRO + GRPO reinforcement learning** improves rhythm, prosody, voice similarity, and audio quality. Flow-GRPO specifically optimizes the audio generation layer. Tokenizer frame rate halved for efficiency. [SOURCE: https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/]

### PyThaiNLP — Thai Word Segmentation for TTS

8. **PyThaiNLP is the standard Thai NLP library** (Apache 2.0, Python 3.9+). Provides `word_tokenize`, `sent_tokenize`, `subword_tokenize`. Multiple tokenizer engines available including dictionary-based, maximum matching (newmm), deep learning-based (deepcut), and ICU. Install: `pip install pythainlp`. [SOURCE: https://github.com/PyThaiNLP/pythainlp] [SOURCE: https://pypi.org/project/pythainlp/]

9. **PyThaiTTS exists as a dedicated Thai TTS library** built on PyThaiNLP. Includes automatic preprocessing: number-to-Thai-text conversion, repetition mark expansion, and text normalization. This confirms that word segmentation is a critical preprocessing step for Thai TTS. [SOURCE: https://github.com/PyThaiNLP/PyThaiTTS] [SOURCE: https://pythainlp.org/PyThaiTTS/]

10. **Thai TTS requires explicit word segmentation as preprocessing** — unlike English/European languages, Thai has no spaces between words. Word tokenization and text normalization are essential before feeding text to any TTS engine. This applies to CosyVoice, Edge-TTS, and all other engines. [SOURCE: https://nlpforthai.com/tasks/word-segmentation/] [INFERENCE: based on PyThaiNLP docs and Thai writing system characteristics]

11. **PyThaiNLP text normalization features relevant to TTS:** `bahttext` (number-to-text), Thai datetime formatting, keyboard layout correction, spelling correction, romanization/transliteration, and IPA conversion. These are building blocks for a TTS preprocessing pipeline. [SOURCE: https://github.com/PyThaiNLP/pythainlp]

### Natural Thai Script Writing

12. **Thai has an elaborate honorific system** that affects naturalness. Politeness particles (ค่ะ/คะ for female, ครับ for male) are essential for natural-sounding Thai. SSML support in commercial engines allows pause insertion and pronunciation customization for conversational flow. [SOURCE: https://www.narakeet.com/languages/thai-text-to-speech/] [INFERENCE: based on Thai linguistic structure and TTS platform docs]

13. **No dedicated English-language resources found for anti-AI Thai script writing.** The search returned only commercial TTS platform pages. This is a gap — the knowledge about making Thai scripts sound human rather than AI-generated likely exists primarily in Thai-language communities and practitioner knowledge. Will need to synthesize guidelines from Thai linguistic principles. [SOURCE: search results from multiple TTS platforms — no specific anti-AI methodology found]

## Ruled Out
- **CosyVoice 3.0 base (pre-3.5) for Thai**: Only 9 languages, Thai NOT included. Must use specifically Fun-CosyVoice 3.5. [SOURCE: https://funaudiollm.github.io/cosyvoice3/]
- **Generic web search for Thai anti-AI script writing in English**: Returns only TTS platform marketing pages. Need Thai-language sources or to derive guidelines from linguistic principles.

## Dead Ends
- None definitively eliminated this iteration.

## Sources Consulted
- https://github.com/FunAudioLLM/CosyVoice (README, features)
- https://funaudiollm.github.io/cosyvoice3/ (CosyVoice 3.0 technical paper page)
- https://gaga.art/blog/fun-cosyvoice3-5-and-fun-audiogen-vd/ (Fun-CosyVoice 3.5 announcement)
- https://news.aibase.com/news/25834 (CosyVoice 3.5 launch coverage)
- https://github.com/PyThaiNLP/pythainlp (PyThaiNLP README)
- https://pypi.org/project/pythainlp/ (PyThaiNLP PyPI)
- https://github.com/PyThaiNLP/PyThaiTTS (PyThaiTTS)
- https://pythainlp.org/PyThaiTTS/ (PyThaiTTS docs)
- https://nlpforthai.com/tasks/word-segmentation/ (Thai word segmentation overview)
- https://www.narakeet.com/languages/thai-text-to-speech/ (Narakeet Thai TTS)

## Assessment
- New information ratio: 0.77
- Questions addressed: Q1, Q2, Q3, Q4, Q6, Q7, Q8
- Questions answered: None fully — but Q2 (voice cloning), Q4 (word segmentation), and Q8 (GPU) are substantially progressed

## Reflection
- What worked and why: Fetching the CosyVoice GitHub README + the Gaga.art announcement article together gave complementary data — the README had technical specs while the blog had the Thai confirmation and RL improvements. The PyThaiNLP GitHub page confirmed the word segmentation ecosystem.
- What did not work and why: English-language search for "anti-AI Thai script writing" returned zero relevant results — this topic is too niche and Thai-specific for English web sources.
- What I would do differently: For Q5 (natural Thai scripts), search in Thai language or derive guidelines from Thai linguistic textbooks/academic papers rather than general web search.

## Recommended Next Focus
1. **GPU/VRAM benchmarks for CosyVoice** — model sizes known (0.3B-1.5B) but actual VRAM needs and inference RTF not documented. Search HuggingFace model cards or community benchmarks.
2. **Pixelle-Video integration architecture** — how to add CosyVoice as a TTS backend. Examine existing TTS integration code in Pixelle-Video.
3. **Natural Thai script writing guidelines** — derive from Thai linguistic principles: sentence-final particles, discourse markers, tonal emphasis patterns, colloquial vs formal register. Try Thai-language sources.
4. **Edge-TTS vs CosyVoice quality comparison** — find any MOS scores or user comparisons for Thai.
5. **Cost analysis** — CosyVoice (free OSS local) vs Edge-TTS (free cloud) vs OpenAI TTS (paid) vs ElevenLabs (paid).
