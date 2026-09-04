#!/bin/bash
# setup-gnome-shortcut.sh — Configura o atalho global Ctrl+Shift+Espaço no GNOME.
# Funciona no GNOME Wayland (sem precisar logout/login).
set -e

SHORTCUT_NAME="Voxtype Ditado"
SHORTCUT_BINDING="<Ctrl><Shift>space"
BASE="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Instala o wrapper (debounce + trava durante transcrição) no PATH do usuário
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/voxtype-toggle" "$HOME/.local/bin/voxtype-toggle"
chmod +x "$HOME/.local/bin/voxtype-toggle"
SHORTCUT_CMD="$HOME/.local/bin/voxtype-toggle"

echo "🎯 Configurando atalho: Ctrl+Shift+Espaço → $SHORTCUT_CMD"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set "$BASE" name "$SHORTCUT_NAME"
gsettings set "$BASE" command "$SHORTCUT_CMD"
gsettings set "$BASE" binding "$SHORTCUT_BINDING"

echo "✅ Atalho configurado!"
echo "   $SHORTCUT_NAME: Ctrl+Shift+Espaço"
echo "   Comando: $SHORTCUT_CMD"
echo ""
echo "   Dica: para trocar o atalho, abra Configurações → Teclado → Atalhos → Atalhos personalizados"