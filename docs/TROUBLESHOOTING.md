# 🔧 Solução de Problemas

Guia de diagnóstico dos erros mais comuns do Voxtype em pt-BR/Wayland.

---

## 1. "Letras viram `:`" ou caracteres trocados

**Causa:** o ydotool usa keymap US por padrão. Em teclado ABNT2, caracteres
como `;` → `:`, e acentos/`ç` saem errados.

**Fix:**
```toml
# ~/.config/voxtype/config.toml
[output]
dotool_xkb_layout = "br"
```

Depois reinicie: `pkill -f "voxtype-.* daemon" && VOXTYPE_GPU=1 voxtype daemon`

---

## 2. Não digita no cursor — só mostra um card/notificação

**Causa:** o `wtype` falha no GNOME Wayland
(`Compositor does not support the virtual keyboard protocol`), então o voxtype
cai no fallback de clipboard + notificação.

**Diagnóstico:**
```bash
tail -30 /tmp/voxtype.log
# wtype failed: Compositor does not support the virtual keyboard protocol
```

**Fix:** usar ydotool como driver principal:
```toml
driver_order = ["ydotool", "wtype", "dotool", "clipboard"]
```

E garantir o daemon do ydotool rodando:
```bash
sudo nohup ydotoold -p /run/user/$UID/.ydotool_socket -o $UID:$UID -P 0666 > /tmp/ydotoold.log 2>&1 &
```

---

## 3. Transcrição demora muito (CPU subindo)

**Causa:** o wrapper `/usr/bin/voxtype` escolhe o binário AVX2 (CPU) por padrão.

**Fix:** habilitar GPU Vulkan:
```bash
VOXTYPE_GPU=1 voxtype daemon
```

O log deve mostrar:
```
ggml_vulkan: Found 1 Vulkan devices:
ggml_vulkan: 0 = AMD Radeon RX 6750 XT (RADV NAVI22) (radv)
whisper_init_with_params_no_state: use gpu = 1
```

Se aparecer `no GPU found`, seu driver Vulkan não está instalado:
```bash
sudo apt install mesa-vulkan-drivers  # AMD/Intel
# ou
sudo apt install nvidia-driver-545    # NVIDIA
```

---

## 4. `voxtype-osd` não aparece

**Verificar:**
```bash
which voxtype-osd   # precisa estar no PATH
ls ~/.local/bin/voxtype-osd
```

**Erro no log:** `Failed to spawn voxtype-osd: No such file or directory`

**Fix:**
```bash
cp bin/voxtype-osd ~/.local/bin/
chmod +x ~/.local/bin/voxtype-osd
export PATH="$HOME/.local/bin:$PATH"   # adicione ao ~/.bashrc
```

---

## 5. OSD roda mas com erros de `cairo.Context`

**Causa:** PyGObject precisa do módulo cairo registrado explicitamente.

**Fix:** o script já importa `import cairo`. Garanta o pacote:
```bash
sudo apt install python3-cairo
```

---

## 6. `ydotoold: failed to open uinput device: Permission denied`

**Causa:** o daemon não tem acesso a `/dev/uinput`.

**Fix:** rodar como root (recomendado para uso desktop):
```bash
sudo nohup ydotoold -p /run/user/$UID/.ydotool_socket -o $UID:$UID -P 0666 > /tmp/ydotoold.log 2>&1 &
```

Alternativa sem root (exige logout): adicionar ao grupo `input`:
```bash
sudo usermod -aG input $USER
# e reiniciar a sessão
```

---

## 7. Atalho não funciona (hotkey embutido)

**Causa:** o hotkey embutido usa evdev (`/dev/input/`) e o usuário não está no
grupo `input` (só ativa após logout).

**Fix:** usar atalho do GNOME apontando para `voxtype record toggle`:
```bash
bash scripts/setup-gnome-shortcut.sh
```

---

## 8. O texto cola no lugar errado (não no cursor)

**Comportamento atual:** o voxtype injeta na **janela focada no momento da
transcrição**. Se você clicar em outro lugar após parar de falar, o texto vai
para lá.

**Dica:** o modo `toggle` mantém o fluxo:
1. Clique no campo onde quer digitar
2. `Ctrl+Shift+Espaço` → grava
3. `Ctrl+Shift+Espaço` → transcreve e injeta **na mesma janela** (que ainda está focada)

---

## 9. Modelo `large-v3-turbo` demora para carregar na 1ª vez

É normal: são 1.6 GB. Na CPU ~7s, na GPU ~1s.
Se carregar toda vez, use `gpu_isolation = false` (mantém o modelo na memória):
```toml
[whisper]
gpu_isolation = false
```

---

## 10. Transcrição no idioma errado

**Fix:**
```toml
[whisper]
language = "pt"
```

---

## Comandos úteis

```bash
voxtype config        # mostra configuração ativa
voxtype status        # estado do daemon (idle/recording/transcribing)
voxtype setup check   # diagnóstico completo do sistema
voxtype record toggle # gravar/parar manualmente
tail -f /tmp/voxtype.log  # logs do daemon
tail -f /tmp/ydotoold.log # logs do ydotool
```