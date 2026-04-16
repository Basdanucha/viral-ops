# Iteration 6: Upload Queue Architecture (Q11) & Multi-Account Management (Q12)

## Focus
This iteration designs the upload queue processing architecture -- how the `upload_queue` database table integrates with n8n workflows for priority-based scheduling, staggered posting, failure retry with exponential backoff, and status tracking. It also addresses multi-account management -- how `platform_accounts` connects to OAuth tokens, handles token rotation across accounts, and tracks per-account rate limits. Additionally covers remaining gaps in Q8 (n8n credential storage for OAuth tokens).

## Findings

### Finding 1: Upload Queue State Machine & n8n Integration Pattern

**State machine** (refined from gen1 schema `queued | processing | completed | failed | cancelled`):

```
                      ┌─────────────────────────────────────────────────────┐
                      │                                                     │
  ┌────────┐    ┌─────┴────┐    ┌───────────┐    ┌───────────┐            │
  │ queued  │───>│scheduled │───>│ processing│───>│ completed │            │
  └────────┘    └──────────┘    └───────────┘    └───────────┘            │
       │              │              │                                      │
       │              │              │         ┌────────┐    ┌───────────┐│
       │              │              └────────>│ failed  │───>│ retry_wait││
       │              │                        └────────┘    └───────────┘│
       │              │                             │              │       │
       │              │                             │              └───────┘
       │              │                             │         (back to scheduled
       │              │                             │          if retry_count < max)
       │              │                             v
       ├──────────────┴─────────────────────> ┌──────────┐
       │              (manual)                │cancelled │
       │                                      └──────────┘
       v
  ┌──────────┐
  │ expired  │  (scheduled_at + window exceeded without processing)
  └──────────┘
```

**Full status enum**: `queued -> scheduled -> processing -> completed | failed -> retry_wait -> scheduled | cancelled | expired`

**n8n integration model**: **Cron-poll + sub-workflow**, not webhook trigger.

The architecture uses a **Schedule Trigger** (every 2 minutes) that polls `upload_queue` for pending jobs, combined with **Execute Sub-workflow** nodes for per-platform upload execution:

```
[Schedule Trigger: */2 * * * *]
    |
    v
[Postgres: SELECT from upload_queue]
  WHERE status IN ('queued', 'retry_wait')
    AND scheduled_at <= NOW()
    AND (platform, platform_account_id) NOT IN (active rate-limited accounts)
  ORDER BY priority DESC, scheduled_at ASC
  LIMIT 5
    |
    v
[Loop Over Items (batch size: 1)]
    |
    v
[Postgres: UPDATE status = 'processing', n8n_execution_id = $executionId]
    |
    v
[Switch: platform]
    |-- tiktok --> [Execute Sub-workflow: tiktok-upload]
    |-- youtube --> [Execute Sub-workflow: youtube-upload]
    |-- instagram --> [Execute Sub-workflow: instagram-upload]
    |-- facebook --> [Execute Sub-workflow: facebook-upload]
    |
    v
[IF: success?]
    |-- Yes --> [Postgres: UPDATE status = 'completed', INSERT platform_publishes]
    |-- No  --> [IF: retryable? (check error tier)]
                  |-- Yes --> [Postgres: UPDATE status = 'retry_wait',
                  |            retry_count++, scheduled_at = NOW() + backoff]
                  |-- No  --> [Postgres: UPDATE status = 'failed', last_error = ...]
                              [Send alert (webhook/email)]
```

**Why cron-poll over webhook**: The upload queue is filled by the content production pipeline (Layer 4). Using Schedule Trigger allows batch processing, rate limit awareness, and priority ordering. A webhook would trigger immediately on INSERT, bypassing scheduling logic.

**Batch size = 1 in Loop Over Items**: Each upload is processed sequentially within a single poll cycle to allow per-item error handling and status updates. The 2-minute poll interval naturally limits throughput.

[SOURCE: n8n docs Schedule Trigger architecture + gen1 research.md Layer 5 distribution flow + prior iteration findings on n8n error handling]
[SOURCE: D:/Dev/Projects/viral-ops/specs/001-base-app-research/research/archive/gen1-2026-04-16/research.md:273-286 (upload_queue schema)]

