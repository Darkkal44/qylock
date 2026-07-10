{
  description = "qylock — SDDM and Quickshell lockscreen themes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }:
    let
      # Apply per-theme variant tweaks (theme.conf edits) inside a derivation.
      # `themeOptions` shape mirrors what the bash installers prompted for.
      mkConfEdits = themeOptions:
        let
          opt = name: themeOptions.${name} or { };
          terraria = opt "terraria";
          genshin = opt "Genshin";
          clockworkOrbital = (opt "clockwork").orbital or { };
          clockworkTape = (opt "clockwork").tape or { };
          osu = opt "osu";
          osumania = opt "osumania";
          sed = file: pat: ''
            if [ -f "${file}" ]; then sed -i "${pat}" "${file}"; fi
          '';
        in ''
          ${nixpkgs.lib.optionalString (terraria ? backgroundMode)
            (sed "themes/terraria/theme.conf"
              "s/^background_mode=.*/background_mode=${terraria.backgroundMode}/")}
          ${nixpkgs.lib.optionalString (terraria ? backgroundIndex)
            (sed "themes/terraria/theme.conf"
              "s/^background_index=.*/background_index=${toString terraria.backgroundIndex}/")}
          ${nixpkgs.lib.optionalString (genshin ? backgroundMode)
            (sed "themes/Genshin/theme.conf"
              "s/^background_mode=.*/background_mode=${genshin.backgroundMode}/")}
          ${nixpkgs.lib.optionalString (genshin ? backgroundIndex)
            (sed "themes/Genshin/theme.conf"
              "s/^background_index=.*/background_index=${toString genshin.backgroundIndex}/")}
          ${nixpkgs.lib.optionalString (clockworkOrbital ? themeMode)
            (sed "themes/clockwork/orbital/theme.conf"
              "s/^themeMode=.*/themeMode=${clockworkOrbital.themeMode}/")}
          ${nixpkgs.lib.optionalString (clockworkOrbital ? enableWindup)
            (sed "themes/clockwork/orbital/theme.conf"
              "s/^enableWindup=.*/enableWindup=${if clockworkOrbital.enableWindup then "true" else "false"}/")}
          ${nixpkgs.lib.optionalString (clockworkTape ? themeMode)
            (sed "themes/clockwork/tape/theme.conf"
              "s/^themeMode=.*/themeMode=${clockworkTape.themeMode}/")}
          ${nixpkgs.lib.optionalString (osu ? gameMode)
            (sed "themes/osu/theme.conf"
              "s/^gameMode=.*/gameMode=${osu.gameMode}/")}
          ${nixpkgs.lib.optionalString (osumania ? gameMode)
            (sed "themes/osumania/theme.conf"
              "s/^gameMode=.*/gameMode=${osumania.gameMode}/")}
        '';
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        mkSddmThemes = { themeOptions ? { } }:
          pkgs.stdenvNoCC.mkDerivation {
            pname = "qylock-sddm-themes";
            version = "unstable";
            src = ./.;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              ${mkConfEdits themeOptions}
              mkdir -p $out/share/sddm/themes
              cp -r themes/. $out/share/sddm/themes/
              runHook postInstall
            '';
            meta.description = "qylock SDDM lockscreen themes";
          };

        mkQuickshell = { defaultTheme ? "nier-automata", themeOptions ? { } }:
          pkgs.stdenvNoCC.mkDerivation {
            pname = "qylock-quickshell";
            version = "unstable";
            src = ./.;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              ${mkConfEdits themeOptions}

              mkdir -p $out/share/qylock
              cp -r quickshell-lockscreen/. $out/share/qylock/
              cp -r themes $out/share/qylock/themes

              mkdir -p $out/bin
              qmlPath="${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtsvg}/lib/qt-6/qml"

              makeWrapper $out/share/qylock/lock.sh $out/bin/qylock-lock \
                --set-default QS_THEME "${defaultTheme}" \
                --set QYLOCK_THEMES_ROOT "$out/share/qylock/themes" \
                --suffix QML2_IMPORT_PATH : "$qmlPath" \
                --suffix QML_IMPORT_PATH : "$qmlPath" \
                --prefix PATH : ${pkgs.lib.makeBinPath [
                  pkgs.quickshell
                  pkgs.psmisc
                  pkgs.systemd
                  pkgs.coreutils
                ]}

              # Patch lock.sh so it (1) resolves the theme path from the wrapper's
              # QYLOCK_THEMES_ROOT instead of ../themes or themes_link, and
              # (2) honours the env-provided QS_THEME (with $1 still overriding)
              # instead of clobbering it via ~/.config/qylock/theme or a
              # hardcoded fallback.
              substituteInPlace $out/share/qylock/lock.sh \
                --replace-fail \
                  'CONFIG_FILE="$HOME/.config/qylock/theme"
if [ -n "$1" ]; then
    export QS_THEME="$1"
elif [ -f "$CONFIG_FILE" ]; then
    export QS_THEME=$(cat "$CONFIG_FILE")
else
    export QS_THEME="nier-automata"
fi' \
                  'if [ -n "$1" ]; then export QS_THEME="$1"; fi' \
                --replace-fail \
                  'if [ -d "$DIR/../themes" ] && [ ! -d "$DIR/themes_link" ]; then
    export QS_THEME_PATH="$DIR/../themes/$QS_THEME"
else
    export QS_THEME_PATH="$DIR/themes_link/$QS_THEME"
fi' \
                  'export QS_THEME_PATH="$QYLOCK_THEMES_ROOT/$QS_THEME"'

              runHook postInstall
            '';
            meta = {
              description = "qylock Quickshell lockscreen wrapper";
              mainProgram = "qylock-lock";
            };
          };
      in {
        packages = {
          qylock-sddm-themes = mkSddmThemes { };
          qylock-quickshell = mkQuickshell { };
          default = mkQuickshell { };
        };

        # Expose builders so the NixOS module can pass user options through.
        legacyPackages = {
          inherit mkSddmThemes mkQuickshell;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            quickshell
            qt6.qtdeclarative
            qt6.qt5compat
            qt6.qtsvg
            qt6.qtmultimedia
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
            fzf
          ];
        };
      }) // {
        nixosModules.default = { config, lib, pkgs, ... }:
          let
            cfg = config.programs.qylock;
            builders = self.legacyPackages.${pkgs.stdenv.hostPlatform.system};
            sddmPkg = builders.mkSddmThemes { themeOptions = cfg.themeOptions; };
            qsPkg = builders.mkQuickshell {
              defaultTheme = cfg.theme;
              themeOptions = cfg.themeOptions;
            };
          in {
            options.programs.qylock = {
              enable = lib.mkEnableOption "qylock lockscreen themes";
              theme = lib.mkOption {
                type = lib.types.str;
                default = "nier-automata";
                description = "Theme directory name under themes/ to activate.";
              };
              sddm.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Install SDDM themes and set the active theme.";
              };
              quickshell.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Install the Quickshell lockscreen wrapper (qylock-lock).";
              };
              themeOptions = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                example = lib.literalExpression ''
                  {
                    clockwork.orbital = { themeMode = "light"; enableWindup = false; };
                    terraria = { backgroundMode = "time"; };
                  }
                '';
                description = "Per-theme tweaks applied to theme.conf at build time.";
              };
            };

            config = lib.mkIf cfg.enable (lib.mkMerge [
              (lib.mkIf cfg.sddm.enable {
                services.displayManager.sddm.theme = cfg.theme;
                services.displayManager.sddm.extraPackages = [
                  sddmPkg
                  # QML modules the themes import (e.g. Qt5Compat.GraphicalEffects).
                  # extraPackages contributes lib/qt-6/qml to the greeter's QML_IMPORT_PATH.
                  pkgs.qt6.qt5compat
                  pkgs.qt6.qtmultimedia
                  pkgs.qt6.qtsvg
                ];
                environment.systemPackages = [ sddmPkg ];
              })
              (lib.mkIf cfg.quickshell.enable {
                environment.systemPackages = [ qsPkg ];
              })
            ]);
          };
      };
}
