# Iteration 3: Video Content Specs (Q5) & Rate Limits (Q6)

## Focus
Deep dive into exact video content specifications for all 4 platforms to build a unified cross-platform comparison matrix, plus rate limit detection mechanisms. This addresses Q5 (video content specs) and Q6 (rate limits deep dive).

## Findings

### Finding 1: TikTok Video Specifications (NEW)
- **Codecs:** H.264 (recommended), H.265, VP8, VP9
- **Container formats:** MP4 (recommended), WebM, MOV
- **Resolution:** Min 360px, Max 4096px (both dimensions)
- **Duration:** Up to 10 minutes via API (most creators: 3 min, some: 5 or 10 min)
- **Frame rate:** 23-60 FPS
- **File size:** Max 4GB
- **Caption/title:** Max 2200 UTF-16 runes
- **Thumbnail:** Specified via `video_cover_timestamp_ms` (frame extraction, not separate upload)
- **Chunk upload:** Min chunk 5MB, max 64MB (final chunk up to 128MB), max 1000 chunks, sequential only
- **Content types supported:** `video/mp4`, `video/quicktime`, `video/webm`
- **Gaps:** No official aspect ratio requirements, no bitrate recommendations, no audio codec specs documented
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-media-transfer-guide]
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-reference-direct-post]

