# Iteration 2: Instagram Graph API & Facebook Video API -- Platform Survey Completion

## Focus
Complete the 4-platform API survey by researching Instagram Graph API video/Reels upload (Q3) and Facebook Video/Reels API (Q4). Following iteration 1's successful approach of fetching official Meta developer documentation directly.

## Findings

### Finding 1: Instagram Graph API -- 2-Step Container Upload Flow
Instagram uses a container-based upload model with two main approaches:

**Standard flow (video_url):**
1. **Create container**: `POST https://graph.facebook.com/v25.0/{ig_user_id}/media` with `media_type=REELS`, `video_url`, `caption`
2. **Publish container**: `POST https://graph.facebook.com/v25.0/{ig_user_id}/media_publish` with the container ID

**Resumable upload flow:**
1. **Create container**: Same endpoint, add `upload_type=resumable`
2. **Upload binary**: `POST https://rupload.facebook.com/ig-api-upload/v25.0/{container_id}` with binary data
3. **Publish container**: Same publish endpoint

**Container status check**: Query the container's `status_code` field -- value `FINISHED` means upload succeeded. Containers expire after 24 hours.

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]

### Finding 2: Instagram Content Types and Parameters
| Content Type | `media_type` | Key Differences |
|-------------|-------------|-----------------|
| Reels | `REELS` | `share_to_feed` controls distribution, `cover_url` for thumbnail, `audio_name` for music, up to 3 collaborators |
| Stories | `STORIES` | Max 60 seconds, max 100 MB, `user_tags` with x/y coordinates |
| Carousel | (items) | Items use `is_carousel_item=true`, supports `product_tags` for shopping |

**Caption limits**: Max 2,200 characters, 30 hashtags, 20 @mentions.
**Additional parameters**: `thumb_offset` (ms) for custom thumbnail frame, `trial_params` for experimental Reels with graduation strategies (`MANUAL` or `SS_PERFORMANCE`).

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]

### Finding 3: Instagram Video Format Specifications
| Spec | Reels | Stories |
|------|-------|---------|
| Container | MOV or MP4 (MPEG-4 Part 14) | MOV or MP4 |
| Video codec | H.264 or HEVC, progressive scan, closed GOP, 4:2:0 chroma | Same |
| Audio | AAC, max 48 kHz, mono/stereo, 128 Kbps | Same |
| Frame rate | 23-60 FPS | 23-60 FPS |
| Max resolution | 1920px horizontal | 1920px horizontal |
| Aspect ratio | 0.01:1 to 10:1 (9:16 recommended) | 0.1:1 to 10:1 (9:16 recommended) |
| Duration | 3 sec to 15 min | 3 sec to 60 sec |
| File size | Max 300 MB | Max 100 MB |
| Video bitrate | VBR max 25 Mbps | VBR max 25 Mbps |

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]

### Finding 4: Instagram Rate Limits
- **Container creation**: 400 containers per account per 24-hour rolling window
- **No explicit hourly API call limit** documented on the media endpoint reference (the gen1 "200 calls/user/hour" figure from strategy Q3 may be a general Graph API limit, not upload-specific)
- Container expiry acts as implicit rate control -- unused containers expire after 24 hours

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]

### Finding 5: Facebook Reels API -- 3-Phase Upload Protocol
Facebook Reels uses a distinct 3-phase flow on the `video_reels` edge:

**Phase 1 -- Initialize:**
- `POST https://graph.facebook.com/v25.0/{page_id}/video_reels` with `upload_phase=start`
- Returns: `video_id` and `upload_url`

**Phase 2 -- Transfer:**
- `POST https://rupload.facebook.com/v25.0/video-upload/{video_id}`
- Headers: `Authorization: OAuth {token}`, `offset`, `file_size`
- Supports local files or hosted URLs

**Phase 3 -- Publish:**
- `POST https://graph.facebook.com/v25.0/{page_id}/video_reels` with `video_id`, `upload_phase=finish`, `video_state=PUBLISHED`

**Status polling**: `GET /v25.0/{video_id}?fields=status` returns `uploading_phase`, `processing_phase`, `publishing_phase`.

**Retrieve Reels list**: `GET /v25.0/{page_id}/video_reels`

