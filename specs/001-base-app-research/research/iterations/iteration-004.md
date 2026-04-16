# Iteration 4: Remaining Components, Breaking Changes, Auth Decision

## Focus
Complete the gen2 version audit by checking Pixelle-Video, Better Auth, and documenting key breaking changes for Next.js 14->16 and n8n 1->2. Also validate Clerk vs Better Auth auth decision.

## Findings

### 1. Pixelle-Video remains at v0.1.15 (Jan 2026), actively maintained
- Latest release: **v0.1.15** (January 27, 2026) -- no new releases since gen1 baseline
- Stars: 4.1k, License: Apache 2.0
- Active development: commits through Jan 2026 including action migration module (Jan 26) and digital human anchor feature (Jan 14)
- Edge-TTS and ComfyUI integrations are prominently featured in README
- Supports multiple LLM models: GPT, Qwen, DeepSeek, Ollama
- No API breaking changes since v0.1.15 -- gen1 integration plan remains valid
- [SOURCE: https://github.com/AIDC-AI/Pixelle-Video]

### 2. Better Auth v1.6.5 -- strong Clerk alternative (MIT, self-hosted)
- **Version**: v1.6.5 (April 16, 2026) -- very actively maintained
- **Stars**: 27.8k GitHub stars, 917 releases, 826+ contributors
- **License**: MIT (fully open source)
- **Self-hosted**: Yes -- "Your data stays in your database"
- **Database**: PostgreSQL, MySQL, SQLite, MongoDB -- **Prisma adapter confirmed**
- **Framework support**: First-class Next.js, Nuxt, SvelteKit, Astro, Hono, Express, 20+ more
- **Features**: Email/password, 40+ social providers, multi-tenancy/orgs, SSO/SAML/SCIM, 50+ plugins (passkeys, 2FA, magic links), AI agent auth
- **TypeScript**: Full TypeScript framework ("most comprehensive authentication framework for TypeScript")
- **vs Clerk**: Better Auth is OSS/self-hosted (no vendor lock-in, no per-MAU pricing); Clerk is commercial SaaS with free tier but paid for production scale
- [SOURCE: https://better-auth.com]
- [SOURCE: https://github.com/better-auth/better-auth]

### 3. Auth Decision: Use Clerk (next-forge default) with Better Auth as escape hatch
- **Recommendation: Start with Clerk** (next-forge default) for these reasons:
  - next-forge ships with Clerk pre-integrated via `@repo/auth` workspace package
  - Replacing Clerk with Better Auth requires rewiring the auth workspace package -- non-trivial effort
  - Clerk free tier supports 10K MAUs -- sufficient for viral-ops MVP/dev phase
  - Clerk provides managed infrastructure (no auth server to maintain)
- **Better Auth escape hatch**: If Clerk pricing becomes prohibitive at scale or vendor lock-in is unacceptable:
  - Better Auth has a Prisma adapter (compatible with our PostgreSQL + Prisma 7 stack)
  - Migration path exists: replace `@repo/auth` package contents with Better Auth SDK
  - Better Auth is the spiritual successor to Auth.js (though no formal absorption confirmed in their docs)
- [INFERENCE: based on next-forge Clerk integration (iter 3) + Better Auth capabilities + gen1 auth requirements]

### 4. Next.js 14->16 Breaking Changes (comprehensive, via 15->16 upgrade guide)
**Critical breaking changes for viral-ops dashboard:**

a) **Async Request APIs (BREAKING)**: `cookies()`, `headers()`, `draftMode()`, `params`, `searchParams` are ALL async-only in v16. Synchronous access fully removed. Every page/layout using these must add `await`.
   - Impact: HIGH -- all dashboard pages using params/searchParams must be updated
   - Mitigation: Codemod available (`@next/codemod upgrade latest`)
   - next-forge already handles this (built on 16.1.6)

b) **Turbopack by default**: Turbopack is now the default bundler for both `next dev` AND `next build`. Custom webpack configs will cause build failures.
   - Impact: MEDIUM -- viral-ops likely uses no custom webpack, so transparent
   - Escape: `--webpack` flag to opt out

c) **Middleware renamed to Proxy**: `middleware.ts` -> `proxy.ts`, `middleware()` export -> `proxy()` export
   - Impact: LOW-MEDIUM -- if gen1 had middleware, must rename
   - Codemod handles this automatically

d) **next/image changes**: `minimumCacheTTL` default 60s -> 4hrs, `imageSizes` removed 16px, `qualities` restricted to [75], local IP blocked by default, max 3 redirects
   - Impact: LOW -- dashboard images are mostly UI assets

e) **Parallel Routes**: All slots now require explicit `default.js` files
   - Impact: LOW -- unless dashboard uses parallel routes

f) **Caching changes**: `revalidateTag` now requires cacheLife profile as second arg; new `updateTag` and `refresh` APIs
   - Impact: MEDIUM -- any data revalidation code needs updating

