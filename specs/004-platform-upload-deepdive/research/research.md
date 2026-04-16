# Upload Per-Platform Deep Dive -- Research Synthesis

> Progressive synthesis document. Updated after each research iteration.
> Last updated: Iteration 7

---

## 1. TikTok Content Posting API

### Auth Flow (OAuth 2.0)
| Property | Value |
|----------|-------|
| Grant type | Authorization Code + PKCE |
| Token endpoint | `POST https://open.tiktokapis.com/v2/oauth/token/` |
| Revoke endpoint | `POST https://open.tiktokapis.com/v2/oauth/revoke/` |
| Access token expiry | 24 hours (86,400s) |
| Refresh token expiry | 365 days (31,536,000s) |
| Upload scope | `video.publish` (direct post), `video.upload` (upload for review) |
| Audit requirement | Unaudited apps restricted to private mode (all uploads private-only) |
| Audit process | Case-by-case via TikTok developer support portal; no documented timeline |
| Creator vs Business | **No difference** for Content Posting API -- distinction is app-level (audited vs unaudited), not account-level |

### Upload Endpoints
| Endpoint | Purpose |
|----------|---------|
| `POST /v2/post/publish/video/init/` | Direct video post (base: `https://open.tiktokapis.com`) |
| `POST /v2/post/publish/content/init/` | Photo post |
| `POST /v2/post/publish/status/fetch/` | Check publish status |

**Upload modes**: `FILE_UPLOAD` (chunked PUT to returned `upload_url`) or `PULL_FROM_URL` (verified domain required).

### Video Specs
| Spec | Value |
|------|-------|
| Codecs | H.264 (recommended), H.265, VP8, VP9 |
| Container | MP4 (recommended), WebM, MOV |
| Min resolution | 360px (both dimensions) |
| Max resolution | 4096px (both dimensions) |
| Duration | Up to 10 min via API (creators vary: 3/5/10 min) |
| Frame rate | 23-60 FPS |
| File size | Max 4GB |
| Caption | Max 2200 UTF-16 runes |
| Thumbnail | Auto-extracted via `video_cover_timestamp_ms` |
| Chunk upload | Min 5MB, max 64MB (final up to 128MB), max 1000 chunks, sequential |
| Audio | Not officially specified |
| Aspect ratio | Not officially specified |

### Rate Limits
- General API: 600 req/min (sliding window) for user/video info endpoints
- Rate exceeded: HTTP `429`, error code `rate_limit_exceeded`
- Content Posting API specific limits: Not separately documented
- Daily posting limits: Not documented via API
- No `X-RateLimit-*` or `Retry-After` headers documented
- Higher limits available by contacting TikTok support

### Official API vs TikTokAutoUploader
| Aspect | Official API | TikTokAutoUploader |
|--------|-------------|-------------------|
| Auth | OAuth 2.0 + PKCE | Cookie-based (exported browser session) |
| Mechanism | REST API (official endpoints) | Phantomwright/Puppeteer headless Chromium browser automation |
| Approval | App audit required (`video.publish` scope) | None |
| TOS compliance | Yes | No (violates TikTok ToS Section 7) |
| Ban risk | None | **HIGH** -- detectable via headless browser fingerprinting, timing patterns, missing mouse entropy |
| Scheduling | Not native (queue-level) | Up to 10 days (uses TikTok web scheduler) |
| Setup effort | High (audit process, 1-4 weeks) | Low (immediate, cookie export) |
| Reliability | Stable (official API) | Fragile (breaks on UI selector changes) |
| Production use | Recommended | Development/testing bridge only |

---

## 2. YouTube Data API v3

### Auth Flow (Google OAuth 2.0)
| Property | Value |
|----------|-------|
| Upload scope | `https://www.googleapis.com/auth/youtube.upload` |
| Access token expiry | ~1 hour (3,600s) -- standard Google OAuth |
| Refresh token expiry | Does not expire unless revoked |

### Upload Flow (Resumable)
1. **Initiate**: `videos.insert` with `MediaFileUpload(file, resumable=True)`
2. **Upload chunks**: Loop `insert_request.next_chunk()`
3. **Resume on failure**: Exponential backoff, `MAX_RETRIES = 10`

### Quota System
| Operation | Cost (units) |
|-----------|-------------|
| `videos.insert` (upload) | 100 |
| `videos.list` | 1 |
| `videos.update` | 50 |
| `videos.delete` | 50 |
| `search.list` | 100 |
| Any invalid request | 1 (minimum) |

- **Default daily quota**: 10,000 units/day (resets midnight Pacific)
- **Practical upload limit**: ~100 uploads/day at default quota
- **Monitor**: Google API Console (`console.cloud.google.com/iam-admin/quotas`)

### Error Handling
- Retriable HTTP codes: `500, 502, 503, 504`
- Strategy: Exponential backoff with jitter

### Video Specs
| Spec | Value |
|------|-------|
| Codec | H.264 required (High Profile, progressive, CABAC, closed GOP, VBR, 4:2:0 chroma) |
| Container | MP4 required (moov atom at front/Fast Start, no Edit Lists) |
| Max resolution | 8K (7680x4320) |
| Aspect ratio | 16:9 standard; auto-adapts for vertical/square |
| Frame rate | 24, 25, 30, 48, 50, 60 fps (encode at recorded rate) |
| File size | Max 256GB via API |
| Duration | 15 min default (unverified accounts); 12h (verified via web) |
| Audio codec | AAC-LC, Opus, or Eclipsa Audio |
| Audio sample rate | 48kHz |
| Audio channels | Stereo or Stereo + 5.1 |
| Audio bitrate | Mono 128kbps, Stereo 384kbps, 5.1 512kbps |
| Color space | BT.709 (SDR) |
| MIME types | `video/*`, `application/octet-stream` |
| Scheduling | `status.publishAt` field for timed publishing |
| AI disclosure | `status.containsSyntheticMedia` field available |

