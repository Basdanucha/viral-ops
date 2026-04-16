# Deep Research Strategy — Generation 2

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Update the viral-ops technology stack from gen1 decisions (April 2026) to current stable versions. The primary boilerplate (next-saas-stripe-starter) is dead and needs replacement. Major framework versions have changed: Next.js 16, Prisma 7, n8n 2.x.

### Usage
- **Gen 1 archive**: `research/archive/gen1-2026-04-16/research.md` (882 lines, 13 iterations)
- **This session**: Version audit + boilerplate replacement + best practices update

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
viral-ops framework version update — boilerplate replacement (next-saas-stripe-starter is dead), Next.js 16, Prisma 7, n8n 2.x compatibility, and pinning stable versions for all stack components with current best practices.

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
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

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- NOT re-evaluating the overall architecture (3-service localhost, n8n orchestrator, Pixelle-Video engine — these decisions stand)
- NOT re-researching intelligence layers (Trend, Viral Brain, Content Lab, Feedback Loop — gen1 decisions carry forward)
- NOT re-evaluating platform upload strategies (gen1 decisions carry forward)
- NOT re-designing the DB schema (only adjust if version changes require it)
- Only updating versions and replacing dead components

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- Replacement boilerplate identified with clear migration path
- All stack components have pinned stable versions
- Breaking changes documented with migration notes
- Architecture confirmed compatible with updated versions
- All 10 key questions answered

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Fetching official project homepages and blogs gave reliable version numbers and feature summaries quickly. Prioritizing the 6 most critical components in parallel was efficient. (iteration 1)
- Fetching GitHub repo pages directly gave rich metadata (stars, releases, commit count, tech stack) for boilerplate evaluation. Checking both the main tremor repo releases AND the tremor-raw repo gave a clear picture of project health. (iteration 2)
- Fetching raw GitHub file URLs for package.json gave exact version numbers immediately -- much more reliable than rendered GitHub pages. The shadcn/ui docs page was well-structured and gave comprehensive chart coverage info in one fetch. (iteration 3)
- Fetching the Next.js upgrade guide directly gave extremely comprehensive breaking change documentation in a single fetch -- the official docs are well-structured for LLM consumption. Better Auth's homepage and GitHub provided complementary data (features from homepage, metadata from GitHub). (iteration 4)
- Fetching official upgrade guides from Prisma docs gave extremely detailed, well-structured breaking change documentation -- two pages covered the entire 5->6->7 path. Using GitHub releases for n8n (after the docs URL was blocked) worked perfectly -- the release page had a clear summary. PyPI for Edge-TTS gave version + status in one fetch. (iteration 5)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- Tremor's GitHub page did not surface enough detail about maintenance status or version info from the rendered page. GitHub pages sometimes omit critical metadata in the fetched content. (iteration 1)
- npm registry direct fetch returned 403. Next time, use registry.npmjs.org API endpoint or `npm view` CLI command instead. (iteration 2)
- The root next-forge package.json did not contain framework deps (monorepo pattern) -- needed a second fetch for the web app's package.json. This cost an extra tool call. (iteration 3)
- n8n breaking changes URL returned 404, likely because their docs restructured since the URL was documented. Should try GitHub releases or alternative doc paths next iteration. (iteration 4)
- Nothing failed this iteration. All 5 web fetches returned usable data. (iteration 5)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### Auth.js v5 as auth solution (already BLOCKED from iteration 3 -- confirmed again: Better Auth is the successor) -- BLOCKED (iteration 4, 1 attempts)
- What was tried: Auth.js v5 as auth solution (already BLOCKED from iteration 3 -- confirmed again: Better Auth is the successor)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Auth.js v5 as auth solution (already BLOCKED from iteration 3 -- confirmed again: Better Auth is the successor)

