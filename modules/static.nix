{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.website = with lib; {
    static = {
      dir = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          Path to a directory with static content. All files will be copied to the final build derivation as is.
        '';
      };
    };
  };

  config = {
    build.extraPackages = lib.mkIf (config.website.static.dir != null) {
      staticPackage = pkgs.copyPathToStore config.website.static.dir;
    };
  };
}
