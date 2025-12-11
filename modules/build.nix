{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.build = with lib; {
    filesPackage = mkOption {
      type = types.package;
      description = "A package containing all files from `config.website.files`.";
      internal = true;
    };

    extraPackages = mkOption {
      type = with types; attrsOf package;
      default = { };
      description = "Extra packages that will be joined with the final website package.";
      example = literalExpression ''
        {
          stylesheetPackage =
              let
                bulma = pkgs.fetchFromGitHub {
                  owner = "jgthms";
                  repo = "bulma";
                  rev = "1.0.4";
                  hash = "sha256-hlejqBI6ayzhm15IymrzhTevkl3xffMfdTasZ2CmAas=";
                };
          
                deps = pkgs.linkFarm "nixtml-docs-stylesheet-deps" [
                  {
                    name = "bulma";
                    path = bulma;
                  }
                ];
              in
              pkgs.stdenv.mkDerivation {
                name = "nixtml-docs-stylesheet";
          
                src = ./stylesheet;
          
                buildInputs = with pkgs; [
                  dart-sass
                ];
          
                buildPhase = '''
                  sass --load-path "''${deps}" main.scss main.css
                ''';
          
                installPhase = '''
                  mkdir -p $out/css
          
                  cp main.css $out/css/main.css
                ''';
              };
        }
      '';
    };

    website = mkOption {
      type = types.package;
      description = "Final built website package.";
    };
  };

  config = {
    build = {
      filesPackage =
        let
          rendered = lib.mapAttrsToList (_: file: {
            name = file.path;
            path = file.source;
          }) config.website.files;
        in
        pkgs.linkFarm "nixtml-${config.website.name}-files" rendered;

      website = pkgs.symlinkJoin {
        name = "nixtml-${config.website.name}-website";
        paths = [
          config.build.filesPackage
        ]
        ++ (lib.mapAttrsToList (_: pkg: pkg) config.build.extraPackages);
      };
    };
  };
}
