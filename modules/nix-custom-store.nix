{ lib, inputs, ... }:
let
  overlay = inputs.nix.overlays.default;
in
{
  flake-file.inputs.nix.url = lib.mkDefault "github:dguibert/nix/pu";
  flake-file.inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.nix.inputs.git-hooks-nix.follows = "git-hooks-nix";
  flake-file.inputs.nix.inputs.flake-parts.follows = "flake-parts";
  flake-file.inputs.nix.inputs.flake-compat.follows = "git-hooks-nix/flake-compat";

  flake.overlays.nix-custom-store = overlay;
  pkgs.overlays = [ overlay ];
}
