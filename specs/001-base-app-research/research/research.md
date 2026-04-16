# viral-ops Framework Version Update — Research (Gen 2)

> Progressive synthesis document. Updated each iteration.
> Gen 1 archive: `research/archive/gen1-2026-04-16/research.md`

---

## 1. Version Matrix (Current as of Iteration 5 -- ALL QUESTIONS ANSWERED)

| Component | Gen 1 Version | Current Stable | Status | Migration Effort |
|-----------|--------------|----------------|--------|-----------------|
| **Dashboard boilerplate** | next-saas-stripe-starter (Next 14) | **next-forge v6.0.2** (Mar 2026) | CONFIRMED | Medium (swap auth) |
| **Next.js** | 14.x | **16.1.6** (in next-forge) / **16.2** (latest) | Confirmed | High (2 major versions) |
| **React** | 18.x | **19.2.4** (in next-forge) | Confirmed | Medium |
| **Prisma** | 5.x | **7.4** (Feb 2026) | Stable | HIGH (5->6->7 two-stage; ESM, driver adapters) |
| **n8n** | 1.x | **2.16.0** | Stable | LOW (security hardening; core workflows unchanged) |
| **Tailwind CSS** | 3.x | **4.2.1** (in next-forge) / **4.1** (Apr 2025 blog) | Confirmed | High (config rewrite) |
| **Node.js** | 18+ | **24 LTS** (v24.15.0) | LTS | Low-Medium |
| **Tremor** | 3.x | Stalled (0 releases) | DEAD -- replaced by shadcn/ui charts | N/A (drop) |
| **Auth** | Auth.js v5 | **Clerk** (next-forge default); **Better Auth v1.6.5** as escape hatch | DECIDED | Low (use Clerk default) |
| **ShadCN UI** | latest | Charts confirmed (Recharts v3) | Active | Low (already compatible) |
| **TypeScript** | 5.x | **6.0** (stable); next-forge pins ^5.9.3 | Confirmed | Low-Medium |
| **PostgreSQL** | 16.x | **18.3** (Feb 2026) | Stable | Low (Prisma handles compat) |
| **Pixelle-Video** | 0.1.15+ | **v0.1.15** (Jan 2026) -- no new release | Confirmed, active dev | None (same version) |
| **ComfyUI** | latest | **v0.19.0** (Apr 2025) | Confirmed, GPL-3.0, active | None (pin latest) |
| **Edge-TTS** | latest | **v7.2.8** (Mar 2026) | Confirmed, LGPLv3, active | None (pin latest) |
| **Bun** | (not in gen1) | **1.3.10** (next-forge default) | New addition | N/A (new) |

---

## 2. Boilerplate Replacement (Q1)

### Current Status
- `next-saas-stripe-starter` is NOT archived but is effectively **stagnant** -- last release June 2024, still on Next.js 14 + Prisma 5.x
- Needs replacement with a modern boilerplate using Next.js 16 + App Router + Prisma 7

### Recommendation: next-forge (haydenbleasel/next-forge)

| Attribute | Value |
|-----------|-------|
| Version | v6.0.2 (March 20, 2026) |
| Stars | 7,000 |
| License | MIT |
| ORM | Prisma |
| Auth | Clerk (swappable to Auth.js) |
| UI | Tailwind CSS + TWBlocks |
| Payments | Stripe |
| Structure | Turborepo monorepo (web, app, api, docs, email, storybook) |
| Batteries | Analytics, observability, security, CMS, AI utils, webhooks, i18n |
| Activity | 1,495 commits, 367 releases, actively maintained |

**Why next-forge over alternatives:**
- Only candidate with active 2026 releases + Stripe + Prisma + monorepo
- Clerk-to-Auth.js swap is a known migration pattern
- Batteries-included approach matches viral-ops complexity

