{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];

  flake-file.description = "Nixpkgs with custom patches to be used as upstream nixpkgs in flakes";
}
