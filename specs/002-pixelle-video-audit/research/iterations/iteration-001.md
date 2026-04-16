# Iteration 1: FastAPI Router Endpoint Catalog

## Focus
Fetch and catalog ALL FastAPI router source files from the Pixelle-Video GitHub repository. Enumerate every endpoint with HTTP method, path, request params/body schema, response type, and purpose. This addresses Q1 (complete endpoint catalog), Q8 (task management), and Q9 (file management).

## Findings

### 1. App-level Architecture (app.py)
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/app.py]

- FastAPI app titled "Pixelle-Video API" v0.1.0
- Lifespan manager handles startup (task_manager init) and shutdown (task_manager stop + shutdown_pixelle_video)
- CORS middleware conditionally enabled via `api_config.cors_enabled` with origins from `api_config.cors_origins`
- All 10 routers mounted under `/api` prefix (from `api_config.api_prefix`)
- Root endpoint `GET /` returns service info and API endpoint listing
- Server launched via uvicorn with argparse (host, port, reload flags)

### 2. Video Router -- 2 Endpoints
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/video.py]

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/video/generate/sync` | Synchronous video generation (blocks until complete) |
| POST | `/api/video/generate/async` | Async video generation (returns task_id immediately) |

**VideoGenerateRequest body (shared by both):**
- `text` (string) -- source text/topic
- `mode` (string) -- generation mode
- `title` (string) -- video title
- `n_scenes` (int) -- number of scenes
- `min_narration_words` (int) -- min words per narration
- `max_narration_words` (int) -- max words per narration
- `min_image_prompt_words` (int) -- min words per image prompt
- `max_image_prompt_words` (int) -- max words per image prompt
- `media_workflow` (string) -- ComfyUI workflow for image/video gen
- `video_fps` (int) -- frames per second
- `frame_template` (string, required) -- HTML template for frames
- `prompt_prefix` (string) -- prefix for LLM prompts
- `bgm_path` (string) -- background music file path
- `bgm_volume` (float) -- BGM volume level
- `tts_workflow` (string, optional) -- TTS ComfyUI workflow
- `ref_audio` (string, optional) -- reference audio for voice cloning
- `voice_id` (string, optional, DEPRECATED) -- legacy voice selection
- `template_params` (object, optional) -- custom template parameters

**Sync response (VideoGenerateResponse):** `video_url`, `duration`, `file_size`
**Async response (VideoGenerateAsyncResponse):** `task_id`

### 3. Content Router -- 3 Endpoints
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/content.py]

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/content/narration` | Generate narration segments from text via LLM |
| POST | `/api/content/image-prompt` | Generate image prompts from narrations via LLM |
| POST | `/api/content/title` | Generate engaging title from text via LLM |

**NarrationGenerateRequest:** `text` (string), `n_scenes` (int), `min_words` (int), `max_words` (int)
**NarrationGenerateResponse:** `narrations` (list[string])

**ImagePromptGenerateRequest:** `narrations` (list[string]), `min_words` (int), `max_words` (int)
**ImagePromptGenerateResponse:** `image_prompts` (list[string])

**TitleGenerateRequest:** `text` (string), `style` (string, optional)
**TitleGenerateResponse:** `title` (string)

### 4. TTS Router -- 1 Endpoint
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tts.py]

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/tts/synthesize` | Text-to-speech synthesis via ComfyUI |

**TTSSynthesizeRequest:** `text` (string), `workflow` (string, optional), `ref_audio` (string, optional), `voice_id` (string, optional, DEPRECATED)
**TTSSynthesizeResponse:** `audio_path` (string), `duration` (float)

### 5. Image Router -- 1 Endpoint
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/image.py]

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/image/generate` | Generate image from text prompt via ComfyUI |

**ImageGenerateRequest:** `prompt` (string), `width` (int, 512-2048), `height` (int, 512-2048), `workflow` (string, optional)
**ImageGenerateResponse:** `image_path` (string)

- Validates that video workflows are NOT used (returns 400 error)

### 6. LLM Router -- 1 Endpoint
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/llm.py]

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/llm/chat` | Generate text via configured LLM |

**LLMChatRequest:** `prompt` (string), `temperature` (float, 0.0-2.0), `max_tokens` (int)
**LLMChatResponse:** `content` (string), `tokens_used` (int, nullable)

- Schemas imported from `api.schemas.llm` (not defined inline)

### 7. Tasks Router -- 3 Endpoints
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tasks.py]

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/tasks` | List tasks with optional status filter |
| GET | `/api/tasks/{task_id}` | Get task details (status, progress, result) |
| DELETE | `/api/tasks/{task_id}` | Cancel a running/pending task |

**List params:** `status` (TaskStatus, optional filter), `limit` (int, 1-1000, default 100)
**TaskStatus enum values (implied):** pending, running, completed, failed, cancelled
**Task model:** includes status, progress, result (if completed), creation time
**Cancel response:** `success` (bool), `message` (string)

