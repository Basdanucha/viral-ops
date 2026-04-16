# Iteration 1: LLM Script Generation Strategies & Thai Viral Script Structures

## Focus
Investigated Q1 (best LLM prompting strategies for generating viral video scripts) and Q2 (Thai short-form viral content script structures). These are foundational questions that inform all subsequent L3 Content Lab research -- script generation architecture, variant production, quality gating, and platform adaptation all depend on understanding the right prompting patterns and Thai-specific content structures.

## Findings

### Q1: LLM Prompting Strategies for Viral Script Generation

#### 1. Multi-Stage Prompt Chain Architecture (NOT single-prompt generation)
Script generation should be decomposed into a chain of specialized prompts rather than one monolithic generation call. Each stage has a narrow objective, improving output quality and allowing per-stage quality gates.

**Recommended chain:**
1. **Concept Expansion** -- Take trend signal + niche + hook from L2, expand into 3-5 concept angles
2. **Script Drafting** -- Take winning concept, generate full script with timing markers
3. **Variant Generation** -- Take base script, produce 2-3 hook/CTA variations
4. **Quality Self-Evaluation** -- LLM scores its own output against rubric (pre-filter before L2 scoring)
5. **TTS Adaptation** -- Reformat script for voice pipeline with pronunciation hints and pacing markers

This aligns with Anthropic's documented "prompt chaining" best practice: break complex tasks into subtasks, where each LLM call handles one focused step. The output of one step feeds as input to the next. This reduces error rates vs. a single complex prompt.
[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices]

#### 2. Structured Output via XML Tags + JSON Schema
For script generation, using XML tags to separate instruction sections (context, examples, constraints, output format) dramatically reduces misinterpretation. The Anthropic docs explicitly recommend wrapping each content type in its own tag: `<instructions>`, `<context>`, `<examples>`, `<input>`.

For the actual script output, enforce JSON structured output with a defined schema:
```json
{
  "hook": "string (max 15 words)",
  "hook_type": "enum: question|statistic|controversy|curiosity|emotion|pattern_interrupt|authority",
  "body_segments": [
    {"timestamp": "0:00-0:03", "text": "...", "visual_cue": "...", "tone": "..."}
  ],
  "cta": "string",
  "cta_type": "enum: follow|comment|share|save|link",
  "total_duration_seconds": "int",
  "platform_target": "enum: tiktok|youtube_shorts|ig_reels|all",
  "language": "enum: th|en|mixed",
  "tts_ready": "boolean"
}
```
[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices -- XML tags section, structured output section]

#### 3. Few-Shot Calibration with Top-Performing Scripts
The Anthropic docs recommend 3-5 examples for best results, wrapped in `<example>` tags. For viral-ops, this means:
- Curate a "gold standard" library of 10-20 top-performing Thai viral scripts (actual published scripts with known view counts)
- Rotate 3-5 relevant examples per generation call, matched by niche and format
- Include both the script AND its performance metrics in examples to teach the model what success looks like
- Refresh examples monthly from L7 feedback data (top performers replace lowest performers)

CRITICAL: spec 005 found that LLM-as-judge performance DECLINES at 3+ examples. However, for GENERATION tasks (not evaluation), 3-5 examples improve output quality. These are different use cases -- scoring needs precision (fewer examples), generation needs variety (more examples).
[SOURCE: specs/005-trend-viral-brain/research/research.md -- LLM-as-Judge section, few-shot calibration finding]
[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices -- "Use examples effectively" section]

#### 4. Role-Based System Prompts with Thai Cultural Expertise
Setting a role in the system prompt focuses behavior and tone. For viral-ops script generation:
```
System: You are a Thai social media content strategist who has produced 
1,000+ viral short-form videos for the Thai market. You deeply understand 
Thai humor (สไตล์ขำๆ), cultural references, trending slang, and what 
makes Thai audiences stop scrolling. You specialize in {niche} content 
on {platform}.
```
The role should be dynamically adjusted per niche and platform. This is more effective than a generic "creative writer" role.
[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices -- "Give Claude a role" section]

