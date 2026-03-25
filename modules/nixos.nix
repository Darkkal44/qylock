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
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ (q.mkLockScript cfg.theme) ];
      }

      (lib.mkIf (cfg.sddmTheme != null) {
        services.displayManager.sddm.theme = lib.last (lib.splitString "/" cfg.sddmTheme);

        services.displayManager.sddm.package = q.sddmPatched;

        # QtGraphicalEffects 1.15 (used by all qylock SDDM themes) is a Qt5 shim
        # that lives in qt5compat under Qt6. Without this, SDDM's QML engine can't
        # resolve the import and silently falls back to the default theme.
        services.displayManager.sddm.extraPackages = [ pkgs.kdePackages.qt5compat ];

        environment.systemPackages = [ (q.mkSddmThemePkg cfg.sddmTheme) ];
      })
    ]
  );
}
