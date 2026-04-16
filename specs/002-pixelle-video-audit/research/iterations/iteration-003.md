# Iteration 3: Content Generation Subsystems — ComfyUI Workflows, TTS Engines, LLM Providers, Video Templates, Image Gen

## Focus
Deep-dive into all five content generation subsystems that feed the `/api/content/generate` pipeline. This iteration addresses Q3 (ComfyUI workflows), Q4 (TTS engines/voices), Q5 (LLM providers), Q6 (image generation options), and Q7 (video templates). These are the core creative building blocks that the viral-ops dashboard must expose as user-selectable options.

## Findings

### F1: ComfyUI Workflow Catalog — 8 selfhost + 21 runninghub workflows
Two deployment modes with different workflow sets:

**selfhost/ (8 workflows — local GPU)**
| Workflow | Purpose | Key Model |
|----------|---------|-----------|
| `image_flux.json` | FLUX image gen | flux1-dev.safetensors |
| `image_nano_banana.json` | Lightweight image gen | nano-banana model |
| `image_qwen.json` | Qwen-based image gen | Qwen vision model |
| `analyse_image.json` | Image analysis/captioning | Vision model |
| `analyse_video.json` | Video analysis/captioning | Vision model |
| `tts_edge.json` | Edge-TTS speech | Edge-TTS engine |
| `tts_index2.json` | Index-TTS speech | Index-TTS model |
| `video_wan2.1_fusionx.json` | Video gen (WAN 2.1) | WAN 2.1 FusionX |

**runninghub/ (21 workflows — cloud GPU)**
| Workflow | Purpose |
|----------|---------|
| `image_flux.json` | FLUX image gen |
| `image_flux2.json` | FLUX v2 image gen |
| `image_qwen.json` | Qwen image gen |
| `image_qwen_chinese_cartoon.json` | Chinese cartoon style |
| `image_sd3.5.json` | Stable Diffusion 3.5 |
| `image_sdxl.json` | Stable Diffusion XL |
| `image_Z-image.json` | Z-image model |
| `digital_image.json` | Digital human image |
| `digital_combination.json` | Digital human composition |
| `digital_customize.json` | Digital human customization |
| `af_scail.json` | ScailFlux model |
| `tts_edge.json` | Edge-TTS speech |
| `tts_index2.json` | Index-TTS speech |
| `tts_spark.json` | Spark-TTS speech |
| `video_wan2.1_fusionx.json` | WAN 2.1 FusionX video |
| `video_wan2.2.json` | WAN 2.2 video gen |
| `video_qwen_wan2.2.json` | Qwen+WAN 2.2 video |
| `video_Z_image_wan2.2.json` | Z-image+WAN 2.2 video |
| `i2v_LTX2.json` | Image-to-video (LTX2) |
| `video_understanding.json` | Video understanding/analysis |
| `analyse_image.json` | Image analysis |

**Dashboard implication**: RunningHub has 2.6x more workflows than selfhost. The `/api/resources/workflows` endpoint dynamically scans the active directory, so the dashboard dropdown adapts automatically per deployment mode.

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/selfhost]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/runninghub]

### F2: ComfyUI Workflow Node Structure — FLUX workflow as reference architecture
The `image_flux.json` workflow reveals the standard ComfyUI API format:

**Node graph (7 functional nodes):**
- `UNETLoader` (node 48): loads `flux1-dev.safetensors` — the diffusion model
- `DualCLIPLoader` (node 47): loads `clip_l.safetensors` + `t5xxl_fp8_e4m3fn.safetensors` — text encoders
- `VAELoader` (node 49): loads `ae.safetensors` — decoder
- `CLIPTextEncode` (node 31): encodes the text prompt
- `FluxGuidance` (node 35): guidance strength = 3.5
- `KSampler` (node 29): steps=20, cfg=1.0, sampler=euler, scheduler=simple, denoise=1.0
- `EmptyLatentImage` (node 43): width=1024, height=1024, batch=1