#### Recommended Bitrates (SDR)
| Resolution | Standard FPS (Mbps) | High FPS (Mbps) |
|-----------|-------------------|-----------------|
| 8K | 80-160 | 120-240 |
| 4K (2160p) | 35-45 | 53-68 |
| 1440p | 16 | 24 |
| 1080p | 8 | 12 |
| 720p | 5 | 7.5 |
| 480p | 2.5 | 4 |
| 360p | 1 | 1.5 |

### Rate Limits
- Quota-based model (not request-rate): 10,000 units/day, resets midnight Pacific
- Upload cost: 100 units per `videos.insert` = ~100 uploads/day
- Quota exceeded: HTTP 400 with `uploadLimitExceeded` reason
- No `X-RateLimit-*` headers; uses quota exhaustion model
- **Restriction**: Unverified API projects (post July 28, 2020) limited to private viewing mode

### Post-Upload Processing States
YouTube videos go through a defined processing pipeline after upload:

**Upload Status** (`status.uploadStatus`): `uploaded` -> `processing` -> `processed` | `failed` | `rejected` | `deleted`

**Processing Progress** (`processingDetails`):
- `processingStatus`: `processing` | `succeeded` | `failed` | `terminated`
- `processingProgress.partsTotal` / `partsProcessed`: Track completion percentage
- `processingProgress.timeLeftMs`: Estimated time remaining (use for adaptive polling intervals)
- `fileDetailsAvailability`: `available` when codec/resolution details can be queried

**Upload Failure Reasons** (`status.failureReason`): `codec`, `conversion`, `emptyFile`, `invalidFile`, `tooSmall`, `uploadAborted`

**Processing Failure Reasons** (`processingDetails.processingFailureReason`): `transcodeFailed`, `streamingFailed`, `uploadFailed`, `other`

**Rejection Reasons** (`status.rejectionReason`): `copyright`, `trademark`, `inappropriate`, `length`, `duplicate`, `termsOfUse`, `claim`, `legal`, `uploaderAccountClosed`, `uploaderAccountSuspended`

**Polling strategy**: Query `videos.list` with `part=processingDetails` (1 quota unit per call). Use `timeLeftMs` to set adaptive polling intervals rather than fixed polling.

**publishAt scheduling**:
| Property | Value |
|----------|-------|
| Format | ISO 8601: `YYYY-MM-DDThh:mm:ss.sZ` (UTC recommended) |
| Timezone | UTC (`Z` suffix) or explicit offset (`+HH:MM`). Also accepts date-only and naive time |
| Prerequisite | `status.privacyStatus` MUST be `private` |
| Behavior | YouTube auto-transitions `privacyStatus` from `private` to `public` at specified time |
| Past dates | Triggers immediate publication |
| Re-scheduling | Cannot be used if video was previously published |
| Max window | **Not documented** -- no maximum scheduling window found in official docs |
| Quota cost | No additional cost beyond the 100-unit `videos.insert` |

### YouTube n8n Built-in Node
| Operation | Supported | Quota Cost |
|-----------|-----------|------------|
| Upload video | Yes (resumable) | 100 units |
| Update video | Yes | 50 units |
| Delete video | Yes | 50 units |
| Get video | Yes | 1 unit |
| List videos | Yes | 1 unit |
| OAuth2 auto-refresh | Yes (built-in Google OAuth) | N/A |
| publishAt scheduling | Yes (via status fields) | Included in upload |

**Only platform with native n8n node for uploads.** TikTok, Instagram, Facebook all require HTTP Request + Generic OAuth2.

### Quota Increase Process
- Apply through Google API Console (`console.cloud.google.com/iam-admin/quotas`)
- Requires: use case justification, expected daily volume, YouTube ToS compliance
- Typical approval: **1-4 weeks** (community reports, not officially documented)
- Google may request additional information or restrict based on app history

### Known Gaps (for future iterations)
- YouTube Shorts specific API parameters

---

## 3. Instagram Graph API

### Auth Flow (Meta OAuth 2.0 -- shared with Facebook)
| Property | Value |
|----------|-------|
| Short-lived user token | ~1-2 hours |
| Long-lived user token | ~60 days |
| Page access token | Does not expire (if derived from long-lived user token with permanent page access) |
| Exchange endpoint | `GET /oauth/access_token?grant_type=fb_exchange_token&client_id={app_id}&client_secret={app_secret}&fb_exchange_token={short_lived}` |
| Required permissions | `pages_show_list`, `pages_read_engagement`, `pages_manage_posts` |

### Upload Flow (2-Step Container Model)

**Standard flow (video_url):**
1. `POST /v25.0/{ig_user_id}/media` with `media_type=REELS`, `video_url`, `caption`
2. Check container `status_code` == `FINISHED`
3. `POST /v25.0/{ig_user_id}/media_publish` with container ID

**Resumable upload flow:**
1. `POST /v25.0/{ig_user_id}/media` with `upload_type=resumable`
2. `POST https://rupload.facebook.com/ig-api-upload/v25.0/{container_id}` with binary data
3. Publish same as above

