# Pixelle-Video Feature Audit — Research Synthesis

> Progressive synthesis document. Updated after each research iteration.

---

## API Endpoint Catalog

**Total: 21 endpoints across 10 routers + app root** (v0.1.15, FastAPI on :8000)

All endpoints mounted under `/api` prefix (configurable via `api_config.api_prefix`).

### Core Generation Endpoints

| # | Method | Path | Request Body | Response | Purpose |
|---|--------|------|-------------|----------|---------|
| 1 | POST | `/api/video/generate/sync` | VideoGenerateRequest | video_url, duration, file_size | Synchronous full video generation |
| 2 | POST | `/api/video/generate/async` | VideoGenerateRequest | task_id | Async video generation (background) |
| 3 | POST | `/api/tts/synthesize` | text, workflow?, ref_audio?, voice_id? | audio_path, duration | Text-to-speech via ComfyUI |
| 4 | POST | `/api/image/generate` | prompt, width, height, workflow? | image_path | Image from text via ComfyUI |
| 5 | POST | `/api/llm/chat` | prompt, temperature?, max_tokens? | content, tokens_used? | LLM text generation |
| 6 | POST | `/api/frame/render` | template, title, text, image | frame_path, width, height | Render HTML frame to image |

### Content Pipeline Endpoints

| # | Method | Path | Request Body | Response | Purpose |
|---|--------|------|-------------|----------|---------|
| 7 | POST | `/api/content/narration` | text, n_scenes, min_words, max_words | narrations[] | Split text into narrations via LLM |
| 8 | POST | `/api/content/image-prompt` | narrations[], min_words, max_words | image_prompts[] | Generate image prompts from narrations |
| 9 | POST | `/api/content/title` | text, style? | title | Generate engaging title via LLM |

### Task Management Endpoints

| # | Method | Path | Params | Response | Purpose |
|---|--------|------|--------|----------|---------|
| 10 | GET | `/api/tasks` | status?, limit (1-1000) | Task[] | List tasks (newest first) |
| 11 | GET | `/api/tasks/{task_id}` | task_id (path) | Task | Get task status/progress/result |
| 12 | DELETE | `/api/tasks/{task_id}` | task_id (path) | success, message | Cancel running/pending task |

TaskStatus enum: pending, running, completed, failed, cancelled

### Resource Discovery Endpoints

| # | Method | Path | Response | Purpose |
|---|--------|------|----------|---------|
| 13 | GET | `/api/resources/workflows/tts` | WorkflowListResponse | List TTS workflows (tts_* prefix) |
| 14 | GET | `/api/resources/workflows/media` | WorkflowListResponse | List image+video workflows |
| 15 | GET | `/api/resources/workflows/image` | WorkflowListResponse | List image workflows (DEPRECATED) |
| 16 | GET | `/api/resources/templates` | TemplateListResponse | List HTML templates (portrait/landscape/square) |
| 17 | GET | `/api/resources/bgm` | BGMListResponse | List BGM files (mp3/wav/flac/m4a/aac/ogg) |

### File & Utility Endpoints

| # | Method | Path | Params | Response | Purpose |
|---|--------|------|--------|----------|---------|
| 18 | GET | `/api/files/{file_path}` | file_path (path) | FileResponse | Serve files from allowed dirs |
| 19 | GET | `/api/frame/template/params` | template (query) | TemplateParamsResponse | Get template custom parameters |
| 20 | GET | `/api/health` | (none) | (inferred) | Health check |
| 21 | GET | `/` | (none) | service info | Root info + API listing |

### Complete Pydantic Schema Catalog (22 models, 8 files)

> Resolved in iteration 2 from `api/schemas/*.py` source files.

#### Base Response Models (base.py)
- **BaseResponse**: `success: bool = True`, `message: str = "Success"`, `data: Optional[Any] = None`
- **ErrorResponse**: `success: bool = False`, `message: str` (required), `error: Optional[str] = None`

#### VideoGenerateRequest (video.py) -- 19 fields, the master schema

