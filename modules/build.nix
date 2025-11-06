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
    };

    extraPackages = mkOption {
      type = with types; attrsOf package;
      default = { };
      description = "Extra packages that will be joined with the final website package.";
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