### Finding 2: YouTube Video Specifications (NEW)
- **Codec:** H.264 required (High Profile, progressive scan, CABAC, 2 consecutive B frames, closed GOP, variable bitrate, 4:2:0 chroma)
- **Container:** MP4 required (moov atom at front/Fast Start, no Edit Lists)
- **Resolution:** Supports 360p through 8K; standard aspect ratio 16:9, auto-adapts for vertical/square
- **Frame rate:** 24, 25, 30, 48, 50, 60 fps (encode at recorded frame rate)
- **File size:** Max 256GB via API
- **Duration:** Not explicitly capped in API docs (15 min default for unverified accounts, 12 hours for verified via web)
- **Audio:** AAC-LC, Opus, or Eclipsa Audio; 48kHz sample rate; Stereo or Stereo+5.1
- **Audio bitrate:** Mono 128kbps, Stereo 384kbps, 5.1 512kbps
- **Color space:** BT.709 (SDR)
- **Quota cost:** 100 units per videos.insert call (10,000 daily = ~100 uploads/day)
- **MIME types accepted:** `video/*`, `application/octet-stream`
- **Scheduling:** `status.publishAt` for timed publishing
- **New restriction:** Unverified API projects (post July 28, 2020) restricted to private viewing mode
[SOURCE: https://support.google.com/youtube/answer/1722171]
[SOURCE: https://developers.google.com/youtube/v3/docs/videos/insert]

### Finding 3: YouTube Recommended Bitrates -- SDR (NEW)

| Resolution | Standard FPS (Mbps) | High FPS (Mbps) |
|-----------|-------------------|-----------------|
| 8K (4320p) | 80-160 | 120-240 |
| 4K (2160p) | 35-45 | 53-68 |
| 1440p | 16 | 24 |
| 1080p | 8 | 12 |
| 720p | 5 | 7.5 |
| 480p | 2.5 | 4 |
| 360p | 1 | 1.5 |

[SOURCE: https://support.google.com/youtube/answer/1722171]

### Finding 4: TikTok Rate Limits -- Confirmed Details (PARTIALLY NEW)
- **Endpoint-specific limits:** `/v2/user/info/`, `/v2/video/query/`, `/v2/video/list/` all at 600 requests/min
- **Time window:** 1-minute sliding window
- **HTTP signal:** Status 429 with error code `rate_limit_exceeded`
- **Content Posting API:** No separate documented rate limit (not listed in the rate limit table)
- **No documented response headers:** X-RateLimit-* and Retry-After not mentioned in official docs
- **Higher limits:** Available by contacting TikTok support
- **Gap:** No daily posting limit documented via API; no sandbox vs production differentiation
[SOURCE: https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit]

### Finding 5: YouTube Rate Limit Mechanism (PARTIALLY NEW)
- **Quota-based, not request-rate-based:** YouTube uses a daily quota system (10,000 units/day) rather than per-minute request limits
- **Upload cost:** 100 quota units per `videos.insert` call = theoretical max ~100 uploads/day
- **Error code for quota exceeded:** HTTP 400 with `uploadLimitExceeded` reason
- **No HTTP rate limit headers:** YouTube uses quota exhaustion model, not X-RateLimit-* headers
- **Required scopes for upload:** `youtube.upload` or `youtube` or `youtube.force-ssl`
- **Error codes for uploads:** 400 (invalid metadata, missing media, bad title/tags/description/category), 403 (forbidden license/privacy settings)
[SOURCE: https://developers.google.com/youtube/v3/docs/videos/insert]
[SOURCE: https://developers.google.com/youtube/v3/determine_quota_cost]

### Finding 6: Instagram Video Specs -- Confirmed from Iter 2 (REDUNDANT, confirming)
- H.264 codec, AAC audio, max 1080x1920, 3s-15min Reels, 0-100MB standard / up to 1GB resumable
- 400 containers/24h rate limit (IG Graph API)
- Rate limit detection: HTTP 429 or error in response body with code/subcode
[SOURCE: iteration-002.md -- prior research confirmed]

### Finding 7: Facebook Video Specs -- Confirmed from Iter 2 (REDUNDANT, confirming)
- 3-phase Reels upload, 30 Reels/Page/24h
- Error codes: 6001 (bad codec), 6004 (bad ratio), 6000 (generic)
- Supports resumable upload for generic videos
[SOURCE: iteration-002.md -- prior research confirmed]

### Finding 8: Unified Cross-Platform Video Specs Comparison Matrix (NEW -- synthesis)

| Spec | TikTok | YouTube | Instagram | Facebook |
|------|--------|---------|-----------|----------|
| **Codec** | H.264, H.265, VP8, VP9 | H.264 (High Profile) | H.264 | H.264 (Reels) |
| **Container** | MP4, WebM, MOV | MP4 (Fast Start) | MP4, MOV | MP4 |
| **Min Resolution** | 360px | 360p | 540x960 (Reels) | 540x960 (Reels) |
| **Max Resolution** | 4096px | 8K (7680x4320) | 1080x1920 | 1080x1920 (Reels) |
| **Aspect Ratio** | Not specified | 16:9 (auto-adapt) | 9:16 (Reels), 1:1 | 9:16 (Reels) |
| **Max File Size** | 4GB | 256GB | 1GB (resumable) | 1GB (Reels) |
| **Min Duration** | Not specified | Not specified | 3s (Reels) | 3s (Reels) |
| **Max Duration** | 10 min (API) | 12h (verified) | 15 min (Reels) | 90s (Reels) |
| **Frame Rate** | 23-60 FPS | 24-60 FPS | 30 FPS recommended | 30 FPS recommended |
| **Audio** | Not specified | AAC-LC/Opus, 48kHz | AAC, 48kHz | AAC |
| **Caption Length** | 2200 chars | 5000 chars (desc) | 2200 chars | 2200 chars |
| **Thumbnail** | Auto from timestamp | Separate upload (2MB, JPG/PNG) | Auto-generated | Auto-generated |

### Finding 9: Cross-Platform Rate Limit Comparison Matrix (NEW -- synthesis)

| Platform | Rate Limit Model | Upload-Specific Limit | Detection Method | Key Header/Code |
|----------|-----------------|----------------------|------------------|-----------------|
| **TikTok** | Per-minute sliding window | 600 req/min (general) | HTTP 429 | `rate_limit_exceeded` error code |
| **YouTube** | Daily quota pool | 100 units/upload (~100/day) | Quota exhaustion | HTTP 400 `uploadLimitExceeded` |
| **Instagram** | Container-based daily cap | 400 containers/24h | HTTP 429 or error body | Error code/subcode in JSON |
| **Facebook** | Content-type daily cap | 30 Reels/Page/24h | Error response | Error codes 6000-6004 |

**Key architectural insight:** Each platform uses a fundamentally different rate limiting model:
- TikTok: Classic sliding-window request rate
- YouTube: Quota unit consumption pool (not request count)
- Instagram: Content container creation cap
- Facebook: Per-content-type per-Page daily cap

None of the 4 platforms consistently use standard `X-RateLimit-*` or `Retry-After` headers. Rate limit detection must be platform-specific.

## Ruled Out
- TikTok's Direct Post API reference page (`content-posting-api-reference-direct-post`) for video specs -- it focuses on API workflow, not technical specs. The Media Transfer Guide is the correct source for TikTok video specifications.
- Looking for standardized `X-RateLimit-*` headers across platforms -- none of the 4 platforms document these standard headers. Rate limit detection is platform-specific via error codes.

## Dead Ends
- Searching for unified rate limit header standards across social platforms -- each uses a proprietary signaling mechanism. A cross-platform upload system must implement per-platform rate limit detection logic.

## Sources Consulted
- https://developers.tiktok.com/doc/content-posting-api-reference-direct-post
- https://developers.tiktok.com/doc/content-posting-api-media-transfer-guide
- https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit
- https://support.google.com/youtube/answer/1722171
- https://developers.google.com/youtube/v3/docs/videos/insert

## Assessment
- New information ratio: 0.72
- Questions addressed: Q5, Q6
- Questions answered: Q5 (substantially -- all 4 platforms now have video specs documented), Q6 (substantially -- rate limit models documented for all 4 platforms)

## Reflection
- What worked and why: Targeting the TikTok Media Transfer Guide (referenced from the Direct Post API page) yielded the specific video specs that were missing from the API reference page. YouTube's support page (not API docs) had the detailed codec/bitrate tables. Following documentation cross-references proved more productive than guessing URLs.
- What did not work and why: The TikTok Direct Post API reference page was workflow-focused, not spec-focused. Had to make a second fetch to the Media Transfer Guide to get actual video specifications.
- What I would do differently: For future platform spec research, start with "media transfer" or "upload requirements" pages rather than API reference pages, as specs tend to live in separate guides.

## Recommended Next Focus
1. **Error handling patterns (Q7)**: Build per-platform error code catalogs with HTTP status codes, error code enumerations, retry strategies (exponential backoff, jitter), and idempotency guarantees for failed uploads.
2. **Token management deep dive (Q8)**: Expand on Meta token lifecycle (covered partially), add TikTok token rotation details, YouTube OAuth refresh specifics.
3. **Platform quirks (Q9)**: TikTok duplicate detection, Instagram container expiry, YouTube processing states.