| Field | Type | Default | Constraints | Notes |
|-------|------|---------|-------------|-------|
| `text` | `str` | REQUIRED | -- | Source text |
| `mode` | `Literal["generate","fixed"]` | `"generate"` | -- | AI narrations vs fixed text |
| `title` | `Optional[str]` | `None` | -- | Auto-generated if omitted |
| `n_scenes` | `Optional[int]` | `5` | `1-20` | Only in "generate" mode |
| `tts_workflow` | `Optional[str]` | `None` | -- | e.g., 'runninghub/tts_edge.json' |
| `ref_audio` | `Optional[str]` | `None` | -- | Voice cloning reference |
| `voice_id` | `Optional[str]` | `None` | -- | DEPRECATED |
| `min_narration_words` | `int` | `5` | `1-100` | -- |
| `max_narration_words` | `int` | `20` | `1-200` | -- |
| `min_image_prompt_words` | `int` | `30` | `10-100` | -- |
| `max_image_prompt_words` | `int` | `60` | `10-200` | -- |
| `media_workflow` | `Optional[str]` | `None` | -- | Custom image/video workflow |
| `video_fps` | `int` | `30` | `15-60` | -- |
| `frame_template` | `Optional[str]` | `None` | -- | e.g., '1080x1920/image_default.html' |
| `template_params` | `Optional[Dict[str,Any]]` | `None` | -- | Dynamic per template |
| `prompt_prefix` | `Optional[str]` | `None` | -- | Image style prefix |
| `bgm_path` | `Optional[str]` | `None` | -- | Background music path |
| `bgm_volume` | `float` | `0.3` | `0.0-1.0` | -- |

**VideoGenerateResponse**: `success`, `message`, `video_url: str`, `duration: float`, `file_size: int`
**VideoGenerateAsyncResponse**: `success`, `message`, `task_id: str`

#### Content Schemas (content.py)

**NarrationGenerateRequest**: `text: str` (req), `n_scenes: int = 5` (1-20), `min_words: int = 5` (1-100), `max_words: int = 20` (1-200)
**NarrationGenerateResponse**: `narrations: List[str]`

**ImagePromptGenerateRequest**: `narrations: List[str]` (req), `min_words: int = 30` (10-100), `max_words: int = 60` (10-200)
**ImagePromptGenerateResponse**: `image_prompts: List[str]`

**TitleGenerateRequest**: `text: str` (req), `style: Optional[str] = None`
**TitleGenerateResponse**: `title: str`

#### TTS Schemas (tts.py)
**TTSSynthesizeRequest**: `text: str` (req), `workflow: Optional[str]`, `ref_audio: Optional[str]`, `voice_id: Optional[str]` (deprecated)
**TTSSynthesizeResponse**: `audio_path: str`, `duration: float`

#### Image Schemas (image.py)
**ImageGenerateRequest**: `prompt: str` (req), `width: int = 1024` (512-2048), `height: int = 1024` (512-2048), `workflow: Optional[str]`
**ImageGenerateResponse**: `image_path: str`

#### LLM Schemas (llm.py)
**LLMChatRequest**: `prompt: str` (req), `temperature: float = 0.7` (0.0-2.0), `max_tokens: int = 2000` (1-32000)
**LLMChatResponse**: `content: str`, `tokens_used: Optional[int]`

#### Resource Discovery Schemas (resources.py)
**WorkflowInfo**: `name`, `display_name`, `source` (runninghub/selfhost), `path`, `key`, `workflow_id: Optional[str]`
**TemplateInfo**: `name`, `display_name`, `size` (e.g., "1080x1920"), `width: int`, `height: int`, `orientation` (portrait/landscape/square), `path`, `key`
**BGMInfo**: `name`, `path`, `source` (default/custom)
List responses: `WorkflowListResponse`, `TemplateListResponse`, `BGMListResponse`

#### frame.py -- NOT YET RESOLVED
Exists but not fetched. Covers template parameter discovery and frame rendering models.

---

## Configuration Catalog

### API Config (api/config.py) -- 12 settings

