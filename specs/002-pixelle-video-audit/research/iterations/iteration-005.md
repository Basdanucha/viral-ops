# Iteration 5: Final Discovery — UI Widget Catalog, Per-Channel Config Mapping, File Management, Feature Matrix

## Focus
Complete the remaining 3 questions (Q10 full widget specs, Q13 per-channel config mapping, Q9 file management) and produce the definitive feature matrix mapping every Pixelle-Video feature to viral-ops dashboard surfaces. This is the final discovery iteration.

## Findings

### F1: Complete Streamlit Widget Catalog (Q10 — FULLY ANSWERED)

**content_input.py — `render_content_input()` returns dict**

| # | Widget | Label | Options/Range | Default | Dashboard Field |
|---|--------|-------|--------------|---------|-----------------|
| 1 | st.checkbox | "Batch Mode" | bool | False | Toggle: single vs batch |
| 2 | st.radio | Processing Mode | ["generate", "fixed"] | "generate" | Radio: AI-generate or paste text |
| 3 | st.text_area | Text Input | height 120-200 | "" | Textarea: topic or fixed script |
| 4 | st.selectbox | Split Mode (fixed only) | ["paragraph", "line", "sentence"] | "paragraph" | Select: text splitting strategy |
| 5 | st.text_input | Title | string | "" | Text input: video title |
| 6 | st.slider | Number of Scenes | 3–30 | 5 | Number input: scene count |
| 7 | st.text_area | Batch Topics | height 300 | "" | Textarea: one topic per line |
| 8 | st.text_input | Title Prefix (batch) | string | "" | Text input: batch title prefix |

**content_input.py — `render_bgm_section()` returns dict**

| # | Widget | Label | Options/Range | Default | Dashboard Field |
|---|--------|-------|--------------|---------|-----------------|
| 9 | st.selectbox | BGM Selection | ["None"] + bgm_files | "default.mp3" | Select: background music |
| 10 | st.slider | BGM Volume | 0.0–0.5, step 0.01 | 0.2 | Range slider: volume |
| 11 | st.button | BGM Preview | — | — | Play button (audio preview) |

**style_config.py — `render_style_config(pixelle_video)` returns dict**

| # | Widget | Label | Options/Range | Default | Dashboard Field |
|---|--------|-------|--------------|---------|-----------------|
| 12 | st.radio | TTS Inference Mode | ["local", "comfyui"] | "local" | Radio: TTS engine mode |
| 13 | st.selectbox | Voice Selector | voice display names | first voice | Select: TTS voice |
| 14 | st.slider | TTS Speed | 0.5–2.0, step 0.1 | 1.0 | Range slider: speech speed |
| 15 | st.selectbox | TTS Workflow (comfyui) | workflow names | first | Select: TTS ComfyUI workflow |
| 16 | st.file_uploader | Reference Audio | mp3/wav/flac/m4a/aac/ogg | — | File upload: voice clone ref |
| 17 | st.radio | Template Type | ["static", "image", "video"] | "static" | Radio: frame template category |
| 18 | st.button[] | Template Gallery | per-template select | — | Card grid: template picker |
| 19 | st.selectbox | Media Workflow | workflow display names | first | Select: image/video gen workflow |
| 20 | st.text_area | Prompt Prefix | string | from config | Textarea: style prompt prefix |
| 21 | st.text_input | Test Prompt | string | "a dog" | Text input: preview prompt |
| 22 | st.button | Preview Style | — | — | Button: generate preview |

**Dynamic template params** (per-template custom fields):
- st.text_input / st.number_input / st.color_picker / st.checkbox — rendered dynamically per template's declared parameters

**Total: 22+ fixed widgets + dynamic template params across 2 component files**

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/components/content_input.py]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/components/style_config.py]

---

### F2: History Page Complete Feature Set (Q10 supplement)

**Pages: `1_Home.py` (generation), `2_History.py` (task browser)**

