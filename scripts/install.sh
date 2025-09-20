#!/usr/bin/env bash
set -euo pipefail

echo "== HalfQ Overlay: install =="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Backup
mkdir -p "$HOME/.hammerspoon"
if [ -f "$HOME/.hammerspoon/init.lua" ]; then
  cp "$HOME/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua.bak.$(date +%Y%m%d-%H%M%S)"
fi

# Install Hammerspoon config
cp -v "$ROOT/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

# Install Karabiner rule
mkdir -p "$HOME/.config/karabiner/assets/complex_modifications"
cp -v "$ROOT/karabiner/halfq_profile.json" "$HOME/.config/karabiner/assets/complex_modifications/"

echo
echo "> Abra Karabiner → Complex Modifications → Add rule → 'HalfQ Left (US-Intl) + Overlay'"
echo "> No Hammerspoon, clique Reload Config."
echo
echo "Checagens macOS:"
echo "  - Privacidade e Segurança → Acessibilidade: Karabiner + Hammerspoon"
echo "  - Privacidade e Segurança → Monitoramento de Entrada: Karabiner"
echo "  - Terminal → desmarcar 'Secure Keyboard Entry' (se ligado)"
echo
echo "Feito."
