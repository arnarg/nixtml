{
  modules,
  pkgs,
  lib ? pkgs.lib,
  specialArgs ? { },
}:
let
  extendedLib = import ../lib { inherit lib; };

  nixtmlModules = [
    ./nixtml.nix
    ./build.nix
    ./content.nix
    ./static.nix
    ./collections.nix
  ];

  module = lib.evalModules {
    modules = nixtmlModules ++ modules;
    specialArgs = {
      inherit pkgs;
      lib = extendedLib;
    };
  };
in
module.config.build.website
