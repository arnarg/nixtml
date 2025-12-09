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

  options =
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
    }).options;

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
          ---
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

  optsHTML =
    let
      py = pkgs.python3.withPackages (
        ps:
        with ps;
        [
          markdown
          pymdown-extensions
          pyyaml
          pygments
        ]
        ++ config.website.content.mdProcessor.extraPythonPackages
      );

      options = pkgs.writeText "content-options-doc.json" (
        builtins.toJSON {
          inherit (config.website.content) dateFormat;
          settings = config.website.content.mdProcessor.settings;
        }
      );

      markdown = pkgs.writeText "content-options-doc.md" optsMd;

      jsonData = pkgs.runCommand "content-data-doc-processed.json" { } ''
        ${py}/bin/python ${../modules/processContent.py} ${toString markdown} ${toString options} > $out
      '';

      contentData = lib.importJSON jsonData;
    in
    {
      inherit (contentData) metadata content;
    };
in
{
  website.pages."options" = {
    layout = config.website.layouts.page;
    extraContext = {
      inherit (optsHTML) content metadata;
      title = optsHTML.metadata.title;
    };
  };
}