**Container expiry**: 24 hours. After expiry, container ID becomes invalid and publishing attempts will fail. No explicit "EXPIRED" status documented -- containers simply become unpublishable.

**Container status polling**: Check `status_code` field on the container object. `FINISHED` = ready to publish. Other states (IN_PROGRESS, ERROR) exist but are not fully documented in official API reference. Poll until `FINISHED` before calling `media_publish`.

**Practical implication**: Upload queue must track container creation timestamps and prioritize publishing containers approaching the 24h boundary. An expired container wastes rate limit budget (counts against the 400 containers/24h cap).

### Content Types & Container Parameters
| Type | `media_type` | Duration | File Size | Key Parameters |
|------|-------------|----------|-----------|----------------|
| Reels | `REELS` | 3s-15min | 300 MB | `video_url`/`upload_type=resumable`, `share_to_feed`, `cover_url`/`thumb_offset`, `collaborators` (max 3), `audio_name`, `user_tags`, `location_id` |
| Stories | `STORIES` | 3s-60s | 100 MB | `video_url`/`upload_type=resumable`, `user_tags` with x/y coords. **No** `caption`, `share_to_feed`, or `collaborators` |
| Feed Video | `VIDEO` + `is_carousel_item=true` | varies | varies | Only as carousel item. `upload_type=resumable`, `thumb_offset`. **No** standalone feed video upload |
| Carousel | `CAROUSEL` | varies | varies | `children` (array of container IDs, max 10), mixed images+videos. **Reels clips cannot appear in carousels** |

**Caption limits**: 2,200 chars, 30 hashtags, 20 @mentions.

### Container Status Polling
| Status | Meaning |
|--------|---------|
| `IN_PROGRESS` | Container still processing |
| `FINISHED` | Ready to publish -- call `media_publish` |
| `ERROR` | Processing failed |

Poll container with `fields=status_code`. Recommended: start at 5s interval, back off to 30s. Container expires after 24h regardless of status.

### Business vs Creator Account
**No difference** for content publishing API. Both are "professional accounts" with identical `/{ig_user_id}/media` access. Personal accounts have no publishing API access. Only distinction: Business gets more detailed Insights API data.

### Video Specs (Reels)
| Spec | Value |
|------|-------|
| Container | MOV or MP4 (MPEG-4 Part 14) |
| Video codec | H.264 or HEVC, progressive scan, closed GOP, 4:2:0 chroma |
| Audio | AAC, max 48 kHz, mono/stereo, 128 Kbps |
| Frame rate | 23-60 FPS |
| Max resolution | 1920px horizontal |
| Aspect ratio | 0.01:1 to 10:1 (9:16 recommended) |
| Video bitrate | VBR max 25 Mbps |

### Rate Limits
- **Container creation**: 400 containers/account/24h rolling window
- **General Graph API**: ~200 calls/user/hour (general, not upload-specific)

---

## 4. Facebook Video API

### Auth Flow (same Meta OAuth as Instagram)
Same token lifecycle as Section 3. Page access tokens with `CREATE_CONTENT` task capability required.

### Upload Flow -- Reels (3-Phase)
1. **Initialize**: `POST /v25.0/{page_id}/video_reels` with `upload_phase=start` -- returns `video_id` + `upload_url`
2. **Transfer**: `POST https://rupload.facebook.com/v25.0/video-upload/{video_id}` with `Authorization: OAuth {token}`, `offset`, `file_size` headers
3. **Publish**: `POST /v25.0/{page_id}/video_reels` with `video_id`, `upload_phase=finish`, `video_state=PUBLISHED`

**Status polling**: `GET /v25.0/{video_id}?fields=status` returns `uploading_phase`, `processing_phase`, `publishing_phase`.

### Upload Flow -- Regular Video (Resumable, Non-Reels)
1. **Initialize**: `POST /v25.0/{app_id}/uploads` with `file_name`, `file_length` (bytes), `file_type` (MIME: `video/mp4`)
   - Response: `{ "id": "upload:{UPLOAD_SESSION_ID}" }`
2. **Upload**: `POST /v25.0/upload:{UPLOAD_SESSION_ID}` with `file_offset: 0` header + binary body
   - Response: `{ "h": "{UPLOADED_FILE_HANDLE}" }`
3. **Publish**: `POST /v25.0/{page_id}/videos` with `fbuploader_video_file_chunk={file_handle}`, `title`, `description`

**Resume**: `GET /v25.0/upload:{UPLOAD_SESSION_ID}` returns current `file_offset` to resume from.

**Page vs User video**: Regular video uploads are **Pages-only** (`/{page_id}/videos`). User profile video uploads are NOT exposed through Graph API for third-party apps.

**Required permissions**: `pages_show_list`, `pages_read_engagement`, `pages_manage_posts` + `CREATE_CONTENT` capability on Page.

### Reels Video Specs
| Spec | Value |
|------|-------|
| File type | .mp4 recommended |
| Aspect ratio | 9:16 |
| Resolution | 1080x1920 recommended; 540x960 minimum |
| Frame rate | 24-60 fps |
| Duration | 3-90 seconds (max 60s as story) |
| Codec | H.264, H.265, VP9, AV1 |
| Audio | AAC LC, 128 Kbps+, 48 kHz |

