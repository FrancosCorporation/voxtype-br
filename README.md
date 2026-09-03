# Voxtype BR 🇧🇷

**Ditado por voz (voice-to-text) no Linux com suporte total ao Português do Brasil (ABNT2) e aceleração por GPU (Vulkan).**

Pacote completo de configuração e utilitários para transformar o [Voxtype](https://github.com/woheller69/voxtype) em um sistema de ditado robusto em pt-BR:

- ✅ Transcrição com **Whisper large-v3-turbo** (pt-BR)
- ✅ Aceleração **GPU via Vulkan** (AMD/NVIDIA/Intel)
- ✅ Injeção de texto no cursor com **ydotool** (funciona no GNOME Wayland)
- ✅ **OSD visual** com ondas animadas conforme o nível de voz
- ✅ Atalho global `Ctrl+Shift+Espaço` (modo toggle)
- ✅ Keymap **ABNT2** corrigido (sem letras virarem `:`)

---

## 🧩 O Problema

O Voxtype por padrão:

1. Usa modelos `.en` (inglês) — transcrição ruim em pt-BR
2. Roda na **CPU** (binário AVX2) — transcrições demoram 70s+ com modelo grande
3. Usa `wtype` para injetar texto — **falha no GNOME Wayland** (protocolo virtual-keyboard não suportado)
4. Usa keymap **US** — caracteres ABNT2 saem trocados (`;` vira `:`)
5. Não tem feedback visual de gravação

Este repositório resolve tudo isso.

---

## 📦 Componentes

| Arquivo | Descrição |
|---------|-----------|
| `bin/voxtype-osd` | OSD visual: microfone + ondas animadas conforme a voz (GTK3) |
| `config/config.toml` | Configuração completa pt-BR + GPU + ydotool |
| `scripts/voxtype-start` | Script de inicialização do daemon com GPU (Vulkan) |
| `scripts/setup-gnome-shortcut.sh` | Configura atalho global `Ctrl+Shift+Espaço` no GNOME |
| `docs/SETUP.md` | Guia completo de instalação |
| `docs/TROUBLESHOOTING.md` | Solução de problemas comuns |

---

## 🚀 Quick Start

```bash
# 1. Instala o voxtype (Debian/Ubuntu)
# dpkg -i voxtype_*.deb

# 2. Baixa o modelo pt-BR e configura
voxtype setup --download --model large-v3-turbo

# 3. Copia a configuração
mkdir -p ~/.config/voxtype
cp config/config.toml ~/.config/voxtype/config.toml

# 4. Instala o OSD
cp bin/voxtype-osd ~/.local/bin/
chmod +x ~/.local/bin/voxtype-osd

# 5. Configura o atalho no GNOME
bash scripts/setup-gnome-shortcut.sh

# 6. Inicia o daemon com GPU
bash scripts/voxtype-start
```

---

## ⚙️ Configuração essencial (`config/config.toml`)

```toml
[hotkey]
key = "SPACE"
modifiers = ["LEFTCTRL", "LEFTSHIFT"]
mode = "toggle"              # 1ª tecla grava, 2ª cola no cursor

[whisper]
model = "large-v3-turbo"     # melhor qualidade pt-BR
language = "pt"              # Português

[output]
mode = "type"
driver_order = ["ydotool", "wtype", "dotool", "clipboard"]
dotool_xkb_layout = "br"     # ABNT2 — corrige caracteres trocados
```

---

## 🖥️ GPU (Vulkan)

O Voxtype tem binários separados: `voxtype-avx2` (CPU) e `voxtype-vulkan` (GPU).

Para usar a GPU, defina `VOXTYPE_GPU=1` ao iniciar o daemon:

```bash
VOXTYPE_GPU=1 voxtype daemon
```

O wrapper `/usr/bin/voxtype` detecta e escolhe o binário Vulkan automaticamente.
O modelo large-v3-turbo (1.6 GB) carrega em ~1s na GPU e transcreve em tempo real.

Verifique a GPU detectada nos logs:
```
ggml_vulkan: Found 1 Vulkan devices:
ggml_vulkan: 0 = AMD Radeon RX 6750 XT (RADV NAVI22) (radv)
whisper_init_with_params_no_state: use gpu = 1
```

---

## ⌨️ Atalho (GNOME Wayland)

O hotkey embutido do voxtype requer o grupo `input` (evdev) que só ativa após logout.
Para funcionar **sem logout**, use um atalho do GNOME que chama `voxtype record toggle`:

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Voxtype Ditado'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'voxtype record toggle'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Shift>space'
```

---

## 🎙️ OSD Visual

O `voxtype-osd` exibe um overlay central com:

- **🎙 Microfone** + ondas vermelhas animadas que **crescem conforme o volume da voz** (lê o socket de nível de áudio do voxtype)
- **"Transcrevendo..."** em azul com pulso na borda durante a transcrição
- Some automaticamente quando idle

O voxtype o inicia automaticamente se encontrar `voxtype-osd` no `PATH`.

---

## 🔧 Problemas resolvidos

| Sintoma | Causa | Solução |
|---------|-------|---------|
| "Letras virando `:`" | ydotool com keymap US | `dotool_xkb_layout = "br"` |
| Não digita no cursor (só card/clipboard) | wtype falha no GNOME Wayland | `driver_order` com `ydotool` primeiro |
| Transcrição demora 70s | Modelo rodando na CPU | `VOXTYPE_GPU=1` (Vulkan) |
| Transcrição ruim em pt-BR | Modelo `.en` | `large-v3-turbo` + `language = "pt"` |
| Sem feedback visual | Sem OSD | `voxtype-osd` |

---

## 🧩 Dependências

- [Voxtype](https://github.com/woheller69/voxtype) (0.7.1+)
- `ydotool` + daemon `ydotoold` (roda como root para uinput)
- `python3-gi` + `gir1.2-gtk-3.0` + `cairo` (para o OSD)
- `wl-copy` (fallback clipboard)
- GPU com driver Vulkan (opcional, recomendado)

---

## 📄 Licença

MIT — sinta-se livre para usar, modificar e compartilhar com a comunidade.

---

## 🙏 Créditos

- [Voxtype](https://github.com/woheller69/voxtype) — ferramenta base de ditado push-to-talk
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) — motor de transcrição local