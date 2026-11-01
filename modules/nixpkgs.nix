{
  config,
  lib,
  inputs,
  ...
}:
let
  overlays = builtins.attrValues config.flake.overlays;

  nixpkgs_config = {
    allowUnfree = true;
  };

  #packages = system: inputs.nixpkgs.legacyPackages.${system}.appendOverlays overlays;
  packages =
    system:
    import inputs.nixpkgs {
      localSystem.system = system;
      overlays = config.pkgs.overlays;
      config = config.pkgs.config;
    };
in
{
  options.pkgs = {
    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = {
        allowUnfree = true;
      };
    };
    overlays = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };
  };

  config = {
    flake-file.inputs = {
      nixpkgs.url = "github:dguibert/nixpkgs/pu";
    };

    # export upstream nixpkgs.lib
    flake.lib = inputs.nixpkgs.lib;

    pkgs.config = nixpkgs_config;
    pkgs.overlays = overlays;

    _module.args.pkgs = builtins.trace "pkgs" packages (builtins.currentSystem or "x86_64-linux");
    #  config._module.args.pkgs = packages config system;
    # https://flake.parts/system
    flake.aspects.nixpkgs.flakeModule = {
      nixpkgs.config = config.pkgs.config;
      nixpkgs.overlays = config.pkgs.overlays;
    };

    flake.aspects.nixpkgs.nixos = {
      nixpkgs.config = config.pkgs.config;
      nixpkgs.overlays = config.pkgs.overlays;
    };

    flake.aspects.nixpkgs.homeManager = {
      nixpkgs.config = config.pkgs.config;
      nixpkgs.overlays = config.pkgs.overlays;
    };

    perSystem =
      {
        system,
        config,
        ...
      }:
      {
        _module.args.pkgs = builtins.trace "pkgs in perSystem" packages system;
        legacyPackages = packages system;
      };
  };
}
