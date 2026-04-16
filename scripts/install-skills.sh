#!/usr/bin/env bash
set -euo pipefail

# Install third-party skills from skills-lock.json sources
# Run after clone: bash scripts/install-skills.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "=== Installing third-party skills ==="

# 1. Install impeccable.style (17 design quality skills)
echo ""
echo "[1/2] Installing impeccable.style..."
npx skills add pbakaus/impeccable -y 2>&1 | tail -5

# 2. Install Google Stitch skills (8 visual prototyping skills)
echo ""
echo "[2/2] Installing Google Stitch skills..."
npx skills add google-labs-code/stitch-skills -y 2>&1 | tail -5

# 3. Cleanup junk directories (installer creates these for agents we don't use)
echo ""
echo "Cleaning up unused agent directories..."
rm -rf .junie .windsurf 2>/dev/null || true

# 4. Apply project customizations (design system refs in framework skills)
echo ""
echo "Applying project customizations..."
cp scripts/skill-patches/sk-code-full-stack-project-design-system.md \
   .opencode/skill/sk-code-full-stack/references/frontend/react/project-design-system.md
cp scripts/skill-patches/sk-code-web-project-design-system.md \
   .opencode/skill/sk-code-web/references/standards/project-design-system.md

# 5. Verify
echo ""
echo "=== Verification ==="
AGENT_COUNT=$(ls .agents/skills/ 2>/dev/null | wc -l)
TOTAL_COUNT=$(ls .opencode/skill/ 2>/dev/null | wc -l)
echo "  .agents/skills/: $AGENT_COUNT third-party skills"
echo "  .opencode/skill/: $TOTAL_COUNT total skills (framework + symlinks)"
echo "  Customizations: applied"

# Check for broken symlinks
BROKEN=0
for skill in .opencode/skill/*/; do
  if [ -L "$skill" ] && [ ! -d "$skill" ]; then
    echo "  BROKEN SYMLINK: $skill"
    BROKEN=$((BROKEN + 1))
  fi
done
if [ "$BROKEN" -eq 0 ]; then
  echo "  Symlinks: all valid"
fi

echo ""
echo "Done! Third-party skills installed and ready."