### **Auth.js v5 as auth solution**: Auth.js has been absorbed into "Better Auth" project. The authjs.dev site confirms this. Auth.js v5 as a standalone maintained project is effectively deprecated. This eliminates Auth.js as a direct dependency choice -- must either adopt Better Auth, use Clerk (next-forge default), or evaluate alternatives. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Auth.js v5 as auth solution**: Auth.js has been absorbed into "Better Auth" project. The authjs.dev site confirms this. Auth.js v5 as a standalone maintained project is effectively deprecated. This eliminates Auth.js as a direct dependency choice -- must either adopt Better Auth, use Clerk (next-forge default), or evaluate alternatives.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Auth.js v5 as auth solution**: Auth.js has been absorbed into "Better Auth" project. The authjs.dev site confirms this. Auth.js v5 as a standalone maintained project is effectively deprecated. This eliminates Auth.js as a direct dependency choice -- must either adopt Better Auth, use Clerk (next-forge default), or evaluate alternatives.

### Checking Auth.js, ShadCN UI, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video versions (not enough tool budget this iteration -- deferred) -- BLOCKED (iteration 1, 1 attempts)
- What was tried: Checking Auth.js, ShadCN UI, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video versions (not enough tool budget this iteration -- deferred)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Checking Auth.js, ShadCN UI, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video versions (not enough tool budget this iteration -- deferred)

### Checking individual component changelogs in detail (deferred to focused iterations per component) -- BLOCKED (iteration 1, 1 attempts)
- What was tried: Checking individual component changelogs in detail (deferred to focused iterations per component)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Checking individual component changelogs in detail (deferred to focused iterations per component)

### Checking individual next-forge workspace packages (e.g., `@repo/auth`, `@repo/design-system`) for exact Clerk/Prisma versions -- deferred due to tool budget. The web app package.json confirmed the framework versions which was the priority. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: Checking individual next-forge workspace packages (e.g., `@repo/auth`, `@repo/design-system`) for exact Clerk/Prisma versions -- deferred due to tool budget. The web app package.json confirmed the framework versions which was the priority.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Checking individual next-forge workspace packages (e.g., `@repo/auth`, `@repo/design-system`) for exact Clerk/Prisma versions -- deferred due to tool budget. The web app package.json confirmed the framework versions which was the priority.

### Direct npm registry scraping (already BLOCKED from iteration 2) -- BLOCKED (iteration 3, 1 attempts)
- What was tried: Direct npm registry scraping (already BLOCKED from iteration 2)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Direct npm registry scraping (already BLOCKED from iteration 2)

### Direct Prisma 5->7 upgrade: Must go through 6 first (two-stage migration) -- BLOCKED (iteration 5, 1 attempts)
- What was tried: Direct Prisma 5->7 upgrade: Must go through 6 first (two-stage migration)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Direct Prisma 5->7 upgrade: Must go through 6 first (two-stage migration)

### **Makerkit, SaaS-Starter-Kit, SaaSBold, Shipfast**: Not investigated this iteration -- defer to iteration 3 if next-forge doesn't pan out -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Makerkit, SaaS-Starter-Kit, SaaSBold, Shipfast**: Not investigated this iteration -- defer to iteration 3 if next-forge doesn't pan out
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Makerkit, SaaS-Starter-Kit, SaaSBold, Shipfast**: Not investigated this iteration -- defer to iteration 3 if next-forge doesn't pan out

### n8n docs.n8n.io breaking changes URL: Already blocked from iteration 4; used GitHub releases instead (success) -- BLOCKED (iteration 5, 1 attempts)
- What was tried: n8n docs.n8n.io breaking changes URL: Already blocked from iteration 4; used GitHub releases instead (success)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: n8n docs.n8n.io breaking changes URL: Already blocked from iteration 4; used GitHub releases instead (success)