### Scheduling via API
| Method | Available | Notes |
|--------|-----------|-------|
| Reels `scheduled_publish_time` | Yes | Set during `upload_phase=finish` with ISO 8601, use `video_state=SCHEDULED` |
| Regular video scheduling | **Not available** | No `scheduled_publish_time` parameter in regular video upload endpoints |
| Business Suite | UI-only | No programmatic API for Business Suite scheduling |
| Feed posts scheduling | Yes (non-video) | `/{page_id}/feed` supports `scheduled_publish_time` for text/link/image posts |

**Implication**: Regular video scheduling must be handled at the queue level (`scheduled_at` + n8n cron-poll).

### Rate Limits
- **Reels**: 30 API-published Reels/Page/24h moving window
- **Collaborator invitations**: 10/Page/24h
- **Limitation**: Both Reels and regular video API are Pages-only (no user profiles)

### Error Codes (Reels-Specific)
| Code | Issue | Solution |
|------|-------|---------|
| 1363040 | Unsupported aspect ratio | Use 16:9 to 9:16 range |
| 1363127 | Resolution unsupported | Min 540x960 |
| 1363128 | Invalid duration | 3-90 seconds |
| 1363129 | Frame rate unsupported | 24-60 fps |

---

## 5. Cross-Platform Comparison

### Upload Flow Summary
| Platform | Flow | Steps | Resume Support |
|----------|------|-------|---------------|
| TikTok | Direct post | 1 (init + upload) | FILE_UPLOAD (chunked PUT) or PULL_FROM_URL |
| YouTube | Resumable | 1 (videos.insert with chunked upload) | Yes (exponential backoff, MAX_RETRIES=10) |
| Instagram | Container | 2-3 (create + [upload] + publish) | Yes (resumable upload type) |
| Facebook Reels | 3-Phase | 3 (start + transfer + finish) | Yes (offset-based resume) |

### Token Lifecycle Comparison
| Platform | Access Token | Refresh Token | Special |
|----------|-------------|--------------|---------|
| TikTok | 24 hours | 365 days | PKCE required |
| YouTube/Google | ~1 hour | Never expires (unless revoked) | Standard Google OAuth |
| Instagram/Facebook | ~1-2 hours (short-lived) | N/A (exchange for long-lived) | Long-lived: ~60 days; Page tokens: permanent |

### Video Specs Comparison
| Spec | TikTok | YouTube | Instagram | Facebook Reels |
|------|--------|---------|-----------|----------------|
| **Codec** | H.264, H.265, VP8, VP9 | H.264 (High Profile) | H.264, HEVC | H.264, H.265, VP9, AV1 |
| **Container** | MP4, WebM, MOV | MP4 (Fast Start) | MOV, MP4 | MP4 |
| **Min Resolution** | 360px | ~360p | 540x960 | 540x960 |
| **Max Resolution** | 4096px | 8K (7680x4320) | 1920px wide | 1080x1920 |
| **Aspect Ratio** | Not specified | 16:9 (auto-adapt) | 9:16 (Reels) | 9:16 |
| **Max File Size** | 4GB | 256GB | 1GB (resumable) | 1GB |
| **Min Duration** | Not specified | Not specified | 3s | 3s |
| **Max Duration** | 10 min (API) | 12h (verified) | 15 min (Reels) | 90s |
| **Frame Rate** | 23-60 FPS | 24-60 FPS | 23-60 FPS | 24-60 FPS |
| **Audio** | Not specified | AAC-LC/Opus, 48kHz | AAC, 48kHz | AAC LC, 48kHz |
| **Caption** | 2200 chars | 5000 chars (desc) | 2200 chars | 2200 chars |
| **Thumbnail** | Auto (timestamp) | Separate upload | Auto-generated | Auto-generated |

### Rate Limits Comparison
| Platform | Model | Upload Limit | Period | Detection Method |
|----------|-------|-------------|--------|-----------------|
| **TikTok** | Sliding window | 600 req/min (general API) | 1-minute window | HTTP 429 + `rate_limit_exceeded` |
| **YouTube** | Quota pool | ~100 uploads (100 units each) | Daily (midnight Pacific) | HTTP 400 `uploadLimitExceeded` |
| **Instagram** | Container cap | 400 containers | 24h rolling | HTTP 429 or error code/subcode in JSON |
| **Facebook** | Content-type cap | 30 Reels/Page | 24h moving window | Error codes 6000-6004 |

**Key insight**: No platform uses standard `X-RateLimit-*` or `Retry-After` headers. Rate limit detection must be implemented per-platform using proprietary error codes/signals.

### Error Handling Comparison
| Platform | Error Format | Auth Error | Rate Limit Error | Duplicate Detection | Retryable Server Errors |
|----------|-------------|-----------|-----------------|---------------------|------------------------|
| **TikTok** | `error.code` + `error.message` + `error.log_id` | HTTP 401 `access_token_invalid` | HTTP 429 `rate_limit_exceeded` | Not documented in error codes | 5xx (generic) |
| **YouTube** | `error.domain` + `error.reason` + `error.message` | HTTP 401 `authorizationRequired` | HTTP 403 `quotaExceeded` | Not documented | HTTP 500, 502, 503, 504 |
| **Instagram** | Meta unified: `error.code` + `error.type` + `error.error_subcode` | Code 190 + subcode 463/467 | Code 4 or 17 | Code 506 (Duplicate Post) | Code 1, 2 |
| **Facebook** | Meta unified (same as Instagram) | Code 190 + subcode 463/467 | Code 4 or 17 | Code 506 (Duplicate Post) | Code 1, 2 |