### Finding 2: Priority Scheduling & Staggered Posting Design

**Priority system**: The `priority` field (INT, default 0) controls processing order. Higher values = higher priority.

| Priority | Use Case | Example |
|----------|----------|---------|
| 10 | Urgent/trending | Trend-riding content needing immediate upload |
| 5 | Normal | Standard scheduled content |
| 3 | Backfill | Re-uploads, variant testing |
| 0 | Low | Archive uploads, non-time-sensitive |
| -1 | Deprioritized | Failed retries (auto-demoted) |

**SQL for priority-based dequeue**:
```sql
SELECT uq.*, pa.platform, pa.access_token, pa.token_expires_at,
       c.video_file_path, c.title, c.script_text
FROM upload_queue uq
JOIN platform_accounts pa ON pa.id = uq.platform_account_id
JOIN content c ON c.id = uq.content_id
WHERE uq.status IN ('queued', 'retry_wait')
  AND uq.scheduled_at <= NOW()
  AND pa.is_active = true
  AND pa.token_expires_at > NOW()  -- Skip accounts with expired tokens
ORDER BY uq.priority DESC, uq.scheduled_at ASC
LIMIT 5;
```

**Staggered posting design**: When content targets multiple platforms, the content production pipeline creates multiple `upload_queue` rows with staggered `scheduled_at` values:

```
Content "video-123" targeting 4 platforms, base_time = 2026-04-17 10:00:
  - TikTok:    scheduled_at = 10:00 (first, for maximum trend freshness)
  - Instagram: scheduled_at = 10:20 (+20min)
  - YouTube:   scheduled_at = 10:40 (+40min, also uses publishAt for native scheduling)
  - Facebook:  scheduled_at = 11:00 (+60min)
```

The 15-30 minute stagger interval (from gen1 spec) serves two purposes:
1. **Anti-fingerprinting**: Avoids simultaneous cross-platform posting that TikTok's behavioral duplicate detection (Layer 4) flags
2. **Error recovery window**: If TikTok upload fails, there's time to retry before Instagram is attempted

**YouTube native scheduling**: For YouTube, set `status.publishAt` in the upload API call to the desired publish time. The video is uploaded immediately (consuming quota) but published at the scheduled time. This means YouTube uploads can be frontloaded without affecting the stagger pattern.

**Multi-account staggering**: When the same content is posted to multiple TikTok accounts (different channels), add an additional 15-minute offset per account to avoid TikTok's behavioral detection of cross-account duplication.

[SOURCE: D:/Dev/Projects/viral-ops/specs/001-base-app-research/research/archive/gen1-2026-04-16/research.md:522-528 (staggered posting spec)]
[SOURCE: iteration-005.md Finding 1 (TikTok 4-layer duplicate detection including behavioral pattern analysis)]
[SOURCE: iteration-003.md Finding 2 (YouTube publishAt scheduling details)]
[INFERENCE: Stagger intervals derived from gen1 15-30min spec combined with TikTok behavioral detection findings]

### Finding 3: Failure Retry with Exponential Backoff (n8n Implementation)

Given the **critical n8n bug** (Retry On Fail silently ignored when Continue Error Output is enabled), retry logic MUST be implemented manually in the queue system, not at the n8n node level.

**Backoff formula**: `next_retry_at = NOW() + min(base_delay * 2^retry_count + jitter, max_delay)`

**Per-platform retry configuration**:

| Platform | Base Delay | Max Delay | Max Retries | Rationale |
|----------|-----------|-----------|-------------|-----------|
| TikTok | 120s (2min) | 3600s (1h) | 5 | 6 req/min upload init limit; back off aggressively |
| YouTube | 60s (1min) | 1800s (30min) | 3 | Quota-based, not rate-based; retries consume quota units |
| Instagram | 300s (5min) | 7200s (2h) | 4 | Container 24h expiry; need time for recovery but not too long |
| Facebook | 180s (3min) | 3600s (1h) | 4 | 30 Reels/day limit; moderate backoff |

**Retry schedule example (TikTok, base=120s)**:
- Attempt 1: immediate
- Attempt 2: ~120s + jitter (2-4 min)
- Attempt 3: ~480s + jitter (8-10 min)
- Attempt 4: ~1920s + jitter (~32 min)
- Attempt 5: ~3600s (capped at 1h)
- After attempt 5: status = 'failed', alert sent