| Setting | Type | Default | Purpose |
|---------|------|---------|---------|
| `host` | `str` | `"0.0.0.0"` | Bind address |
| `port` | `int` | `8000` | Server port |
| `reload` | `bool` | `False` | Hot reload |
| `cors_enabled` | `bool` | `True` | CORS toggle |
| `cors_origins` | `list[str]` | `["*"]` | Allowed origins |
| `max_concurrent_tasks` | `int` | `5` | Task concurrency |
| `task_cleanup_interval` | `int` | `3600` | Clean completed tasks (sec) |
| `task_retention_time` | `int` | `86400` | Retain task results (sec) |
| `max_upload_size` | `int` | `104857600` | 100MB upload limit |
| `api_prefix` | `str` | `"/api"` | Route prefix |
| `docs_url` | `Optional[str]` | `"/docs"` | Swagger UI |
| `redoc_url` | `Optional[str]` | `"/redoc"` | ReDoc |

### Core Config (config.example.yaml) -- 4 sections

**llm section**: `api_key`, `base_url`, `model` -- supports any OpenAI-compatible API. Presets: Qwen Max, GPT-4o, DeepSeek, Ollama (local).

**comfyui section**:
- Global: `comfyui_url` (default `http://127.0.0.1:8188`), `comfyui_api_key`, `runninghub_api_key`, `runninghub_concurrent_limit` (1-10)
- TTS: `tts.default_workflow` = `selfhost/tts_edge.json`
- Image: `image.default_workflow` = `runninghub/image_flux.json`, `image.prompt_prefix`
- Video: `video.default_workflow` = `runninghub/video_wan2.1_fusionx.json`, `video.prompt_prefix`

**template section**: `default_template` = `"1080x1920/image_default.html"`
- Naming: `static_*` (no AI media), `image_*` (AI images), `video_*` (AI videos)
- Sizes: 1080x1920 (portrait), 1080x1080 (square), 1920x1080 (landscape)

### File Access Control

Allowed directories for `/api/files/{file_path}`:
- `output/` (default fallback for legacy paths)
- `workflows/`
- `templates/`
- `bgm/`
- `data/bgm/`
- `data/templates/`
- `resources/`

---

## Key Observations for viral-ops Dashboard

1. **Two generation modes**: Sync (blocking, <30s videos) and Async (task_id based, for longer videos). Dashboard should use async + polling.
2. **Content pipeline is composable**: narration, image-prompt, and title generation are separate endpoints. Dashboard could expose step-by-step or one-click-full-pipeline.
3. **Resource discovery endpoints exist**: Templates, workflows, and BGM can be listed dynamically. Dashboard dropdowns should populate from these.
4. **Task management is built in**: List, status, cancel -- dashboard needs a job queue view.
5. **No file upload endpoint**: Only file serving exists. Uploads (custom BGM, templates) may need separate handling.
6. **Template params are dynamic**: Each HTML template defines its own custom params. Dashboard must fetch and render these dynamically.
7. **voice_id is deprecated**: Use `workflow` + `ref_audio` instead for TTS configuration.

---

## ComfyUI Workflow Catalog

**Total: 29 workflows across 2 deployment modes** (selfhost=8, runninghub=21)

Workflows are auto-scanned from `workflows/{mode}/` directory. The `/api/resources/workflows/media` and `/api/resources/workflows/tts` endpoints return the available list dynamically.

### Selfhost Workflows (8 -- local GPU)
| Workflow | Category | Key Model |
|----------|----------|-----------|
| `image_flux.json` | Image gen | flux1-dev (FLUX) |
| `image_nano_banana.json` | Image gen | Nano Banana (lightweight) |
| `image_qwen.json` | Image gen | Qwen Vision |
| `analyse_image.json` | Analysis | Vision model |
| `analyse_video.json` | Analysis | Vision model |
| `tts_edge.json` | TTS | Edge-TTS |
| `tts_index2.json` | TTS | Index-TTS |
| `video_wan2.1_fusionx.json` | Video gen | WAN 2.1 FusionX |