[SOURCE: https://developers.facebook.com/docs/video-api/guides/reels-publishing]

### Finding 6: Facebook Reels Specifications and Rate Limits
| Spec | Requirement |
|------|-------------|
| File type | .mp4 recommended |
| Aspect ratio | 9:16 |
| Resolution | 1080x1920 recommended; 540x960 minimum |
| Frame rate | 24-60 fps |
| Duration | 3-90 seconds (max 60 sec when published as story) |
| Codec | H.264, H.265, VP9, AV1 |
| Audio bitrate | 128 Kbps+ |
| Audio encoding | AAC Low Complexity |
| Sample rate | 48 kHz |

**Rate limits**: 30 API-published Reels per Page per 24-hour moving period.
**Collaborator invitations**: Max 10 per Page per 24 hours.
**Limitation**: Reels publishing via API is limited to Facebook Pages only (not user profiles).
**Rejection rule**: Files hosted on Meta CDN (fbcdn URLs) are rejected; must use crossposting feature instead.

**Reels-specific error codes**:
| Code | Issue | Solution |
|------|-------|---------|
| 1363040 | Unsupported aspect ratio | Use 16:9 to 9:16 range |
| 1363127 | Resolution unsupported | Min 540x960 |
| 1363128 | Invalid duration | 3-90 seconds required |
| 1363129 | Frame rate unsupported | 24-60 fps required |

[SOURCE: https://developers.facebook.com/docs/video-api/guides/reels-publishing]

### Finding 7: Facebook Video Upload (Non-Reels) -- Resumable Protocol
The generic Facebook Video API uses a different upload protocol than Reels:

1. **Initialize**: `POST /v25.0/{app_id}/uploads` with `file_name`, `file_length`, `file_type`
2. **Upload**: `POST /v25.0/upload:{upload_session_id}` with `file_offset` header + binary body
3. **Publish**: `POST /v25.0/{page_id}/videos` with `fbuploader_video_file_chunk={file_handle}`

**Resume capability**: `GET /v25.0/upload:{upload_session_id}` returns current `file_offset` for resume.
**Supported MIME types for upload**: video/mp4, image/jpeg, image/png, application/pdf.

[SOURCE: https://developers.facebook.com/docs/video-api/guides/publishing]

### Finding 8: Meta Token Lifecycle (Facebook + Instagram shared)
Both Instagram Graph API and Facebook API share the Meta OAuth token system:

| Token Type | Expiry | Notes |
|-----------|--------|-------|
| Short-lived user token | ~1-2 hours | Initial OAuth callback token |
| Long-lived user token | ~60 days | Exchanged from short-lived |
| Page access token | Does not expire* | Derived from long-lived user token (*if user granted permanent page access) |
| App access token | Does not expire | Generated from app_id + app_secret |
| System user token | Does not expire | For programmatic operations without user interaction |

**Exchange endpoint (short-lived to long-lived)**:
```
GET https://graph.facebook.com/oauth/access_token
  ?grant_type=fb_exchange_token
  &client_id={app_id}
  &client_secret={app_secret}
  &fb_exchange_token={short_lived_token}
```

**Required permissions for publishing**:
- `pages_show_list`
- `pages_read_engagement`
- `pages_manage_posts`
- Page must grant `CREATE_CONTENT` task capability

**Critical caveat from Meta docs**: "You should not expect the remaining lifespan to match what is stated, as it may change without notice or expire early."

[SOURCE: https://developers.facebook.com/docs/facebook-login/guides/access-tokens]

## Ruled Out
- None. All four research actions (4 WebFetch calls to official Meta docs) returned substantive data.

## Dead Ends
- The generic Facebook Video API publishing guide (`/docs/video-api/guides/publishing`) describes the upload-session protocol but omits video-specific rate limits, codec requirements, and resolution specs. The Reels-specific page is far more complete for our use case.
- The access token guide does not document Instagram-specific token considerations separately -- they share the same Meta token infrastructure.

## Sources Consulted
- https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media
- https://developers.facebook.com/docs/video-api/guides/reels-publishing
- https://developers.facebook.com/docs/video-api/guides/publishing
- https://developers.facebook.com/docs/facebook-login/guides/access-tokens

## Assessment
- New information ratio: 0.94
- Questions addressed: Q3, Q4, Q8 (partial -- token lifecycle)
- Questions answered: None fully (Q3 and Q4 have strong coverage but missing some error code catalogs and non-Reels Facebook video specs)

## Reflection
- What worked and why: Targeting specific Meta developer doc pages (media reference, reels-publishing, access-tokens) yielded dense structured data with exact numbers. The Reels publishing page was exceptionally well-structured with error codes, specs, and rate limits all on one page.
- What did not work and why: The generic Video API publishing guide was sparse on video-specific details (no codec/resolution/rate limits) -- it describes a general file upload protocol rather than video publishing specifics. This is likely because Meta separates "upload infrastructure" from "content type specs."
- What I would do differently: For future iterations, prefer content-type-specific pages (e.g., "reels-publishing") over generic API pages (e.g., "video-api/publishing"). The content-type pages have the specifications we need.

## Recommended Next Focus
1. **Video content specs deep dive (Q5)**: Return to each platform for exact codec/resolution/duration requirements in a unified comparison matrix. Instagram and Facebook specs are now documented; need TikTok and YouTube equivalents.
2. **Rate limits consolidation (Q6)**: Cross-platform rate limit comparison with detection methods (HTTP status codes, response headers).
3. **Error handling patterns (Q7)**: Build error code catalogs per platform with retry strategies.