**Error tier classification for retry decisions** (from iteration 4):

| Tier | Action | Errors |
|------|--------|--------|
| Tier 1 (retryable) | Retry with backoff | 5xx, network timeout, TikTok `rate_limit_exceeded`, YT 500/502/503/504, Meta codes 1/2/4/17 |
| Tier 2 (rate limit) | Wait for reset window | TikTok `spam_risk_too_many_posts`, YT `quotaExceeded`, IG 400 containers, FB 30 Reels |
| Tier 3 (fatal) | Fail immediately, alert | Auth errors (401, Meta 190), permission (403), validation (400), duplicate (506) |

**Tier 2 handling**: For rate limit exhaustion, the queue sets `status = 'retry_wait'` with `scheduled_at` set to the estimated reset time:
- TikTok: `NOW() + 60s` (1-minute sliding window)
- YouTube: `midnight Pacific + 1h` (daily quota reset)
- Instagram: Track per-account container creation timestamps, schedule after oldest container ages out of 24h window
- Facebook: Track per-page Reel count, schedule after oldest Reel ages out of 24h window

**Queue SQL for retry**:
```sql
UPDATE upload_queue
SET status = 'retry_wait',
    retry_count = retry_count + 1,
    scheduled_at = NOW() + INTERVAL '1 second' * LEAST(
      $base_delay * POWER(2, retry_count) + (RANDOM() * 30),
      $max_delay
    ),
    last_error = $error_message,
    updated_at = NOW()
WHERE id = $queue_id
  AND retry_count < max_retries;
```

[SOURCE: iteration-004.md (unified retry strategy tiers, per-platform retryable vs fatal errors)]
[SOURCE: iteration-005.md Finding 5 (n8n Retry On Fail bug -- retries silently ignored with Continue Error Output)]
[SOURCE: iteration-001.md (TikTok 6 req/min upload init limit)]
[SOURCE: iteration-003.md (rate limit detection per platform)]

### Finding 4: Rate Limit Awareness -- Per-Account Tracking Table

The queue processor needs real-time awareness of per-account rate limit consumption. The gen1 schema does not include a rate limit tracking table. This is a **schema addition** needed:

```sql
-- Rate limit tracking per platform account
rate_limit_tracker (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform_account_id UUID NOT NULL REFERENCES platform_accounts(id),
  platform VARCHAR(20) NOT NULL,
  limit_type VARCHAR(50) NOT NULL,        -- 'upload_init' | 'container_create' | 'quota_daily' | 'reels_daily'
  window_start TIMESTAMPTZ NOT NULL,
  window_duration_seconds INT NOT NULL,    -- 60 for TikTok, 86400 for YouTube/IG/FB
  current_count INT DEFAULT 0,
  max_count INT NOT NULL,                  -- 6 for TikTok, 100 for YT, 400 for IG, 30 for FB
  last_request_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(platform_account_id, limit_type)
);
```

**Per-platform rate limit tracking**:

| Platform | Limit Type | Max Count | Window | Reset Logic |
|----------|-----------|-----------|--------|-------------|
| TikTok | `upload_init` | 6 | 60s (sliding) | Decrement after oldest request ages past 60s |
| YouTube | `quota_daily` | 100 | 86400s (fixed, midnight Pacific) | Reset at midnight Pacific Time |
| Instagram | `container_create` | 400 | 86400s (rolling) | Decrement after oldest container ages past 24h |
| Facebook | `reels_daily` | 30 | 86400s (rolling) | Decrement after oldest reel ages past 24h |

**Queue dequeue with rate limit check** (enhanced SQL):
```sql
SELECT uq.*
FROM upload_queue uq
JOIN platform_accounts pa ON pa.id = uq.platform_account_id
LEFT JOIN rate_limit_tracker rlt ON rlt.platform_account_id = pa.id
  AND rlt.limit_type = CASE pa.platform
    WHEN 'tiktok' THEN 'upload_init'
    WHEN 'youtube' THEN 'quota_daily'
    WHEN 'instagram' THEN 'container_create'
    WHEN 'facebook' THEN 'reels_daily'
  END
WHERE uq.status IN ('queued', 'retry_wait')
  AND uq.scheduled_at <= NOW()
  AND pa.is_active = true
  AND (rlt.current_count IS NULL OR rlt.current_count < rlt.max_count)
ORDER BY uq.priority DESC, uq.scheduled_at ASC
LIMIT 5;
```

