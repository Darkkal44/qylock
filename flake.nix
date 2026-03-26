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

      # ---------------------------------------------------------------------------
      # mkQylockPkgs
      #
      # Produces the derivations and helper functions used by both the NixOS module
      # and the Home Manager module.  Called once per pkgs instance so that
      # cross-compilation and multi-host flakes work correctly.
      # ---------------------------------------------------------------------------
      mkQylockPkgs = pkgs: rec {

        # ── Quickshell lockscreen shell directory ─────────────────────────────
        # A store path containing:
        #   lock_shell.qml   — QML entry point for the Quickshell lockscreen
        #   shim/            — SddmShim.qml (mocks SDDM globals for qs)
        #   imports/         — Qt5→Qt6 compat shims (QtGraphicalEffects, QtMultimedia)
        #   themes_link/     — symlink into the flake source themes/ directory
        qylockShell = pkgs.runCommand "qylock-shell" { } ''
          mkdir -p $out
          cp ${self}/quickshell-lockscreen/lock_shell.qml $out/lock_shell.qml
          cp -r --no-preserve=mode,ownership \
            ${self}/quickshell-lockscreen/shim $out/shim
          cp -r --no-preserve=mode,ownership \
            ${self}/quickshell-lockscreen/imports $out/imports
          ln -s ${self}/themes $out/themes_link
        '';

        # ── qylock-lock script ────────────────────────────────────────────────
        # Wraps `quickshell` with the correct QML_IMPORT_PATH so that:
        #   • Real Qt6 modules (qtmultimedia, qt5compat) are found first.
        #   • The local compat shims are appended as a fallback.
        # The theme name is baked in at build time; users can override at runtime
        # by passing a different QS_THEME value before calling the script.
        mkLockScript =
          theme:
          pkgs.writeShellScriptBin "qylock-lock" ''
            # Real Qt6 modules first so shims don't shadow them (e.g. QtMultimedia).
            # qt5compat provides Qt5Compat.GraphicalEffects; our shims re-expose it
            # as the legacy QtGraphicalEffects 1.15 import name.
            export QML_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:${qylockShell}/imports''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
            export QML2_IMPORT_PATH="$QML_IMPORT_PATH"
            export QML_XHR_ALLOW_FILE_READ=1
            export QS_THEME="${theme}"
            exec ${pkgs.quickshell}/bin/quickshell -p ${qylockShell}/lock_shell.qml "$@"
          '';

        # ── SDDM theme package ────────────────────────────────────────────────
        # Installs a qylock theme under $out/share/sddm/themes/<leaf> and applies
        # all patches needed to make Qt5-targeting QML run under SDDM's Qt6 greeter.
        #
        # Why patches instead of QML_IMPORT_PATH?
        #   SDDM's greeter does not honour QML_IMPORT_PATH from the environment, so
        #   we cannot inject shim modules via the search path.  Dropping local
        #   component files into the theme root is the only reliable mechanism —
        #   QML resolves bare type names against the directory of the importing file
        #   before searching the module path.
        #
        # Patches applied (via sed, in-place on the copied theme):
        #   • QtGraphicalEffects 1.15  → Qt5Compat.GraphicalEffects
        #   • QtMultimedia 5.15        → QtMultimedia  (Qt6 bare import)
        #   • loops: MediaPlayer.Infinite → loops: -1
        #       MediaPlayer.Infinite is an enum on the real Qt module type; local
        #       shim components don't expose type-level enums, so we inline the
        #       value (-1 is Qt's universal "loop forever" sentinel).
        #   • VideoOutput.PreserveAspectCrop/Fit/Stretch → integer literals
        #       Same reason: VideoOutput.qml is a local shim, not a real module,
        #       so type-level enum references like VideoOutput.PreserveAspectCrop
        #       would be unresolved.  2/1/0 match Qt6's VideoOutput enum values.
        #   • Video { → QylockVideo {
        #       The bare name "Video" is exported by the real QtMultimedia module,
        #       which takes precedence over a local Video.qml shim when
        #       `import QtMultimedia` is in scope.  Renaming to QylockVideo ensures
        #       our shim (copied as QylockVideo.qml) is always used.
        #   • Connections { onFoo: } → Connections { function onFoo() {} }
        #       Qt6 deprecation; becomes a hard error in strict mode.
        #
        # Shims copied into the theme root:
        #   QylockVideo.qml  — wraps Qt6 MediaPlayer + VideoOutput for themes using
        #                       the Video {} convenience element (renamed to avoid
        #                       shadowing by the real QtMultimedia Video type)
        #   MediaPlayer.qml  — thin shim so themes referencing MediaPlayer directly
        #                       resolve the type without an explicit module import
        #   VideoOutput.qml  — same for VideoOutput
        mkSddmThemePkg =
          themePath:
          let
            safeName = builtins.replaceStrings [ "/" ] [ "-" ] themePath;
            themeLeaf = builtins.baseNameOf themePath;
          in
          pkgs.runCommand "qylock-sddm-${safeName}" { } ''
            mkdir -p $out/share/sddm/themes
            cp -r --no-preserve=mode,ownership \
              ${self}/themes/${themePath} $out/share/sddm/themes/

            find $out/share/sddm/themes -name "*.qml" -exec \
              sed -i \
                -e 's/import QtGraphicalEffects 1\.15/import Qt5Compat.GraphicalEffects/g' \
                -e 's/import QtMultimedia 5\.15/import QtMultimedia/g' \
                -e 's/loops: MediaPlayer\.Infinite/loops: -1/g' \
                -e 's/VideoOutput\.PreserveAspectCrop/2/g' \
                -e 's/VideoOutput\.PreserveAspectFit/1/g' \
                -e 's/VideoOutput\.Stretch/0/g' \
                -e 's/\bVideo {/QylockVideo {/g' \
                -e 's/onLoginFailed:/function onLoginFailed()/g' \
              {} +

            cp ${self}/quickshell-lockscreen/imports/QtMultimedia/Video.qml \
              $out/share/sddm/themes/${themeLeaf}/QylockVideo.qml
            cp ${self}/quickshell-lockscreen/imports/QtMultimedia/MediaPlayerShim.qml \
              $out/share/sddm/themes/${themeLeaf}/MediaPlayer.qml
            cp ${self}/quickshell-lockscreen/imports/QtMultimedia/VideoOutputShim.qml \
              $out/share/sddm/themes/${themeLeaf}/VideoOutput.qml
          '';

        # ── Patched SDDM package ──────────────────────────────────────────────
        # NixOS's Qt6-only SDDM build ships the greeter as `sddm-greeter-qt6` but
        # some internal SDDM code paths still look for the bare `sddm-greeter` name.
        # Adding the symlink here avoids a "requires missing sddm-greeter" warning
        # in the display-manager journal.
        sddmPatched = pkgs.kdePackages.sddm.overrideAttrs (old: {
          buildCommand = old.buildCommand + ''
            ln -s $out/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
          '';
        });

      };
    in
    {
      # ── packages ──────────────────────────────────────────────────────────────
      # packages.<s>.default  — qylock-lock script (Genshin theme baked in)
      # packages.<s>.shell    — raw Quickshell lockscreen store path
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

      # ── NixOS module ──────────────────────────────────────────────────────────
      # Add to your flake inputs, then:
      #
      #   programs.qylock = {
      #     enable    = true;
      #     theme     = "terraria";   # Quickshell lockscreen theme
      #     sddmTheme = "cyberpunk";  # optional: install + activate an SDDM theme
      #   };
      nixosModules.default = import ./modules/nixos.nix { inherit self mkQylockPkgs; };

      # ── Home Manager module ───────────────────────────────────────────────────
      # Add to your flake inputs, then:
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
            kdePackages.sddm       # sddm-greeter-qt6 test binary
            kdePackages.qt5compat  # Qt5Compat.GraphicalEffects compat layer
            qt6.qtmultimedia       # QtMultimedia (required by video themes)
            qt6.qtdeclarative      # QtQuick / QML engine
            qt6.qttools            # qmllint, qmlformat
            quickshell             # Quickshell lockscreen runner
            fzf                    # used by sddm.sh / quickshell.sh installers
          ];

          shellHook = ''
            # Real Qt6 modules come first so the shims don't shadow them.
            # qt5compat provides Qt5Compat.GraphicalEffects; the local imports/
            # directory re-exposes it under the legacy QtGraphicalEffects 1.15 name.
            export QML_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml:$PWD/quickshell-lockscreen/imports:$QML_IMPORT_PATH"

            # ── testTheme <theme-path> ──────────────────────────────────────
            # Applies the same Qt5→Qt6 patches and shim copies that mkSddmThemePkg
            # performs at build time, but targets a disposable temp directory so the
            # source tree is never touched.  This lets you test the exact post-patch
            # state without running a full `nix build`.
            #
            # Usage:
            #   testTheme Genshin
            #   testTheme cozytile/Cozy
            #   testTheme tui/Amber
            testTheme() {
              local theme="''${1:?Usage: testTheme <theme-path>}"
              local leaf
              leaf=$(basename "$theme")
              local tmp
              tmp=$(mktemp -d --suffix=-qylock-test)

              echo "  Copying themes/$theme → $tmp/$leaf"
              cp -r "$PWD/themes/$theme" "$tmp/"

              echo "  Applying Qt5→Qt6 patches..."
              find "$tmp/$leaf" -name "*.qml" -exec sed -i \
                -e 's/import QtGraphicalEffects 1\.15/import Qt5Compat.GraphicalEffects/g' \
                -e 's/import QtMultimedia 5\.15/import QtMultimedia/g' \
                -e 's/loops: MediaPlayer\.Infinite/loops: -1/g' \
                -e 's/VideoOutput\.PreserveAspectCrop/2/g' \
                -e 's/VideoOutput\.PreserveAspectFit/1/g' \
                -e 's/VideoOutput\.Stretch/0/g' \
                -e 's/\bVideo {/QylockVideo {/g' \
                -e 's/onLoginFailed:/function onLoginFailed()/g' \
              {} +

              echo "  Copying QtMultimedia shims..."
              cp quickshell-lockscreen/imports/QtMultimedia/Video.qml \
                "$tmp/$leaf/QylockVideo.qml"
              cp quickshell-lockscreen/imports/QtMultimedia/MediaPlayerShim.qml \
                "$tmp/$leaf/MediaPlayer.qml"
              cp quickshell-lockscreen/imports/QtMultimedia/VideoOutputShim.qml \
                "$tmp/$leaf/VideoOutput.qml"

              echo "  Launching sddm-greeter-qt6 --test-mode..."
              sddm-greeter-qt6 --test-mode --theme "$tmp/$leaf"

              rm -rf "$tmp"
            }

            echo "qylock dev shell"
            echo ""
            echo "  Test a patched SDDM theme (mirrors the Nix build):"
            echo "    testTheme Genshin"
            echo "    testTheme cozytile/Cozy"
            echo ""
            echo "  Test an unpatched theme directly (source tree):"
            echo "    sddm-greeter-qt6 --test-mode --theme \$PWD/themes/<n>"
            echo ""
            echo "  Run the Quickshell lockscreen:"
            echo "    quickshell -p \$PWD/quickshell-lockscreen"
            echo ""
          '';
        };
      });
    };
}
