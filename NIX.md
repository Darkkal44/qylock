# Nix / NixOS Setup

qylock ships a Nix flake with a **NixOS module**, a **Home Manager module**, and a **dev shell**. No manual file copying required — just import and configure.

---

## NixOS Module

**Step 1 — add the flake input:**

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    qylock.url  = "github:Darkkal44/qylock";
  };

  outputs = inputs@{ nixpkgs, qylock, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        qylock.nixosModules.default
        ./modules/features/qylock.nix  # your config (see step 2)
        # ... your other modules
      ];
    };
  };
}
```

**Step 2 — configure qylock in a module:**

```nix
# modules/features/qylock.nix
{ ... }:
{
  programs.qylock = {
    enable    = true;
    theme     = "paper";     # Quickshell lockscreen theme
    sddmTheme = "paper";     # optional: also sets services.displayManager.sddm.theme

    # Optional: fonts for themes that require licensed fonts not in the repo.
    # Drop the font file(s) in your config directory and reference them here.
    # sddmThemeFonts = [ ./fonts/zhcn.ttf ];
  };
}
```

> [!NOTE]
> Some SDDM themes require fonts that cannot be redistributed. For those themes, download the font manually and reference it via `sddmThemeFonts` — the file will be copied into the theme's `font/` directory at build time.
>
> | Theme | Font file |
> | :--- | :--- |
> | `Genshin` | `zhcn.ttf` (HYWenHei-85W) |
> | `terraria` | `Andy Bold.ttf` |
> | `nier-automata` | `FOT-Rodin Pro DB.otf` |
> | `sword` | `The Last Shuriken.ttf` |
> | `minecraft` | `minecraft.ttf` |
>
> Example:
> ```nix
> programs.qylock = {
>   enable         = true;
>   sddmTheme      = "Genshin";
>   sddmThemeFonts = [ ./fonts/zhcn.ttf ];
> };
> ```

**Step 3 — enable SDDM with Wayland support** (required for Wayland compositors like Hyprland):

```nix
services.displayManager.sddm = {
  enable         = true;
  wayland.enable = true;
};
```

**Step 4 — bind the lock command in your compositor:**

```ini
# hyprland.conf
bind = SUPER, L, exec, qylock-lock
```

`qylock-lock` is installed automatically by the module. `sddmTheme` is optional — when set it installs the SDDM theme package and configures `services.displayManager.sddm.theme` for you.

---

## Home Manager Module

Home Manager support covers the Quickshell lockscreen only (SDDM is system-wide and requires NixOS).

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    qylock.url       = "github:Darkkal44/qylock";
  };

  outputs = { nixpkgs, home-manager, qylock, ... }: {
    homeConfigurations.charlotte = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        qylock.homeManagerModules.default
        {
          programs.qylock = {
            enable = true;
            theme  = "tui/Crimson";
          };
        }
      ];
    };
  };
}
```

---

## Available Themes

| `theme` value | Notes |
| :--- | :--- |
| `Genshin` | Time-based day/night cycle (4 videos) |
| `terraria` | 5 biome backgrounds |
| `cyberpunk` | Glitch effects |
| `nier-automata` | Scanner beam & tech overlay |
| `enfield` | Video background |
| `sword` | Video background |
| `porsche` | Video background |
| `ninja_gaiden` | Static |
| `paper` | Minimal static |
| `minecraft` | Static |
| `windows_7` | Static |
| `star_rail` | Video background |
| `wuwa` | Video background |
| `cozytile/Carbon` | — |
| `cozytile/Cozy` | — |
| `cozytile/Everforest` | — |
| `cozytile/Natura` | — |
| `cozytile/Sakura` | — |
| `tui/Amber` | Terminal UI |
| `tui/Amethyst` | Terminal UI |
| `tui/Crimson` | Terminal UI |
| `tui/Emerald` | Terminal UI |
| `tui/Indigo` | Terminal UI |

The same values work for both `theme` (Quickshell lockscreen) and `sddmTheme` (SDDM login screen).

---

## Dev Shell

A dev shell is included for testing themes locally without touching your system:

```sh
nix develop
```

**Test an SDDM theme:**
```sh
# Without a font (theme has bundled assets):
testTheme paper

# With a font file (for themes requiring licensed fonts):
testTheme Genshin ~/fonts/zhcn.ttf
```

**Test the Quickshell lockscreen:**
```sh
testLockscreen Genshin
```

---

## Qt6 Compatibility Notes

The nixpkgs SDDM package (`kdePackages.sddm`) is Qt6-based, but qylock's themes target Qt5 APIs. The following compatibility fixes are applied automatically at build time — no changes to upstream theme files are required:

- **QtGraphicalEffects** — shimmed via `kdePackages.qt5compat` (`Qt5Compat.GraphicalEffects`)
- **Video** — Qt5's `Video {}` component is shimmed using Qt6's `MediaPlayer + AudioOutput + VideoOutput` composition
- **Enum values** — `MediaPlayer.Infinite`, `VideoOutput.PreserveAspectCrop`, etc. are inlined to their numeric equivalents
- **Signal syntax** — `onLoginFailed:` is rewritten to `function onLoginFailed()` per Qt6 deprecation