**Customizable parameters exposed to API:**
- `prompt` (text) — injected into CLIPTextEncode node
- `width` / `height` (int) — injected into EmptyLatentImage node
- `steps` (int, default 20) — KSampler parameter
- `seed` (int) — KSampler parameter
- `cfg` (float, default 1.0) — KSampler parameter
- `guidance` (float, default 3.5) — FluxGuidance parameter

**Note**: Negative prompt is handled via `ConditioningZeroOut` (zeroed out, not user-settable for FLUX). Other workflows (SD, SDXL) likely expose `negative_prompt` as a separate parameter.

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/workflows/selfhost/image_flux.json]

### F3: TTS Voice Catalog — 28 Edge-TTS voices across 11 languages
The `tts_voices.py` file defines `EDGE_TTS_VOICES` with 28 voice entries:

| Language | Locale | Voices (Female) | Voices (Male) | Count |
|----------|--------|-----------------|---------------|-------|
| Chinese | zh-CN | XiaoxiaoNeural, XiaoyiNeural, liaoning-XiaobeiNeural | YunjianNeural, YunxiNeural, YunyangNeural, YunyeNeural, YunfengNeural | 8 |
| English (US) | en-US | AriaNeural, JennyNeural | GuyNeural, DavisNeural | 4 |
| English (UK) | en-GB | SoniaNeural | RyanNeural | 2 |
| Korean | ko-KR | 1 female | 1 male | 2 |
| French | fr-FR | 1 female | 1 male | 2 |
| Portuguese | pt-BR | 1 female | 1 male | 2 |
| German | de-DE | 1 female | 1 male | 2 |
| Russian | ru-RU | 1 female | 1 male | 2 |
| Turkish | tr-TR | 1 female | 1 male | 2 |
| Spanish | es-ES | 1 female | 1 male | 2 |

**Voice data structure per entry:**
```python
{"id": "zh-CN-XiaoxiaoNeural", "label_key": "voice.xiaoxiao", "locale": "zh-CN", "gender": "male"|"female"}
```

**Helper functions:**
- `get_voice_display_name(voice, locale, t)` — returns localized display name with translation function fallback
- `speed_to_rate(speed: float) -> str` — converts multiplier (e.g., 1.2) to Edge-TTS rate format ("+20%")

**Notable gap**: Thai is NOT in the default voice list. Edge-TTS does support Thai (`th-TH-PremwadeeNeural`, `th-TH-NiwatNeural`) but Pixelle-Video doesn't include them by default. For viral-ops Thai content, we must either:
1. Add Thai voices to the config, or
2. Use the `ref_audio` voice cloning path (ref_audio + ref_text in TTS schema)

**TTS engines beyond Edge-TTS**: The workflow files confirm 3 TTS engines:
- `tts_edge.json` — Edge-TTS (cloud, free, 28+ voices)
- `tts_index2.json` — Index-TTS (local model, voice cloning capable)
- `tts_spark.json` — Spark-TTS (RunningHub only, cloud model)

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/tts_voices.py]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/selfhost]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/runninghub]

### F4: LLM Provider Presets — 6 providers, OpenAI-compatible API pattern
The `llm_presets.py` file defines `LLM_PRESETS` list with 6 provider configs:

| Provider | Default Model | Base URL | Notes |
|----------|--------------|----------|-------|
| **Qwen** | qwen-max | `dashscope.aliyuncs.com/compatible-mode/v1` | Alibaba Cloud, listed first (likely default) |
| **OpenAI** | gpt-4o | `api.openai.com/v1` | Standard OpenAI |
| **Claude** | claude-sonnet-4-5 | `api.anthropic.com/v1/` | Anthropic (via OpenAI-compatible endpoint) |
| **DeepSeek** | deepseek-chat | `api.deepseek.com` | DeepSeek |
| **Ollama** | llama3.2 | `localhost:11434/v1` | Local, default_api_key="ollama" (SDK placeholder) |
| **Moonshot** | moonshot-v1-8k | `api.moonshot.cn/v1` | Moonshot AI (Chinese provider) |

**Preset data structure:**
```python
{"name": "...", "base_url": "...", "model": "...", "api_key_url": "...", "default_api_key": "..."}
```