g) **Removals**: AMP support removed, `next lint` removed (use ESLint/Biome directly), `serverRuntimeConfig`/`publicRuntimeConfig` removed (use env vars), `next/legacy/image` deprecated
   - Impact: LOW -- viral-ops unlikely to use AMP or runtime config

h) **Node.js 20.9+ minimum** (Node 18 dropped), React 19.2, TypeScript 5.1+ minimum
   - Impact: NONE -- gen2 targets Node 24 LTS, React 19.2.4, TS 6.0

i) **ESLint Flat Config**: `@next/eslint-plugin-next` defaults to flat config format
   - Impact: LOW -- needs `.eslintrc` -> flat config migration

- [SOURCE: https://nextjs.org/docs/app/guides/upgrading/version-16]

### 5. n8n 1->2 Breaking Changes (partial -- docs page 404'd on specific URL)
- n8n docs confirm v2.0 breaking changes exist with a dedicated page and migration tool
- A "v2.0 Migration tool" exists for automated migration
- Specific breaking changes page URL returned 404 (docs restructured)
- Self-hosted licensing status not confirmed from docs page
- **Deferred**: Need to check alternative URLs or GitHub releases for specific breaking changes
- [SOURCE: https://docs.n8n.io/release-notes/]
- [NOTE: https://docs.n8n.io/release-notes/2-0-breaking-changes/ returned 404]

### 6. Architecture Compatibility Assessment (partial)
Based on confirmed versions so far:
- **Dashboard (Next.js 16.1.6 via next-forge) :3000**: Compatible with Node 24 LTS, Bun 1.3.10 as package manager
- **n8n 2.16.0 :5678**: Requires Node.js (not Bun) -- n8n runs separately, no conflict with Bun in next-forge
- **Pixelle-Video v0.1.15 :8000**: Python/FastAPI service, completely independent runtime
- **PostgreSQL 18.3 + Prisma 7.4**: Both confirmed compatible (Prisma 7 supports PG 18)
- **Bun vs Node conflict?**: No -- Bun is only for the next-forge monorepo; n8n runs in its own Node.js process
- **The 3-service localhost architecture remains valid**
- [INFERENCE: based on confirmed versions from iterations 1-3 + architectural isolation of services]

### 7. ComfyUI + Edge-TTS Status (from Pixelle-Video docs)
- ComfyUI integration is confirmed active in Pixelle-Video README -- listed as image/video generation backend
- Edge-TTS is confirmed active -- listed alongside "Index-TTS" as voice synthesis options
- Both are core Pixelle-Video dependencies, actively maintained within that ecosystem
- Specific version numbers for ComfyUI/Edge-TTS not extracted (would need pip/requirements.txt from Pixelle-Video repo)
- [SOURCE: https://github.com/AIDC-AI/Pixelle-Video]

## Ruled Out
- Auth.js v5 as auth solution (already BLOCKED from iteration 3 -- confirmed again: Better Auth is the successor)
- n8n v2.0 breaking changes at `docs.n8n.io/release-notes/2-0-breaking-changes/` (404 -- URL restructured)

## Dead Ends
- None this iteration. The n8n URL 404 is a URL issue, not a fundamental dead end -- alternative URLs exist.

## Sources Consulted
- https://github.com/AIDC-AI/Pixelle-Video
- https://better-auth.com
- https://github.com/better-auth/better-auth
- https://docs.n8n.io/release-notes/
- https://nextjs.org/docs/app/guides/upgrading/version-16

## Assessment
- New information ratio: 0.79
- Questions addressed: Q2, Q5, Q7, Q9, Q10
- Questions answered: Q2 (Next.js breaking changes), Q5 (Clerk vs Better Auth), Q7 (Pixelle-Video), Q10 (architecture partial)

## Reflection
- What worked and why: Fetching the Next.js upgrade guide directly gave extremely comprehensive breaking change documentation in a single fetch -- the official docs are well-structured for LLM consumption. Better Auth's homepage and GitHub provided complementary data (features from homepage, metadata from GitHub).
- What did not work and why: n8n breaking changes URL returned 404, likely because their docs restructured since the URL was documented. Should try GitHub releases or alternative doc paths next iteration.
- What I would do differently: For n8n, try fetching the GitHub releases page or changelog directly instead of the docs subdirectory. Also could check Pixelle-Video's requirements.txt for exact ComfyUI/Edge-TTS versions.

## Recommended Next Focus
1. **n8n 2.0 breaking changes** (Q4) -- try GitHub releases page or `https://docs.n8n.io/breaking-changes/` or similar
2. **Prisma 5->7 breaking changes** (Q3) -- fetch Prisma upgrade guide
3. **ComfyUI + Edge-TTS exact versions** (Q9) -- check Pixelle-Video requirements.txt
4. **Final architecture compatibility summary** (Q10) -- consolidate all findings once Q3/Q4 are answered
