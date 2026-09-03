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
# ydotool (injeção de texto no Wayland — funciona no GNOME)
sudo apt install ydotool

# OSD visual (GTK3 + cairo)
sudo apt install python3-gi gir1.2-gtk-3.0 python3-cairo

# Clipboard fallback
sudo apt install wl-clipboard
```

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

[output]
driver_order = ["ydotool", "wtype", "dotool", "clipboard"]
dotool_xkb_layout = "br"
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
O OSD mostra:
- 🎙 microfone + ondas vermelhas animadas **conforme o volume da voz**
- "Transcrevendo..." em azul com borda pulsante
- some quando idle

---

## 7. Atalho global (GNOME, sem logout)

```bash
bash scripts/setup-gnome-shortcut.sh
```

Isso cria um atalho personalizado: **Ctrl+Shift+Espaço → `voxtype record toggle`**

Modo **toggle**:
1. Pressiona `Ctrl+Shift+Espaço` → começa a gravar
2. Fala normalmente
3. Pressiona de novo → para, transcreve e **cola no cursor**

> 💡 O hotkey embutido do voxtype requer o grupo `input` (evdev), que só ativa
> após logout. O atalho do GNOME contorna isso — funciona imediatamente.

---

## 8. Iniciar com GPU

```bash
bash scripts/voxtype-start
```

Ou manualmente:
```bash
VOXTYPE_GPU=1 voxtype daemon
```

Verifique que a GPU foi detectada:
```bash
tail -f /tmp/voxtype.log
# ggml_vulkan: 0 = AMD Radeon RX 6750 XT (RADV NAVI22) (radv)
# whisper_init_with_params_no_state: use gpu = 1
```

---

## 9. Autostart (opcional)

Para iniciar o daemon automaticamente ao logar:

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
- [ ] `VOXTYPE_GPU=1` → log mostra Vulkan device
- [ ] `voxtype-osd` no `PATH`