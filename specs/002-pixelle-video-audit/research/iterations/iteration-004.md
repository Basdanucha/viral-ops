# Iteration 4: Streamlit UI Architecture + Complete Data Flow Pipeline + Batch/GPU Processing

## Focus
This iteration investigated Q10 (Streamlit UI feature set), Q14 (complete data flow), Q11 (batch/bulk generation), and Q12 (GPU/resource management). The strategy recommended fetching the Streamlit app source, the core pipeline orchestrator, and batch processing patterns.

## Findings

### F1: Streamlit App Architecture — Multi-page with Dynamic Pipeline Tabs
The Streamlit UI is at `web/app.py` (launched via `uv run streamlit run web/app.py`). The app uses a 2-page structure:
- **Home** (`web/pages/1_Home.py`) — Main video generation interface
- **History** (`web/pages/2_History.py`) — Past generation history browser

The Home page dynamically loads pipeline UIs via `get_all_pipeline_uis()`, rendering each as a separate `st.tab`. The web module structure is:
```
web/
  app.py              # Entry point, page config, navigation
  pages/              # Streamlit multi-page routing
  components/         # Reusable UI widgets (content_input, style_config, output_preview)
  pipelines/          # Pipeline-specific UI renderers
  state/              # Session state management
  i18n/               # Internationalization (multi-language)
  utils/              # UI utilities
```
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/app.py]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/web]

### F2: Standard Pipeline UI — 3-Column Layout with Component Delegation
The `StandardPipelineUI` renders a 3-column layout:
- **Left column**: Content input (`render_content_input()`), BGM selection (`render_bgm_section()`), version info
- **Middle column**: Style configuration (`render_style_config(pixelle_video)`) — template, voice, image workflow
- **Right column**: Output preview (`render_output_preview(pixelle_video, video_params)`)

Actual widget definitions (selectboxes, sliders, text areas) are in `web/components/content_input.py`, `web/components/style_config.py`, and `web/components/output_preview.py`. These were not fetchable within budget but the component structure is clear.
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/pipelines/standard.py]

### F3: Core Service Architecture — PixelleVideoCore as Central Orchestrator
`pixelle_video/service.py` defines `PixelleVideoCore`, the central orchestrator that initializes and manages:
- **LLMService** — Script/narration generation
- **TTSService** — Text-to-speech audio
- **MediaService** — Image/video generation
- **ImageAnalysisService** — Image analysis
- **VideoAnalysisService** — Video analysis
- **VideoService** — Video concatenation/composition
- **FrameProcessor** — Per-frame rendering (audio + image + template compositing)
- **PersistenceService** — Task metadata storage
- **HistoryManager** — Generation history tracking

ComfyKit is lazy-initialized with hot-reload detection (MD5 hash of config state) for configuration changes.
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/service.py]

### F4: Pipeline Architecture — 4 Pipeline Types with Template Method Pattern
The `pixelle_video/pipelines/` module contains 5 files implementing 4 pipeline types:
1. **`base.py`** — Base pipeline interface/ABC
2. **`linear.py`** — LinearVideoPipeline base (sequential frame processing)
3. **`standard.py`** — StandardPipeline (extends LinearVideoPipeline) — the main pipeline
4. **`custom.py`** — CustomPipeline (user-customized workflows)
5. **`asset_based.py`** — AssetBasedPipeline (generates from existing assets)

Each pipeline is registered and appears as a tab in the Streamlit UI via `get_all_pipeline_uis()`.
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/pixelle_video/pipelines]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/service.py]

### F5: COMPLETE Data Flow — 8-Stage Pipeline (Topic to Video)
The StandardPipeline implements an 8-stage lifecycle:

| Stage | Method | Input | Output | Artifacts |
|-------|--------|-------|--------|-----------|
| 1. Setup | `setup_environment()` | task params | task_id, task_dir | Task directory created |
| 2. Content | `generate_content()` | topic OR fixed script | narrations[] | Script segments (in memory) |
| 3. Title | `determine_title()` | narrations | title string | Title (in memory) |
| 4. Visual Plan | `plan_visuals()` | narrations, template type | image_prompts[] | Image prompts (in memory) |
| 5. Storyboard | `initialize_storyboard()` | narrations, prompts, config | Storyboard object | StoryboardFrame objects |
| 6. Assets | `produce_assets()` | storyboard frames | audio + images + video segments | .mp3/.wav audio, .png images, .mp4 segments per frame |
| 7. Post-prod | `post_production()` | video segments | final video | Concatenated .mp4, BGM mixed |
| 8. Finalize | `finalize()` | final video | VideoGenerationResult | Metadata JSON, storyboard JSON |

Content generation has two modes:
- **"generate"** mode: LLM creates narrations from topic (controlled by `n_scenes` parameter)
- **"fixed"** mode: User-provided script split into segments by line

Progress callback reports granular percentages: narration 5%, title 1%, image prompts 15%, frame processing 60%, concatenation 85%, completion 100%.
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py]

### F6: Per-Frame Asset Production — TTS + Image + Template Rendering
Stage 6 (`produce_assets`) processes each frame through `FrameProcessor`:
1. **TTS generation** — Converts narration text to audio via TTSService (voice_id, speed)
2. **Image generation** — Generates visual via ComfyUI workflow (image_prompt → FLUX/SD/WAN)
3. **Template rendering** — Composites audio + image into HTML template frame
4. **Video segment** — Renders frame to video segment (.mp4)