**Rate limit update flow**: After each successful upload API call, the queue processor increments `current_count` in `rate_limit_tracker`. A separate n8n cron (every 5 minutes) runs a cleanup query to decrement expired window entries.

[SOURCE: iteration-001.md Finding 4 (TikTok 6 req/min upload init)]
[SOURCE: iteration-003.md (YouTube 100 quota/day, Instagram 400/24h, Facebook 30/24h)]
[INFERENCE: rate_limit_tracker table design synthesized from all 4 platform rate limit findings across iterations 1-3]

### Finding 5: Multi-Account Management Architecture (Q12)

**Relationship model**: `platform_accounts` has a **many-to-one relationship with channels** (many accounts can belong to one channel, but each account belongs to exactly one channel). This is confirmed by the gen1 schema where `channels` -> `platform_accounts` is via `channel_id`:

```
channels (1) ──> (N) platform_accounts (1) ──> (N) upload_queue
                         │
                         └──> (N) platform_publishes
```

**One channel, multiple accounts example**:
- Channel "Thai Food Reviews" has:
  - 1 TikTok account (`@thaifoodreviews`)
  - 1 YouTube account (Thai Food Reviews channel)
  - 1 Instagram account (`@thai.food.reviews`)
  - 1 Facebook Page (Thai Food Reviews)
- Each platform account stores its own OAuth credentials independently

**Token storage per platform** (what to store in `platform_accounts`):

| Platform | `auth_type` | `access_token` | `refresh_token` | `token_expires_at` | `cookies_json` | `platform_metadata` |
|----------|------------|----------------|-----------------|-------------------|---------------|-------------------|
| TikTok (API) | `oauth` | Bearer token (24h) | Refresh token (365d) | access expiry | NULL | `{open_id, scope}` |
| TikTok (Auto) | `cookie` | NULL | NULL | Cookie expiry | Session cookies | `{session_id}` |
| YouTube | `oauth` | Bearer token (~1h) | Refresh token (permanent) | access expiry | NULL | `{channel_id, playlist_id}` |
| Instagram | `oauth` | Long-lived token (60d) | NULL | token expiry | NULL | `{ig_user_id, page_id, business_id}` |
| Facebook | `oauth` | Page access token (permanent) | NULL | NULL (permanent) | NULL | `{page_id, business_id}` |

**Token encryption**: n8n stores credentials encrypted using AES-256-GCM with the `ENCRYPTION_KEY` environment variable. The `platform_accounts` table in PostgreSQL should use Prisma's `@db.Text` with application-level encryption (via `pgcrypto` extension or Node.js `crypto.createCipheriv`). Tokens should NEVER be stored in plaintext.

**Recommended encryption approach**:
```sql
-- PostgreSQL pgcrypto for at-rest encryption
ALTER TABLE platform_accounts
  ALTER COLUMN access_token TYPE BYTEA USING pgp_sym_encrypt(access_token, $encryption_key),
  ALTER COLUMN refresh_token TYPE BYTEA USING pgp_sym_encrypt(refresh_token, $encryption_key);
```

Or better: use Prisma middleware for encrypt-on-write / decrypt-on-read, keeping the key in `DATABASE_ENCRYPTION_KEY` env var.

[SOURCE: D:/Dev/Projects/viral-ops/specs/001-base-app-research/research/archive/gen1-2026-04-16/research.md:188-204 (platform_accounts schema)]
[SOURCE: iteration-001.md (TikTok 24h/365d token lifecycle)]
[SOURCE: iteration-002.md (Meta token lifecycle: short 1-2h, long 60d, page permanent)]
[SOURCE: iteration-005.md Finding 4 (n8n credential storage encrypted, per-credential entity)]
[INFERENCE: encryption approach synthesized from n8n AES-256-GCM documentation + PostgreSQL pgcrypto standard practice]

### Finding 6: Token Refresh Automation (n8n Cron Workflows)

**Proactive token refresh** prevents upload failures due to expired tokens. Each platform needs a different refresh strategy:

