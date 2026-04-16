# Spec: Content Lab (L3)

## Requirements
<!-- DR-SEED:REQUIREMENTS -->
Deep dive research into the Content Lab (L3) layer for viral-ops — covering LLM-based script generation for viral short-form video, A/B testing of content variants, script-to-production handoff format, Thai-specific content patterns, platform-specific adaptation (TikTok/YouTube/IG/FB), feedback loop integration from L7, and content calendar orchestration via n8n.

## Scope
<!-- DR-SEED:SCOPE -->
- LLM prompting strategies for viral video script generation (model selection, structured prompting, few-shot)
- Thai viral content script structures and cultural patterns
- A/B testing framework for content variants (pre-production and post-production)
- Multi-variant generation from single trend signals
- L1 trend + L2 viral score integration into script generation prompts
- Script-to-production handoff format (shot lists, TTS directives, timing markers)
- Platform-specific content adaptation (TikTok, YouTube Shorts, IG Reels, FB)
- Thai TTS integration (spec 003) for automated voice-over scripts
- Script quality pre-scoring and automated quality gates
- L7 performance feedback → script generation improvement loop
- n8n workflow design for content generation cadence and batch scheduling
- Multi-format output support (talking head, voiceover+B-roll, text overlay, green screen)

## Open Questions
All 12 questions answered across 7 autonomous iterations.

## Research Context
Deep research **complete**. Canonical findings in `research/research.md` (790+ lines).

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Research Findings Summary (7 iterations, 12 questions)

### L3 Script Generation Architecture
| Component | Design | Detail |
|-----------|--------|--------|
| Prompt chain | 5-stage pipeline | Concept expansion → hook gen → script body → visual/TTS → quality check |
| Structuring | XML tags + JSON schema | `<trend_context>`, `<instructions>`, `<examples>`, `<output_format>` |
| Model | GPT-4o-mini primary | DeepSeek fallback for Thai, Claude Haiku for quality evaluation |
| Few-shot | Dynamic from L7 data | Top 10% performers, 30-day window, 2 exemplars/generation |
| Variant expansion | 3x3 matrix | 3 concept angles x 3 hook types = 9 candidates → prune to 3-4 |
| Cost | ~$0.17/trend | $0.13 generation + $0.036 adaptation for 4 platforms |

### Thai Content Patterns
- **4-beat structure**: Hook → Problem → Solution → CTA (scaled to 15/30/60s)
- **Emotional triggers**: ฮา (humor) > สงสาร (sympathy) > ดราม่า (drama) > ตกใจ (shock) > FOMO
- **Language**: Emphatic particles (นะ/เลย/จริงๆ), code-switching, numeric anchoring
- **Dynamic slang**: Refreshed from L1 trend data (555, ปัง, แซ่บ, จัดไป, etc.)

### Quality & Testing
| Layer | Method | Threshold |
|-------|--------|-----------|
| Pre-production | Two-layer gate: structural self-eval + 6-dim LLM-as-Judge | Accept ≥4.0, Revise 3.0-3.9, Reject <3.0 |
| Post-production | Thompson Sampling multi-armed bandit | Platform benchmarks (TikTok 2.80% engagement) |
| A/B framework | NOT classical frequentist (too slow for 24-48h lifecycle) | Bayesian, 10-20 observations per arm |

### Production Handoff
- **Format**: AV two-column JSON with parallel audio+visual segments
- **TTS**: Engine-agnostic directives (L4 translates to ElevenLabs/OpenAI/Edge-TTS/CosyVoice)
- **L3/L4 boundary**: L4 owns PyThaiNLP preprocessing; L3 provides clean text + pronunciation overrides
- **Platform adaptation**: One base script → adapt per platform (~$0.003/adaptation)

### n8n Orchestration (5 Workflows)
| Workflow | Schedule | Purpose |
|----------|----------|---------|
| L3-Content-Generator | 30min cron | Master: poll trends → dispatch generation → queue output |
| L3-Script-Generator | Sub-workflow | 5-stage chain + quality gate + adaptation |
| L3-Content-Calendar | Daily 02:00 | Assign posting slots, P0-P3 priority queue |
| L3-Retry-Failures | Every 2h | Dead-letter queue recovery |
| L3-Feedback-Aggregator | Weekly | Process L7 data, update exemplars/weights |

Daily volume: 60-216 scripts/day at $0.51-$1.84/day LLM cost.

### Feedback Loop (L7 → L3)
- **4 channels**: Few-shot exemplars (per-gen) + Template selection (weekly) + Prompt tuning (monthly) + Variant strategy (bi-weekly)
- **Bootstrap**: Phase 0 (0-50 videos, static) → Phase 1 (50-200, semi-auto) → Phase 2 (200+, fully auto)
- **Anti-stagnation**: 20% epsilon-greedy exploration budget

### 6 Video Formats
| Format | Automation | Phase |
|--------|-----------|-------|
| text_overlay | 95% | MVP (Phase 0) |
| voiceover_broll | 85% | MVP (Phase 0) |
| green_screen | 70% | Phase 1 |
| tutorial_demo | 60% | Phase 1 |
| talking_head | 40% | Phase 2 |
| ugc_testimonial | 30% | Phase 2 |

### Ruled Out
- Single-prompt generation, generic role prompts, classical A/B testing, full factorial testing, L3-side PyThaiNLP, inline SSML for all engines, format as matrix dimension, monolithic n8n workflow
<!-- END GENERATED: deep-research/spec-findings -->