Each frame produces: `frame.duration` (from audio length) and `frame.video_segment_path` (segment file path).
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py]

### F7: Batch Processing — Per-Frame Parallelism, NOT Per-Video Batch
**Critical finding**: Batch processing is at the FRAME level, not the video level:
- **RunningHub (cloud GPU)**: Frames processed in parallel with `asyncio.Semaphore(runninghub_concurrent_limit)` — configurable concurrency
- **Self-hosted (local GPU)**: Frames processed sequentially (serial loop)

The API's `video_count` parameter (from iteration 1) controls `n_scenes` (number of frames/narration segments), NOT number of separate videos. True multi-video batch generation is NOT a built-in feature — it would need to be orchestrated externally (e.g., via n8n looping over the API).
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py]
[INFERENCE: based on API schema video_count mapping to n_scenes + absence of multi-video loop in pipeline code]

### F8: GPU/Resource Management — RunningHub Cloud vs Local Self-Host
Two execution modes with automatic detection:
- **RunningHub (cloud)**: Detected via `is_runninghub` flag from workflow configuration. Uses cloud GPU via API key (`runninghub_api_key` in config). Parallel frame processing enabled with configurable `runninghub_concurrent_limit`.
- **Self-hosted (local)**: Default mode. Serial frame processing. ComfyKit initialized lazily with hot-reload.

No per-request GPU switching — the mode is determined by workflow selection (RunningHub workflows vs selfhost workflows). Config-based, not request-based.
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/service.py]

### F9: Configuration Parameters for Standard Pipeline
Complete parameter set for a single video generation:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mode` | "generate" | Content source: "generate" (LLM) or "fixed" (user script) |
| `n_scenes` | 5 | Number of narration segments / frames |
| `title` | Auto-generated | Video title (LLM generates if not provided) |
| `frame_template` | "1080x1920/default.html" | HTML template for frame rendering |
| `voice_id` | "zh-CN-YunjianNeural" | TTS voice selection |
| `tts_speed` | 1.2 | Speech rate multiplier |
| `video_fps` | 30 | Output frame rate |
| `bgm_path` | None | Background music file path |
| `bgm_volume` | 0.2 | BGM volume (0.0-1.0) |
| `prompt_prefix` | Config value | Prefix added to all image generation prompts |
| `output_path` | Task directory | Custom output location |

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py]

### F10: Task Persistence and History
- **Task ID**: Generated during `setup_environment()`, used as primary key for all artifacts
- **Persistence**: `PersistenceService.save_task_metadata()` stores task config + result metadata as JSON
- **Storyboard**: `PersistenceService.save_storyboard()` stores frame-by-frame details
- **History**: `HistoryManager` provides browsable history (powering the History page in Streamlit)
- **Result object**: `VideoGenerationResult(video_path, storyboard, duration, file_size)`

Persistence failures are non-fatal (logged as warnings, don't break video output).
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/service.py]

## Ruled Out
- `webui/` directory path — does not exist; the Streamlit UI is at `web/` instead
- `pixelle_video/content.py` — does not exist as a standalone file; content generation is embedded in pipeline stages
- `pixelle_video/services/content.py` — does not exist; the service layer is flat at `pixelle_video/service.py`

## Dead Ends
- None. All paths that returned 404 were quickly corrected by discovering the actual repository structure.

## Sources Consulted
- https://github.com/AIDC-AI/Pixelle-Video/tree/main (root directory listing)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/app.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/pages/1_Home.py (via encoded URL)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/web
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/service.py
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/pixelle_video
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/pixelle_video/pipelines
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/pixelle_video/pipelines/standard.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/pipelines/standard.py

## Assessment
- New information ratio: 0.90
- Questions addressed: Q10, Q11, Q12, Q14
- Questions answered: Q10-substantial, Q11-full, Q12-full, Q14-full

## Reflection
- What worked and why: Fetching the repository root listing first (when initial paths 404'd) quickly revealed the correct directory structure (`web/` not `webui/`, `pixelle_video/service.py` not `pixelle_video/services/`). The StandardPipeline source was the single most valuable fetch — it contained the complete 8-stage data flow, batch processing logic, GPU mode switching, and all configuration parameters.
- What did not work and why: Initial 3 fetches all 404'd because path assumptions from iteration 1 (which only looked at `api/` routers) were wrong for the core package and UI. The web component files (content_input.py, style_config.py) could not be fetched within budget, leaving exact widget definitions incomplete.
- What I would do differently: Start with directory listing fetches before assuming file paths. For iteration 5, fetch `web/components/content_input.py` and `web/components/style_config.py` to complete Q10 with exact widget specs.

## Recommended Next Focus
Iteration 5 should:
1. **Complete Q10** — Fetch `web/components/content_input.py`, `web/components/style_config.py`, `web/components/output_preview.py` to get exact Streamlit widget definitions (selectboxes, sliders, text areas with labels/defaults/options)
2. **Q13: Per-channel config mapping** — Synthesize all findings (iter 1-4) into the definitive per-channel configuration table mapping viral-ops channel fields to Pixelle-Video API parameters
3. **History page** — Fetch `web/pages/2_History.py` to understand what history/task browsing features exist