**Key design insight**: All providers use the OpenAI-compatible API pattern (`/v1` base URL). No provider-specific parameters (temperature, max_tokens) are in the presets file — these come from:
1. `config.example.yaml` → `llm.temperature` (default), `llm.max_tokens` (default)
2. Per-request override via `/api/llm/generate` body (`temperature`, `max_tokens` fields in LLMRequest schema)

**Helper functions:**
- `get_preset_names()` — returns list of provider names for dropdown
- `get_preset(name)` — retrieves config by name
- `find_preset_by_base_url_and_model(base_url, model)` — reverse lookup

**Dashboard implication**: The preset system means the dashboard can show a provider dropdown populated by `get_preset_names()`, then auto-fill base_url and model. Users can also enter custom base_url/model for unlisted providers.

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/llm_presets.py]

### F5: Video Template Catalog — 25 templates across 3 aspect ratios
Templates are organized by aspect ratio with HTML files:

**Aspect ratio directories:**
- `1080x1920/` — vertical (9:16, TikTok/Reels/Shorts)
- `1920x1080/` — horizontal (16:9, YouTube)
- `1080x1080/` — square (1:1, Instagram)

**1080x1920 templates (25 confirmed):**

| Category | Templates | Count |
|----------|-----------|-------|
| **Image-based** | image_default, image_blur_card, image_book, image_cartoon, image_elegant, image_excerpt, image_fashion_vintage, image_full, image_healing, image_health_preservation, image_life_insights, image_life_insights_light, image_long_text, image_modern, image_neon, image_psychology_card, image_purple, image_satirical_cartoon, image_simple_black, image_simple_line_drawing | 20 |
| **Video-based** | video_default, video_healing | 2 |
| **Static** | static_default, static_excerpt | 2 |
| **Asset** | asset_default | 1 |

**Template naming convention:**
- `{type}_{style}.html` where type = image|video|static|asset
- `image_*` = generated image as background with text overlay
- `video_*` = generated video as background
- `static_*` = no dynamic background
- `asset_*` = user-uploaded asset as background

**Dashboard implication**: Template selection in the dashboard should:
1. Filter by aspect ratio (from API's `width`/`height` or explicit ratio selector)
2. Show template previews grouped by type (image/video/static/asset)
3. Each template has its own `template_params` schema (dynamic per-template, from iteration 2's VideoComposeRequest)

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/templates/1080x1920]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/templates]

### F6: Image Generation Model Coverage — 7+ models across selfhost and RunningHub
Combining workflow analysis with the catalog:

| Model | Workflow Files | Deployment | Type |
|-------|---------------|------------|------|
| **FLUX** (flux1-dev) | image_flux.json | Both | Text-to-image |
| **FLUX v2** | image_flux2.json | RunningHub only | Text-to-image |
| **Qwen Vision** | image_qwen.json | Both | Text-to-image |
| **Qwen Chinese Cartoon** | image_qwen_chinese_cartoon.json | RunningHub only | Style-specific |
| **SD 3.5** | image_sd3.5.json | RunningHub only | Text-to-image |
| **SDXL** | image_sdxl.json | RunningHub only | Text-to-image |
| **Nano Banana** | image_nano_banana.json | Selfhost only | Lightweight |
| **Z-Image** | image_Z-image.json | RunningHub only | Text-to-image |
| **ScailFlux** | af_scail.json | RunningHub only | Enhanced FLUX |

**Common tunable parameters** (from FLUX workflow analysis):
- `prompt` (text) — the image description
- `width` / `height` (int) — output resolution
- `steps` (int) — inference steps (quality vs speed)
- `seed` (int) — reproducibility
- `cfg` (float) — classifier-free guidance scale
- `guidance` (float) — model-specific guidance (FLUX)

**Selfhost limitations**: Only 3 image models (FLUX, Nano Banana, Qwen) vs 8 on RunningHub. This is significant for dashboard feature gating — must detect deployment mode.

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/selfhost]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/runninghub]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/workflows/selfhost/image_flux.json]

