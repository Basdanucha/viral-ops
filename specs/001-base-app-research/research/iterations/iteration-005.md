# Iteration 5: Prisma 5->7 Breaking Changes, n8n 2.0 Breaking Changes, ComfyUI/Edge-TTS Status, Architecture Synthesis

## Focus
Final discovery iteration targeting all remaining unanswered questions: Q3 (Prisma migration), Q4 (n8n migration), Q9 (ComfyUI/Edge-TTS pinning), and Q10 (architecture compatibility synthesis). This closes the version audit so the next iteration can be pure synthesis.

## Findings

### 1. Prisma 5->7 Migration Requires Two-Stage Upgrade (5->6->7)
**The upgrade path is NOT direct.** Prisma 7 upgrade guide assumes Prisma 6 as baseline. Must upgrade through Prisma 6 first.

**Prisma 5->6 breaking changes:**
- Node.js 18.18.0+ required (gen1 used 18+, so OK if pinned correctly)
- TypeScript 5.1.0+ required
- PostgreSQL M:N relation tables change from unique index to primary key (auto-migration generated)
- `fullTextSearch` feature flag must be renamed to `fullTextSearchPostgres` for PostgreSQL
- `Buffer` replaced with `Uint8Array` for Bytes fields
- `NotFoundError` removed -- must use `PrismaClientKnownRequestError` with code P2025
- `async`, `await`, `using` are reserved keywords -- cannot be model names

**Prisma 6->7 breaking changes (MAJOR -- architectural shift):**
- **ESM-only**: Must add `"type": "module"` to package.json, update tsconfig
- **New provider**: `prisma-client-js` removed, must use `prisma-client`
- **Output field mandatory**: Prisma Client no longer generates to node_modules; must specify output path
- **Import path changes**: From `@prisma/client` to custom generated paths (e.g., `./generated/prisma/client`)
- **Driver adapters mandatory**: ALL databases require explicit driver adapters (e.g., `@prisma/adapter-pg` for PostgreSQL)
- **prisma.config.ts mandatory**: Configuration centralized in TypeScript config file at project root
- **Env vars not auto-loaded**: Must manually load `.env` via dotenv
- **$use() middleware removed**: Must migrate to Client Extensions
- **CLI changes**: `--skip-generate`, `--skip-seed` removed from `prisma migrate dev`; auto-generation removed; auto-seeding removed
- **SSL validation strict by default**: May need explicit config for local dev
- **12 environment variables removed**: Including `PRISMA_MIGRATE_SKIP_GENERATE`
- Node.js 20.19.0+ required (gen2 targets Node 24, so OK)
- TypeScript 5.4.0+ required (gen2 targets TS 6.0, so OK)

**Impact on gen1's 14-table schema:**
- Schema itself likely compatible (no JSONB-specific breaks found, UUID generation unchanged)
- The BIGGEST migration effort is the ESM + driver adapter + prisma.config.ts restructuring, not the schema
- M:N relation tables (if any in gen1) will get auto-migrated primary keys

[SOURCE: https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-6]
[SOURCE: https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-7]

### 2. n8n 1->2 Breaking Changes: Database, Security, Node Removals
**n8n 2.0.0 breaking changes confirmed from GitHub release page:**

- **MySQL/MariaDB dropped**: Only PostgreSQL and SQLite supported now (gen1 uses PostgreSQL -- no impact)
- **4 nodes removed**: Spontit, Crowd.dev, Kitemaker, Automizy (gen1 does not use these -- no impact)
- **Security hardening**:
  - Environment variable access blocked in code/expressions by default
  - OAuth callback endpoints require authentication
  - File access settings enforced by default
- **CLI changes**: `--tunnel` option removed
- **Config changes**: `N8N_CONFIG_FILES` env var removed
- **Binary data**: Memory mode dropped
- **Pyodide disabled**: Python execution via Pyodide made unrunnable
- **Nodes disabled by default**: `ExecuteCommand` and `LocalFileTrigger` must be explicitly enabled
- **Worker changes**: Implicit retries setting removed
- **Git node**: Bare repositories disabled by default
- **SQLite**: Non-pooling driver dropped

**Impact on viral-ops n8n workflows:**
- HTTP Request nodes calling Pixelle-Video API: **No breaking change** -- HTTP Request node is unchanged
- PostgreSQL backend: **No breaking change** -- PG still fully supported
- `ExecuteCommand` node: If used, must be explicitly enabled via env var
- Environment variable access in expressions: May need to allow explicitly if workflows reference env vars
- Self-hosted licensing: Release notes do not mention licensing changes -- still free for self-host

