# 📖 Guia de Instalação Completo

Setup do Voxtype para ditado em Português do Brasil com GPU e Wayland.

---

## 1. Instalar o Voxtype

```bash
# Download do .deb (versão 0.7.1+)
wget https://github.com/woheller69/voxtype/releases/latest/download/voxtype_amd64.deb
sudo dpkg -i voxtype_amd64.deb
# Se der erro de dependência:
sudo apt-get install -f
```

Verifique:
```bash
voxtype --version  # deve retornar 0.7.1+
```

---

## 2. Dependências do sistema

```bash
# ydotool (injeção de teclas no Wayland — funciona no GNOME)
sudo apt install ydotool

# OSD visual (GTK3 + cairo + conversor gi-cairo)
sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-cairo

# Clipboard fallback
sudo apt install wl-clipboard
```

> ⚠️ **Remova o `wtype`** se estiver instalado: ele é incompatível com o GNOME
> Wayland (protocolo virtual-keyboard não suportado) e, na colagem, o Voxtype
> tentava usá-lo primeiro — o que **travava a colagem por ~1 minuto**:
> ```bash
> sudo apt remove wtype
> ```

---

## 3. Baixar o modelo pt-BR (large-v3-turbo)

```bash
# Baixa e configura automaticamente
voxtype setup --download --model large-v3-turbo
```

O modelo (~1.6 GB) fica em `~/.local/share/voxtype/models/ggml-large-v3-turbo.bin`.

> **Alternativa menor (mais rápida, menos precisa):** `voxtype setup --download --model small`

---

## 4. Configuração pt-BR

```bash
mkdir -p ~/.config/voxtype
cp config/config.toml ~/.config/voxtype/config.toml
```

Pontos-chave:
```toml
[whisper]
model = "large-v3-turbo"
language = "pt"
gpu_isolation = false   # sem recarregar o modelo a cada ditado

[output]
mode = "paste"          # Ctrl+V atômico: instantâneo e sem erro ABNT2
paste_keys = "ctrl+v"
driver_order = ["dotool", "ydotool", "clipboard"]  # sem wtype (GNOME não implementa)
pre_type_delay_ms = 450 # tempo de soltar Ctrl+Shift e o foco voltar à caixa
```

---

## 5. Configurar o ydotool daemon

O `ydotool` injeta texto via kernel (uinput) — funciona em **qualquer** compositor Wayland.

```bash
# ydotoold precisa de /dev/uinput → roda como root
sudo nohup ydotoold -p /run/user/$UID/.ydotool_socket -o $UID:$UID -P 0666 > /tmp/ydotoold.log 2>&1 &

# Verificar socket acessível ao usuário
ls -la /run/user/$UID/.ydotool_socket
# srw-rw-rw- 1 servidor servidor ... .ydotool_socket  ✓
```

> 💡 **Por que `wtype` não funciona no GNOME?** O wtype usa o protocolo
> `zwp_virtual_keyboard_v1`, que o **GNOME não implementa**. O ydotool contorna
> isso usando `uinput` (nível de kernel).

---

## 6. Instalar o OSD visual

```bash
cp bin/voxtype-osd ~/.local/bin/
chmod +x ~/.local/bin/voxtype-osd
```

O Voxtype detecta e inicia o OSD automaticamente se estiver no `PATH`.
O OSD é um **overlay na tela** (parte inferior central) com:
- 🎙 speaker + ondas vermelhas animadas **conforme o volume da voz**
- ⏳ "Transcrevendo..." em azul com borda pulsante
- some quando idle
- **nunca rouba o foco**: `accept_focus(False)` + click-through — o texto cola
  na caixa de diálogo onde você estava

---

## 7. Atalho global (GNOME, sem logout)

```bash
bash scripts/setup-gnome-shortcut.sh
```

Isso cria um atalho personalizado: **Ctrl+Shift+Espaço → `voxtype-toggle`**
(wrapper com debounce + trava durante a transcrição — veja `scripts/voxtype-toggle`)

Modo **toggle**:
1. Clique no campo onde quer digitar
2. Pressiona `Ctrl+Shift+Espaço` → começa a gravar
3. Fala normalmente
4. Pressiona de novo → para, transcreve e **cola no cursor** (não clique em
   outro lugar até o OSD azul sumir; se cair na janela errada, clique na caixa
   certa e dê `Ctrl+V` — o texto continua no clipboard)

> 💡 O hotkey embutido do voxtype requer o grupo `input` (evdev), que só ativa
> após logout. O atalho do GNOME contorna isso — funciona imediatamente.

---

## 8. Iniciar com GPU

> **Importante:** em instalações via `.deb`, o `/usr/bin/voxtype` é um **symlink**
> para um binário em `/usr/lib/voxtype/` (avx2/avx512 = CPU, vulkan = GPU).
> A variável `VOXTYPE_GPU=1` **não ativa GPU no .deb** — ela só funciona no
> wrapper do AppImage. Para ativar a GPU no .deb use o comando oficial:

```bash
# 1. (uma única vez) Ativa GPU permanentemente — troca o symlink para voxtype-vulkan
sudo voxtype setup gpu --enable

# 2. Inicia com o script (ele executa /usr/lib/voxtype/voxtype-vulkan diretamente)
bash scripts/voxtype-start
```

O script `voxtype-start` detecta e usa o binário Vulkan automaticamente, mesmo
sem rodar o `setup gpu` (não precisa de sudo). Verifique que a GPU foi usada:

```bash
tail -f /tmp/voxtype.log
# ggml_vulkan: 0 = AMD Radeon RX 6750 XT (RADV NAVI22) (radv)
# whisper_init_with_params_no_state: use gpu = 1
```

Para voltar para CPU: `sudo voxtype setup gpu --disable`

---

## 9. Autostart (automático pelo apply.sh)

O `scripts/apply.sh` já instala dois autostarts no login:
- `voxtype.desktop` → inicia o **daemon** (o atalho nunca mais fica morto após reboot)
- `voxtype-update.desktop` → puxa novidades do GitHub e reaplica sozinho

Para instalar manualmente (se não usou o apply.sh):

```bash
cat > ~/.config/autostart/voxtype.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Voxtype
Exec=/home/SEU_USUARIO/Git/voxtype-br/scripts/voxtype-start
X-GNOME-Autostart-enabled=true
EOF
```

---

## 10. Teste rápido

```bash
# 1. Confira o daemon
voxtype status  # deve mostrar "idle"

# 2. Grave um áudio de teste manualmente
voxtype record toggle   # fala algo...
voxtype record toggle   # para e transcreve

# 3. O texto aparece no cursor (ou no clipboard como fallback)
```

---

## ✅ Checklist final

- [ ] `voxtype --version` → 0.7.1+
- [ ] Modelo `large-v3-turbo` em `~/.local/share/voxtype/models/`
- [ ] `dotool_xkb_layout = "br"` no config
- [ ] `ydotoold` rodando + socket acessível
- [ ] Atalho `Ctrl+Shift+Espaço` configurado no GNOME
- [ ] `sudo voxtype setup gpu --enable` ou `voxtype-start` → log mostra Vulkan device
- [ ] `voxtype-osd` no `PATH`