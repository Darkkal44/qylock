{ self, mkQylockPkgs }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.qylock;
  q = mkQylockPkgs pkgs;
in
{
  options.programs.qylock = {
    enable = lib.mkEnableOption "qylock lockscreen";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "Genshin";
      description = ''
        Quickshell lockscreen theme name, relative to the themes/ directory.

        Top-level themes: cyberpunk, enfield, Genshin, minecraft, nier-automata,
        ninja_gaiden, paper, porsche, sword, terraria, windows_7

        Nested themes (use the full sub-path):
          cozytile/Carbon, cozytile/Cozy, cozytile/Everforest, cozytile/Natura, cozytile/Sakura
          tui/Amber, tui/Amethyst, tui/Crimson, tui/Emerald, tui/Indigo
      '';
      example = "terraria";
    };

    sddmTheme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        If set, installs a qylock SDDM theme and sets it as the active SDDM theme.
        Uses the same path format as `theme` (e.g. "cyberpunk" or "cozytile/Cozy").
        The SDDM theme name will be the last path component.
      '';
      example = "cyberpunk";
    };

    sddmThemeFonts = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Font files to install into the SDDM theme's font/ directory.
        Required for themes that use licensed fonts not included in the repo.
        Each entry should be a path to a .ttf or .otf file — typically a path
        relative to your flake root (e.g. ./fonts/zhcn.ttf).

        Theme → required font file:
          Genshin      → zhcn.ttf          (HYWenHei-85W)
          terraria     → Andy Bold.ttf
          nier-automata → FOT-Rodin Pro DB.otf
          sword        → The Last Shuriken.ttf
          minecraft    → minecraft.ttf
      '';
      example = lib.literalExpression "[ ./fonts/zhcn.ttf ]";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ (q.mkLockScript cfg.theme) ];
      }

      (lib.mkIf (cfg.sddmTheme != null) {
        services.displayManager.sddm.theme = lib.last (lib.splitString "/" cfg.sddmTheme);

        services.displayManager.sddm.package = q.sddmPatched;

        # qt5compat: provides Qt5Compat.GraphicalEffects (rewritten from QtGraphicalEffects 1.15)
        # qtmultimedia: provides QtMultimedia for the Video.qml shim dropped into each theme
        services.displayManager.sddm.extraPackages = [
          pkgs.kdePackages.qt5compat
          pkgs.qt6.qtmultimedia
        ];

        environment.systemPackages = [ (q.mkSddmThemePkg cfg.sddmTheme cfg.sddmThemeFonts) ];
      })
    ]
  );
}
