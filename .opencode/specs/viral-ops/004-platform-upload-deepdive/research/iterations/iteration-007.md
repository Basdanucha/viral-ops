# Iteration 7: Formal Closure of Q1-Q4 -- Sub-Gap Fill

## Focus
Close remaining sub-gaps in Q1 (TikTok), Q2 (YouTube), Q3 (Instagram), Q4 (Facebook) that were not covered in iterations 1-2. These questions were substantially answered for core auth flows and upload mechanics, but lacked specific details on: account type differences, scheduling parameters, content type variations, and regular (non-Reels) video upload flows.

## Findings

### Finding 1: TikTok -- Unaudited App Restrictions & Audit Process
The official Content Posting API docs confirm: **all content posted by unaudited clients is restricted to private viewing mode**. This means during development and testing, videos uploaded via the API will only be visible to the creator -- they will not appear in anyone's feed or search results. To remove this restriction, apps must "undergo an audit to verify compliance with Terms of Service." The audit requires the `video.publish` scope to be approved. **Specific timeline for audit approval is not documented in the official API docs** -- it is handled through TikTok's developer support portal on a case-by-case basis.

The documentation does **not** differentiate between Creator and Business TikTok accounts for Content Posting API access. Both `FILE_UPLOAD` and `PULL_FROM_URL` modes are presented as available to any authorized user with the `video.publish` scope. The distinction is at the **app level** (audited vs unaudited), not the **account level** (creator vs business).

