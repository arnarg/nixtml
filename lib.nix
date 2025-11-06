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
      ++ imports;
    };
in
{
  inherit evalModules mkWebsite;
}