### Unified Retry Strategy
| Tier | Error Type | Strategy | Max Retries | Applies To |
|------|-----------|----------|-------------|------------|
| **Tier 1** | Network/server (5xx, IOError) | Exponential backoff + jitter: `delay = random() * 2^attempt`, max 300s | 10 (YT), 5 (others) | All platforms |
| **Tier 2** | Rate limits, quotas | Fixed delay + check reset timing | 3 | HTTP 429, error 4/17, `quotaExceeded`, `spam_risk_too_many_posts` |
| **Tier 3** | Validation, auth, policy | Fail fast, log, alert operator | 0 | 400 validation, 401 auth, 403 permission, 506 duplicate |

**Per-platform retryable vs fatal errors:**

**TikTok** -- Retryable: `rate_limit_exceeded`, `spam_risk_too_many_posts`, `reached_active_user_cap`, 5xx. Fatal: `access_token_invalid`, `scope_not_authorized`, `spam_risk_user_banned_from_posting`, `invalid_param`, `privacy_level_option_mismatch`.

**YouTube** -- Retryable: `processingFailure`, `quotaExceeded`, HTTP 500/502/503/504. Fatal: `invalidVideoMetadata`, `uploadLimitExceeded`, `forbidden`, `insufficientPermissions`, `authenticatedUserAccountClosed/Suspended`.

**Meta (IG+FB)** -- Retryable: codes 1, 2, 4, 17, 341, 368. Fatal: codes 3, 10, 102, 190 (auth), 200-299 (permissions), 506 (duplicate).

**Critical discovery:** TikTok's `/v2/post/publish/video/init/` endpoint is limited to **6 requests per minute** per access token (not 600 req/min like general API). Upload URLs expire after 1 hour.

### Token Lifecycle & Refresh Strategy
| Platform | Access TTL | Refresh TTL | Rotation on Refresh? | Auto-refresh in n8n? |
|----------|-----------|-------------|---------------------|---------------------|
| **TikTok** | 24h | 365 days | No (same refresh token reusable) | Manual via OAuth2 Generic |
| **YouTube** | ~1h | Never (unless revoked) | No | Yes (built-in Google OAuth) |
| **Meta (IG+FB)** | 1-2h (short) / 60d (long) | N/A (exchange flow) | N/A (page tokens permanent) | Manual via OAuth2 Generic |

**Token error detection and recovery:**
- TikTok: HTTP 401 `access_token_invalid` --> refresh via `POST /v2/oauth/token/` with `grant_type=refresh_token`
- YouTube: HTTP 401 `authorizationRequired` --> auto-refresh via Google OAuth client
- Meta: Error code 190 + subcode 463/467 --> exchange for new long-lived token; page tokens are permanent and never need refresh

**Multi-account management:** Each platform account requires its own OAuth credential. n8n stores credentials encrypted. Token refresh failures must trigger alerts since a dead token stops the entire upload pipeline for that account. YouTube testing apps (unverified) have 7-day token expiry and 100 test user limit.

---

## 6. Platform-Specific Quirks

### TikTok: Multi-Layer Duplicate Detection
TikTok employs a 4+ layer duplicate detection system with 90%+ accuracy even through superficial edits:

| Layer | Method | What It Detects |
|-------|--------|----------------|
| **1. Visual** | Deep learning + perceptual hashing | Pixel-level and structural matches. Sees through filters, crops, speed changes, mirroring. Analyzes camera angles, object placement, backgrounds, visual flow. |
| **2. Audio** | Audio fingerprinting (ACRCloud partnership) | Matches music/sound even with pitch/timing modifications. Detects same audio with completely different visuals. |
| **3. Metadata** | C2PA metadata tracking | File creation dates, device info, editing software signatures. Traces content origins and cross-platform reposts. |
| **4. Behavioral** | Pattern analysis | Rapid sequential uploads, cross-account duplication, engagement anomalies suggesting automated distribution. |

**Penalty model**: Shadow suppression (reduced distribution) rather than immediate removal. No public threshold documented.

**API limitation**: No "duplicate detected" error code exists. Duplicate detection operates post-upload at the content moderation layer. No pre-upload duplicate check endpoint exists. The API only surfaces `spam_risk_too_many_posts` for rate-related blocks and `spam_risk_user_banned_from_posting` for account bans.

**Implication for viral-ops**: Content must be genuinely unique per platform. Simple re-encoding, filter overlay, or mirror flip is insufficient. Consider platform-specific intro/outro, different aspect ratios, or unique captions per platform.

### Instagram: Container Expiry (24h Window)
- Containers expire after **exactly 24 hours** from creation
- Expired containers become invalid; publishing attempts fail silently
- No explicit "EXPIRED" status in API -- containers just become unpublishable
- Container creation counts against the 400/24h rate limit even if expired without publishing
- **Upload queue must track container creation timestamps** and prioritize containers approaching the 24h boundary

### YouTube: Processing Pipeline
See Section 2 "Post-Upload Processing States" for full details. Key operational points:
- Processing time varies from seconds (short clips) to hours (4K/8K content)
- Use `timeLeftMs` for adaptive polling instead of fixed intervals
- `rejected` status with `duplicate` reason = YouTube's own duplicate detection
- `processingDetails.fileDetailsAvailability` = `available` confirms video specs can be queried