History page capabilities:
- **Task list grid** with video thumbnail, title, status emoji, duration, frame count, creation date
- **Status filter**: all / completed / failed / running / pending (sidebar selectbox)
- **Sort**: by created_at / completed_at / title / duration (selectbox) + asc/desc (radio)
- **Pagination**: page_size 15/30/60, prev/next buttons
- **Statistics**: completed count + failed count (st.metric in sidebar)
- **Detail modal** (3-column): full storyboard frames, composed images, narration audio, video segments
- **Actions per task**: View details, Download MP4, Delete (with confirmation dialog)
- **No re-run capability** — re-generation requires going back to Home page
- **Preview**: st.video() for output + segments, st.image() for frames, st.audio() for narration

API integration:
- `pixelle_video.history.get_task_list(page, page_size, status, sort_by, sort_order)` → {tasks[], total, total_pages}
- `pixelle_video.history.get_task_detail(task_id)` → full metadata + storyboard
- `pixelle_video.history.delete_task(task_id)` → success/message
- `pixelle_video.history.get_statistics()` → completed/failed counts

File paths referenced: `video_path`, `frame.composed_image_path`, `frame.image_path`, `frame.audio_path`, `frame.video_segment_path`

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/pages/2_%F0%9F%93%9A_History.py]

---

### F3: File Management System (Q9 — FULLY ANSWERED)

**Files router** (`api/routers/files.py`): Single endpoint serving generated assets.

| Endpoint | Method | Path | Purpose |
|----------|--------|------|---------|
| Serve file | GET | `/api/files/{file_path:path}` | Serve any file from allowed directories |

**Allowed directories** (7 categories, priority-ordered):
1. `output/` — Generated videos, images, audio (DEFAULT fallback)
2. `workflows/` — ComfyUI workflow JSON files
3. `templates/` — HTML template files
4. `bgm/` — Default background music
5. `data/bgm/` — Custom/user background music
6. `data/templates/` — Custom/user templates
7. `resources/` — Miscellaneous assets (images, fonts, examples)

**File serving features**:
- MIME type detection by extension (mp4, mp3, wav, png, jpg, gif, html, json)
- `inline` Content-Disposition for browser preview
- Fallback to `application/octet-stream`
- Path validation: must start with allowed prefix, resolved path must stay within boundaries
- Security: 403 if path escapes, 404 if nonexistent

**No upload endpoint** — files are generated by the pipeline, not uploaded by users.
**No cleanup/deletion endpoint** — file cleanup is manual or external (no auto-purge).
**No streaming/range-request support** — simple FileResponse only.

**Storage structure** (from config + pipeline analysis):
- `output/{task_id}/` — per-task output directory
- `output/{task_id}/frames/` — composed frame images
- `output/{task_id}/audio/` — narration audio segments
- `output/{task_id}/video/` — video segments + final output
- `resources/` — shared resources (fonts, example images)
- `data/` — user-customizable assets (bgm, templates)

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/files.py]
[INFERENCE: Storage structure inferred from pipeline output patterns (iteration 4 StandardPipeline) + files router allowed directories]

---

### F4: Per-Channel Configuration Mapping (Q13 — FULLY ANSWERED)

Synthesis from ALL iterations (1-5): which Pixelle-Video parameters should be per-channel in viral-ops, and which are global system settings.

#### PER-CHANNEL PARAMETERS (n8n injects before each API call)

| Pixelle-Video Parameter | API Endpoint | Type | Options | Dashboard Surface |
|------------------------|-------------|------|---------|-------------------|
| tts_inference_mode | /api/tts | enum | "local" / "comfyui" | Channel Settings > Voice > Engine |
| voice (tts_voice) | /api/tts | string | 28 voices across Edge-TTS/ChatTTS/Index | Channel Settings > Voice > Voice |
| tts_speed | /api/tts | float | 0.5–2.0 | Channel Settings > Voice > Speed |
| tts_workflow | /api/tts | string | tts_* ComfyUI workflows | Channel Settings > Voice > Workflow |
| ref_audio | /api/tts | file path | uploaded audio file | Channel Settings > Voice > Clone Reference |
| media_workflow | /api/image | string | image/video ComfyUI workflows | Channel Settings > Visual Style > Workflow |
| prompt_prefix | /api/image | string | free text | Channel Settings > Visual Style > Style Prompt |
| frame_template | /api/video | string | template path (static/image/video) | Channel Settings > Visual Style > Template |
| template_params | /api/video | dict | per-template custom params | Channel Settings > Visual Style > Template Params |
| n_scenes | /api/content | int | 3–30 | Channel Settings > Content > Scenes |
| mode | /api/content | enum | "generate" / "fixed" | Channel Settings > Content > Mode |
| split_mode | /api/content | enum | "paragraph" / "line" / "sentence" | Channel Settings > Content > Split Mode |
| bgm_path | /api/video | string | bgm file path | Channel Settings > Audio > BGM |
| bgm_volume | /api/video | float | 0.0–0.5 | Channel Settings > Audio > BGM Volume |
| language | /api/content | string | via LLM prompt template | Channel Settings > Content > Language |
| llm_system_prompt | n8n injection | string | free text (NOT in API) | Channel Settings > Persona > System Prompt |