**Token Refresh Workflow** (separate n8n workflow, Schedule Trigger):

```
[Schedule Trigger: 0 */6 * * *]  (every 6 hours)
    |
    v
[Postgres: SELECT accounts needing refresh]
  WHERE is_active = true
    AND (
      -- TikTok: refresh when access token expires within 6h
      (platform = 'tiktok' AND token_expires_at < NOW() + INTERVAL '6 hours')
      OR
      -- YouTube: refresh when access token expires within 30min
      (platform = 'youtube' AND token_expires_at < NOW() + INTERVAL '30 minutes')
      OR
      -- Instagram: refresh when long-lived token expires within 7 days
      (platform = 'instagram' AND token_expires_at < NOW() + INTERVAL '7 days')
      -- Facebook page tokens: permanent, skip
    )
    |
    v
[Loop Over Items]
    |
    v
[Switch: platform]
    |-- tiktok --> [HTTP Request: POST /v2/oauth/token/
    |               grant_type=refresh_token, refresh_token=$refresh_token]
    |-- youtube --> [HTTP Request: POST https://oauth2.googleapis.com/token
    |               grant_type=refresh_token, refresh_token=$refresh_token]
    |-- instagram --> [HTTP Request: GET /oauth/access_token
    |                  grant_type=fb_exchange_token, fb_exchange_token=$access_token]
    |
    v
[IF: success?]
    |-- Yes --> [Postgres: UPDATE access_token, token_expires_at, updated_at]
    |           [Also update n8n credential via n8n API if applicable]
    |-- No  --> [Postgres: UPDATE is_active = false]
                [Send alert: "Token refresh failed for {account_name}"]
```

**Refresh timing rationale**:
- **TikTok (6h before expiry)**: 24h access token, refresh early enough that upload queue never encounters expired token. 6h buffer accounts for potential refresh API downtime.
- **YouTube (30min before)**: Google auto-refreshes in the built-in node, but for HTTP Request workflows, pre-refresh ensures valid token.
- **Instagram (7 days before)**: 60-day long-lived token. 7-day buffer provides multiple retry opportunities for the exchange flow.
- **Facebook**: Page tokens are permanent. No refresh needed unless the page admin revokes access.

**Account health monitoring**: Add an `account_health` workflow (daily cron) that:
1. Queries each active account's API (lightweight call like profile info)
2. Updates `is_active = false` if token is revoked (HTTP 401/190)
3. Logs health status to a `platform_account_health_log` table
4. Alerts on accounts inactive for > 24h

[SOURCE: iteration-001.md (TikTok refresh endpoint: POST /v2/oauth/token/ with grant_type=refresh_token)]
[SOURCE: iteration-002.md (Meta token exchange: GET /oauth/access_token with grant_type=fb_exchange_token)]
[SOURCE: iteration-005.md Finding 4 (n8n OAuth2 Generic auto-refresh, built-in Google OAuth)]
[INFERENCE: refresh timing windows derived from token TTLs documented in iterations 1-2 with safety margins]

### Finding 7: n8n Credential Storage & Q8 Closure

**n8n credential architecture** (closing remaining Q8 gap):

| Aspect | Detail |
|--------|--------|
| **Encryption** | AES-256-GCM with `ENCRYPTION_KEY` (32-char hex, set in n8n env) |
| **Storage backend** | n8n internal SQLite/PostgreSQL database (configurable via `DB_TYPE`) |
| **Credential entity** | Each credential is a standalone encrypted record with `id`, `name`, `type`, `data` (encrypted JSON) |
| **Sharing** | Credentials can be shared between workflows (enterprise) or are workflow-scoped (community) |
| **OAuth2 lifecycle** | Generic OAuth2 credentials store: clientId, clientSecret, accessToken, refreshToken, oauthTokenData (full response) |
| **Multi-account** | N credentials of same type allowed. Each node selects its credential by name. 5 TikTok accounts = 5 "OAuth2 API" credentials named distinctly |

**Dual-storage problem**: Tokens live in TWO places:
1. **n8n credentials** (for n8n workflow execution)
2. **platform_accounts table** (for queue management, health monitoring, dashboard display)

