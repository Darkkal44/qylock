<p align="center">
  <img src="./Assets/title.png" alt="qylock" width="100%"/>
</p>

<br>

<p align="center">
  <a href="#-sddm-setup">SDDM</a> &nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="#-quickshell-setup">Quickshell</a> &nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="#-gallery">Gallery</a> &nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="#-credits">Credits</a>
</p>

<p align="center">
  <a href="https://github.com/sddm/sddm">
    <img src="https://img.shields.io/badge/SDDM-black?style=flat-square&logo=linux&logoColor=white" alt="SDDM"/>
  </a>
  &nbsp;
  <a href="https://github.com/outfoxxed/quickshell">
    <img src="https://img.shields.io/badge/Quickshell-black?style=flat-square&logo=qtile&logoColor=white" alt="Quickshell"/>
  </a>
  &nbsp;
  <a href="https://github.com/Darkkal44/qylock/stargazers">
    <img src="https://img.shields.io/github/stars/Darkkal44/qylock?style=flat-square&color=black&labelColor=black&logo=star&logoColor=white" alt="Stars"/>
  </a>
  &nbsp;
  <a href="https://ko-fi.com/darkkal">
    <img src="https://img.shields.io/badge/Ko--fi-black?style=flat-square&logo=ko-fi&logoColor=white" alt="Ko-fi"/>
  </a>
</p>

<br>

<p align="center">
  A curated collection of pixel-perfect lockscreen themes for SDDM and Quickshell.<br>
  Switch themes instantly with an interactive script — no manual file moving required.
</p>

<br>

---

<br>

## ⚡ SDDM Setup

### Dependencies

| | Packages |
|:--|:--|
| **Core** | `sddm` &nbsp; `qt5-graphicaleffects` &nbsp; `qt5-quickcontrols2` &nbsp; `qt5-svg` |
| **Video · Qt5** | `qt5-multimedia` |
| **Video · Qt6** | `qt6-multimedia-ffmpeg` |
| **Optional** | `fzf` |

### Install

```sh
chmod +x sddm.sh && ./sddm.sh
```

> [!NOTE]
> The script uses `fzf` for an interactive theme picker. Falls back to a numbered list if not installed.

<br>

### Font Requirements

Some themes rely on fonts that cannot be bundled here. Download the font and drop it into `themes/<theme_name>/font/` — it loads automatically.

| Theme | Font | Filename |
|:--|:--|:--|
| NieR: Automata | FOT-Rodin Pro DB | `FOT-Rodin Pro DB.otf` |
| Terraria | Andy Bold | `Andy Bold.ttf` |
| Genshin Impact | HYWenHei-85W | `zhcn.ttf` |
| Sword | The Last Shuriken | `The Last Shuriken.ttf` |
| Minecraft | Minecraft Regular | `minecraft.ttf` |

<br>

---

<br>

## 🔒 Quickshell Setup

### Dependencies

| | Packages |
|:--|:--|
| **Core** | `quickshell` &nbsp; `qt6-declarative` &nbsp; `qt6-5compat` |
| **Video** | `qt6-multimedia` &nbsp; `qt6-multimedia-ffmpeg` |
| **Optional** | `fzf` |

### Install

```sh
chmod +x quickshell.sh && ./quickshell.sh
```

### Bind a Shortcut

Point your WM keybind to:

```sh
~/.local/share/quickshell-lockscreen/lock.sh
```

Compatible with **Hyprland**, **Qtile**, **Sway**, **i3**, and more.

<br>

---

<br>

## 🎨 Gallery

<br>

<table>
  <tr>
    <td align="center" width="50%">
      <b>Pixel · Coffee</b><br><br>
      <img src="./Assets/pixel_coffee.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Pixel · Dusk City</b><br><br>
      <img src="./Assets/pixel_dusk_city.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Pixel · Emerald</b><br><br>
      <img src="./Assets/pixel_emerald.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Pixel · Hollow Knight</b><br><br>
      <img src="./Assets/pixel_hollowknight.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Pixel · Munchax</b><br><br>
      <img src="./Assets/pixel_munchax.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Pixel · Night City</b><br><br>
      <img src="./Assets/pixel_night_city.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Pixel · Rainy Room</b><br><br>
      <img src="./Assets/pixel_rainyroom.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Pixel · Skyscrapers</b><br><br>
      <img src="./Assets/pixel_skyscrapers.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>NieR: Automata</b><br><br>
      <img src="./Assets/nier_automata.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Terraria</b><br><br>
      <img src="./Assets/terraria.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Enfield</b><br><br>
      <img src="./Assets/enfield.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Sword</b><br><br>
      <img src="./Assets/sword.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Paper</b><br><br>
      <img src="./Assets/paper.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Windows 7</b><br><br>
      <img src="./Assets/win7.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Cyberpunk</b><br><br>
      <img src="./Assets/cyberpunk.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>TUI</b><br><br>
      <img src="./Assets/tui.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Porsche</b><br><br>
      <img src="./Assets/porsche.gif" width="100%"/>
    </td>
    <td align="center" width="50%">
      <b>Genshin Impact</b><br><br>
      <img src="./Assets/genshin.gif" width="100%"/>
    </td>
  </tr>
  <tr>
    <td align="center" colspan="2">
      <b>Ninja Gaiden</b><br><br>
      <img src="./Assets/ninja_gaiden.gif" width="50%"/>
    </td>
  </tr>
</table>

<br>

---

<br>

## 🤝 Credits

| | |
|:--|:--|
| ☕ **[max](https://ko-fi.com/B0B1UPVVB)** | Genuinely blown away — thank you! |
| **Pumphium** | Theme suggestions, testing, and late-night debugging. |
| **Qt / QML Community** | The framework powering every theme in this collection. |
| **Unixporn** | Endless aesthetic inspiration and community feedback. |

<br>

---

<br>

<p align="center">
  <i>Make your login your own.</i>
  &nbsp;&nbsp;·&nbsp;&nbsp;
  <a href="https://ko-fi.com/darkkal">☕ Buy me a coffee</a>
</p>

<br>
