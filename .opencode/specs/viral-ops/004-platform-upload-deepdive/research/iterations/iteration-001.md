# Iteration 1: Platform API Survey -- TikTok Content Posting API & YouTube Data API v3

## Focus
Survey the first two platform APIs (TikTok and YouTube) to establish baseline documentation: official endpoints, OAuth 2.0 flows, token lifecycle, upload mechanisms, rate limits, and quota systems. This is the foundation iteration for the 12-question research agenda.

## Findings

### Finding 1: TikTok Content Posting API -- OAuth 2.0 Flow & Token Lifecycle
- **Authorization**: OAuth 2.0 with PKCE (code_verifier for mobile/desktop). Standard authorization_code grant.
- **Token endpoint**: `POST https://open.tiktokapis.com/v2/oauth/token/`
- **Revoke endpoint**: `POST https://open.tiktokapis.com/v2/oauth/revoke/`
- **Access token expiry**: 24 hours (86,400 seconds, field: `expires_in`)
- **Refresh token expiry**: 365 days (31,536,000 seconds, field: `refresh_expires_in`)
- **Token exchange params**: `client_key`, `client_secret`, `code`, `grant_type=authorization_code`, `redirect_uri`, `code_verifier` (mobile/desktop only)
- **Token refresh params**: `client_key`, `client_secret`, `grant_type=refresh_token`, `refresh_token`
- **Key scopes**: `video.publish` (direct post), `video.upload` (upload for user review). Both require app approval and user authorization.
- **Unaudited restriction**: Unaudited apps have content restricted to private viewing mode. Must pass TikTok audit to lift restriction.
[SOURCE: https://developers.tiktok.com/doc/oauth-user-access-token-management/]
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-get-started/]

### Finding 2: TikTok Content Posting API -- Upload Endpoints & Flow
- **Direct Post endpoint**: `POST https://open.tiktokapis.com/v2/post/publish/video/init/`
- **Photo Post endpoint**: `POST https://open.tiktokapis.com/v2/post/publish/content/init/`
- **Status Check endpoint**: `POST https://open.tiktokapis.com/v2/post/publish/status/fetch/`
- **Two source modes**:
  - `FILE_UPLOAD`: Returns an `upload_url` for chunked upload via PUT request
  - `PULL_FROM_URL`: Requires verified domain/URL prefix (TikTok pulls video from your server)
- **Video format**: MP4 + H.264 supported (detailed specs in Media Transfer Guide)
- **Creator vs Business**: No explicit differentiation found in docs for Content Posting API; privacy level options vary by account configuration.
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-get-started/]

### Finding 3: TikTok API Rate Limits
- **General API rate limit**: 600 requests per minute (1-minute sliding window) for endpoints: `/v2/user/info/`, `/v2/video/query/`, `/v2/video/list/`
- **Rate limit exceeded response**: HTTP `429` with error code `rate_limit_exceeded`
- **Content Posting API specific limits**: NOT documented in the general rate limits page. Likely separate limits exist but require direct TikTok support inquiry or deeper docs dive.
- **Daily posting limits**: NOT explicitly documented in the rate limits page. Known from gen1 research that practical limits exist but exact numbers are unclear for the official API.
- **Higher limits**: Available by contacting TikTok support via their Support Page.
[SOURCE: https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit]

### Finding 4: TikTok Official API vs TikTokAutoUploader Comparison
- **Official Content Posting API**:
  - Pros: Officially supported, OAuth 2.0 compliant, no account ban risk, returns publish status
  - Cons: Requires app audit approval, content restricted to private until audited, limited scheduling capability (not native), scope approval process
  - Upload: Direct via API endpoint, chunked upload or pull-from-URL
- **TikTokAutoUploader** (from gen1 known context):
  - Pros: No app approval needed, cookie-based auth, scheduling up to 10 days, works immediately
  - Cons: Uses Phantomwright stealth (browser automation), violates TikTok TOS, risk of account ban, cookie expiry requires manual refresh, no official support
  - Upload: Browser automation simulating human upload flow
- **Recommendation**: For production viral-ops, official API is preferred for longevity despite higher setup cost. TikTokAutoUploader is viable as interim solution during API audit approval process.
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-get-started/]
[INFERENCE: based on gen1 research context + official API documentation comparison]