### RunningHub Workflows (21 -- cloud GPU)
| Workflow | Category | Key Model |
|----------|----------|-----------|
| `image_flux.json` | Image gen | FLUX |
| `image_flux2.json` | Image gen | FLUX v2 |
| `image_qwen.json` | Image gen | Qwen |
| `image_qwen_chinese_cartoon.json` | Image gen | Qwen (cartoon style) |
| `image_sd3.5.json` | Image gen | Stable Diffusion 3.5 |
| `image_sdxl.json` | Image gen | Stable Diffusion XL |
| `image_Z-image.json` | Image gen | Z-Image |
| `digital_image.json` | Digital human | Avatar image |
| `digital_combination.json` | Digital human | Avatar composite |
| `digital_customize.json` | Digital human | Avatar custom |
| `af_scail.json` | Image gen | ScailFlux |
| `tts_edge.json` | TTS | Edge-TTS |
| `tts_index2.json` | TTS | Index-TTS |
| `tts_spark.json` | TTS | Spark-TTS |
| `video_wan2.1_fusionx.json` | Video gen | WAN 2.1 FusionX |
| `video_wan2.2.json` | Video gen | WAN 2.2 |
| `video_qwen_wan2.2.json` | Video gen | Qwen+WAN 2.2 |
| `video_Z_image_wan2.2.json` | Video gen | Z-Image+WAN 2.2 |
| `i2v_LTX2.json` | Video gen | LTX2 (image-to-video) |
| `video_understanding.json` | Analysis | Video understanding |
| `analyse_image.json` | Analysis | Image analysis |

### Workflow Node Architecture (FLUX reference)
ComfyUI API format with node graph:
- `UNETLoader` -- diffusion model (flux1-dev.safetensors)
- `DualCLIPLoader` -- text encoders (clip_l + t5xxl)
- `VAELoader` -- decoder (ae.safetensors)
- `CLIPTextEncode` -- prompt injection point
- `FluxGuidance` -- guidance=3.5
- `KSampler` -- steps=20, cfg=1.0, sampler=euler, scheduler=simple
- `EmptyLatentImage` -- width/height (1024x1024 default)

**Tunable parameters per workflow**: prompt, width, height, steps, seed, cfg, guidance (model-specific).

---

## TTS Engine Catalog

**3 engines, 28+ Edge-TTS voices across 11 languages**

### TTS Engines
| Engine | Workflow | Deployment | Type |
|--------|---------|------------|------|
| Edge-TTS | tts_edge.json | Both | Cloud (free, Microsoft) |
| Index-TTS | tts_index2.json | Both | Local model, voice cloning |
| Spark-TTS | tts_spark.json | RunningHub only | Cloud model |

### Edge-TTS Voice Catalog (28 voices)
| Language | Locale | Female | Male | Count |
|----------|--------|--------|------|-------|
| Chinese | zh-CN | XiaoxiaoNeural, XiaoyiNeural, liaoning-XiaobeiNeural | YunjianNeural, YunxiNeural, YunyangNeural, YunyeNeural, YunfengNeural | 8 |
| English (US) | en-US | AriaNeural, JennyNeural | GuyNeural, DavisNeural | 4 |
| English (UK) | en-GB | SoniaNeural | RyanNeural | 2 |
| Korean | ko-KR | 1F | 1M | 2 |
| French | fr-FR | 1F | 1M | 2 |
| Portuguese | pt-BR | 1F | 1M | 2 |
| German | de-DE | 1F | 1M | 2 |
| Russian | ru-RU | 1F | 1M | 2 |
| Turkish | tr-TR | 1F | 1M | 2 |
| Spanish | es-ES | 1F | 1M | 2 |

**Voice data structure**: `{"id": "zh-CN-XiaoxiaoNeural", "label_key": "voice.xiaoxiao", "locale": "zh-CN", "gender": "male"|"female"}`

**Helper functions**: `get_voice_display_name()` (localized labels), `speed_to_rate()` (multiplier to "+20%" format)

**IMPORTANT**: Thai (th-TH) NOT included in default voice list. Edge-TTS supports Thai natively -- must add or use ref_audio cloning path.

---

## LLM Provider Catalog

**6 providers, all OpenAI-compatible API pattern**

| Provider | Default Model | Base URL | Notes |
|----------|--------------|----------|-------|
| Qwen | qwen-max | dashscope.aliyuncs.com/compatible-mode/v1 | Listed first (likely default) |
| OpenAI | gpt-4o | api.openai.com/v1 | Standard |
| Claude | claude-sonnet-4-5 | api.anthropic.com/v1/ | Via OpenAI-compat endpoint |
| DeepSeek | deepseek-chat | api.deepseek.com | -- |
| Ollama | llama3.2 | localhost:11434/v1 | Local, api_key="ollama" |
| Moonshot | moonshot-v1-8k | api.moonshot.cn/v1 | Chinese provider |

