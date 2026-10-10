#!/bin/bash
# M.A.R.A Setup Script — Automated setup untuk PC Toko #2 & PC Rumah
# Usage: bash setup-mara.sh <github_username> <pc_name>
# Example: bash setup-mara.sh AAN PC2-TOKO

set -e

if [ $# -lt 1 ]; then
  echo "Usage: bash setup-mara.sh <pc_name>"
  echo "Example: bash setup-mara.sh PC2-TOKO"
  exit 1
fi

PC_NAME=$1
WINDOWS_USER=$(whoami | cut -d'\\' -f2)
PROJECTS_DIR="C:/Users/$WINDOWS_USER/Projects"
HERMES_DIR="C:/Users/$WINDOWS_USER/AppData/Local/hermes"
MARA_DIR="$PROJECTS_DIR/M.A.R.A"

echo "======================================"
echo "M.A.R.A Setup untuk: $PC_NAME"
echo "User: $WINDOWS_USER"
echo "Projects: $PROJECTS_DIR"
echo "Hermes: $HERMES_DIR"
echo "======================================"

# 1. Clone M.A.R.A
if [ ! -d "$MARA_DIR" ]; then
  echo "[1/6] Cloning M.A.R.A repository..."
  mkdir -p "$PROJECTS_DIR"
  cd "$PROJECTS_DIR"
  gh repo clone tikusgot007/M.A.R.A
  echo "✓ M.A.R.A cloned"
else
  echo "[1/6] M.A.R.A already exists, pulling latest..."
  cd "$MARA_DIR"
  git pull origin master
  echo "✓ M.A.R.A updated"
fi

# 2. Backup lokal config
echo "[2/6] Backing up local Hermes config..."
mkdir -p "$MARA_DIR/.backup-$PC_NAME"
[ -f "$HERMES_DIR/.env" ] && cp "$HERMES_DIR/.env" "$MARA_DIR/.backup-$PC_NAME/.env" && echo "  ✓ .env backed up"
[ -f "$HERMES_DIR/auth.json" ] && cp "$HERMES_DIR/auth.json" "$MARA_DIR/.backup-$PC_NAME/auth.json" && echo "  ✓ auth.json backed up"
[ -f "$HERMES_DIR/config.yaml" ] && cp "$HERMES_DIR/config.yaml" "$MARA_DIR/.backup-$PC_NAME/config.yaml.bak" && echo "  ✓ config.yaml backed up"

# 3. Remove local skills & memories
echo "[3/6] Removing local skills/ & memories/ folders..."
rm -rf "$HERMES_DIR/skills" 2>/dev/null
rm -rf "$HERMES_DIR/memories" 2>/dev/null
echo "✓ Removed local folders"

# 4. Create symlinks
echo "[4/6] Creating symlinks..."
ln -s "$MARA_DIR/skills" "$HERMES_DIR/skills"
ln -s "$MARA_DIR/memories" "$HERMES_DIR/memories"
echo "✓ Symlinks created"

# 5. Verify symlinks
echo "[5/6] Verifying symlinks..."
if [ -L "$HERMES_DIR/skills" ] && [ -L "$HERMES_DIR/memories" ]; then
  echo "✓ Symlinks verified"
else
  echo "✗ Symlinks failed!"
  exit 1
fi

# 6. Git config (optional)
echo "[6/6] Configuring git..."
cd "$MARA_DIR"
git config user.name "$PC_NAME" 2>/dev/null || true
git config user.email "hermes@aulia.local" 2>/dev/null || true
echo "✓ Git configured for $PC_NAME"

echo ""
echo "======================================"
echo "Setup selesai! ✓"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Restart Hermes Desktop"
echo "2. Verify Skills load dari M.A.R.A"
echo "3. Test: cd $MARA_DIR && git pull origin master"
echo ""
echo "Backup lokal: $MARA_DIR/.backup-$PC_NAME/"
echo ""
