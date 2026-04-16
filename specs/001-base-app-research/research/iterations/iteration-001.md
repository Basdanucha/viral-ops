# Iteration 1: Stack Component Version Survey (Gen 2)

## Focus
Survey the current state of all gen1 stack components to establish baselines for version updates. Priority on confirming next-saas-stripe-starter status and identifying current stable versions for all major components (Next.js, Prisma, n8n, Tailwind CSS, Node.js, Tremor).

## Findings

### 1. next-saas-stripe-starter: NOT dead -- but stale
Contrary to user's assumption, the GitHub repo (mickasmt/next-saas-stripe-starter) is NOT archived. It has 3,000 stars, 608 forks, and a v1.0.0 release from June 26, 2024. However, the last release is nearly 2 years old, and it still uses Next.js 14 + Prisma 5.x. There are 16 open issues and 6 PRs. The project is effectively **stagnant** -- not dead, but far behind current versions. It would require significant migration effort to bring to Next.js 16 + Prisma 7.
[SOURCE: https://github.com/mickasmt/next-saas-stripe-starter]

### 2. Next.js 16.2 is latest stable (released March 18, 2026)
- Next.js 16.0 released October 21, 2025
- Next.js 16.2 released March 18, 2026 (current stable)
- Key improvements: ~400% faster dev startup, ~50% faster rendering, agent-ready scaffolding, Turbopack server fast refresh, browser log forwarding
- Breaking changes from 14: async params, image defaults, caching semantics updates
- The jump from 14 to 16 is significant -- two major versions with accumulated breaking changes
[SOURCE: https://nextjs.org/blog]

### 3. Prisma 7.4 is latest stable (released February 19, 2026)
- Prisma 7.x series is fully released and stable
- Prisma 7.4: query caching, partial indexes, BigInt precision fixes
- Prisma 7.3: compiler build options, query performance improvements
- Prisma 7.2: restored --url flag, CLI improvements
- "Major architectural changes" in v7 (referenced in AMA) -- specific breaking changes need deeper investigation in next iteration
- Migration path from 5.x to 7.x spans two major versions (5 -> 6 -> 7)
[SOURCE: https://www.prisma.io/blog]

### 4. n8n 2.x is released (up to 2.16.0)
- n8n 2.x is fully released with versions through 2.16.0
- Dedicated "v2.0 breaking changes" documentation exists
- Sustainable Use License still listed in licensing section
- New features: visual diff for version history, external secrets management, folder-based filtering, custom roles with granular permissions, AI Agent functionality
- Specific breaking changes from 1.x to 2.x need deeper investigation
[SOURCE: https://docs.n8n.io/release-notes/]

### 5. Tailwind CSS v4.1 is latest stable (April 3, 2025)
- Tailwind CSS v4.0 released January 22, 2025
- v4.1 released April 3, 2025
- Major rewrite: new "Oxide" engine, reimagined configuration/customization
- v4.1 adds: text shadow utilities, mask utilities
- Breaking changes from v3 to v4 are significant -- configuration system completely redesigned
- Migration path from v3 needs deeper investigation
[SOURCE: https://tailwindcss.com/blog]

### 6. Tremor: Status unclear -- needs deeper investigation
- Tremor repo (tremorlabs/tremor) has 3.4k stars, 148 forks
- Only 84 commits on main branch -- relatively low activity
- Could not determine: latest version, last commit date, Tailwind v4 compatibility, deprecation status
- Built on Tailwind CSS + Radix UI
- Risk: if Tremor doesn't support Tailwind v4, it becomes a blocker for the Tailwind upgrade
[SOURCE: https://github.com/tremorlabs/tremor]

### 7. Node.js 24 LTS is current (v24.15.0)
- Node.js 24 is the current LTS at v24.15.0
- Node.js 25.9.0 is the latest current (non-LTS) release
- Gen1 used Node.js 18+ which is likely approaching or past EOL
- Should target Node.js 24 LTS for viral-ops
[SOURCE: https://nodejs.org/en]

## Ruled Out
- Checking individual component changelogs in detail (deferred to focused iterations per component)
- Checking Auth.js, ShadCN UI, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video versions (not enough tool budget this iteration -- deferred)

## Dead Ends
- None identified this iteration (first survey pass)

## Sources Consulted
- https://github.com/mickasmt/next-saas-stripe-starter
- https://nextjs.org/blog
- https://www.prisma.io/blog
- https://docs.n8n.io/release-notes/
- https://tailwindcss.com/blog
- https://github.com/tremorlabs/tremor
- https://nodejs.org/en

## Assessment
- New information ratio: 0.86
- Questions addressed: Q1 (partial), Q2, Q3 (partial), Q4 (partial), Q6 (partial), Q8 (partial)
- Questions answered: None fully answered yet -- all need deeper investigation on breaking changes and migration paths

## Reflection
- What worked and why: Fetching official project homepages and blogs gave reliable version numbers and feature summaries quickly. Prioritizing the 6 most critical components in parallel was efficient.
- What did not work and why: Tremor's GitHub page did not surface enough detail about maintenance status or version info from the rendered page. GitHub pages sometimes omit critical metadata in the fetched content.
- What I would do differently: For Tremor, check npm registry or the releases page directly. Also allocate a dedicated iteration for the remaining unchecked components (Auth.js, ShadCN, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video).

## Recommended Next Focus
1. **Boilerplate replacement candidates (Q1)**: Now that we know next-saas-stripe-starter is stale but not dead, research actual replacement options: next-forge, create-t3-app, taxonomy, Makerkit, SaaS-Starter-Kit. Evaluate each for Next.js 16 + Prisma 7 + App Router compatibility.
2. **Tremor deep dive (Q6)**: Determine if Tremor is still maintained and Tailwind v4 compatible. If not, identify replacement charting libraries.
3. **Remaining component versions (Q5, Q7, Q8, Q9)**: Auth.js, ShadCN UI, TypeScript, PostgreSQL, ComfyUI, Edge-TTS, Pixelle-Video.
