{ self, mkQylockPkgs }:
{ config, lib, pkgs, ... }:

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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ (q.mkLockScript cfg.theme) ];
  };
}
