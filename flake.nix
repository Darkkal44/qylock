{
  description = "qylock — SDDM theme collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f nixpkgs.legacyPackages.${system};
          }) systems
        );

      # Builds the Quickshell lockscreen shell directory for a given pkgs.
      # The resulting store path contains the QML entry point, shims, and a
      # themes_link/ symlink that resolves into the flake source.
      mkQylockPkgs = pkgs: rec {
        qylockShell = pkgs.runCommand "qylock-shell" { } ''
          mkdir -p $out
          cp ${self}/quickshell-lockscreen/lock_shell.qml $out/lock_shell.qml
          cp -r --no-preserve=mode,ownership \
            ${self}/quickshell-lockscreen/shim $out/shim
          cp -r --no-preserve=mode,ownership \
            ${self}/quickshell-lockscreen/imports $out/imports
          ln -s ${self}/themes $out/themes_link
        '';

        # Produces a `qylock-lock` script with the given theme baked in.
        mkLockScript =
          theme:
          pkgs.writeShellScriptBin "qylock-lock" ''
            # QML_IMPORT_PATH: real Qt6 modules first, then the compatibility shims
            export QML_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:${qylockShell}/imports''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
            export QML2_IMPORT_PATH="$QML_IMPORT_PATH"
            export QML_XHR_ALLOW_FILE_READ=1
            export QS_THEME="${theme}"
            exec ${pkgs.quickshell}/bin/quickshell -p ${qylockShell}/lock_shell.qml "$@"
          '';

        # Produces an SDDM theme package for the given theme path (e.g. "cyberpunk"
        # or "cozytile/Cozy"). The package installs the theme under
        # $out/share/sddm/themes/<last-component>.
        # Patches QtGraphicalEffects import for Qt6
        mkSddmThemePkg =
          themePath:
          let
            safeName = builtins.replaceStrings [ "/" ] [ "-" ] themePath;
          in
          pkgs.runCommand "qylock-sddm-${safeName}" { } ''
            mkdir -p $out/share/sddm/themes
            cp -r --no-preserve=mode,ownership \
              ${self}/themes/${themePath} $out/share/sddm/themes/
            find $out/share/sddm/themes -name "*.qml" -exec \
              sed -i 's/import QtGraphicalEffects 1\.15/import Qt5Compat.GraphicalEffects/g' {} +
          '';

        # SDDM patched to add sddm-greeter symlink so Qt6-only NixOS builds
        # pass the theme validation check (which looks for sddm-greeter by name).
        sddmPatched = pkgs.runCommand "sddm-greeter-compat" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
          mkdir -p $out/bin
          ln -s ${pkgs.kdePackages.sddm}/bin/sddm $out/bin/sddm
          ln -s ${pkgs.kdePackages.sddm}/bin/sddm-greeter-qt6 $out/bin/sddm-greeter-qt6
          ln -s ${pkgs.kdePackages.sddm}/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
        '';

      };
    in
    {
      # ── packages ─────────────────────────────────────────────────────────────
      # `packages.<system>.default`  — qylock-lock script (Genshin theme)
      # `packages.<system>.shell`    — raw Quickshell lockscreen directory
      packages = forEachSystem (
        pkgs:
        let
          q = mkQylockPkgs pkgs;
        in
        {
          default = q.mkLockScript "Genshin";
          shell = q.qylockShell;
        }
      );

      # ── NixOS module ─────────────────────────────────────────────────────────
      # Usage:
      #   inputs.qylock.nixosModules.default
      #
      #   programs.qylock = {
      #     enable = true;
      #     theme  = "terraria";        # quickshell lockscreen theme
      #     sddmTheme = "cyberpunk";    # optional: also configure SDDM
      #   };
      nixosModules.default = import ./modules/nixos.nix { inherit self mkQylockPkgs; };

      # ── Home Manager module ───────────────────────────────────────────────────
      # Usage:
      #   inputs.qylock.homeManagerModules.default
      #
      #   programs.qylock = {
      #     enable = true;
      #     theme  = "terraria";
      #   };
      homeManagerModules.default = import ./modules/home-manager.nix { inherit self mkQylockPkgs; };

      # ── dev shell ─────────────────────────────────────────────────────────────
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # SDDM (Qt6 based, 0.21+)
            kdePackages.sddm

            # Qt6 QML runtime
            kdePackages.qt5compat # provides QtGraphicalEffects 1.15 compat shim for Qt6
            qt6.qtmultimedia # QtMultimedia (video themes)
            qt6.qtdeclarative # QtQuick, QML engine
            qt6.qttools # qmllint, qmlformat

            # Quickshell lockscreen
            quickshell

            # Install script deps
            fzf
          ];

          shellHook = ''
            # Real Qt6 modules come first so the shims don't shadow them (e.g. QtMultimedia)
            # Qt5Compat provides Qt5Compat.GraphicalEffects, shims expose it as QtGraphicalEffects 1.15
            export QML_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:$PWD/quickshell-lockscreen/imports:$QML_IMPORT_PATH"

            echo "qylock dev shell"
            echo ""
            echo "  Test an SDDM theme:"
            echo "    sddm-greeter-qt6 --test-mode --theme \$PWD/themes/<name>"
            echo ""
            echo "  Run quickshell lockscreen:"
            echo "    quickshell -p \$PWD/quickshell-lockscreen"
            echo ""
          '';
        };
      });
    };
}