### Facebook: Encoding & Validation
- Facebook **re-encodes all uploaded video** through their transcoding pipeline
- The `finish` phase validates uploaded binary against `file_size` declared during init (offset-based validation, not cryptographic checksum)
- Processing states: `uploading_phase` -> `processing_phase` -> `publishing_phase`
- Poll `GET /{video_id}?fields=status` during `processing_phase` before checking publish status

---

## 7. n8n Integration Patterns

### OAuth2 Credential Architecture
| Feature | Detail |
|---------|--------|
| **Credential types** | Generic OAuth2 API (any provider) + Predefined (Google/YouTube built-in) |
| **Grant types** | Authorization Code, Client Credentials, PKCE |
| **Configuration** | Client ID, Client Secret, Auth URL, Token URL, Scopes, Redirect URL (auto-generated) |
| **Token auto-refresh** | Built-in for Google OAuth (YouTube). Generic OAuth2 auto-refreshes via configured token endpoint. |
| **Multi-account** | Each credential is a separate entity. 5 TikTok accounts = 5 OAuth2 credentials. Selection is per-node. |
| **Storage** | Credentials stored encrypted in n8n database |

**Per-platform credential setup**:
| Platform | Credential Type | Notes |
|----------|----------------|-------|
| YouTube | Built-in Google OAuth2 | Native node, auto-refresh, simplest setup |
| TikTok | Generic OAuth2 API (PKCE) | Known issue: Authorization header may not send correctly. Workaround: manual `Authorization: Bearer` header |
| Instagram | Generic OAuth2 API | Meta token exchange (short -> long-lived) requires custom logic |
| Facebook | Generic OAuth2 API | Same Meta infrastructure as Instagram |

### Error Handling Architecture

**Node-level settings**:
- **On Error**: `Stop Workflow` (default) | `Continue Regular Output` | `Continue Error Output`
- **Retry On Fail**: Configurable retries count + wait between tries (ms)

**CRITICAL BUG**: If Retry On Fail is ON and On Error is set to any Continue option, retry settings are **silently ignored**. Retries only work with `On Error = Stop Workflow`.

**Error data**: `$json["error"]["message"]`, `$json["error"]["code"]`, `$json["requestUrl"]`

**Recommended upload workflow pattern**:
```
HTTP Request (upload) [On Error: Continue Error Output]
    |
    +-- Success branch --> Status update (DB) --> Next platform
    |
    +-- Error branch --> IF (retryable?)
                            |
                            +-- Yes --> Wait (exponential: 2^attempt * 1000ms, max 5 attempts)
                            |           --> Loop back to HTTP Request
                            +-- No --> Log error to DB --> Alert (webhook/email)
```

**Error Trigger workflow**: Separate workflow starting with Error Trigger node for global error handling. `execution.retryOf` indicates retry executions.

### Community Nodes Assessment
| Node | Status | Recommendation |
|------|--------|---------------|
| Built-in YouTube | Stable, maintained | USE -- native upload support |
| `n8n-nodes-upload-post` | Official community node, included by default | AVOID for viral-ops -- adds third-party middleware dependency |
| `@igabm/n8n-nodes-tiktok` | Abandoned, non-functional | DO NOT USE |

**Recommendation**: Use HTTP Request nodes with Generic OAuth2 for TikTok, Instagram, Facebook. Use built-in YouTube node for YouTube.

---

## 8. Upload Queue Architecture (Q11)

### Queue State Machine
```
queued -> scheduled -> processing -> completed
                                  -> failed -> retry_wait -> scheduled (if retry_count < max)
queued/scheduled -> cancelled (manual)
queued -> expired (scheduled_at + window exceeded)
```

### n8n Integration Pattern: Cron-Poll + Sub-Workflow
- **Schedule Trigger** (every 2 minutes) polls `upload_queue` for pending jobs
- **Postgres node** selects jobs: `WHERE status IN ('queued', 'retry_wait') AND scheduled_at <= NOW()` ordered by `priority DESC, scheduled_at ASC`
- **Loop Over Items** (batch size: 1) processes sequentially
- **Switch** routes to per-platform **Execute Sub-workflow** (tiktok-upload, youtube-upload, etc.)
- Success: `UPDATE status = 'completed'`, INSERT `platform_publishes`
- Failure: Check error tier -> retryable = `retry_wait` with backoff, fatal = `failed` + alert

**Why cron-poll over webhook**: Priority ordering, rate limit awareness, batch control. Webhook triggers bypass scheduling logic.

### Priority Scheduling
| Priority | Use Case |
|----------|----------|
| 10 | Urgent/trending content |
| 5 | Normal scheduled |
| 3 | Backfill/variant testing |
| 0 | Low priority (archive) |
| -1 | Auto-demoted failed retries |

### Staggered Posting
Content targeting 4 platforms uses offset `scheduled_at` values:
- TikTok: T+0 (first, trend freshness)
- Instagram: T+20min
- YouTube: T+40min (uses `publishAt` for native scheduling)
- Facebook: T+60min

Multi-account: Additional 15min offset per account on same platform to avoid behavioral fingerprinting.

### Failure Retry with Exponential Backoff
Formula: `next_retry_at = NOW() + min(base_delay * 2^retry_count + jitter, max_delay)`