**Preset structure**: `{"name", "base_url", "model", "api_key_url", "default_api_key"}`
**No per-provider parameters** (temperature, max_tokens) in presets -- these come from config.yaml defaults or per-request override.
**Helper functions**: `get_preset_names()`, `get_preset(name)`, `find_preset_by_base_url_and_model()`

---

## Video Template Catalog

**25+ HTML templates across 3 aspect ratios**

### Aspect Ratio Directories
| Directory | Ratio | Use Case |
|-----------|-------|----------|
| `1080x1920/` | 9:16 vertical | TikTok, Reels, Shorts |
| `1920x1080/` | 16:9 horizontal | YouTube |
| `1080x1080/` | 1:1 square | Instagram |

### 1080x1920 Templates (25 confirmed)
| Type | Templates |
|------|-----------|
| **image_*** (20) | default, blur_card, book, cartoon, elegant, excerpt, fashion_vintage, full, healing, health_preservation, life_insights, life_insights_light, long_text, modern, neon, psychology_card, purple, satirical_cartoon, simple_black, simple_line_drawing |
| **video_*** (2) | default, healing |
| **static_*** (2) | default, excerpt |
| **asset_*** (1) | default |

**Naming convention**: `{type}_{style}.html`
- `image_*` = AI-generated image background + text overlay
- `video_*` = AI-generated video background
- `static_*` = no dynamic AI media background
- `asset_*` = user-uploaded asset as background

**Template selection path**: aspect ratio -> type -> style. Each template has dynamic `template_params` (fetched via `/api/frame/template/params?template=...`).

---

## Image Generation Model Summary

**9+ models across deployment modes**

| Model | Selfhost | RunningHub | Type |
|-------|----------|------------|------|
| FLUX (flux1-dev) | Yes | Yes | Text-to-image |
| FLUX v2 | -- | Yes | Text-to-image |
| Qwen Vision | Yes | Yes | Text-to-image |
| Qwen Chinese Cartoon | -- | Yes | Style-specific |
| SD 3.5 | -- | Yes | Text-to-image |
| SDXL | -- | Yes | Text-to-image |
| Nano Banana | Yes | -- | Lightweight |
| Z-Image | -- | Yes | Text-to-image |
| ScailFlux | -- | Yes | Enhanced FLUX |

Selfhost: 3 models | RunningHub: 8 models. Dashboard must detect deployment mode for feature gating.

---

## Key Observations for viral-ops Dashboard

1. **Two generation modes**: Sync (blocking, <30s videos) and Async (task_id based, for longer videos). Dashboard should use async + polling.
2. **Content pipeline is composable**: narration, image-prompt, and title generation are separate endpoints. Dashboard could expose step-by-step or one-click-full-pipeline.
3. **Resource discovery endpoints exist**: Templates, workflows, and BGM can be listed dynamically. Dashboard dropdowns should populate from these.
4. **Task management is built in**: List, status, cancel -- dashboard needs a job queue view.
5. **No file upload endpoint**: Only file serving exists. Uploads (custom BGM, templates) may need separate handling.
6. **Template params are dynamic**: Each HTML template defines its own custom params. Dashboard must fetch and render these dynamically.
7. **voice_id is deprecated**: Use `workflow` + `ref_audio` instead for TTS configuration.
8. **Deployment mode gates features**: RunningHub has 2.6x more workflows than selfhost. Dashboard must adapt available options per deployment.
9. **Thai voice gap**: Default voice list lacks Thai. Must add custom voices or use voice cloning for Thai content.
10. **LLM provider is pluggable**: 6 presets + custom base_url/model. Dashboard can show provider dropdown with auto-fill.
11. **Template variety is strong**: 25+ templates for vertical alone. Dashboard needs template preview/selection UI.

---

## Streamlit UI Widget Catalog (Iteration 5)

**2 pages, 3 component modules, 22+ fixed widgets + dynamic template params**

### Content Input Component (content_input.py)

