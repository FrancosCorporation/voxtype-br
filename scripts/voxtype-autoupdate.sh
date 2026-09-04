#!/bin/bash
# voxtype-autoupdate.sh — Sincroniza o repo e reaplica sozinho no login.
# Instalado em ~/.config/autostart pelo scripts/apply.sh (uma única vez).
# Uso: voxtype-autoupdate.sh /caminho/do/repo
# Depois disso, você NUNCA mais roda comando: é só atalho + falar.
set -u

REPO_DIR="${1:?informe o caminho do repo}"
LOG=/tmp/voxtype-autoupdate.log

{
echo "=== $(date '+%F %T') ==="
export GIT_TERMINAL_PROMPT=0

# Espera a rede aparecer (até ~60s)
for _ in $(seq 1 12); do
    timeout 15 git -C "$REPO_DIR" ls-remote origin HEAD >/dev/null 2>&1 && break
    sleep 5
done

before=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo none)
if ! timeout 60 git -C "$REPO_DIR" pull --ff-only 2>&1; then
    echo "pull falhou (sem rede ou mudança local em conflito) — mantendo a versão atual."
    exit 0
fi
after=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo none)

if [ "$before" != "$after" ]; then
    echo "nova versão ($after) — aplicando..."
    bash "$REPO_DIR/scripts/apply.sh" >>"$LOG" 2>&1 || echo "apply.sh falhou, veja o log."
    command -v notify-send >/dev/null 2>&1 && notify-send -a Voxtype -t 4000 "Voxtype atualizado" "Nova versão aplicada. É só usar o atalho." 2>/dev/null || true
else
    echo "já atualizado ($after) — nada a fazer."
fi
} >>"$LOG" 2>&1