| Platform | Base Delay | Max Delay | Max Retries | Rationale |
|----------|-----------|-----------|-------------|-----------|
| TikTok | 120s | 3600s | 5 | 6 req/min upload init limit |
| YouTube | 60s | 1800s | 3 | Quota-based, retries cost units |
| Instagram | 300s | 7200s | 4 | Container 24h expiry window |
| Facebook | 180s | 3600s | 4 | 30 Reels/day limit |

Error tier routing: Tier 1 (5xx, network) = retry with backoff. Tier 2 (rate limits) = wait for reset window. Tier 3 (auth, validation, duplicate) = fail immediately + alert.

### Rate Limit Tracking (New Table)
```sql
rate_limit_tracker (
  platform_account_id UUID REFERENCES platform_accounts(id),
  limit_type VARCHAR(50),  -- 'upload_init' | 'container_create' | 'quota_daily' | 'reels_daily'
  window_start TIMESTAMPTZ,
  window_duration_seconds INT,
  current_count INT DEFAULT 0,
  max_count INT,  -- TikTok:6, YouTube:100, IG:400, FB:30
  UNIQUE(platform_account_id, limit_type)
);
```

Queue dequeue query joins `rate_limit_tracker` to skip accounts at their limit.

---

## 9. Multi-Account Management (Q12)

### Relationship Model
```
channels (1) --> (N) platform_accounts (1) --> (N) upload_queue
                         |
                         +--> (N) platform_publishes
```
One channel has multiple platform accounts (one per platform). Each account stores its own OAuth credentials independently.

### Token Storage Per Platform
| Platform | auth_type | access_token | refresh_token | token_expires_at | cookies_json | platform_metadata |
|----------|----------|--------------|---------------|-----------------|-------------|-------------------|
| TikTok (API) | oauth | Bearer (24h) | Refresh (365d) | access expiry | NULL | `{open_id, scope}` |
| TikTok (Auto) | cookie | NULL | NULL | Cookie expiry | Session cookies | `{session_id}` |
| YouTube | oauth | Bearer (~1h) | Permanent | access expiry | NULL | `{channel_id, playlist_id}` |
| Instagram | oauth | Long-lived (60d) | NULL | token expiry | NULL | `{ig_user_id, page_id, business_id}` |
| Facebook | oauth | Page token (permanent) | NULL | NULL | NULL | `{page_id, business_id}` |

### Token Encryption
- Application-level: Prisma middleware encrypt-on-write / decrypt-on-read with `DATABASE_ENCRYPTION_KEY` env var
- Or PostgreSQL `pgcrypto`: `pgp_sym_encrypt(token, key)` / `pgp_sym_decrypt(token, key)`
- n8n side: AES-256-GCM with `ENCRYPTION_KEY` env var

### Token Refresh Automation (n8n Cron)
Separate workflow (Schedule Trigger every 6 hours):
- TikTok: Refresh when access token expires within 6h (`POST /v2/oauth/token/` with `grant_type=refresh_token`)
- YouTube: Refresh when expires within 30min (Google OAuth auto-refresh handles most cases)
- Instagram: Refresh when long-lived token expires within 7 days (`GET /oauth/access_token` with `grant_type=fb_exchange_token`)
- Facebook: Page tokens permanent -- no refresh needed

Failed refresh: Set `is_active = false`, send alert.

### Dual-Storage Synchronization
Tokens live in two places: n8n credentials (for workflow execution) and `platform_accounts` (for queue management).

Schema addition: `ALTER TABLE platform_accounts ADD COLUMN n8n_credential_id VARCHAR(100);`

Token refresh workflow updates BOTH via n8n API (`PUT /api/v1/credentials/{id}`).

### Account Health Monitoring
Daily cron workflow:
1. Query each active account's API (lightweight profile call)
2. HTTP 401/Meta 190 = set `is_active = false`
3. Log to `platform_account_health_log` table
4. Alert on accounts inactive > 24h

---

## 10. Open Gaps (for future iterations)
- YouTube resume URI raw protocol for n8n HTTP Request (generic Google Resumable Upload Protocol docs)
- ~~YouTube quota increase process~~ **CLOSED** (iter 7): 1-4 weeks via Google API Console
- TikTok duplicate detection threshold tuning (how much modification is "enough")
- ~~Instagram container status values~~ **CLOSED** (iter 7): IN_PROGRESS, FINISHED, ERROR documented
- PostgreSQL queue processing optimization (SKIP LOCKED, advisory locks for concurrent workers)
- n8n API endpoints for credential management (exact API shape for token sync)
- YouTube Shorts specific API parameters (from iter 2 known gap)
- YouTube publishAt maximum scheduling window (undocumented -- needs empirical testing)
- Facebook Business Suite API integration (confirmed UI-only, no programmatic access)

---

## Sources
- https://developers.tiktok.com/doc/content-posting-api-get-started/
- https://developers.tiktok.com/doc/oauth-user-access-token-management/
- https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit
- https://developers.tiktok.com/doc/content-posting-api-reference-direct-post (error codes)
- https://developers.google.com/youtube/v3/guides/uploading_a_video
- https://developers.google.com/youtube/v3/determine_quota_cost
- https://developers.google.com/youtube/v3/docs/errors (error catalog)
- https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media
- https://developers.facebook.com/docs/video-api/guides/reels-publishing
- https://developers.facebook.com/docs/video-api/guides/publishing
- https://developers.facebook.com/docs/facebook-login/guides/access-tokens
- https://developers.facebook.com/docs/graph-api/guides/error-handling (Meta error system)
- https://developers.google.com/youtube/v3/docs/videos (processing states, publishAt, failure/rejection reasons)
- https://docs.n8n.io/integrations/builtin/credentials/httprequest/ (OAuth2 credential types)

