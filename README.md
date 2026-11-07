# Quickshell Stats

Desktop system stats widget (CPU, RAM, disk, optional NVIDIA GPU) using Quickshell, in the same style as [quickshell-clock-widget](https://github.com/cedev-1/quickshell-clock-widget). No extra dependencies: values come from `/proc`, `df`, `/sys/class/hwmon` and, optionally, `nvidia-smi`.

## Try it

```sh
nix run github:cedev-1/quickshell-stats
```

## NixOS

Add the input to your system `flake.nix` and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell-stats = {
      url = "github:cedev-1/quickshell-stats";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, quickshell-stats, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        quickshell-stats.nixosModules.default
      ];
    };
  };
}
```

Then enable it in your configuration:

```nix
services.quickshell-stats = {
  enable = true;
  position = "bottom-left";
  gpu = true; # NVIDIA only
  screens = [ "DP-1" ]; # omit for all screens
};
```

The widget runs as a systemd **user** service bound to `graphical-session.target`. If you start Hyprland without UWSM, that target may not be active: enable `programs.hyprland.withUWSM` or add `exec-once = systemctl --user start quickshell-stats` to your Hyprland config.

Options:
- `position` - `bottom-left` (default), `bottom-right`, `top-right`, `top-left`, `center`
- `fontSize` - Size of the values (default: 20). Everything else scales proportionally.
- `interval` - Refresh interval in milliseconds (default: 2000)
- `screens` - List of monitor names to show the widget on, e.g. `[ "DP-1" "HDMI-A-1" ]` (find them with `hyprctl monitors`). Empty (default) means all screens.
- `gpu` - Show NVIDIA GPU and VRAM usage via `nvidia-smi` (default: false, requires `hardware.nvidia`)

The CPU temperature is read from the first `k10temp`, `coretemp` or `zenpower` sensor.
