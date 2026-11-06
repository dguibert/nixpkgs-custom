{ ... }@args:
let
  # Load the flake in the current directory
  flake = builtins.getFlake (toString (/. + builtins.unsafeDiscardStringContext ./.));
  nixpkgs = flake.inputs.nixpkgs;
  lib = nixpkgs.lib;
  config = { };
  overlays = lib.attrsets.attrValues flake.overlays;
in
import nixpkgs.outPath (
  args
  // {
    config = config // (args.config or { });
    overlays = overlays ++ (args.overlays or [ ]);
  }
)
