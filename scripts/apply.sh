#!/bin/bash
# apply.sh — Leva o código deste repo até a ferramenta instalada no Ubuntu.
#
# Por que existe: o atalho Ctrl+Shift+Espaço NÃO executa os arquivos do repo.
# Ele executa as CÓPIAS instaladas. Editar o repo sozinho não muda nada no
# ditado até este script rodar:
#
#   Repo (fonte)                          Onde o atalho/daemon lê (instalado)
#   -----------------                     ------------------------------------
#   config/config.toml            --->    ~/.config/voxtype/config.toml (daemon lê ao iniciar)
#   bin/voxtype-osd               --->    ~/.local/bin/voxtype-osd (daemon inicia via PATH)
#   scripts/voxtype-toggle        --->    ~/.local/bin/voxtype-toggle (alvo do atalho GNOME)
#
# Uso: após `git pull` (ou qualquer edição), rode:
#   bash scripts/apply.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

ok()   { echo "✅ $*"; }
info() { echo "ℹ️  $*"; }
warn() { echo "⚠️  $*" >&2; }

mkdir -p ~/.config/voxtype ~/.local/bin

# 1) Config (com backup da atual)
if [ -f ~/.config/voxtype/config.toml ]; then
    cp ~/.config/voxtype/config.toml ~/.config/voxtype/config.toml.bak.$(date +%Y%m%d-%H%M%S)
    info "Backup da config atual criado em ~/.config/voxtype/"
fi
cp "$ROOT_DIR/config/config.toml" ~/.config/voxtype/config.toml
ok "config.toml instalado em ~/.config/voxtype/"

# 2) OSD + wrapper do atalho
cp "$ROOT_DIR/bin/voxtype-osd" ~/.local/bin/voxtype-osd
cp "$ROOT_DIR/scripts/voxtype-toggle" ~/.local/bin/voxtype-toggle
chmod +x ~/.local/bin/voxtype-osd ~/.local/bin/voxtype-toggle
ok "voxtype-osd + voxtype-toggle instalados em ~/.local/bin/"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) warn "~/.local/bin NÃO está no PATH. Adicione ao ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

# 3) Atalho do GNOME -> wrapper
bash "$SCRIPT_DIR/setup-gnome-shortcut.sh"

# 4) Reinicia o daemon (só assim ele relê o config.toml)
bash "$SCRIPT_DIR/voxtype-start"

# 5) Verificação: instalado == repo?
echo ""
echo "🔍 Conferindo se o instalado bate com o repo:"
for pair in "config/config.toml:$HOME/.config/voxtype/config.toml" "bin/voxtype-osd:$HOME/.local/bin/voxtype-osd" "scripts/voxtype-toggle:$HOME/.local/bin/voxtype-toggle"; do
    src="$ROOT_DIR/${pair%%:*}"; dst="${pair##*:}"
    if cmp -s "$src" "$dst"; then ok "$(basename "$dst") sincronizado"; else warn "$(basename "$dst") DIVERGENTE de $src"; fi
done
command -v voxtype-osd >/dev/null 2>&1 && ok "voxtype-osd no PATH" || warn "voxtype-osd fora do PATH (abra um novo terminal)"
echo ""
ok "Pronto. Teste: clique numa caixa de texto, Ctrl+Shift+Espaço, fale, Ctrl+Shift+Espaço."
