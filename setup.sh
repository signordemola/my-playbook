#!/usr/bin/env bash
# my-playbook setup script
# Clones the playbook into .playbook/ and creates an AGENTS.md config file.
#
# Usage:
#   bash setup.sh                    ← project setup only
#   bash setup.sh --global           ← also install/update global rules for all AI tools
#   bash setup.sh --force            ← regenerate project AGENTS.md even if it exists
#   bash setup.sh --global --force   ← both
#   bash setup.sh /path/to/project   ← specify a project path

set -euo pipefail

# ─── Parse args ────────────────────────────────────────────────────
INSTALL_GLOBAL=false
FORCE=false
PROJECT_DIR=""

for arg in "$@"; do
  case "$arg" in
    --global) INSTALL_GLOBAL=true ;;
    --force) FORCE=true ;;
    *) PROJECT_DIR="$arg" ;;
  esac
done

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
REPO_URL="https://github.com/signordemola/my-playbook.git"
PLAYBOOK_DIR="$PROJECT_DIR/.playbook"

echo "🔧 Setting up my-playbook in $PROJECT_DIR"

# ─── Clone or update ───────────────────────────────────────────────
if [ -d "$PLAYBOOK_DIR" ]; then
  echo "📦 Playbook already exists. Pulling latest..."
  git -C "$PLAYBOOK_DIR" pull --quiet
else
  echo "📥 Cloning playbook..."
  git clone --quiet "$REPO_URL" "$PLAYBOOK_DIR"
fi

# ─── Add .playbook to .gitignore ──────────────────────────────────
GITIGNORE="$PROJECT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "^\.playbook" "$GITIGNORE"; then
    echo ".playbook/" >> "$GITIGNORE"
    echo "📋 Added .playbook/ to .gitignore"
  fi
else
  echo ".playbook/" > "$GITIGNORE"
  echo "📋 Created .gitignore with .playbook/"
fi

# ─── Copy workflows ───────────────────────────────────────────────
WORKFLOWS_SRC="$PLAYBOOK_DIR/workflows"
WORKFLOWS_DST="$PROJECT_DIR/.agents/workflows"

if [ -d "$WORKFLOWS_SRC" ]; then
  mkdir -p "$WORKFLOWS_DST"
  cp -u "$WORKFLOWS_SRC"/*.md "$WORKFLOWS_DST/" 2>/dev/null
  echo "📂 Copied workflows to .agents/workflows/"
fi

# ─── Create AGENTS.md ─────────────────────────────────────────────
AGENTS_FILE="$PROJECT_DIR/AGENTS.md"

if [ ! -f "$AGENTS_FILE" ] || [ "$FORCE" = true ]; then
  cat > "$AGENTS_FILE" << 'EOF'
# MANDATORY: Read these before ANY action

1. **Read `.playbook/rules/`** — code-style.md, project-structure.md, mistakes.md. Follow every rule strictly.
2. **Read `node_modules/next/dist/docs/`** — Local docs are the source of truth for the stack.
3. **Read `.playbook/playbooks/*/INDEX.md`** for the relevant domain (e.g., `booking`, `core`).
4. **Check `.playbook/recommended-skills.md`** — Install any relevant package skills for this project.

NEVER guess on architecture or naming. Consult the Playbook first.
EOF
  if [ "$FORCE" = true ]; then
    echo "📝 Regenerated AGENTS.md (--force)"
  else
    echo "📝 Created AGENTS.md"
  fi
else
  echo "⏭️  AGENTS.md already exists (use --force to regenerate)"
fi

# ─── Global rules (--global flag) ─────────────────────────────────
if [ "$INSTALL_GLOBAL" = true ]; then
  echo ""
  echo "🌍 Installing global rules for all AI tools..."

  GLOBAL_RULES_FILE="$PLAYBOOK_DIR/rules/global-rules.md"
  if [ ! -f "$GLOBAL_RULES_FILE" ]; then
    echo "   ❌ Error: $GLOBAL_RULES_FILE not found"
    exit 1
  fi

  # Claude Code: ~/.claude/CLAUDE.md
  mkdir -p "$HOME/.claude"
  cp "$GLOBAL_RULES_FILE" "$HOME/.claude/CLAUDE.md"
  echo "   ✅ Claude Code  → ~/.claude/CLAUDE.md"

  # Gemini CLI: ~/.gemini/GEMINI.md
  mkdir -p "$HOME/.gemini"
  cp "$GLOBAL_RULES_FILE" "$HOME/.gemini/GEMINI.md"
  echo "   ✅ Gemini CLI   → ~/.gemini/GEMINI.md"

  # OpenAI Codex: ~/.codex/AGENTS.md
  mkdir -p "$HOME/.codex"
  cp "$GLOBAL_RULES_FILE" "$HOME/.codex/AGENTS.md"
  echo "   ✅ OpenAI Codex → ~/.codex/AGENTS.md"

  # Cursor: no file-based global config
  echo ""
  echo "   ⚠️  Cursor has no file-based global config."
  echo "   To add global rules in Cursor:"
  echo "     1. Open Cursor Settings (Cmd/Ctrl + ,)"
  echo "     2. Go to General → Rules for AI"
  echo "     3. Paste the contents of .playbook/rules/cursor-rules.md"
fi

# ─── Done ─────────────────────────────────────────────────────────
echo ""
echo "✅ Done! Your playbook is set up."
echo ""
echo "   AGENTS.md:   Points to .playbook/rules/ and playbooks/"
echo "   Playbooks:   .playbook/playbooks/"
echo "   Rules:       .playbook/rules/"
echo ""
echo "   To update: cd .playbook && git pull"
echo "   To update global rules: bash setup.sh --global"
echo ""
echo "💡 Optional:"
echo "   shadcn/ui skill:  npx skills add shadcn/ui"
echo "   See all:          .playbook/recommended-skills.md"
echo ""
