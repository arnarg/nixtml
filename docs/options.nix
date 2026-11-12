{
  lib,
  pkgs,
  config,
  ...
}:
let
  nixtmlPath = toString ./..;

  # Borrowed from home-manager :)
  gitHubDeclaration = user: repo: subpath: {
    url = "https://github.com/${user}/${repo}/blob/main/${subpath}";
    name = "${repo}/${subpath}";
  };

  inherit
    (lib.evalModules {
      modules = [
        ../modules/nixtml.nix
        ../modules/build.nix
        ../modules/content.nix
        ../modules/static.nix
        ../modules/collections.nix
      ];
      specialArgs = {
        inherit lib pkgs;
      };
    })
    options
    ;

  optionsDoc = pkgs.buildPackages.nixosOptionsDoc {
    options = removeAttrs options [ "_module" ];
    transformOptions =
      opt:
      opt
      // {
        declarations = map (
          decl:
          if lib.hasPrefix nixtmlPath (toString decl) then
            gitHubDeclaration "arnarg" "nixtml" (
              lib.removePrefix "/" (lib.removePrefix nixtmlPath (toString decl))
            )
          else if decl == "lib/modules.nix" then
            gitHubDeclaration "NixOS" "nixpkgs" decl
          else
            decl
        ) opt.declarations;
      };
  };

  optsMd =
    with lib;
    concatStringsSep "\n" (
      [
        ''
          ---
          title: Configuration Options
          description: Generated reference for the options exposed by nixtml's modules
          nav:
            section: reference
            order: 40
            label: Configuration options
          ---

          This reference is generated directly from nixtml's module options. In an imported module, use the full option names shown below. `mkWebsite` exposes common `website` settings as top-level arguments such as `content`, `collections`, and `layouts`.

          Use the table of contents to jump to an option. Heading permalinks provide direct section links, and each option's “Declared by” entries link to its source repository.

          [TOC]
        ''
      ]
      ++ (mapAttrsToList (
        n: opt:
        ''
          ## ${lib.escapeHTML n}

          ${if opt.description != null then opt.description else ""}

          ***Type:***
          ${opt.type}

        ''
        + (lib.optionalString (hasAttrByPath [ "default" "text" ] opt) ''
          ***Default:***
          `#!nix ${opt.default.text}`

        '')
        + (lib.optionalString (hasAttrByPath [ "example" "text" ] opt) (
          ''
            ***Example:***
          ''
          + (
            if
              (hasPrefix "attribute set" opt.type)
              || (hasPrefix "list of" opt.type)
              || (hasPrefix "function" opt.type)
            then
              ''

                ```nix
                ${opt.example.text}
                ```

              ''
            else
              ''
                `#!nix ${opt.example.text}`

              ''
          )
        ))
        + (
          if (length opt.declarations > 0) then
            ''
              ***Declared by:***

              ${concatStringsSep "\n" (
                map (decl: ''
                  - [&lt;${decl.name}&gt;](${decl.url})
                '') opt.declarations
              )}
            ''
          else
            ""
        )
      ) optionsDoc.optionsNix)
    );
in
{
  website.content.pages."options" = {
    text = optsMd;
    processor = "md";
  };
}