### n8n v2.0 breaking changes at `docs.n8n.io/release-notes/2-0-breaking-changes/` (404 -- URL restructured) -- BLOCKED (iteration 4, 1 attempts)
- What was tried: n8n v2.0 breaking changes at `docs.n8n.io/release-notes/2-0-breaking-changes/` (404 -- URL restructured)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: n8n v2.0 breaking changes at `docs.n8n.io/release-notes/2-0-breaking-changes/` (404 -- URL restructured)

### None identified this iteration (first survey pass) -- BLOCKED (iteration 1, 1 attempts)
- What was tried: None identified this iteration (first survey pass)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None identified this iteration (first survey pass)

### None new this iteration. All research avenues were productive. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: None new this iteration. All research avenues were productive.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None new this iteration. All research avenues were productive.

### None this iteration. The n8n URL 404 is a URL issue, not a fundamental dead end -- alternative URLs exist. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: None this iteration. The n8n URL 404 is a URL issue, not a fundamental dead end -- alternative URLs exist.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None this iteration. The n8n URL 404 is a URL issue, not a fundamental dead end -- alternative URLs exist.

### **npm direct scraping for Tremor**: Returns 403, need alternative approach (GitHub API or registry.npmjs.org API) -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **npm direct scraping for Tremor**: Returns 403, need alternative approach (GitHub API or registry.npmjs.org API)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **npm direct scraping for Tremor**: Returns 403, need alternative approach (GitHub API or registry.npmjs.org API)

### **taxonomy (shadcn/taxonomy)**: Not investigated this iteration due to tool budget -- defer to iteration 3 -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **taxonomy (shadcn/taxonomy)**: Not investigated this iteration due to tool budget -- defer to iteration 3
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **taxonomy (shadcn/taxonomy)**: Not investigated this iteration due to tool budget -- defer to iteration 3

### **tremor-raw as alternative to Tremor**: Confirmed dead. Only 2 commits, redirects to main tremor repo. Not a viable separate path. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **tremor-raw as alternative to Tremor**: Confirmed dead. Only 2 commits, redirects to main tremor repo. Not a viable separate path.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **tremor-raw as alternative to Tremor**: Confirmed dead. Only 2 commits, redirects to main tremor repo. Not a viable separate path.

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
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

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
All 10 key questions are now answered. The next iteration should be **pure synthesis**: consolidate iterations 1-5 into the definitive version matrix and migration guide in research/research.md. No new research needed.

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### Gen 1 Stack (from research/archive/gen1-2026-04-16/research.md)
| Component | Gen 1 Version | Gen 1 Decision |
|-----------|--------------|----------------|
| Dashboard boilerplate | next-saas-stripe-starter | **DEAD — needs replacement** |
| Next.js | 14.x | App Router |
| TypeScript | 5.x | Standard |
| Prisma | 5.x | ORM for PostgreSQL |
| PostgreSQL | 16.x | Primary DB |
| Auth.js (NextAuth) | v5 | Auth provider |
| ShadCN UI | latest | UI components |
| Tremor | 3.x | Charts/dashboard |
| Tailwind CSS | 3.x | Utility CSS |
| n8n | 1.x | Orchestrator :5678 |
| Pixelle-Video | 0.1.15+ | Video engine :8000 |
| ComfyUI | latest | Image generation |
| Edge-TTS | latest | Thai TTS (3 voices) |
| Node.js | 18+ | Runtime |

### Gen 1 Architecture (carries forward)
- 3-service localhost: Dashboard :3000 → n8n :5678 → Pixelle-Video :8000
- n8n = orchestrator + job queue
- Pixelle-Video FastAPI with 9 routers
- 14-table PostgreSQL schema
- Multi-channel identity via channels table

### User-reported changes
- next-saas-stripe-starter is dead
- Next.js 16 is available
- Prisma 7 is available
- n8n 2.x is available

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 10
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- Generation: 2 (restart from gen1)
- Parent session: dr-1776310994-5288
- Started: 2026-04-17T10:00:00Z
<!-- /ANCHOR:research-boundaries -->