#### GLOBAL SYSTEM SETTINGS (shared across all channels)

| Setting | Config Source | Type | Dashboard Surface |
|---------|-------------|------|-------------------|
| llm_provider | config.yaml > llm_provider | enum (gpt/qwen/deepseek/ollama/...) | System Settings > LLM |
| llm_model | config.yaml > llm_model | string | System Settings > LLM |
| llm_api_key | config.yaml > llm_api_key | secret | System Settings > LLM |
| llm_base_url | config.yaml > llm_base_url | URL | System Settings > LLM |
| image_generation_mode | config.yaml | enum (selfhost/runninghub) | System Settings > GPU |
| tts_generation_mode | config.yaml | enum (selfhost/runninghub) | System Settings > GPU |
| video_generation_mode | config.yaml | enum (selfhost/runninghub) | System Settings > GPU |
| runninghub_api_key | config.yaml | secret | System Settings > GPU |
| runninghub_base_url | config.yaml | URL | System Settings > GPU |
| concurrent_limit | config.yaml | int (1-10) | System Settings > GPU |
| comfyui_base_url | api_config | URL | System Settings > ComfyUI |
| resource_dir | config.yaml | path | System Settings > Storage |
| output_dir | implicit | path | System Settings > Storage |
| api_host / api_port | api_config | string/int | System Settings > Server |
| api_prefix | api_config | string | System Settings > Server |

[INFERENCE: Synthesized from iterations 1-4 endpoint schemas + iteration 5 widget analysis. Per-channel = parameters that appear in API request bodies or UI style_config return dict. Global = parameters in config.yaml/api_config that affect all requests.]

---

### F5: Definitive Feature Matrix — Pixelle-Video to viral-ops Dashboard

#### Page 1: Content Creation (maps to Streamlit Home page)

| Feature | Pixelle Source | Widget Type | API Param | Form Field |
|---------|---------------|-------------|-----------|------------|
| Topic/script input | content_input.py | text_area | text | Topic textarea |
| Content mode | content_input.py | radio | mode | Toggle: generate/fixed |
| Text split mode | content_input.py | selectbox | split_mode | Select (fixed mode only) |
| Video title | content_input.py | text_input | title | Text input |
| Scene count | content_input.py | slider 3-30 | n_scenes | Number input with slider |
| Batch mode | content_input.py | checkbox | batch_mode | Toggle switch |
| Batch topics | content_input.py | text_area | topics[] | Multi-line textarea |
| Batch title prefix | content_input.py | text_input | title_prefix | Text input |
| BGM selection | content_input.py | selectbox | bgm_path | Select from /api/resources/bgm |
| BGM volume | content_input.py | slider 0-0.5 | bgm_volume | Range slider |
| TTS mode | style_config.py | radio | tts_inference_mode | Radio: local/comfyui |
| TTS voice | style_config.py | selectbox | tts_voice | Select from voice list |
| TTS speed | style_config.py | slider 0.5-2.0 | tts_speed | Range slider |
| TTS workflow | style_config.py | selectbox | tts_workflow | Select from /api/resources/workflows/tts |
| Voice clone ref | style_config.py | file_uploader | ref_audio | File upload (audio) |
| Template type | style_config.py | radio | — | Radio: static/image/video |
| Template selection | style_config.py | button gallery | frame_template | Card grid picker |
| Template params | style_config.py | dynamic | template_params | Dynamic form fields |
| Media workflow | style_config.py | selectbox | media_workflow | Select from /api/resources/workflows/media |
| Prompt prefix | style_config.py | text_area | prompt_prefix | Textarea |
| Generate button | Home page | button | POST /api/video/generate/async | Submit button |

