{
  description = "Quickshell system stats widget";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Quickshell config directory, stored in the nix store
    mkConfig = pkgs: pkgs.runCommand "quickshell-stats-config" { } ''
      mkdir -p $out
      cp ${./.}/*.qml $out/
    '';
  in {
    packages = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      config = mkConfig pkgs;
      default = pkgs.writeShellScriptBin "quickshell-stats" ''
        export PATH=${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.bash ]}:$PATH
        exec ${pkgs.quickshell}/bin/quickshell -p ${mkConfig pkgs} "$@"
      '';
    });

    devShells = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      default = pkgs.mkShell {
        packages = [ pkgs.quickshell ];
      };
    });

    nixosModules.default = { config, pkgs, lib, ... }:
    let
      cfg = config.services.quickshell-stats;
    in {
      options.services.quickshell-stats = with lib; {
        enable = mkEnableOption "Quickshell system stats widget";
        position = mkOption {
          type = types.enum [ "bottom-right" "bottom-left" "top-right" "top-left" "center" ];
          default = "bottom-left";
          description = "Widget position on the screen";
        };
        fontSize = mkOption {
          type = types.ints.positive;
          default = 20;
          description = "Size of the values (other elements scale proportionally)";
        };
        interval = mkOption {
          type = types.ints.positive;
          default = 2000;
          description = "Refresh interval in milliseconds";
        };
        screens = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "DP-1" "HDMI-A-1" ];
          description = "Monitor names to show the widget on (see `hyprctl monitors`). Empty means all screens.";
        };
        gpu = mkOption {
          type = types.bool;
          default = false;
          description = "Show NVIDIA GPU and VRAM usage (requires hardware.nvidia)";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.quickshell ];

        # User service: needs access to the Wayland session (WAYLAND_DISPLAY etc.)
        systemd.user.services.quickshell-stats = {
          description = "Quickshell system stats widget";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          # tools called from the QML (df, sh, nvidia-smi)
          path = [ pkgs.coreutils pkgs.bash ]
            ++ lib.optional cfg.gpu config.hardware.nvidia.package.bin;
          environment = {
            STATS_POSITION = cfg.position;
            STATS_FONT_SIZE = toString cfg.fontSize;
            STATS_INTERVAL = toString cfg.interval;
            STATS_GPU = if cfg.gpu then "1" else "0";
            STATS_SCREENS = lib.concatStringsSep "," cfg.screens;
          };
          serviceConfig = {
            ExecStart = "${pkgs.quickshell}/bin/quickshell -p ${mkConfig pkgs}";
            Restart = "on-failure";
            RestartSec = "3";
          };
        };
      };
    };
  };
}