**CONFIRMED (iteration 3):** Next.js 16.1.6, Tailwind CSS 4.2.1, React 19.2.4, Zod 4.3.6, Sentry 10.42.0. Uses Bun 1.3.10 as package manager. Monorepo with workspace packages: `@repo/auth` (Clerk), `@repo/design-system`, `@repo/cms`, `@repo/email`, `@repo/analytics`, `@repo/security`, `@repo/internationalization`.

**Auth note:** next-forge uses Clerk for auth (via `@repo/auth` workspace package). Since Auth.js is now absorbed into Better Auth, Clerk becomes the path of least resistance for viral-ops. Clerk-to-Better-Auth swap remains possible if needed.

### Runner-up: create-t3-app (t3-oss/create-t3-app)
- v7.40.0 (Nov 2025) -- 5 months stale, yellow flag
- 28.8k stars, MIT, Prisma or Drizzle, NextAuth.js, tRPC
- **No Stripe integration** -- would need to add from scratch
- Scaffold-only, no batteries -- significantly more work to build out
- Best for: projects wanting typesafety (tRPC) over completeness

### Other Candidates (not yet evaluated)
- taxonomy (by shadcn) -- deferred
- Makerkit -- deferred
- SaaS-Starter-Kit -- deferred
- Shipfast -- deferred

---

## 3. Key Framework Updates

### Next.js 14 -> 16.2 (Q2 -- ANSWERED iteration 4)
- **Released**: Next.js 16.0 (Oct 2025), 16.2.4 (Apr 2026)
- **Performance**: ~400% faster dev startup, ~50% faster rendering
- **React**: 19.2 with View Transitions, useEffectEvent, Activity API
- **React Compiler**: Built-in support now stable (auto-memoization)
- **Key Breaking Changes (14->16)**:
  1. **Async Request APIs (HIGH)**: `cookies()`, `headers()`, `params`, `searchParams` are ALL async-only. Must add `await` everywhere. Codemod available.
  2. **Turbopack default (MEDIUM)**: Default bundler for dev+build. Custom webpack configs cause build failures. Use `--webpack` flag to opt out.
  3. **Middleware -> Proxy (MEDIUM)**: `middleware.ts` renamed to `proxy.ts`, export renamed too. Codemod handles this.
  4. **next/image defaults changed (LOW)**: Cache TTL 60s->4hrs, imageSizes removed 16px, qualities restricted to [75], local IP blocked, max 3 redirects.
  5. **Caching changes (MEDIUM)**: `revalidateTag` requires cacheLife profile as 2nd arg. New `updateTag` + `refresh` APIs.
  6. **Parallel Routes**: All slots require explicit `default.js` files.
  7. **Removals**: AMP, `next lint`, `serverRuntimeConfig`/`publicRuntimeConfig`, `next/legacy/image`.
  8. **ESLint**: Flat config format is now default.
  9. **Node.js 20.9+ minimum** (18 dropped), TypeScript 5.1+ minimum.
