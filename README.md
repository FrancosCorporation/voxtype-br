# Voxtype BR 🇧🇷

**Ditado por voz (voice-to-text) no Linux com suporte total ao Português do Brasil (ABNT2) e aceleração por GPU (Vulkan).**

Pacote completo de configuração e utilitários para transformar o [Voxtype](https://github.com/woheller69/voxtype) em um sistema de ditado robusto em pt-BR:

- ✅ Transcrição com **Whisper large-v3-turbo** (pt-BR)
- ✅ Aceleração **GPU via Vulkan** (AMD/NVIDIA/Intel)
- ✅ Injeção de texto no cursor com **ydotool** (funciona no GNOME Wayland)
- ✅ **OSD visual** com onda senoidal animada conforme o nível de voz
- ✅ Atalho global `Ctrl+Shift+Espaço` (modo toggle)
- ✅ Keymap **ABNT2** corrigido (sem letras virarem `:`)

---

## 🎬 OSD Visual (onda senoidal)

| Ouvindo (gravação) | Transcrevendo |
|---|---|
| ![Rec](docs/imgs/voxtype-osd-recording.gif) | ![Trans](docs/imgs/voxtype-osd-transcribing.png) |

O overlay central mostra uma **onda senoidal que ondula conforme o volume da sua voz**:
- 🎙 **Vermelho + onda animada** — enquanto grava (a onda cresce com a fala)
- ⏳ **Azul + borda pulsante** — enquanto transcreve
- Desaparece automaticamente quando idle

> Inspirado na estética de apps como o [whisper-flow](https://github.com/dimastatz/whisper-flow) e Shazam/voice-notes.

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
| `bin/voxtype-osd` | OSD visual: microfone + ondas animadas conforme a voz (GTK3, topo da tela, click-through) |
| `config/config.toml` | Configuração completa pt-BR + GPU + colagem atômica (`paste`) |
| `scripts/voxtype-start` | Script de inicialização do daemon com GPU (usa `voxtype-vulkan` diretamente) |
| `scripts/voxtype-toggle` | Wrapper do atalho global (debounce + ignora toques durante a transcrição) |
| `scripts/voxtype-start` | Script de inicialização do daemon com GPU (usa `voxtype-vulkan` diretamente) |
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

# 6. Inicia o daemon com GPU (usa voxtype-vulkan diretamente)
bash scripts/voxtype-start
```

> ⚠️ **O atalho não lê o repo — lê as cópias instaladas.** Depois de `git pull`
> ou qualquer edição, rode **`bash scripts/apply.sh`**: ele copia
> `config.toml` → `~/.config/voxtype/`, `voxtype-osd` + `voxtype-toggle` →
> `~/.local/bin/`, reaponta o atalho do GNOME e reinicia o daemon (com backup
> automático do config anterior). No final ele confere se instalado == repo.

## 🔁 Ciclo de teste (a cada alteração no código)

1. Aqui no repo: edita → commit → push para o `main`
2. No Ubuntu: `git pull && bash scripts/apply.sh`
3. Testa o ditado e reporta o resultado (ideal: `tail -20 /tmp/voxtype.log` junto)

> Da 1ª vez que o `apply.sh` roda, ele instala o **auto-update no login**:
> a partir daí você não roda mais comando nenhum — a cada login ele puxa
> novidades do GitHub e reaplica sozinho (log em `/tmp/voxtype-autoupdate.log`).
> O teste passa a ser só: atalho → falar → atalho.

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
gpu_isolation = false        # mantém o modelo na RAM (sem recarregar a cada ditado)

[output]
mode = "paste"               # colagem atômica via Ctrl+V (instantânea, sem erro ABNT2)
driver_order = ["dotool", "ydotool", "clipboard"]  # sem wtype (não existe no GNOME)
pre_type_delay_ms = 450      # tempo de soltar o Ctrl+Shift e o foco voltar à caixa
```

---

## 🖥️ GPU (Vulkan)

O Voxtype instala binários separados em `/usr/lib/voxtype/`: `voxtype-avx2`
(CPU), `voxtype-avx512` (CPU) e `voxtype-vulkan` (GPU). O `/usr/bin/voxtype` é
um **symlink** para um deles.

> ⚠️ **Importante:** `VOXTYPE_GPU=1` só funciona no wrapper do **AppImage**. Em
> instalações `.deb`, a GPU é ativada trocando o symlink — não por variável de
> ambiente.

Para ativar a GPU no `.deb` (uma única vez):
```bash
sudo voxtype setup gpu --enable
```

Ou use o `scripts/voxtype-start`, que executa `/usr/lib/voxtype/voxtype-vulkan`
diretamente (sem sudo), verificando no log se a GPU foi usada.

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

O `voxtype-osd` exibe um overlay central com **onda senoidal animada**:

- 🎙 **Onda vermelha animada** que cresce/ondula **conforme o volume da voz** (lê o socket de nível de áudio do voxtype)
- ⏳ **"Transcrevendo..."** em azul com borda pulsante durante a transcrição
- Some automaticamente quando idle

**Importante para não "roubar" o cursor:**
- A janela usa `Gtk.WindowTypeHint.NOTIFICATION` (tipo OSD do GNOME)
- `set_accept_focus(False)` — nunca rouba o foco do aplicativo ativo
- Ancorada no **topo da tela** — nunca cobre a caixa de diálogo onde está o cursor
- **Click-through** (input shape vazia) — cliques atravessam o OSD, a seleção do campo se mantém
- Assim, quando a transcrição termina, a colagem cai **na caixa onde você estava**

O voxtype o inicia automaticamente se encontrar `voxtype-osd` no `PATH`.
O script `scripts/voxtype-start` mata instâncias duplicadas (evita 2 micrófonos na tela).

---

## 🔧 Problemas resolvidos

| Sintoma | Causa | Solução |
|---------|-------|---------|
| "Letras virando `:`" | ydotool com keymap US | `dotool_xkb_layout = "br"` |
| Não digita no cursor (só card/clipboard) | wtype falha no GNOME Wayland | `driver_order` com `ydotool` primeiro |
| Texto não sai no terminal (colava em outro lugar) | OSD roubava o foco com `present()` | OSD usa `NOTIFICATION` + `set_accept_focus(False)` + topo da tela + click-through |
| Injeção lenta / texto na janela errada | `mode="type"` tecla-por-tecla + `pre_type_delay=0` + `wtype` (inexistente no GNOME) no caminho | `mode="paste"` (Ctrl+V atômico) + `pre_type_delay_ms=450` + `driver_order` sem `wtype` |
| 2º toque "não finaliza" / parece travado | Toque durante `transcribing` é ignorado; disparo duplo do atalho | Atalho via `voxtype-toggle` (avisa "aguarde" + debounce) |
| Dois micrófonos na tela | Instâncias duplicadas do OSD | `voxtype-start` mata duplicados |
| Transcrição demora 70s | Modelo rodando na CPU (symlink do .deb aponta para CPU; `VOXTYPE_GPU=1` não vale no .deb) | `sudo voxtype setup gpu --enable` ou `voxtype-start` (executa `voxtype-vulkan`) |
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