{
  description = "Static website generator implemented in nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      lib = import ./lib.nix;
      libTests = import ./lib/tests.nix { nixpkgslib = nixpkgs.lib; };
    }
    // (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          docs = self.lib.evalModules {
            inherit pkgs;
            modules = [ ./docs ];
          };
          examples = {
            simple = self.lib.evalModules {
              inherit pkgs;
              modules = [ ./examples/simple ];
            };
            blog = self.lib.evalModules {
              inherit pkgs;
              modules = [ ./examples/blog ];
            };
          };
        };

        apps = {
          # Runs lib unit tests
          libTests = {
            type = "app";
            program =
              (pkgs.writeShellScript "lib-unit-tests" ''
                set -eo pipefail

                ${pkgs.nix-unit}/bin/nix-unit \
                  --extra-experimental-features flakes \
                  --flake "${self}#libTests"
              '').outPath;
          };

          # Runs statix for linting the nix code
          staticCheck = {
            type = "app";
            program =
              (pkgs.writeShellScript "static-lint-check" ''
                set -eo pipefail

                ${pkgs.statix}/bin/statix check .
              '').outPath;
          };

          # Quickly build and serve docs
          serveDocs = {
            type = "app";
            program =
              (pkgs.writeShellScript "serve-docs" ''
                ${pkgs.python3}/bin/python -m http.server -d ${self.packages.${system}.docs} 8080
              '').outPath;
          };
        };
      }
    ));
}