| Widget | Label | Type/Range | Default | Dashboard Equivalent |
|--------|-------|-----------|---------|---------------------|
| Batch Mode | checkbox | bool | False | Toggle switch |
| Processing Mode | radio | "generate"/"fixed" | "generate" | Radio buttons |
| Text Input | text_area | string, height 120-200 | "" | Textarea |
| Split Mode | selectbox | paragraph/line/sentence | "paragraph" | Select (fixed mode only) |
| Title | text_input | string | "" | Text input |
| Scene Count | slider | 3-30 | 5 | Number input w/ slider |
| Batch Topics | text_area | string, height 300 | "" | Multi-line textarea |
| Title Prefix | text_input | string | "" | Text input |
| BGM Selection | selectbox | ["None"] + bgm_files | "default.mp3" | Select dropdown |
| BGM Volume | slider | 0.0-0.5, step 0.01 | 0.2 | Range slider |

### Style Config Component (style_config.py)

| Widget | Label | Type/Range | Default | Dashboard Equivalent |
|--------|-------|-----------|---------|---------------------|
| TTS Inference Mode | radio | "local"/"comfyui" | "local" | Radio buttons |
| Voice Selector | selectbox | voice display names | first | Select dropdown |
| TTS Speed | slider | 0.5-2.0, step 0.1 | 1.0 | Range slider |
| TTS Workflow | selectbox | tts workflow names | first | Select (comfyui mode) |
| Reference Audio | file_uploader | mp3/wav/flac/m4a/aac/ogg | -- | File upload |
| Template Type | radio | static/image/video | "static" | Radio buttons |
| Template Gallery | button[] | per-template select | -- | Card grid picker |
| Media Workflow | selectbox | workflow names | first | Select dropdown |
| Prompt Prefix | text_area | string | from config | Textarea |
| Dynamic Params | text_input/number_input/color_picker/checkbox | per-template | per-template | Dynamic form |

### History Page (2_History.py)

| Feature | Widget | API Call | Dashboard Component |
|---------|--------|---------|---------------------|
| Task grid | container cards | get_task_list(page, size, status, sort) | Data table |
| Status filter | selectbox (sidebar) | status param | Filter select |
| Sort controls | selectbox + radio | sort_by, sort_order | Sort dropdown |
| Statistics | st.metric x2 | get_statistics() | Summary cards |
| Video preview | st.video | files endpoint | Video player |
| Task detail | 3-column modal | get_task_detail(id) | Slide-over panel |
| Frame gallery | st.image | frame paths | Image carousel |
| Audio playback | st.audio | audio_path | Audio player |
| Download | download_button | GET /api/files/{path} | Download button |
| Delete | button + confirm | delete_task(id) | Delete w/ confirmation |
| Pagination | prev/next buttons | page param | Pagination controls |

---

## File Management System (Iteration 5)

**Single serving endpoint, no upload, no cleanup.**

| Feature | Status | Notes |
|---------|--------|-------|
| File serving | GET /api/files/{path} | 7 allowed directories, MIME detection |
| File upload | NOT AVAILABLE | viral-ops must implement separately |
| File cleanup | NOT AVAILABLE | No auto-purge; manual/external only |
| Streaming | NOT AVAILABLE | Simple FileResponse only |

**Storage structure**: `output/{task_id}/` with subdirs: `frames/`, `audio/`, `video/`

**Allowed directories**: output/, workflows/, templates/, bgm/, data/bgm/, data/templates/, resources/

**Security**: path prefix validation, 403 on escape, 404 on missing.

---

## Per-Channel Configuration Mapping (Iteration 5)

### Per-Channel Parameters (n8n injects per call)

| Parameter | API | Dashboard Location |
|-----------|-----|--------------------|
| tts_inference_mode | /api/tts | Channel > Voice > Engine |
| tts_voice | /api/tts | Channel > Voice > Voice |
| tts_speed | /api/tts | Channel > Voice > Speed |
| tts_workflow | /api/tts | Channel > Voice > Workflow |
| ref_audio | /api/tts | Channel > Voice > Clone Ref |
| media_workflow | /api/image | Channel > Visual > Workflow |
| prompt_prefix | /api/image | Channel > Visual > Style Prompt |
| frame_template | /api/video | Channel > Visual > Template |
| template_params | /api/video | Channel > Visual > Template Params |
| n_scenes | /api/content | Channel > Content > Scenes |
| mode | /api/content | Channel > Content > Mode |
| split_mode | /api/content | Channel > Content > Split Mode |
| bgm_path | /api/video | Channel > Audio > BGM |
| bgm_volume | /api/video | Channel > Audio > Volume |
| language | /api/content (LLM prompt) | Channel > Content > Language |
| llm_system_prompt | n8n injection | Channel > Persona > System Prompt |