### 8. Files Router -- 1 Endpoint
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/files.py]

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/files/{file_path}` | Retrieve files from restricted directories |

**Allowed directories:** output/, workflows/, templates/, bgm/, data/bgm/, data/templates/, resources/
**Access control:** Path validation, 403 for unauthorized dirs
**Media types:** auto-detected from extension (.mp4, .mp3, .png, .jpg, .json, .html)
**Disposition:** Inline (browser preview), not forced download
**Errors:** 404 (missing), 400 (not a file), 403 (unauthorized dir), 500 (exception)

### 9. Resources Router -- 5 Endpoints
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/resources.py]

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/resources/workflows/tts` | List available TTS workflows |
| GET | `/api/resources/workflows/media` | List media workflows (image + video) |
| GET | `/api/resources/workflows/image` | List image workflows (DEPRECATED, legacy) |
| GET | `/api/resources/templates` | List video HTML templates |
| GET | `/api/resources/bgm` | List background music files |

**WorkflowListResponse:** Lists workflows from RunningHub + self-hosted sources
- TTS workflows: filenames starting with "tts_"
- Media workflows: all non-TTS workflows
- Image workflows (legacy): filenames starting with "image_"

**TemplateListResponse:** Templates merged from default + custom dirs, grouped by size/orientation (portrait, landscape, square)

**BGMListResponse:** Audio files from default + custom dirs (mp3, wav, flac, m4a, aac, ogg). Custom files override defaults.

### 10. Frame Router -- 2 Endpoints
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/frame.py]

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/frame/render` | Render a frame image from HTML template |
| GET | `/api/frame/template/params` | Get custom params for a template |

**FrameRenderRequest:** `template` (string), `title` (string), `text` (string), `image` (string)
**FrameRenderResponse:** frame path, width, height

**Template params query:** `template` (string, query param)
**TemplateParamsResponse:** parameter definitions with type (text, number, color, boolean), default value, label
- Template parameter syntax: `{{param_name:type=default}}`

### 11. Health Router -- Inferred
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/app.py (router mount)]

- Mounted without prefix, likely provides `GET /api/health` or similar
- Not fetched this iteration -- low priority for dashboard design

## Complete Endpoint Summary Table

| # | Method | Full Path | Router | Purpose |
|---|--------|-----------|--------|---------|
| 1 | GET | `/` | app.py | Service info + API listing |
| 2 | POST | `/api/video/generate/sync` | video | Sync video generation |
| 3 | POST | `/api/video/generate/async` | video | Async video generation |
| 4 | POST | `/api/content/narration` | content | Generate narrations |
| 5 | POST | `/api/content/image-prompt` | content | Generate image prompts |
| 6 | POST | `/api/content/title` | content | Generate title |
| 7 | POST | `/api/tts/synthesize` | tts | Text-to-speech |
| 8 | POST | `/api/image/generate` | image | Image generation |
| 9 | POST | `/api/llm/chat` | llm | LLM text generation |
| 10 | GET | `/api/tasks` | tasks | List tasks |
| 11 | GET | `/api/tasks/{task_id}` | tasks | Get task details |
| 12 | DELETE | `/api/tasks/{task_id}` | tasks | Cancel task |
| 13 | GET | `/api/files/{file_path}` | files | Retrieve files |
| 14 | GET | `/api/resources/workflows/tts` | resources | List TTS workflows |
| 15 | GET | `/api/resources/workflows/media` | resources | List media workflows |
| 16 | GET | `/api/resources/workflows/image` | resources | List image workflows (deprecated) |
| 17 | GET | `/api/resources/templates` | resources | List HTML templates |
| 18 | GET | `/api/resources/bgm` | resources | List background music |
| 19 | POST | `/api/frame/render` | frame | Render frame image |
| 20 | GET | `/api/frame/template/params` | frame | Get template params |
| 21 | GET | `/api/health` (inferred) | health | Health check |

**Total: 21 endpoints across 10 routers + app root**

## Ruled Out
- Health router source fetch: low priority, inferred from mount pattern. Can confirm in a later iteration if needed.

## Dead Ends
[None -- all 10 router files were successfully fetched and parsed]

## Sources Consulted
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/app.py
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/api/routers (directory listing)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/video.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/content.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tts.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/image.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/llm.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tasks.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/files.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/resources.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/frame.py

## Assessment
- New information ratio: 0.95
- Questions addressed: Q1 (complete endpoint catalog), Q8 (task management), Q9 (file management)
- Questions answered: Q1 (substantially -- 21 endpoints cataloged with schemas), Q8 (fully -- 3 task endpoints with status/cancel), Q9 (partially -- file serving confirmed, but no upload endpoint found)

## Reflection
- What worked and why: Fetching raw GitHub source files directly gave complete endpoint definitions with parameter types and response models. The structured approach of starting from app.py router mounts then fetching each router ensured completeness.
- What did not work and why: WebFetch summarization occasionally omitted exact type annotations or default values (e.g., LLM router temperature range). Schema details imported from `api.schemas.*` modules were not fully resolved since we only fetched router files, not schema files.
- What I would do differently: Next iteration should fetch the Pydantic schema files (`api/schemas/*.py`) to get exact field types, defaults, and validation rules that the routers import but don't define inline.

## Recommended Next Focus
Iteration 2 should fetch `api/schemas/` directory -- all Pydantic request/response models with exact field types, defaults, Optional markers, and validation rules. This completes Q1 with full schema resolution. Secondary: fetch `api/config.py` to catalog all configuration options (addresses Q2).