#### Page 2: Generation Settings (global config — no Streamlit equivalent)

| Feature | Config Source | Type | Form Field |
|---------|-------------|------|------------|
| LLM provider | config.yaml > llm_provider | enum | Select: gpt/qwen/deepseek/ollama/gemini/zhipu |
| LLM model | config.yaml > llm_model | string | Text input |
| LLM API key | config.yaml > llm_api_key | secret | Password input |
| LLM base URL | config.yaml > llm_base_url | URL | Text input |
| GPU mode (image) | config.yaml > image_generation_mode | enum | Radio: selfhost/runninghub |
| GPU mode (TTS) | config.yaml > tts_generation_mode | enum | Radio: selfhost/runninghub |
| GPU mode (video) | config.yaml > video_generation_mode | enum | Radio: selfhost/runninghub |
| RunningHub API key | config.yaml > runninghub_api_key | secret | Password input |
| RunningHub URL | config.yaml > runninghub_base_url | URL | Text input |
| Concurrent limit | config.yaml > concurrent_limit | int 1-10 | Number input |
| ComfyUI URL | api_config > comfyui_base_url | URL | Text input |

#### Page 3: Content Library (maps to Streamlit History page)

| Feature | Pixelle Source | Widget Type | API | Dashboard Component |
|---------|---------------|-------------|-----|---------------------|
| Task list | History page | grid | get_task_list() | Data table with pagination |
| Status filter | History sidebar | selectbox | status param | Filter select |
| Sort controls | History sidebar | selectbox+radio | sort_by, sort_order | Sort dropdown |
| Statistics | History sidebar | metric | get_statistics() | Summary cards (completed/failed) |
| Video preview | History grid | st.video | files endpoint | Video player thumbnail |
| Task detail modal | History detail | 3-col layout | get_task_detail() | Slide-over panel |
| Frame gallery | History detail | st.image | per-frame paths | Image carousel |
| Audio playback | History detail | st.audio | audio_path | Audio player |
| Video segments | History detail | st.video | segment paths | Segment player |
| Download video | History detail | download_button | GET /api/files/{path} | Download button |
| Delete task | History grid | button+confirm | delete_task() | Delete with confirmation |

#### Page 4: Channel Settings (viral-ops specific — no Pixelle equivalent)

| Feature | Per-Channel Param | Source | Form Field |
|---------|------------------|--------|------------|
| Voice engine | tts_inference_mode | style_config | Radio: local/comfyui |
| Voice selection | tts_voice | style_config | Select from voices |
| Speech speed | tts_speed | style_config | Range slider |
| Voice clone | ref_audio | style_config | File upload |
| Visual workflow | media_workflow | style_config | Select from workflows |
| Style prompt | prompt_prefix | style_config | Textarea |
| Template | frame_template | style_config | Card grid picker |
| Scene count default | n_scenes | content_input | Number input |
| Content mode default | mode | content_input | Radio |
| BGM default | bgm_path | content_input | Select |
| BGM volume default | bgm_volume | content_input | Range slider |
| Language | language | LLM prompt | Select |
| Persona/system prompt | llm_system_prompt | n8n inject | Textarea |

#### Page 5: System Settings (infrastructure — no Streamlit equivalent)

| Feature | Config Key | Form Field |
|---------|-----------|------------|
| API host/port | api_host, api_port | Text + Number input |
| API prefix | api_prefix | Text input |
| Resource directory | resource_dir | Path input |
| Storage paths | output dir | Path input (read-only) |

#### n8n Workflow Nodes (orchestration layer)

