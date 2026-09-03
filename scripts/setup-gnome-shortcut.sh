#!/bin/bash
# setup-gnome-shortcut.sh — Configura o atalho global Ctrl+Shift+Espaço no GNOME.
# Funciona no GNOME Wayland (sem precisar logout/login).
set -e

SHORTCUT_NAME="Voxtype Ditado"
SHORTCUT_CMD="voxtype record toggle"
SHORTCUT_BINDING="<Ctrl><Shift>space"
BASE="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

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