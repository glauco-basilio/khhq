#!/usr/bin/env bash
set -euo pipefail

echo "== HalfQ Overlay: uninstall =="

rm -f "$HOME/.hammerspoon/init.lua"
rm -f "$HOME/.config/karabiner/assets/complex_modifications/halfq_profile.json"

echo "Removido. Outras regras/configs não foram alteradas."
