{ lib, config, ... }:
let
  isNixStore = builtins.storeDir == "/nix/store";

  custom_config = {
    replaceStdenv = builtins.trace "custom_stdenv" import custom_stdenv/_stdenv.nix;
  };
  dontCheck =
    pkg:
    pkg.overrideAttrs (o: {
      doCheck = false;
      doInstallCheck = false;
    });

  narHash =
    lib: pkg: version: hash:
    builtins.trace "${pkg.name} with new hash: ${hash}" upgradeOverride pkg (_: {
      inherit version;
      src = pkg.src.overrideAttrs (_: {
        outputHash = hash;
      });
    });

  composeOverlays = lib.foldl' lib.composeExtensions (self: super: { });
  upgradeOverride =
    package: overrides:
    let
      upgraded = package.overrideAttrs overrides;
    in
    (upgradeReplace package upgraded);

  upgradeReplace =
    package: upgraded:
    let
      upgradedVersion = (builtins.parseDrvName upgraded.name).version;
      originalVersion = (builtins.parseDrvName package.name).version;

      isDowngrade = (builtins.compareVersions upgradedVersion originalVersion) == -1;

      warn = builtins.trace "Warning: ${package.name} downgraded by overlay with ${upgraded.name}.";
      pass = x: x;
    in
    (if isDowngrade then warn else pass) upgraded;

  overlay = final: prev: {
      nss_sss = prev.callPackage ./custom_stdenv/_nss-client.nix { };

      whoami_ = builtins.derivation {
        name = "test";
        system = "aarch64-linux";
        #__noChroot = true;
        builder = prev.writeShellScript "builder.sh" ''
          export PATH=$PATH:${prev.coreutils}/bin
          cat /etc/passwd
          command -v whoami
          whoami
        '';
      };
      #bind = dontCheck prev.bind;
      #bmake = dontCheck prev.bmake;
      coreutils = dontCheck prev.coreutils;
      #dbus = dontCheck prev.dbus;
      #libffi = dontCheck prev.libffi;
      libuv = dontCheck prev.libuv;
      onetbb = dontCheck prev.onetbb; # needs Transparent huge pages

      #nix = dontCheck prev.nix; # build-remote-input-addressed.sh... [FAIL]
      #nixStable = dontCheck prev.nixStable; # build-remote-input-addressed.sh... [FAIL]
      #p11-kit = dontCheck prev.p11-kit;
      fish = dontCheck prev.fish;
      swtpm = dontCheck prev.swtpm;
      rsync = dontCheck prev.rsync; # FAIL    chgrp
      #watchman = (dontCheck prev.watchman).overrideAttrs (o: {
      #  buildInputs = o.buildInputs ++ [ prev.gtest ];
      #}); # CacheTest.future: malloc(): unaligned tcache chunk detected
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          datalad = upgradeOverride python-prev.datalad (finalAttrs: {
            version = "1.6.2";
            src = prev.fetchFromGitHub {
              owner = "datalad";
              repo = "datalad";
              tag = finalAttrs.version;
              hash = "sha256-uz1jTl90xFleQwZ4gFzOGsTXvxZSRMyGd0lIvFiBIMY="; # jupiter-fscratch
            };
          });
          psutil = python-prev.psutil.overrideAttrs (o: {
            disabledTests = o.disabledTests ++ [
              "test_heap_info"
            ];
          });
          mypy = dontCheck python-prev.mypy;
          numpy = dontCheck python-prev.numpy;
        })
      ];

      llvmPackages_21 = prev.llvmPackages_21.overrideScope (
        final: prev: {
          libllvm = dontCheck prev.libllvm;
        }
      );
    };
in
{

  options.custom_stdenv.enable = lib.mkOption {
    description = "Enable custom_stdenv pkgs";
    type = lib.types.bool;
    default = !isNixStore;
  };
  config = lib.mkIf config.custom_stdenv.enable {
    pkgs = {
      config = custom_config;
      overlays = [ overlay ];
    };

    flake.overlays.custom_stdenv = overlay;
    # https://flake.parts/system
    flake.aspects.custom_stdenv.nixos = {
      nixpkgs.config = custom_config;
      nixpkgs.overlays = [ overlay ];
    };

    flake.aspects.custom_stdenv.homeManager = {
      nixpkgs.config = custom_config;
      nixpkgs.overlays = [ overlay ];
    };
  };
}
