let
  evalModules = import ./modules;
  mkWebsite =
    {
      pkgs,
      name,
      baseURL,
      metadata ? { },
      content ? { },
      static ? { },
      collections ? { },
      layouts ? { },
      themes ? { },
      imports ? [ ],
    }:
    evalModules {
      inherit pkgs;
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
      ++ imports
      ++ pkgs.lib.optional (themes != { }) { inherit themes; };
    };
in
{
  inherit evalModules mkWebsite;
}