### Finding 5: YouTube Data API v3 -- Upload Flow & Quota System
- **Upload method**: Resumable upload via `videos.insert` method
  - Initiate: Call `videos.insert` with `MediaFileUpload(file, chunksize=-1, resumable=True)`
  - Upload: Loop calling `insert_request.next_chunk()` to transmit chunks
  - Resume: On failure, implements exponential backoff with `MAX_RETRIES = 10`
- **OAuth scope**: `https://www.googleapis.com/auth/youtube.upload` (upload-only, no other channel access)
- **Default daily quota**: 10,000 units per day (resets at midnight Pacific Time)
- **Quota cost for upload**: `videos.insert` = **1,600 units** (100 base + 1,500 for video media)
  - CORRECTION: The direct API doc states **100 quota points** for videos.insert. However, the actual cost includes media upload overhead. The 100-unit figure is confirmed from the quota determination page.
- **Other operation costs**:
  - List operations (videos.list, channels.list): **1 unit**
  - Update operations (videos.update): **50 units**
  - Delete operations (videos.delete): **50 units**
  - Search (search.list): **100 units**
  - Every API request (even invalid): minimum **1 unit**
- **Practical daily upload limit**: At 100 units per upload, default quota allows ~100 uploads/day (10,000 / 100). But if actual cost is 1,600, only ~6 uploads/day with default quota.
- **Quota monitoring**: Via Google API Console at `console.cloud.google.com/iam-admin/quotas`
- **Retriable HTTP status codes**: `500, 502, 503, 504`
- **Retriable exceptions**: HttpLib2Error, IOError, NotConnected, IncompleteRead, ImproperConnectionState, CannotSendRequest, CannotSendHeader, ResponseNotReady, BadStatusLine
[SOURCE: https://developers.google.com/youtube/v3/guides/uploading_a_video]
[SOURCE: https://developers.google.com/youtube/v3/determine_quota_cost]

### Finding 6: YouTube Upload -- Key Gaps Identified
- **publishAt scheduling**: Not covered in the upload guide page fetched. Needs separate investigation of the `videos.insert` resource reference for the `status.publishAt` field.
- **Video format requirements**: Not detailed in the upload guide. YouTube supports a wide range but exact limits (file size cap, duration limits, codec requirements) need the "Recommended upload encoding settings" page.
- **Quota increase process**: Not documented on the quota page. Requires separate investigation.
- **Token lifecycle**: YouTube uses standard Google OAuth 2.0 -- access tokens expire in 1 hour (3600s), refresh tokens do not expire unless revoked. This is Google-wide, not YouTube-specific.
[INFERENCE: based on standard Google OAuth 2.0 behavior known from general API knowledge]

## Ruled Out
- None for this iteration (first survey pass)

## Dead Ends
- None identified yet

## Sources Consulted
- https://developers.tiktok.com/doc/content-posting-api-get-started/
- https://developers.tiktok.com/doc/oauth-user-access-token-management/
- https://developers.tiktok.com/doc/tiktok-api-v2-rate-limit
- https://developers.google.com/youtube/v3/guides/uploading_a_video
- https://developers.google.com/youtube/v3/determine_quota_cost

## Assessment
- New information ratio: 0.83
- Questions addressed: Q1 (TikTok auth/upload), Q2 (YouTube upload/quota), Q6 (partial -- rate limits for TikTok and YouTube)
- Questions answered: None fully (Q1 and Q2 both have remaining gaps)

## Reflection
- What worked and why: Fetching official developer documentation pages directly yielded high-quality structured data. The TikTok token management page was particularly rich with exact numeric values (24h access, 365d refresh). YouTube quota page provided exact unit costs.
- What did not work and why: Some documentation pages are fragmented -- TikTok splits content posting, token management, and rate limits across many separate pages, making it hard to get a complete picture in one fetch. YouTube upload guide focuses on code samples rather than specifications.
- What I would do differently: For iteration 2, target specific reference pages (not "get started" guides) for deeper specs. Also fetch the TikTok Media Transfer Guide and YouTube encoding settings page for video format details.

## Recommended Next Focus
1. **Immediate next**: Instagram Graph API video upload (Q3) and Facebook Video API (Q4) -- complete the 4-platform survey
2. **Follow-up**: Return to TikTok Media Transfer Guide for video specs, and YouTube `videos.insert` resource reference for publishAt scheduling details
3. **Gap fill**: TikTok Content Posting API daily posting limits (may need the direct post reference page or content sharing guidelines)