| Node | Purpose | Pixelle API Call |
|------|---------|-----------------|
| Channel Config Loader | Load per-channel overrides from DB | — |
| Content Generator | Generate narrations + image prompts | POST /api/content/narration, /api/content/image-prompt |
| Title Generator | Generate video title | POST /api/content/title |
| Video Generator | Trigger async video generation | POST /api/video/generate/async |
| Status Poller | Poll until completion | GET /api/tasks/{task_id} |
| File Retriever | Download final video | GET /api/files/{video_path} |
| Error Handler | Retry or notify on failure | — |
| Config Injector | Merge channel defaults into request body | — |

[INFERENCE: Feature matrix synthesized from all 5 iterations. Dashboard page structure is a viral-ops design decision informed by Pixelle-Video's feature surface.]

---

### F6: Template Parameter Schema Detail (Q7 supplement)

From style_config.py analysis, template custom parameters are rendered dynamically based on each template's declared config. The widget type is auto-selected:
- **string** params → st.text_input
- **number** params → st.number_input
- **color** params → st.color_picker
- **boolean** params → st.checkbox

This means the dashboard template picker must:
1. Fetch template list from `/api/resources/templates`
2. Read each template's parameter declarations
3. Render a dynamic form matching the template's declared params

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/components/style_config.py]

---

### F7: TTS Service Detail (Q4 supplement)

From widget analysis: TTS speed control exists (slider 0.5-2.0). No pitch control was found in any UI component or API schema across all 5 iterations. The TTS controls are:
- **Local mode**: voice selector + speed slider
- **ComfyUI mode**: workflow selector + reference audio uploader (for voice cloning)

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/components/style_config.py]
[INFERENCE: Pitch control absence confirmed by exhaustive search across all API schemas (iter 2) and UI widgets (iter 5)]

## Ruled Out
- `2_History.py` path without emoji (404) — actual filename is `2_📚_History.py` with URL-encoded emoji prefix
- File upload API endpoint — does not exist; all files are generated by the pipeline
- File cleanup API endpoint — does not exist; cleanup is manual/external
- Re-run/re-generate from History page — not available; must go to Home page
- TTS pitch control — does not exist anywhere in the system

## Dead Ends
- No file upload endpoint in the entire API — Pixelle-Video generates all files internally. The viral-ops dashboard will need a separate upload mechanism for voice clone reference audio (store in data/ and pass path to API).
- No auto-cleanup — generated files accumulate indefinitely. viral-ops must implement its own cleanup policy (cron job or storage quota).

## Sources Consulted
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/components/content_input.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/components/style_config.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/web/pages/2_%F0%9F%93%9A_History.py
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/files.py
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/web/pages

## Assessment
- New information ratio: 0.86
- Questions addressed: Q10, Q13, Q9, Q4, Q7
- Questions answered: Q10-full, Q13-full, Q9-full, Q4-full (speed confirmed, no pitch), Q7-full (dynamic template params)

All 14 key questions are now fully answered:
- Q1-full (iter 1-2), Q2-full (iter 2), Q3-full (iter 3), Q4-full (iter 3+5), Q5-full (iter 3)
- Q6-full (iter 3), Q7-full (iter 3+5), Q8-full (iter 1), Q9-full (iter 5), Q10-full (iter 4+5)
- Q11-full (iter 4), Q12-full (iter 4), Q13-full (iter 5), Q14-full (iter 4)

## Reflection
- What worked and why: Fetching the actual component source files (content_input.py, style_config.py) yielded the exact widget specs needed to complete Q10. The History page fetch revealed the complete task browsing feature set. The files router analysis closed Q9 definitively. The synthesis approach for Q13 (combining all prior iteration data) produced the per-channel mapping without requiring new fetches.
- What did not work and why: History page filename had emoji prefix that caused initial 404 — resolved by checking the directory listing first. This is a recurring pattern with Streamlit's multi-page convention.
- What I would do differently: For any future Streamlit project, always fetch the pages/ directory listing first before attempting to fetch individual page files, since emoji-prefixed filenames are standard practice.

## Recommended Next Focus
All 14 questions are fully answered. The research is ready for convergence and synthesis. Recommended next step: final synthesis iteration to produce the definitive research.md document consolidating all findings into the complete Pixelle-Video feature audit.
