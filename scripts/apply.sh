#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

ok()   { echo "✅ $*"; }
info() { echo "ℹ️  $*"; }
warn() { echo "⚠️  $*" >&2; }

mkdir -p ~/.config/voxtype ~/.local/bin ~/.local/share/voxtype/assets

if [ -f ~/.config/voxtype/config.toml ]; then
    cp ~/.config/voxtype/config.toml ~/.config/voxtype/config.toml.bak.$(date +%Y%m%d-%H%M%S)
    info "Backup da config atual criado em ~/.config/voxtype/"
fi
cp "$ROOT_DIR/config/config.toml" ~/.config/voxtype/config.toml
ok "config.toml instalado em ~/.config/voxtype/"

cp "$ROOT_DIR/bin/voxtype-osd" ~/.local/bin/voxtype-osd
cp "$ROOT_DIR/scripts/voxtype-toggle" ~/.local/bin/voxtype-toggle
cp "$ROOT_DIR/scripts/voxtype-type" ~/.local/bin/voxtype-type
cp "$ROOT_DIR/scripts/notify-send-shim" ~/.local/bin/notify-send
chmod +x ~/.local/bin/voxtype-osd ~/.local/bin/voxtype-toggle ~/.local/bin/voxtype-type ~/.local/bin/notify-send

cp -r "$ROOT_DIR/assets/"* ~/.local/share/voxtype/assets/
ok "assets instalados em ~/.local/share/voxtype/assets/"

mkdir -p ~/.local/share/voxtype
echo "$ROOT_DIR" > ~/.local/share/voxtype/repo_path
ok "caminho do repo registrado (auto-recuperação do atalho)"
ok "shim notify-send instalado (pop-up curto, sem roubar o foco)"

ok "voxtype-osd + voxtype-toggle instalados em ~/.local/bin/"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) warn "~/.local/bin NÃO está no PATH. Adicione ao ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

bash "$SCRIPT_DIR/setup-gnome-shortcut.sh"

mkdir -p ~/.config/autostart
cat > ~/.config/autostart/voxtype-update.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Voxtype Autoupdate
Comment=Sincroniza voxtype-br do GitHub e reaplica no login (sem acao manual)
Exec=bash $ROOT_DIR/scripts/voxtype-autoupdate.sh $ROOT_DIR
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
ok "auto-update instalado (login aplica novidades sozinho)"

cat > ~/.config/autostart/voxtype.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Voxtype
Comment=Daemon de ditado por voz com GPU (Ctrl+Shift+Espaço)
Exec=bash $ROOT_DIR/scripts/voxtype-start
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
ok "autostart do daemon instalado (sobe sozinho no login)"

bash "$SCRIPT_DIR/voxtype-start"

echo ""
echo "🔍 Conferindo se o instalado bate com o repo:"
for pair in "config/config.toml:$HOME/.config/voxtype/config.toml" "bin/voxtype-osd:$HOME/.local/bin/voxtype-osd" "scripts/voxtype-toggle:$HOME/.local/bin/voxtype-toggle"; do
    src="$ROOT_DIR/${pair%%:*}"; dst="${pair##*:}"
    if cmp -s "$src" "$dst"; then ok "$(basename "$dst") sincronizado"; else warn "$(basename "$dst") DIVERGENTE de $src"; fi
done
command -v voxtype-osd >/dev/null 2>&1 && ok "voxtype-osd no PATH" || warn "voxtype-osd fora do PATH (abra um novo terminal)"
echo ""
ok "Pronto. Teste: clique numa caixa de texto, Ctrl+Shift+Espaço, fale, Ctrl+Shift+Espaço."