#### 5. Model Selection: GPT-4o-mini Primary, DeepSeek Fallback for Thai-Heavy Content
Spec 005 already established this hierarchy. For L3 Content Lab, the recommendation carries forward with refinement:
- **GPT-4o-mini**: Primary for all script generation. Fast, cheap ($0.15/1M input), good structured output. Handles Thai adequately for mixed-language scripts.
- **DeepSeek-V3**: Fallback for pure-Thai scripts or when GPT-4o-mini produces poor Thai particle usage. Lower cost, strong multilingual. Needs benchmarking against GPT-4o-mini specifically for script quality.
- **Claude Sonnet/Haiku**: Alternative for the quality self-evaluation step (step 4 in chain). Using a different model family for self-evaluation reduces systematic bias.
- **Temperature**: Use temperature 0.7-0.9 for concept expansion and variant generation (creative diversity needed), 0.3-0.5 for structured script drafting (consistency needed), 0.0-0.1 for quality evaluation (precision needed).
[SOURCE: specs/005-trend-viral-brain/research/research.md -- Model Selection section]
[INFERENCE: Temperature recommendations derived from standard creative vs. analytical task patterns across LLM documentation]

#### 6. Context Injection Pattern: Trend Data as Structured Input Block
L1 trend data and L2 viral scores should be injected into prompts using a structured XML block:
```xml
<trend_context>
  <trend_name>ลองของใหม่</trend_name>
  <platform>tiktok</platform>
  <velocity>SURGING (+0.72)</velocity>
  <lifecycle>growth</lifecycle>
  <freshness_score>0.85</freshness_score>
  <viral_score>0.78</viral_score>
  <top_hooks>
    <hook type="curiosity" score="4.5">ทำไมทุกคนถึงลอง...</hook>
    <hook type="question" score="4.2">เคยลองยัง?</hook>
  </top_hooks>
  <niche>lifestyle</niche>
  <thai_peak_hours>19:00-22:00 ICT</thai_peak_hours>
</trend_context>
```
This gives the model precise context without burying it in prose. The Anthropic docs confirm that structured XML context at the top of the prompt improves performance by up to 30%.
[SOURCE: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices -- "Long context prompting" section]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- Composite Viral Potential Score, Hook Variant Generation sections]

### Q2: Thai Short-Form Viral Content Script Structures

#### 7. Thai Viral Script Anatomy: 4-Beat Structure
Based on synthesis of Thai content patterns from spec 005 research and general short-form video structure:

**15-second script (TikTok primary):**
| Beat | Time | Purpose | Thai Pattern |
|------|------|---------|-------------|
| Hook | 0:00-0:03 | Stop the scroll | Question/shock + particle (นะ/เลย) |
| Setup | 0:03-0:07 | Context + tension | Problem statement or relatable situation |
| Payoff | 0:07-0:12 | Value delivery | Solution, reveal, or punchline |
| CTA | 0:12-0:15 | Action prompt | จัดไป / กดติดตาม / คอมเมนต์บอกหน่อย |

**30-second script:**
| Beat | Time | Purpose | Thai Pattern |
|------|------|---------|-------------|
| Hook | 0:00-0:03 | Stop the scroll | Strong hook, max 15 words |
| Setup | 0:03-0:10 | Context + stakes | Build tension, introduce problem |
| Development | 0:10-0:20 | Story progression | Steps, reveal, or transformation |
| Payoff | 0:20-0:27 | Resolution | Solution, twist, or result |
| CTA | 0:27-0:30 | Action prompt | Specific engagement request |

**60-second script:**
| Beat | Time | Purpose | Thai Pattern |
|------|------|---------|-------------|
| Hook | 0:00-0:03 | Stop the scroll | Strongest possible hook |
| Context | 0:03-0:10 | Background | Why this matters now |
| Body Part 1 | 0:10-0:25 | First main point | Story/tutorial/reveal |
| Body Part 2 | 0:25-0:40 | Second main point | Deepening or contrast |
| Climax | 0:40-0:52 | Peak moment | Transformation, result, twist |
| CTA | 0:52-0:60 | Action prompt | Multi-CTA (follow + comment + share) |

[INFERENCE: Timing structures derived from standard short-form video production principles applied to Thai content specs from spec 004 (TikTok 3-60s, YouTube Shorts 15-60s, IG Reels 3-90s) and Thai viral content characteristics from spec 005]

#### 8. Thai-Specific Script Elements That Drive Virality
From spec 005 Thai content research, the following elements should be systematically incorporated into script generation prompts:

**Humor patterns (highest viral potential in Thai market):**
- Slapstick/situational comedy scripts
- Self-deprecating humor (มุขตัวเอง)
- Pranking/แกล้ง format
- Exaggerated reactions (โอ้โห / อ้าว / ตายแล้ว)