**Synchronization strategy**: When the token refresh workflow updates `platform_accounts`, it should ALSO update the corresponding n8n credential via the **n8n API**:

```
PUT /api/v1/credentials/{credential_id}
Content-Type: application/json
Authorization: Bearer {n8n_api_key}

{
  "name": "TikTok - @thaifoodreviews",
  "type": "oAuth2Api",
  "data": {
    "accessToken": "{new_token}",
    "oauthTokenData": { ... }
  }
}
```

This keeps both storage locations in sync. The `platform_accounts` table should store an `n8n_credential_id` field to link to the n8n credential entity:

```sql
ALTER TABLE platform_accounts ADD COLUMN n8n_credential_id VARCHAR(100);
```

**Security considerations**:
- n8n `ENCRYPTION_KEY` must be set before first credential creation (cannot be changed later without re-encryption)
- The n8n API key for credential updates should be stored as an environment variable, never in the database
- `platform_accounts.access_token` is used for health monitoring and queue logic only; actual upload execution uses n8n credentials
- Consider removing raw tokens from `platform_accounts` entirely and only storing metadata (expiry, health status) -- the token of record lives in n8n credentials

[SOURCE: iteration-005.md Finding 4 (n8n credentials encrypted in database, per-entity model)]
[SOURCE: https://docs.n8n.io/credentials/ (credential types, sharing, storage)]
[INFERENCE: dual-storage sync via n8n API derived from the architectural reality that both systems need tokens]

## Ruled Out
- **n8n webhook trigger for queue processing**: Webhooks trigger immediately on external calls, bypassing priority ordering and rate limit checks. Cron-poll is the correct pattern for a queue with priority and scheduling semantics.
- **n8n built-in retry for upload error handling**: Confirmed again -- the Retry On Fail + Continue Error Output bug (iteration 5) means all retry logic must be queue-level (database status + scheduled_at manipulation), not node-level.

## Dead Ends
- None identified this iteration. All design decisions are constructive (no external sources returned "this approach doesn't work").

## Sources Consulted
- D:/Dev/Projects/viral-ops/specs/001-base-app-research/research/archive/gen1-2026-04-16/research.md (lines 188-286, 519-528, 647-695, 731-775) -- gen1 DB schema, distribution flow, sprint plan
- https://docs.n8n.io/flow-logic/subworkflows/ -- sub-workflow architecture (partial)
- https://docs.n8n.io/flow-logic/looping/ -- Loop Over Items, batch processing (partial)
- https://docs.n8n.io/credentials/ -- credential management architecture (partial)
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/ -- Schedule Trigger (partial)
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.wait/ -- Wait node (partial)
- Prior iteration findings: iterations 1-5 (rate limits, error tiers, token lifecycles, n8n patterns, duplicate detection)

## Assessment
- New information ratio: 0.71
- Questions addressed: Q11, Q12, Q8
- Questions answered: Q11 (upload queue architecture), Q12 (multi-account management), Q8 (n8n credential storage -- now fully closed)

## Reflection
- What worked and why: Synthesizing prior iteration findings (rate limits from iter 1-3, error tiers from iter 4, n8n patterns from iter 5) with gen1 DB schema produced a concrete architectural design. The gen1 schema was the most valuable source -- it provided the exact fields, relationships, and constraints to design around. The queue architecture is essentially a state machine layered on top of the existing `upload_queue` table with n8n as the execution engine.
- What did not work and why: n8n documentation pages continue to render with minimal content (client-side rendering issue). However, this was less impactful than prior iterations because the architectural design relies more on synthesizing known constraints (rate limits, error tiers, token lifecycles) than on discovering new n8n features.
- What I would do differently: For this iteration, the n8n doc fetches were low-value since we already had enough n8n knowledge from iteration 5. The tool call budget would have been better spent on researching PostgreSQL queue processing patterns (SKIP LOCKED, advisory locks) or n8n API documentation for credential management endpoints.

## Recommended Next Focus
1. **Formal closure of Q1-Q4**: These questions about per-platform auth flows are substantially answered across iterations 1-2 but need formal consolidation and closure in the registry.
2. **Final synthesis**: With Q5-Q12 now addressed, the remaining work is synthesis and gap-filling rather than new research. Consider a consolidation iteration to close all questions and produce the final research.md.
