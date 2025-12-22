{
  nixpkgs ? null,
}:
let
  # To not having to maintain versions of dependencies in 2 locations
  # we here read the flake.lock to parse revisions and hashes
  # for a select few dependencies.
  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);

  # Helper function to fetch metadata about a locked input.
  # Currently only fetches relevant information for github.
  flakeLockMeta =
    node:
    let
      lock = flakeLock.nodes.${node}.locked;
    in
    {
      inherit (lock)
        owner
        repo
        rev
        type
        ;
      hash = lock.narHash;
    };

  # Import nixpkgs from either parameter or the lock file.
  pkgs =
    let
      meta = flakeLockMeta "nixpkgs";
      npkgs =
        if nixpkgs == null then
          builtins.fetchTarball {
            url = "https://github.com/${meta.owner}/${meta.repo}/archive/${meta.rev}.tar.gz";
            sha256 = meta.hash;
          }
        else
          nixpkgs;
    in
    import npkgs { };

  nlib = import ./lib.nix;

  evalModules =
    {
      modules,
      lib ? pkgs.lib,
      specialArgs ? { },
    }:
    nlib.evalModules {
      inherit
        pkgs
        lib
        modules
        specialArgs
        ;
    };
in
{
  lib = {
    inherit evalModules;

    mkWebsite =
      {
        name,
        baseURL,
        metadata ? { },
        content ? { },
        static ? { },
        collections ? { },
        layouts ? { },
        imports ? [ ],
      }:
      evalModules {
        modules = [
          {
            website = {
              inherit
                name
                baseURL
                metadata
                content
                static
                collections
                layouts
                ;
            };
          }
        ]
        ++ imports;
      };
  };
}