---

## 11. Questions Summary (All 12 Answered)

- [x] Q1: TikTok Content Posting API — OAuth 2.0+PKCE, 24h/365d tokens, video.publish+video.upload scopes, Creator vs Business = no difference, TikTokAutoUploader HIGH ban risk
- [x] Q2: YouTube Data API v3 — Resumable upload, 100 quota/upload, 10K daily (~100 uploads), publishAt ISO 8601 UTC, built-in n8n node, quota increase 1-4 weeks
- [x] Q3: Instagram Graph API — 2-step container (create+publish), 400 containers/24h, 24h expiry, Reels/Stories/Feed Video/Carousel types, Business vs Creator = no API difference
- [x] Q4: Facebook Video API — Reels 3-phase (start/transfer/finish), regular video 2-phase resumable, Pages-only, 30 Reels/Page/24h, no regular video scheduling via API
- [x] Q5: Video content specs — TikTok H.264 4GB/10min, YouTube H.264 256GB/12h, Instagram H.264 1GB/15min, Facebook H.264 1GB/90s Reels
- [x] Q6: Rate limits — TikTok 6 req/min upload init, YouTube 100 quota/upload, Instagram 400 containers/24h, Facebook 30 Reels/Page/24h. No platform uses X-RateLimit-* headers
- [x] Q7: Error handling — 3-tier retry strategy (server=backoff, rate=fixed delay, validation=fail fast). TikTok log_id, YouTube domain/reason, Meta unified code+subcode
- [x] Q8: Token management — TikTok rotation overlap, YouTube permanent refresh, Meta exchange flow, n8n credential dual-storage sync, proactive refresh cron
- [x] Q9: Platform quirks — TikTok 4-layer duplicate detection (visual+audio+metadata+behavioral), IG 24h container expiry, YouTube 6 upload states + 10 rejection reasons, FB re-encodes all video
- [x] Q10: n8n integration — Generic OAuth2 for TT/IG/FB, built-in YouTube node, CRITICAL retry bug (silently ignored with Continue), Error Trigger workflow, no viable TikTok community node
- [x] Q11: Upload queue — Cron-poll + sub-workflow pattern, priority scheduling (0-10), staggered posting (0/20/40/60min), per-platform exponential backoff, rate_limit_tracker table
- [x] Q12: Multi-account — channels(1)->platform_accounts(N), per-platform token storage, Prisma/pgcrypto encryption, n8n_credential_id sync, 6h refresh cron, health monitoring

---

## 12. Convergence Report

- **Stop reason**: all_questions_answered
- **Total iterations**: 7
- **Questions answered**: 12/12
- **Convergence threshold**: 0.05
- **Info ratios**: 0.83 → 0.94 → 0.72 → 0.79 → 0.79 → 0.71 → 0.69

### Key Architectural Decisions
1. **TikTok: Use official Content Posting API** — TikTokAutoUploader has HIGH ban risk (headless detection, TOS violation). Official API requires audit (1-4 weeks) but is production-safe
2. **YouTube: Only platform with built-in n8n node** — simplest integration, native OAuth auto-refresh, resumable upload built-in
3. **Instagram: Container lifecycle is critical** — 24h expiry + 400/24h cap means upload queue MUST track container timestamps and prioritize publishing near-expiry containers
4. **Facebook: Pages-only, Reels-favored** — Regular video scheduling NOT available via API, only Reels support `scheduled_publish_time`
5. **Rate limit tracking requires dedicated table** — `rate_limit_tracker` per-account, per-limit-type, joined in dequeue query to prevent quota violations
6. **n8n retry bug requires manual retry pattern** — Cannot rely on built-in Retry On Fail with Continue Error Output. Must implement custom retry via Wait node + loop
7. **Token dual-storage sync mandatory** — n8n credentials + platform_accounts must stay in sync via n8n API on every refresh
8. **Content must be genuinely unique per platform** — TikTok 4-layer duplicate detection defeats simple re-encoding. Platform-specific intros/outros/captions required

### Next Step
Implementation: `/spec_kit:plan [upload-pipeline]` to design the n8n upload workflows, DB schema additions (rate_limit_tracker), and per-platform sub-workflows.
- https://docs.n8n.io/flow-logic/error-handling/ (error handling architecture)
- https://docs.n8n.io/flow-logic/subworkflows/ (sub-workflow architecture)
- https://docs.n8n.io/flow-logic/looping/ (Loop Over Items, batch processing)
- https://docs.n8n.io/credentials/ (credential management, encryption)
- https://flowgenius.in/n8n-partial-failure-handling/ (retry patterns, error output branches)
- https://community.n8n.io/t/http-request-node-not-sending-authorization-header-despite-selecting-connected-oauth2-credential-tiktok-api/99963 (TikTok OAuth2 bug)
- https://github.com/n8n-io/n8n/issues/10763 (Retry On Fail + Continue Error Output conflict)
- https://napolify.com/blogs/news/duplicate-content-detection (TikTok duplicate detection layers, via search)
- https://www.musicbusinessworldwide.com/tiktoks-distro-service-soundon-cracks-down-on-manipulated-audio-via-acrcloud-partnership/ (ACRCloud audio fingerprinting)
- specs/001-base-app-research/research/archive/gen1-2026-04-16/research.md (gen1 DB schemas, distribution flow)