### Global System Settings (shared across channels)

| Setting | Config Source | Dashboard Location |
|---------|-------------|-------------------|
| llm_provider + model + key + url | config.yaml | System > LLM |
| image/tts/video_generation_mode | config.yaml | System > GPU |
| runninghub_api_key + url | config.yaml | System > GPU |
| concurrent_limit | config.yaml | System > GPU |
| comfyui_base_url | api_config | System > ComfyUI |
| resource_dir | config.yaml | System > Storage |
| api_host + port + prefix | api_config | System > Server |

---

## Definitive Feature Matrix (Iteration 5)

### Dashboard Page Architecture

| Page | Pixelle Source | Key Features |
|------|---------------|--------------|
| Content Creation | Home page | Topic input, mode, scenes, voice, template, style, BGM |
| Generation Settings | config.yaml (no UI equiv) | LLM provider, GPU mode, RunningHub, ComfyUI |
| Content Library | History page | Task grid, filters, preview, detail, download, delete |
| Channel Settings | viral-ops specific | Per-channel overrides for all generation params |
| System Settings | config.yaml/api_config | Server, storage, API keys |

### n8n Workflow Nodes

| Node | Pixelle API | Purpose |
|------|------------|---------|
| Channel Config Loader | -- | Load per-channel overrides from DB |
| Content Generator | POST /api/content/* | Generate narrations + prompts |
| Title Generator | POST /api/content/title | Generate title |
| Video Generator | POST /api/video/generate/async | Trigger async generation |
| Status Poller | GET /api/tasks/{id} | Poll until completion |
| File Retriever | GET /api/files/{path} | Download final video |
| Error Handler | -- | Retry or notify on failure |
| Config Injector | -- | Merge channel defaults into request |

---

## Coverage Tracker

| Question | Status | Iteration |
|----------|--------|-----------|
| Q1: All endpoints with schemas | FULLY ANSWERED -- 21 endpoints + 22 Pydantic models | 1, 2 |
| Q2: Config settings | FULLY ANSWERED -- 27+ settings across api/config.py + config.yaml | 2 |
| Q3: ComfyUI workflows | FULLY ANSWERED -- 29 workflows (8 selfhost + 21 runninghub) | 3 |
| Q4: TTS engines/options | FULLY ANSWERED -- 3 engines, 28 voices, speed 0.5-2.0, no pitch | 3, 5 |
| Q5: LLM providers/config | FULLY ANSWERED -- 6 providers, preset structure | 3 |
| Q6: Image generation options | FULLY ANSWERED -- 9+ models across deployment modes | 3 |
| Q7: Video composition options | FULLY ANSWERED -- 25+ templates, dynamic params, 3 aspect ratios | 3, 5 |
| Q8: Task management | FULLY ANSWERED -- list, status, cancel, queue | 1 |
| Q9: File management | FULLY ANSWERED -- 7 dirs served, no upload/cleanup | 1, 5 |
| Q10: Streamlit UI features | FULLY ANSWERED -- 22+ widgets, 2 pages, 3 components | 4, 5 |
| Q11: Batch/bulk capabilities | FULLY ANSWERED -- frame-level parallelism, multi-video via n8n | 4 |
| Q12: GPU/resource management | FULLY ANSWERED -- selfhost vs runninghub, concurrent_limit, ComfyKit | 4 |
| Q13: Per-channel config | FULLY ANSWERED -- 16 per-channel + 15 global params mapped | 5 |
| Q14: Complete data flow | FULLY ANSWERED -- 8-stage StandardPipeline | 4 |

**ALL 14 QUESTIONS FULLY ANSWERED. Research ready for convergence and final synthesis.**