[SOURCE: https://developers.tiktok.com/doc/content-posting-api-get-started]
[SOURCE: https://www.tokportal.com/learn/tiktok-content-posting-api-developer-guide (via search)]

### Finding 2: TikTok -- TikTokAutoUploader Detailed Comparison
From gen1 research and web search corroboration, TikTokAutoUploader uses **Phantomwright/Puppeteer browser automation** with stealth plugins to mimic human interaction with the TikTok web interface. Key details:

| Aspect | Detail |
|--------|--------|
| **Auth method** | Cookie-based session (no OAuth) -- user exports browser cookies |
| **How it works** | Launches headless Chromium, injects cookies, navigates TikTok Creator Studio, fills upload form fields programmatically |
| **Scheduling** | Supports scheduling up to 10 days in advance (uses TikTok's built-in web scheduler) |
| **Ban risk** | **HIGH** -- violates TikTok ToS Section 7 (automated access), detectable through browser fingerprinting anomalies, automation timing patterns, and missing client-side JS execution traces |
| **Detection vectors** | Headless browser detection (navigator.webdriver), consistent timing patterns, missing mouse movement entropy, IP reputation if running from server/VPS |
| **Reliability** | Fragile -- breaks when TikTok updates web UI selectors, session cookies expire unpredictably |
| **Rate limiting** | No documented limits beyond TikTok's standard web rate limits |

**Recommendation**: Use TikTokAutoUploader only as a development/testing bridge while waiting for official API audit approval. Never for production at scale.

[SOURCE: specs/001-base-app-research (gen1 Layer 5 Distribution)]
[INFERENCE: based on Phantomwright/Puppeteer architecture patterns and TikTok ToS analysis]

### Finding 3: YouTube -- publishAt Scheduling Parameter Details
The `status.publishAt` parameter has these exact specifications:

| Property | Value |
|----------|-------|
| **Format** | ISO 8601 datetime: `YYYY-MM-DDThh:mm:ss.sZ` |
| **Timezone** | UTC recommended. Supports timezone offset format `YYYY-MM-DDTHH:MM:SS+HH:MM` |
| **Prerequisite** | `status.privacyStatus` MUST be set to `private` |
| **Behavior** | At the specified time, YouTube automatically transitions `privacyStatus` from `private` to `public` |
| **Past dates** | Setting `publishAt` to a past datetime triggers immediate publication |
| **Constraint** | Cannot be used if the video was previously published (no re-scheduling after first publication) |
| **Scheduling window** | No documented maximum scheduling window (no "must be within X days" limit found in official docs) |
| **Alternative formats** | Also accepts date-only `YYYY-MM-DD` and naive time `YYYY-MM-DDTHH:MM:SS` |

**Quota cost**: `videos.insert` costs **100 units** regardless of whether `publishAt` is set. Scheduling does not cost additional quota.

[SOURCE: https://developers.google.com/youtube/v3/docs/videos/insert]
[SOURCE: https://developers.google.com/youtube/v3/docs/videos (VideoStatus resource)]
[SOURCE: https://googleapis.github.io/google-api-python-client/docs/dyn/youtube_v3.videos.html (via search)]

### Finding 4: YouTube -- Built-in n8n Node Capabilities
From prior iteration research (iteration 5) and gen1 context, the YouTube built-in n8n node supports:

| Operation | Supported | Notes |
|-----------|-----------|-------|
| **Upload video** | Yes | Native `videos.insert` with resumable upload |
| **Update video** | Yes | `videos.update` for metadata changes |
| **Delete video** | Yes | `videos.delete` |
| **Get video** | Yes | `videos.list` with video ID |
| **List videos** | Yes | By channel or playlist |
| **OAuth2 auto-refresh** | Yes | Built-in Google OAuth handles token refresh automatically |
| **publishAt scheduling** | Yes | Set via status fields in upload parameters |

The YouTube node is the **only platform with native n8n support** for upload operations. TikTok, Instagram, and Facebook all require HTTP Request nodes with Generic OAuth2 credentials.

**Quota monitoring**: Not available within n8n directly -- must check Google API Console (`console.cloud.google.com/iam-admin/quotas`).

**Quota increase process**: Apply through Google API Console. Requires justification of use case, expected daily volume, and compliance with YouTube ToS. **Typical approval timeline: 1-4 weeks** based on community reports. Google may request additional information or restrict increase based on app history.

[SOURCE: https://docs.n8n.io/integrations/builtin/ (n8n YouTube node, iteration 5)]
[INFERENCE: quota increase timeline based on Google developer community reports, not official documentation]

### Finding 5: Instagram -- Reels vs Feed Video vs Stories Container Parameters
The Instagram Graph API uses distinct parameter sets for each content type:

**Reels** (`media_type=REELS`):
- `video_url` or `upload_type=resumable`
- `caption`, `share_to_feed` (true/false), `cover_url` or `thumb_offset`
- `collaborators` (max 3), `audio_name`, `user_tags`, `location_id`
- Duration: 3s-15min, Max file: 300MB, FPS: 3-60

**Stories** (`media_type=STORIES`):
- `video_url` or `upload_type=resumable`
- `user_tags` with optional x/y coordinates
- Duration: 3s-60s, Max file: 100MB
- No `share_to_feed`, no `collaborators`, no `caption`

**Feed Video (in Carousel only)** (`media_type=VIDEO` with `is_carousel_item=true`):
- `upload_type=resumable`, `thumb_offset`
- **Cannot exist as standalone feed video** -- only as carousel item
- No `share_to_feed` or `collaborators`
- `user_tags` NOT supported for videos in carousels

**Carousel** (`media_type=CAROUSEL`):
- `children` (array of container IDs, max 10 items)
- Mixed images + videos allowed
- **Reels clips cannot appear in carousels** (only `VIDEO` type items)
- `caption`, `share_to_feed`, `collaborators`, `location_id`, `product_tags`

**Container status polling**: Query the container object with `fields=status_code`. Values: `IN_PROGRESS` (still processing), `FINISHED` (ready to publish), `ERROR` (failed). Poll until `FINISHED` before calling `media_publish`. **No documented polling interval** -- recommended: start at 5s, back off to 30s.

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]

### Finding 6: Instagram -- Business vs Creator Account API Access
The official IG Graph API documentation does **not differentiate between Instagram Business and Instagram Creator accounts** for media publishing endpoints. Both account types are referred to as "professional accounts" and access the same `/{ig_user_id}/media` endpoint with identical parameters.

The key distinction is: **personal accounts have no API access for publishing**. Only professional accounts (Business OR Creator) can use the Content Publishing API. The only documented difference between Business and Creator is in Insights API access (Business gets more detailed analytics), not in content publishing capabilities.

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]
[INFERENCE: based on absence of any account-type-specific parameter restrictions in the official docs]

### Finding 7: Facebook -- Regular Video Upload (Non-Reels) via Graph API
Facebook supports regular video uploads (not Reels) through a 2-phase resumable upload protocol:

**Phase 1: Upload to Meta servers**
```
POST /v25.0/{app_id}/uploads
Body: file_name, file_length (bytes), file_type (MIME: video/mp4)
Response: { "id": "upload:{UPLOAD_SESSION_ID}" }
```

**Phase 2: Transfer file data**
```
POST /v25.0/upload:{UPLOAD_SESSION_ID}
Headers: file_offset: 0
Body: binary file data
Response: { "h": "{UPLOADED_FILE_HANDLE}" }
```

**Phase 3: Publish to Page**
```
POST /v25.0/{page_id}/videos
Body: fbuploader_video_file_chunk={file_handle}, title, description, access_token
```

**Resume interrupted uploads**: `GET /v25.0/upload:{UPLOAD_SESSION_ID}` returns current `file_offset` to resume from that point.

**Page vs User video**: The documentation focuses on Page video uploads (`/{page_id}/videos`). **User profile video uploads are not exposed through the Graph API** for third-party apps -- they are limited to the Facebook web/mobile interface.

**Required permissions**: `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`, plus `CREATE_CONTENT` capability on the Page.

[SOURCE: https://developers.facebook.com/docs/video-api/guides/publishing]

### Finding 8: Facebook -- Scheduling via Graph API
The official Video API publishing guide (`/docs/video-api/guides/publishing`) does **not document a `scheduled_publish_time` parameter** for video uploads. Scheduling capabilities are:

| Method | Available | Notes |
|--------|-----------|-------|
| **Reels API `scheduled_publish_time`** | Yes (Reels only) | Set during `upload_phase=finish` with ISO 8601 datetime, requires `video_state=SCHEDULED` instead of `PUBLISHED` |
| **Regular video scheduling** | Not documented | No `scheduled_publish_time` parameter found in regular video upload endpoints |
| **Business Suite scheduling** | Yes (UI only) | Manual scheduling through Meta Business Suite web interface, not programmatic |
| **Graph API scheduled posts** | Yes (non-video) | `/{page_id}/feed` supports `scheduled_publish_time` for text/link/image posts, but video scheduling through this endpoint is undocumented |

**Implication for viral-ops**: For scheduled video publishing on Facebook, the queue system should set `status=queued` with `scheduled_at` and let the n8n cron-poll trigger the upload at the right time, rather than relying on Facebook's native scheduling (which is limited to Reels and not available for regular videos via API).

[SOURCE: https://developers.facebook.com/docs/video-api/guides/publishing]
[SOURCE: https://developers.facebook.com/docs/video-api/guides/reels-publishing (iteration 2)]
[INFERENCE: based on absence of scheduling parameters in regular video upload docs]

## Ruled Out
- **TikTok Creator vs Business account API differences**: The Content Posting API does not differentiate between account types. The distinction is at the app level (audited vs unaudited), not the account level.
- **Facebook regular video scheduling via Graph API**: No `scheduled_publish_time` parameter exists for regular video uploads. Only Reels support native scheduling. Regular video scheduling must be handled at the queue level.
- **Instagram standalone feed video upload**: Feed videos can only exist as carousel items (`is_carousel_item=true`). There is no standalone feed video upload -- use Reels for single video posts.

## Dead Ends
- **YouTube publishAt maximum scheduling window**: No maximum documented. Attempted to find limits in both official docs and Java client library reference -- none exist. This is either unlimited or undocumented.
- **Facebook Business Suite API integration**: Business Suite scheduling is UI-only. No programmatic API for Business Suite scheduling features exists for third-party apps.

## Sources Consulted
- https://developers.tiktok.com/doc/content-posting-api-get-started
- https://developers.google.com/youtube/v3/docs/videos/insert
- https://developers.google.com/youtube/v3/docs/videos
- https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media
- https://developers.facebook.com/docs/video-api/guides/publishing
- https://www.tokportal.com/learn/tiktok-content-posting-api-developer-guide (via WebSearch)
- https://googleapis.github.io/google-api-python-client/docs/dyn/youtube_v3.videos.html (via WebSearch)

## Assessment
- New information ratio: 0.69
- Questions addressed: Q1, Q2, Q3, Q4
- Questions answered: Q1, Q2, Q3, Q4

## Reflection
- What worked and why: Combining official doc fetches (4 parallel WebFetch calls) with targeted web searches (2 calls) provided both authoritative specs and gap-filling context. The Instagram media reference page was exceptionally dense -- one fetch yielded Reels vs Stories vs Carousel differences, container polling, and account type information all at once.
- What did not work and why: TikTok official docs do not document Creator vs Business differences at all -- the distinction simply does not exist for the Content Posting API. YouTube publishAt scheduling window limits are not documented anywhere (tried official docs, Java client lib, Python client lib).
- What I would do differently: For undocumented limits (like YouTube scheduling window), file a note as "undocumented -- test empirically" rather than spending additional research actions searching for information that likely does not exist in public documentation.

## Recommended Next Focus
With Q1-Q12 now all formally addressed, the next iteration should be a **convergence/synthesis iteration** to: (1) verify all 12 questions have complete answers, (2) close out open gaps in research.md Section 10, and (3) produce a final consolidated view suitable for implementation planning.
