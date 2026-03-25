{
  description = "qylock — SDDM theme collection dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: builtins.listToAttrs (map (system: {
        name = system;
        value = f nixpkgs.legacyPackages.${system};
      }) systems);
    in {
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # SDDM (Qt6 based, 0.21+)
            kdePackages.sddm

            # Qt6 QML runtime
            kdePackages.qt5compat           # provides QtGraphicalEffects 1.15 compat shim for Qt6
            qt6.qtmultimedia                # QtMultimedia (video themes)
            qt6.qtdeclarative               # QtQuick, QML engine
            qt6.qttools                     # qmllint, qmlformat

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
