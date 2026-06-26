#!/usr/bin/env bash
# my-playbook setup script
# Clones the playbook, symlinks rules, and creates AI agent config files.
#
# Usage:
#   bash setup.sh                    ← run from your project root
#   bash setup.sh /path/to/project   ← or specify a project path

set -euo pipefail

REPO_URL="https://github.com/signordemola/my-playbook.git"
PROJECT_DIR="${1:-$(pwd)}"
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

# ─── Helper: create symlink + add to .gitignore ──────────────────
create_symlink() {
  local target="$1"
  local link_name="$2"
  local link_path="$PROJECT_DIR/$link_name"

  if [ -L "$link_path" ]; then
    rm "$link_path"
  fi

  ln -sf "$target" "$link_path"
  echo "🔗 Symlinked $link_name → $target"

  if ! grep -q "^${link_name}$" "$GITIGNORE"; then
    echo "$link_name" >> "$GITIGNORE"
  fi
}

# ─── Symlink rule files ───────────────────────────────────────────
for rule_file in "$PLAYBOOK_DIR"/rules/*.md; do
  if [ -f "$rule_file" ]; then
    rule_name=$(basename "$rule_file")
    create_symlink ".playbook/rules/$rule_name" "$rule_name"
  fi
done

# ─── Create AGENTS.md (primary config) ────────────────────────────
AGENTS_FILE="$PROJECT_DIR/AGENTS.md"

if [ ! -f "$AGENTS_FILE" ]; then
  cat > "$AGENTS_FILE" << 'EOF'
# AI Agent Rules

Read and follow these rule files before writing any code:
- `code-style.md` — Coding style, Karpathy principles, Loop Engineering
- `project-structure.md` — Folder layout, naming conventions
- `mistakes.md` — Known AI mistakes to avoid

## Build & Test Commands

<!-- Fill these in for your project -->
- `npm run dev` — Start development server
- `npm run build` — Production build
- `npm run test` — Run tests
- `npm run lint` — Lint check

## Playbooks

For domain-specific patterns, read the relevant playbook:
- `.playbook/playbooks/core/INDEX.md` — Universal patterns
- `.playbook/playbooks/booking/INDEX.md` — Booking platforms
- `.playbook/playbooks/ecommerce/INDEX.md` — E-commerce
- `.playbook/playbooks/ui-ux/INDEX.md` — UI/UX design
- `.playbook/playbooks/dashboard/INDEX.md` — Admin dashboards
EOF
  echo "📝 Created AGENTS.md (primary config)"
else
  echo "⏭️  AGENTS.md already exists — skipping"
fi

# ─── Symlink CLAUDE.md and GEMINI.md → AGENTS.md ─────────────────
create_symlink "AGENTS.md" "CLAUDE.md"
create_symlink "AGENTS.md" "GEMINI.md"

# ─── Done ─────────────────────────────────────────────────────────
echo ""
echo "✅ Done! Your playbook is set up."
echo ""
echo "   Primary config: AGENTS.md"
echo "   Symlinks:       CLAUDE.md → AGENTS.md, GEMINI.md → AGENTS.md"
echo "   Rules:          Symlinked from .playbook/rules/"
echo "   Playbooks:      .playbook/playbooks/"
echo ""
echo "   To update: cd .playbook && git pull"
echo ""
