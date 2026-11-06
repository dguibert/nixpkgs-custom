{ ... }@args:
let
  # Load the flake in the current directory
  # builtins.getFlake (builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?dir=a/b&narHash=...")
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  getInput =
    name:
    let
      node = lock.nodes.${lock.nodes.root.inputs.${name}};
    in
    builtins.getFlake (builtins.flakeRefToString node.locked);
  nixpkgs = getInput "nixpkgs";
  nix = getInput "nix";
  config = { };
  customStdenvOverlays =
    if builtins.storeDir == "/nix/store" then [ ] else [ (import ./overlays/custom_stdenv.nix) ];
  overlays = customStdenvOverlays ++ [ nix.overlays.default ];
in
import nixpkgs.outPath (
  args
  // {
    config = config // (args.config or { });
    overlays = overlays ++ (args.overlays or [ ]);
  }
)