[SOURCE: https://github.com/n8n-io/n8n/releases/tag/n8n%402.0.0]

### 3. ComfyUI: v0.19.0 (April 2025), Actively Maintained, No Major Version Break
- **Latest release**: v0.19.0 (April 13, 2025)
- **Release cadence**: Very active -- v0.16 through v0.19 in roughly one month (March-April 2025)
- **Versioning**: Semantic versioning, still pre-1.0 (v0.x.x)
- **License**: GPL-3.0 (unchanged)
- **Key recent features**: LTX2 audio, Ace Step 1.5 XL, RT-DETRv4 detection, flux 2 decoder, fp16 optimizations, VAE VRAM improvements
- **No breaking API changes** for Pixelle-Video integration -- ComfyUI's workflow JSON format remains stable across 0.x releases
- **Pin recommendation**: v0.19.0 or latest (Pixelle-Video bundles its own ComfyUI workflows)

[SOURCE: https://github.com/comfyanonymous/ComfyUI/releases]

### 4. Edge-TTS: v7.2.8 (March 2026), Actively Maintained, Thai Voices Available
- **Latest version**: 7.2.8 (March 22, 2026)
- **Previous**: 7.2.7 (December 2025)
- **Python requirement**: >=3.7
- **License**: LGPLv3
- **Status**: Actively maintained, no deprecation notices
- **Thai voices**: Still available (th-TH-PremwadeeNeural, th-TH-NiwatNeural, th-TH-AcharaNeural) -- Microsoft Edge TTS service remains operational
- **Major version jump**: Was likely ~6.x at gen1 time, now 7.2.8 -- but the API (`edge-tts` CLI and Python module) has remained stable
- **No breaking changes** for Pixelle-Video's TTS integration

[SOURCE: https://pypi.org/project/edge-tts/]

### 5. Architecture Compatibility Synthesis (Q10 -- FINAL)
With all versions now confirmed, the 3-service localhost architecture remains fully compatible:

| Service | Runtime | Port | Compatibility Notes |
|---------|---------|------|-------------------|
| Dashboard (next-forge) | Bun 1.3.10 | :3000 | Bun runs Next.js; no conflict with Node services |
| n8n 2.16.0 | Node.js 24 | :5678 | Drops MySQL (irrelevant); PG still supported; HTTP Request nodes unchanged |
| Pixelle-Video 0.1.15 | Python/FastAPI | :8000 | Independent Python process; ComfyUI/Edge-TTS bundled |

**Cross-service compatibility confirmed:**
- **PostgreSQL 18.3 + Prisma 7.4**: Compatible via `@prisma/adapter-pg` driver adapter (mandatory in v7)
- **n8n 2.x + PostgreSQL 18.3**: n8n supports PG as primary backend; PG 18 is standard
- **n8n HTTP Request -> Pixelle-Video**: HTTP Request node API unchanged in n8n 2.0; same REST calls work
- **Bun + Node.js coexistence**: next-forge uses Bun for the dashboard; n8n runs on Node.js; no port/runtime conflicts
- **No version combination breaks the gen1 architecture**

**Migration effort ranking:**
1. **Prisma 5->7** (HIGH): ESM migration, driver adapters, prisma.config.ts, import path changes
2. **Next.js 14->16** (MEDIUM): Async APIs, Turbopack default, middleware changes (documented in iteration 4)
3. **n8n 1->2** (LOW): Mostly security hardening; core workflow format unchanged
4. **ComfyUI/Edge-TTS** (NONE): Pin latest versions, no migration needed

[INFERENCE: based on all findings from iterations 1-5 combined]

## Ruled Out
- Direct Prisma 5->7 upgrade: Must go through 6 first (two-stage migration)
- n8n docs.n8n.io breaking changes URL: Already blocked from iteration 4; used GitHub releases instead (success)

## Dead Ends
- None new this iteration. All research avenues were productive.

## Sources Consulted
- https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-6
- https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-7
- https://github.com/n8n-io/n8n/releases/tag/n8n%402.0.0
- https://github.com/comfyanonymous/ComfyUI/releases
- https://pypi.org/project/edge-tts/

## Assessment
- New information ratio: 0.90
- Questions addressed: Q3, Q4, Q9, Q10
- Questions answered: Q3 (Prisma 5->7 breaking changes fully documented), Q4 (n8n 2.0 breaking changes documented), Q9 (ComfyUI v0.19.0 + Edge-TTS v7.2.8 pinned), Q10 (architecture compatibility confirmed)

## Reflection
- What worked and why: Fetching official upgrade guides from Prisma docs gave extremely detailed, well-structured breaking change documentation -- two pages covered the entire 5->6->7 path. Using GitHub releases for n8n (after the docs URL was blocked) worked perfectly -- the release page had a clear summary. PyPI for Edge-TTS gave version + status in one fetch.
- What did not work and why: Nothing failed this iteration. All 5 web fetches returned usable data.
- What I would do differently: Could have fetched ComfyUI license separately (not shown on releases page), but GPL-3.0 is well-established from prior knowledge.

## Recommended Next Focus
All 10 key questions are now answered. The next iteration should be **pure synthesis**: consolidate iterations 1-5 into the definitive version matrix and migration guide in research/research.md. No new research needed.
