---
title: Deep Research Dashboard
description: Auto-generated reducer view over the research packet.
---

# Deep Research Dashboard - Session Overview

Auto-generated from JSONL state log, iteration files, findings registry, and strategy state. Never manually edited.

<!-- ANCHOR:overview -->
## 1. OVERVIEW

Reducer-generated observability surface for the active research packet.

<!-- /ANCHOR:overview -->
<!-- ANCHOR:status -->
## 2. STATUS
- Topic: viral-ops framework version update — boilerplate replacement (next-saas-stripe-starter is dead), Next.js 16, Prisma 7, n8n 2.x compatibility, and stable versions for all stack components
- Started: 2026-04-17T10:00:00Z
- Status: INITIALIZED
- Iteration: 5 of 10
- Session ID: dr-gen2-1776397200
- Parent Session: dr-1776310994-5288
- Lifecycle Mode: restart
- Generation: 2
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | Stack component version survey — Next.js, Prisma, n8n, Tailwind, Node.js, Tremor, boilerplate status | version-survey | 0.86 | 7 | complete |
| 2 | Boilerplate replacement candidates (Q1) + Tremor status deep dive (Q6) | boilerplate-and-ui | 0.80 | 5 | complete |
| 3 | next-forge version confirmation + shadcn/ui charts + remaining component versions (TypeScript, PostgreSQL, Auth.js) | version-pinning | 0.86 | 7 | complete |
| 4 | Remaining components + breaking changes + auth decision (Pixelle-Video, Better Auth, Next.js 16 migration, n8n partial, architecture validation) | version-audit | 0.79 | 7 | complete |
| 5 | Prisma 5->7 breaking changes (Q3) + n8n 2.0 breaking changes (Q4) + ComfyUI/Edge-TTS pinning (Q9) + architecture synthesis (Q10) | version-audit | 0.90 | 5 | complete |

- iterationsCompleted: 5
- keyFindings: 205
- openQuestions: 10
- resolvedQuestions: 0

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 0/10
- [ ] Q1: What replaces next-saas-stripe-starter as the dashboard boilerplate? (dead repo — find living alternatives with Next.js 16 + App Router)
- [ ] Q2: Next.js 16 — what's new, stable?, breaking changes from 14? Migration path?
- [ ] Q3: Prisma 7 — stable? Breaking changes from 5.x? New features relevant to viral-ops?
- [ ] Q4: n8n 2.x — stable? Breaking changes from 1.x? New features? Self-hosted licensing changes?
- [ ] Q5: Auth.js / NextAuth — latest stable version? Breaking changes? Better alternatives?
- [ ] Q6: ShadCN UI + Tremor + Tailwind CSS — latest versions? Tailwind v4? Tremor status?
- [ ] Q7: Pixelle-Video — latest version? API changes since v0.1.15? New features?
- [ ] Q8: Node.js LTS, PostgreSQL, TypeScript — latest stable versions to pin?
- [ ] Q9: ComfyUI, Edge-TTS, RunningHub — any significant updates?
- [ ] Q10: Does the gen1 architecture (3-service localhost) still hold with updated versions? Any breaking incompatibilities?

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.86 -> 0.79 -> 0.90
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.90
- coverageBySources: {"authjs.dev":1,"better-auth.com":1,"docs.n8n.io":1,"github.com":14,"nextjs.org":2,"nodejs.org":1,"pypi.org":1,"raw.githubusercontent.com":4,"tailwindcss.com":1,"ui.shadcn.com":2,"web":1,"www.npmjs.com":2,"www.postgresql.org":2,"www.prisma.io":3,"www.typescriptlang.org":2}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
- Checking Auth.js, ShadCN UI, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video versions (not enough tool budget this iteration -- deferred) (iteration 1)
- Checking individual component changelogs in detail (deferred to focused iterations per component) (iteration 1)
- None identified this iteration (first survey pass) (iteration 1)
- **Makerkit, SaaS-Starter-Kit, SaaSBold, Shipfast**: Not investigated this iteration -- defer to iteration 3 if next-forge doesn't pan out (iteration 2)
- **npm direct scraping for Tremor**: Returns 403, need alternative approach (GitHub API or registry.npmjs.org API) (iteration 2)
- **taxonomy (shadcn/taxonomy)**: Not investigated this iteration due to tool budget -- defer to iteration 3 (iteration 2)
- **tremor-raw as alternative to Tremor**: Confirmed dead. Only 2 commits, redirects to main tremor repo. Not a viable separate path. (iteration 2)
- **Auth.js v5 as auth solution**: Auth.js has been absorbed into "Better Auth" project. The authjs.dev site confirms this. Auth.js v5 as a standalone maintained project is effectively deprecated. This eliminates Auth.js as a direct dependency choice -- must either adopt Better Auth, use Clerk (next-forge default), or evaluate alternatives. (iteration 3)
- Checking individual next-forge workspace packages (e.g., `@repo/auth`, `@repo/design-system`) for exact Clerk/Prisma versions -- deferred due to tool budget. The web app package.json confirmed the framework versions which was the priority. (iteration 3)
- Direct npm registry scraping (already BLOCKED from iteration 2) (iteration 3)
- Auth.js v5 as auth solution (already BLOCKED from iteration 3 -- confirmed again: Better Auth is the successor) (iteration 4)
- n8n v2.0 breaking changes at `docs.n8n.io/release-notes/2-0-breaking-changes/` (404 -- URL restructured) (iteration 4)
- None this iteration. The n8n URL 404 is a URL issue, not a fundamental dead end -- alternative URLs exist. (iteration 4)
- Direct Prisma 5->7 upgrade: Must go through 6 first (two-stage migration) (iteration 5)
- n8n docs.n8n.io breaking changes URL: Already blocked from iteration 4; used GitHub releases instead (success) (iteration 5)
- None new this iteration. All research avenues were productive. (iteration 5)

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
All 10 key questions are now answered. The next iteration should be **pure synthesis**: consolidate iterations 1-5 into the definitive version matrix and migration guide in research/research.md. No new research needed.

<!-- /ANCHOR:next-focus -->
<!-- ANCHOR:active-risks -->
## 8. ACTIVE RISKS
- None active beyond normal research uncertainty.

<!-- /ANCHOR:active-risks -->
<!-- ANCHOR:blocked-stops -->
## 9. BLOCKED STOPS
No blocked-stop events recorded.

<!-- /ANCHOR:blocked-stops -->
<!-- ANCHOR:graph-convergence -->
## 10. GRAPH CONVERGENCE
- graphConvergenceScore: 0.00
- graphDecision: [Not recorded]
- graphBlockers: none recorded

<!-- /ANCHOR:graph-convergence -->