- **Migration**: Codemod available (`@next/codemod upgrade latest`). next-forge already on 16.1.6 so most changes are pre-handled.
- [SOURCE: https://nextjs.org/docs/app/guides/upgrading/version-16]

### Prisma 5.x -> 7.4 (Q3 -- ANSWERED iteration 5)
- **Released**: Prisma 7.4 (Feb 2026)
- **Migration path**: Must go 5->6->7 (no direct 5->7 path)
- **Prisma 5->6 breaking changes**:
  1. Node.js 18.18.0+ required
  2. TypeScript 5.1.0+ required
  3. M:N relation tables: unique index -> primary key (auto-migration)
  4. `fullTextSearch` renamed to `fullTextSearchPostgres` for PG
  5. `Buffer` -> `Uint8Array` for Bytes fields
  6. `NotFoundError` removed (use `PrismaClientKnownRequestError` P2025)
  7. `async`/`await`/`using` reserved as model names
- **Prisma 6->7 breaking changes (MAJOR)**:
  1. **ESM-only**: `"type": "module"` required, tsconfig updates
  2. **New provider**: `prisma-client-js` -> `prisma-client`
  3. **Output field mandatory**: No more node_modules generation
  4. **Import paths changed**: `@prisma/client` -> custom generated paths
  5. **Driver adapters mandatory**: Must use `@prisma/adapter-pg` for PostgreSQL
  6. **prisma.config.ts mandatory**: All config centralized in TS config
  7. **Env vars not auto-loaded**: Must use dotenv manually
  8. **$use() middleware removed**: Migrate to Client Extensions
  9. **CLI flags removed**: `--skip-generate`, `--skip-seed` gone from `prisma migrate dev`
  10. **Auto-generation/seeding removed**: Must run `prisma generate` and `prisma db seed` explicitly
  11. **SSL validation strict by default**
  12. Node.js 20.19.0+ required (gen2 = Node 24, OK)
  13. TypeScript 5.4.0+ required (gen2 = TS 6.0, OK)
- **Impact on gen1 schema**: Schema itself compatible (no JSONB/UUID/array breaks); main effort is ESM + driver adapter + config restructuring
- [SOURCE: https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-6]
- [SOURCE: https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-7]

### n8n 1.x -> 2.16.0 (Q4 -- ANSWERED iteration 5)
- **Status**: Fully released, up to v2.16.0
- **New features**: Visual diff, external secrets, folder filtering, custom roles, AI Agent functionality
- **Licensing**: Sustainable Use License still listed; no licensing changes in 2.0 release notes -- still free for single-user self-host
- **n8n 2.0 breaking changes**:
  1. **MySQL/MariaDB dropped**: Only PostgreSQL + SQLite supported (gen1 uses PG -- no impact)
  2. **4 nodes removed**: Spontit, Crowd.dev, Kitemaker, Automizy (gen1 doesn't use these)
  3. **Environment vars blocked** in code/expressions by default (may need explicit allow)
  4. **OAuth callbacks require auth**: Security hardening
  5. **File access enforced by default**: Security hardening
  6. **`--tunnel` CLI removed**: Use ngrok or similar for external access
  7. **`N8N_CONFIG_FILES` removed**: Use env vars directly
  8. **Binary data memory mode dropped**: Use filesystem or S3
  9. **Pyodide disabled**: Python execution via Pyodide unrunnable
  10. **ExecuteCommand + LocalFileTrigger disabled by default**: Must explicitly enable
  11. **Worker implicit retries removed**: Configure retries explicitly
  12. **Git node: bare repos disabled by default**
  13. **Non-pooling SQLite driver dropped**
- **Impact on viral-ops**: LOW -- HTTP Request nodes unchanged, PG fully supported, core workflow format unchanged
- [SOURCE: https://github.com/n8n-io/n8n/releases/tag/n8n%402.0.0]

### Tailwind CSS 3.x -> 4.1
- **Released**: v4.0 (Jan 2025), v4.1 (Apr 2025)
- **Engine**: New "Oxide" engine, completely reimagined config
- **Risk**: Configuration system completely redesigned -- all tailwind.config.js must be rewritten
- **Dependency risk**: Tremor and ShadCN compatibility with v4 unknown

### Node.js 18+ -> 24 LTS
- **Current LTS**: v24.15.0
- **Current**: v25.9.0
- **Migration**: Relatively straightforward -- Node.js maintains good backward compatibility

---

## 4. Risk Assessment

| Risk | Severity | Component | Notes |
|------|----------|-----------|-------|
| Tremor stalled / likely dead | HIGH | Tremor | RESOLVED: Replace with shadcn/ui charts (Recharts v3) |
| Prisma 5->7 migration | HIGH | Prisma | 20 breaking changes across 2 major versions; ESM-only + driver adapters are biggest |
| Next.js 14->16 migration | MEDIUM | Next.js | 9 categories of breaking changes; codemod available; next-forge pre-handles most |
| Tailwind v4 config migration | MEDIUM | Tailwind CSS | Config rewrite needed; next-forge already on v4.2.1 |
| n8n 2.x migration | LOW | n8n | 13 breaking changes but core HTTP Request workflows unchanged; PG still supported |
| ComfyUI/Edge-TTS | LOW | Pixelle-Video | No migration needed; pin latest versions |

---

## 5. Questions Summary (All Answered)

- [x] Q1: next-forge v6.0.2 — Next.js 16.1.6, Tailwind 4.2.1, React 19.2.4, Turborepo, Clerk, Bun 1.3.10
- [x] Q2: Next.js 14→16 — 9 breaking change categories, codemod available, next-forge pre-handles most
- [x] Q3: Prisma 5→7 — 2-stage migration (5→6→7), 20 breaking changes, ESM-only + driver adapters. Schema compatible.
- [x] Q4: n8n 1→2 — 13 breaking changes, HTTP Request nodes unchanged, LOW impact
- [x] Q5: Auth — Clerk (next-forge default), Better Auth v1.6.5 as OSS escape hatch. Auth.js dead.
- [x] Q6: Tremor DEAD → shadcn/ui charts (6 types, Recharts v3). ShadCN Tailwind v4 compatible.
- [x] Q7: Pixelle-Video v0.1.15 — no change, actively maintained
- [x] Q8: TypeScript 6.0, PostgreSQL 18.3 stable
- [x] Q9: ComfyUI v0.19.0, Edge-TTS v7.2.8 — both active, Thai voices available
- [x] Q10: Architecture validated — 3-service localhost fully compatible with all updated versions

---

## 6. Convergence Report

- **Stop reason**: all_questions_answered
- **Total iterations**: 5 (generation 2)
- **Questions answered**: 10/10
- **Convergence threshold**: 0.05
- **Info ratios**: 0.86 → 0.80 → 0.86 → 0.79 → 0.90

### Migration Effort Summary
| Priority | Component | Effort | Action |
|----------|-----------|--------|--------|
| 1 | Boilerplate | SWAP | next-saas-stripe-starter → next-forge v6.0.2 |
| 2 | Auth | SWAP | Auth.js v5 → Clerk (next-forge default) |
| 3 | Charts | SWAP | Tremor → shadcn/ui charts |
| 4 | Prisma | HIGH | 5→6→7 two-stage migration (ESM, driver adapters) |
| 5 | Next.js | MEDIUM | 14→16 (next-forge handles most, codemod for custom code) |
| 6 | Tailwind | MEDIUM | 3→4 config rewrite (next-forge already on v4) |
| 7 | n8n | LOW | 1→2 (core workflows unchanged) |
| 8 | Node.js | LOW | 18→24 LTS |
| 9 | PostgreSQL | LOW | 16→18 (Prisma handles compat) |
| 10 | Pixelle-Video | NONE | v0.1.15 unchanged |
| 11 | ComfyUI | NONE | Pin v0.19.0 |
| 12 | Edge-TTS | NONE | Pin v7.2.8, Thai voices active |

### Key Decisions (Gen 2)
1. **next-forge replaces next-saas-stripe-starter** — actively maintained, batteries-included, Next.js 16 + Tailwind v4 ready
2. **Clerk replaces Auth.js** — Auth.js absorbed into Better Auth; Clerk is next-forge default with Better Auth as OSS escape hatch
3. **shadcn/ui charts replace Tremor** — Tremor stalled/dead; shadcn charts provide same capability via Recharts v3
4. **Bun added as package manager** — next-forge default, compatible with Node.js ecosystem
5. **Gen1 architecture (3-service localhost) validated** — no breaking incompatibilities with any version update

### Next Step
Implementation: fork next-forge, apply Prisma schema, install n8n 2.x + Pixelle-Video, test webhook chain.
Reference gen1 architecture from `research/archive/gen1-2026-04-16/research.md` for intelligence layers, upload strategies, and multi-channel identity (unchanged).
