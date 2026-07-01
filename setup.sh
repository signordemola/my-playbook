#!/usr/bin/env bash
# my-playbook setup script
# Clones the playbook into .playbook/ and creates an AGENTS.md config file.
#
# Usage:
#   bash setup.sh /path/to/project             ← project setup
#   bash setup.sh /path/to/project --global    ← project setup + global rules
#   bash setup.sh --global                     ← update global rules only (no project setup)
#   bash setup.sh /path/to/project --force     ← regenerate project AGENTS.md

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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_URL="https://github.com/signordemola/my-playbook.git"

# ─── Global-only mode (no project dir) ────────────────────────────
if [ "$INSTALL_GLOBAL" = true ] && [ -z "$PROJECT_DIR" ]; then
  echo "🌍 Updating global rules for all AI tools..."

  GLOBAL_RULES_FILE="$SCRIPT_DIR/rules/global-rules.md"
  if [ ! -f "$GLOBAL_RULES_FILE" ]; then
    echo "   ❌ Error: $GLOBAL_RULES_FILE not found"
    exit 1
  fi

  mkdir -p "$HOME/.claude"
  cp "$GLOBAL_RULES_FILE" "$HOME/.claude/CLAUDE.md"
  echo "   ✅ Claude Code  → ~/.claude/CLAUDE.md"

  mkdir -p "$HOME/.gemini"
  cp "$GLOBAL_RULES_FILE" "$HOME/.gemini/GEMINI.md"
  echo "   ✅ Gemini CLI   → ~/.gemini/GEMINI.md"

  mkdir -p "$HOME/.codex"
  cp "$GLOBAL_RULES_FILE" "$HOME/.codex/AGENTS.md"
  echo "   ✅ OpenAI Codex → ~/.codex/AGENTS.md"

  echo ""
  echo "   ⚠️  Cursor: paste rules/cursor-rules.md into Settings → Rules for AI"
  echo ""
  echo "✅ Global rules updated."
  exit 0
fi

# ─── Project setup mode ───────────────────────────────────────────
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
PLAYBOOK_DIR="$PROJECT_DIR/.playbook"

echo "🔧 Setting up my-playbook in $PROJECT_DIR"

# Clone or update
if [ -d "$PLAYBOOK_DIR" ]; then
  echo "📦 Playbook already exists. Pulling latest..."
  git -C "$PLAYBOOK_DIR" pull --quiet
else
  echo "📥 Cloning playbook..."
  git clone --quiet "$REPO_URL" "$PLAYBOOK_DIR"
fi

# Add .playbook to .gitignore
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

# ─── Copy workflows to all AI tool paths ──────────────────────────
WORKFLOWS_SRC="$PLAYBOOK_DIR/workflows"

if [ -d "$WORKFLOWS_SRC" ]; then
  # Antigravity: .agents/workflows/
  mkdir -p "$PROJECT_DIR/.agents/workflows"
  cp -u "$WORKFLOWS_SRC"/*.md "$PROJECT_DIR/.agents/workflows/" 2>/dev/null
  echo "📂 Antigravity  → .agents/workflows/"

  # Claude Code: .claude/commands/
  mkdir -p "$PROJECT_DIR/.claude/commands"
  cp -u "$WORKFLOWS_SRC"/*.md "$PROJECT_DIR/.claude/commands/" 2>/dev/null
  echo "📂 Claude Code  → .claude/commands/"

  # Cursor: .cursor/rules/ (convert .md to .mdc with alwaysApply: false)
  mkdir -p "$PROJECT_DIR/.cursor/rules"
  for f in "$WORKFLOWS_SRC"/*.md; do
    basename=$(basename "$f" .md)
    target="$PROJECT_DIR/.cursor/rules/$basename.mdc"
    if [ ! -f "$target" ] || [ "$f" -nt "$target" ]; then
      desc=$(grep "^description:" "$f" | head -1 | sed 's/description: *//')
      {
        echo "---"
        echo "description: \"$desc\""
        echo "alwaysApply: false"
        echo "---"
        echo ""
        sed '1,/^---$/{ /^---$/,/^---$/d }' "$f"
      } > "$target"
    fi
  done
  echo "📂 Cursor       → .cursor/rules/ (.mdc)"
fi

# Create AGENTS.md
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

# Global rules (if --global passed with a project dir)
if [ "$INSTALL_GLOBAL" = true ]; then
  echo ""
  echo "🌍 Installing global rules for all AI tools..."

  GLOBAL_RULES_FILE="$PLAYBOOK_DIR/rules/global-rules.md"
  if [ ! -f "$GLOBAL_RULES_FILE" ]; then
    echo "   ❌ Error: $GLOBAL_RULES_FILE not found"
    exit 1
  fi

  mkdir -p "$HOME/.claude"
  cp "$GLOBAL_RULES_FILE" "$HOME/.claude/CLAUDE.md"
  echo "   ✅ Claude Code  → ~/.claude/CLAUDE.md"

  mkdir -p "$HOME/.gemini"
  cp "$GLOBAL_RULES_FILE" "$HOME/.gemini/GEMINI.md"
  echo "   ✅ Gemini CLI   → ~/.gemini/GEMINI.md"

  mkdir -p "$HOME/.codex"
  cp "$GLOBAL_RULES_FILE" "$HOME/.codex/AGENTS.md"
  echo "   ✅ OpenAI Codex → ~/.codex/AGENTS.md"

  echo ""
  echo "   ⚠️  Cursor: paste rules/cursor-rules.md into Settings → Rules for AI"
fi

# Done
echo ""
echo "✅ Done! Your playbook is set up."
echo ""
echo "   To update: cd .playbook && git pull"
echo "   To update global rules: bash setup.sh --global"
echo ""
