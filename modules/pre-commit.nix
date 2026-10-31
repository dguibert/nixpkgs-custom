{
  inputs,
  ...
}:
{
  flake-file.inputs.git-hooks-nix.url = "github:cachix/git-hooks.nix";
  flake-file.inputs.git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";

  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    let
      isNixStore = builtins.storeDir == "/nix/store";
      pre-commit-check-shellHook = inputs.self.checks.${system}.pre-commit-check.shellHook;
      pre-commit-check-enabledPackages = inputs.self.checks.${system}.pre-commit-check.enabledPackages;
      name =
        if isNixStore then
          "pre-commit"
        else
          "pre-commit-${builtins.replaceStrings [ "/" ] [ "-" ] (builtins.dirOf builtins.storeDir)}";
    in
    {
      checks = {
        pre-commit-check = inputs.git-hooks-nix.lib.${system}.run {
          src = ./..;
          hooks = {
            nixfmt.enable = true;
            trailing-whitespace = {
              enable = true;
              name = "trim trailing whitespace";
              entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/trailing-whitespace-fixer";
              types = [ "text" ];
              stages = [
                "pre-commit"
                "pre-push"
                "manual"
              ];
            };
            check-merge-conflict = {
              enable = true;
              name = "check for merge conflicts";
              entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/check-merge-conflict";
              types = [ "text" ];
              stages = [
                "pre-commit"
                "pre-push"
              ];
            };
          };
        };
      };
      devShells.pre-commit = pkgs.mkShell rec {
        inherit name;
        ENVRC = name;

        buildInputs = [ ] ++ lib.optional isNixStore pre-commit-check-enabledPackages;
        shellHook = ''
          ${if isNixStore then pre-commit-check-shellHook else ""}

          unset NIX_INDENT_MAKE
          unset IN_NIX_SHELL NIX_REMOTE
        '';

      };
    };
}