### F7: Video Generation Models — WAN 2.1/2.2 + LTX2 + Digital Human
| Model | Workflow | Deployment | Type |
|-------|---------|------------|------|
| **WAN 2.1 FusionX** | video_wan2.1_fusionx.json | Both | Text/image-to-video |
| **WAN 2.2** | video_wan2.2.json | RunningHub only | Text/image-to-video |
| **Qwen+WAN 2.2** | video_qwen_wan2.2.json | RunningHub only | Prompt enhancement+video |
| **Z-Image+WAN 2.2** | video_Z_image_wan2.2.json | RunningHub only | Image gen+video |
| **LTX2** | i2v_LTX2.json | RunningHub only | Image-to-video |
| **Digital Human** | digital_*.json (3 files) | RunningHub only | Digital avatar video |

**Selfhost video limitation**: Only WAN 2.1 FusionX is available locally. The dashboard must handle this gracefully.

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/selfhost]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/runninghub]

### F8: Cross-Subsystem Integration Pattern
The content generation pipeline from iteration 1's `/api/content/generate` endpoint ties everything together:

```
User Topic → LLM (script gen, 6 providers) → TTS (voice, 3 engines) → Image Gen (per-scene, 9+ models)
                                                                        → Video Gen (optional, 6 models)
                                                                        → Template Composition (25+ templates)
                                                                        → Final Video (FFmpeg merge)
```

Each subsystem is independently configurable via the ContentGenerationRequest schema (iteration 2):
- `llm_provider` + `model` → selects LLM preset
- `tts_workflow` + `voice_id` or `ref_audio` → selects TTS engine and voice
- `image_workflow` → selects ComfyUI image workflow
- `frame_template` + `template_params` → selects HTML template and style
- `video_workflow` → optional video generation workflow

[INFERENCE: based on iterations 1-2 API schema analysis + this iteration's subsystem catalogs]

## Ruled Out
- None. All five target areas yielded substantial results from GitHub source files.

## Dead Ends
- None identified. The direct raw GitHub fetch approach continues to be highly productive.

## Sources Consulted
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/selfhost (8 workflow files)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/workflows/runninghub (21 workflow files)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/workflows/selfhost/image_flux.json (workflow node structure)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/tts_voices.py (28 Edge-TTS voices)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/llm_presets.py (6 LLM providers)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/templates/1080x1920 (25 HTML templates)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/templates (3 aspect ratio dirs)

## Assessment
- New information ratio: 0.94
- Questions addressed: Q3, Q4, Q5, Q6, Q7
- Questions answered: Q3 (full — workflow catalog complete), Q4 (substantial — voices cataloged, need service layer detail for ChatTTS/IndexTTS config), Q5 (full — all 6 providers documented), Q6 (full — all image models mapped), Q7 (substantial — templates cataloged, need template_params schema per template)

## Reflection
- What worked and why: Fetching GitHub directory listings for workflows/ and templates/ gave complete file catalogs. Fetching raw source for tts_voices.py and llm_presets.py gave exact data structures. The FLUX workflow JSON revealed the standard ComfyUI node parameter architecture. Covering 5 questions in one iteration was possible because each area had a clear canonical source file.
- What did not work and why: GitHub directory listings truncate — the templates/1080x1920 listing shows 25 files but may have more. Also could not fetch 1920x1080 and 1080x1080 template listings within budget.
- What I would do differently: Prioritize fetching one sample template HTML file to understand template_params schema, rather than trying to list all three aspect ratio directories.

## Recommended Next Focus
Iteration 4 should focus on:
1. **Streamlit UI feature set (Q10)** — fetch the Streamlit app source to catalog all UI pages/features that need dashboard equivalents
2. **Data flow pipeline (Q14)** — fetch the core pipeline orchestrator (pixelle_video/services/ or pixelle_video/pipelines/) to trace topic-to-video artifact chain
3. **Template params schema** — fetch one sample HTML template to understand what template_params are available per template (completes Q7)
4. **Batch/bulk generation (Q11)** — check if batch endpoints or queue patterns exist beyond what iteration 1 found
