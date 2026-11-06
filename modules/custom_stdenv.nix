{ lib, config, ... }:
let
  isNixStore = builtins.storeDir == "/nix/store";

  custom_config = {
    replaceStdenv = builtins.trace "custom_stdenv" import custom_stdenv/_stdenv.nix;
  };
  overlay = import ../overlays/custom_stdenv.nix;
  customStdenvModule = { ... }: {
    nixpkgs.config = custom_config;
    nixpkgs.overlays = [ overlay ];
  };
in
{

  options.custom_stdenv.enable = lib.mkOption {
    description = "Enable custom_stdenv pkgs";
    type = lib.types.bool;
    default = !isNixStore;
  };
  config = {
    pkgs = lib.mkIf config.custom_stdenv.enable {
      config = custom_config;
      overlays = [ overlay ];
    };

    flake.overlays = lib.mkIf config.custom_stdenv.enable {
      custom_stdenv = overlay;
    };
    flake.modules.nixos.custom_stdenv = customStdenvModule;
    flake.modules.homeManager.custom_stdenv = customStdenvModule;
  };
}