**Language techniques:**
- Thai-English code-switching: "ทำไม [English trend term] ถึงได้ viral ขนาดนี้" -- triggers curiosity in bilingual Thai audiences
- Emphatic particles at hook endings: นะ (softened assertion), เลย (emphasis), จริงๆ (really/seriously), มากๆ (intensifier)
- Direct address: คุณ or เธอ for personal connection
- Numeric patterns: "3 สิ่งที่..." / "5 เหตุผลที่..." (numbers work universally, Thai audiences respond strongly)

**Emotional triggers (ranked by Thai viral potential):**
1. ฮา (humor) -- strongest, fastest spread
2. สงสาร (sympathy) -- strong sharing behavior
3. ดราม่า (drama) -- high engagement, comment-heavy
4. ตกใจ (shock/surprise) -- stop-scroll power
5. FOMO / กลัวตกเทรนด์ -- drives immediate action

**Thai internet slang integration (for hook generation):**
Must be current -- slang ages fast. The generation prompt should include a dynamically-updated slang dictionary drawn from L1 trend data. Key entries from spec 005: 555 (laughter), ปัง (amazing), แซ่บ (fierce), จัดไป (let's go), คือดีมาก (it's so good).

[SOURCE: specs/005-trend-viral-brain/research/research.md -- Thai Viral Content Characteristics, Thai Hook Patterns, Thai Internet Slang sections]

#### 9. Platform-Specific Script Adaptations (Preliminary)
Scripts need adaptation per platform, not just duration changes:

| Element | TikTok | YouTube Shorts | IG Reels |
|---------|--------|---------------|----------|
| Optimal hook | Pattern interrupt, visual | Question, informational | Aesthetic, aspirational |
| Duration sweet spot | 15-30s | 30-60s | 15-30s |
| CTA style | Follow + duet challenge | Subscribe + comment | Save + share to Stories |
| Aspect ratio | 9:16 (mandatory) | 9:16 (mandatory) | 9:16 (recommended) |
| Text overlay | Yes, 2-3 lines max | Optional, captions preferred | Yes, aesthetic styling |
| Audio dependency | High (trending sounds) | Medium (voice-first) | Medium (music + voice) |

[SOURCE: specs/004-platform-upload/research/research.md -- Content specs per platform (referenced in strategy known context)]
[INFERENCE: Platform-specific CTA and content style patterns derived from general short-form video production knowledge applied to viral-ops platform specs]

## Ruled Out
- **Single-prompt script generation**: Multi-stage chain is clearly superior for quality and variant control. A single prompt trying to generate hooks, body, visual cues, and TTS markers simultaneously produces inconsistent results.
- **Generic creative writing role prompts**: Thai market requires Thai-specific cultural expertise baked into the system prompt. Generic "creative writer" underperforms vs. Thai-specific role.

## Dead Ends
None identified in this iteration (first iteration, all approaches were productive).

## Sources Consulted
- https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices (Anthropic prompting best practices -- comprehensive reference on XML tags, few-shot, roles, structured output, prompt chaining)
- specs/005-trend-viral-brain/research/research.md (Prior L1+L2 research -- hook categories, LLM-as-judge rubric, Thai content patterns, model selection, n8n orchestration)
- specs/006-content-lab/research/deep-research-strategy.md (Known context from specs 001, 003, 004, 005)

## Assessment
- New information ratio: 0.78
- Questions addressed: Q1, Q2, Q7 (partially -- platform adaptation)
- Questions answered: None fully -- Q1 and Q2 are substantially addressed but need validation against real Thai creator workflows and deeper model benchmarking

## Reflection
- What worked and why: Starting from the rich spec 005 research base was highly productive. The prior L1+L2 research already documented hook categories, Thai slang, viral content characteristics, and LLM-as-judge patterns. This allowed iteration 1 to synthesize and extend rather than start from scratch. The Anthropic prompting docs provided authoritative backing for the multi-stage chain, XML structuring, and few-shot calibration recommendations.
- What did not work and why: OpenAI platform docs returned 403 (auth required for new docs site). YouTube video content extraction returned only footer/nav metadata (WebFetch cannot extract video transcripts). The creator economy article returned 404 (URL likely changed or was removed).
- What I would do differently: For next iteration, target specific implementable resources -- n8n workflow patterns for content generation, existing open-source script generation tools/repos, and Thai creator case studies via accessible blogs rather than paywalled or video-only sources.

## Recommended Next Focus
Q3 (A/B testing framework for video content variants) and Q4 (efficient multi-variant generation from single trend signal). These are the natural next step after establishing the script generation architecture (Q1) and Thai content structures (Q2). Understanding A/B testing informs how many variants to produce and how to measure their effectiveness, while Q4 addresses the practical mechanics of variant production at scale.
