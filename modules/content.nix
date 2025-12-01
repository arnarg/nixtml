{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.website.content) dateFormat;

  processContent =
    name: path: dateFormat:
    let
      py = pkgs.python3.withPackages (
        ps: with ps; [
          markdown
          pymdown-extensions
          pyyaml
          pygments
        ]
      );

      options = pkgs.writeText "content-options-${name}.json" (
        builtins.toJSON {
          inherit (config.website.content) dateFormat;
          settings = config.website.content.mdProcessor.settings;
        }
      );

      jsonData = pkgs.runCommand "content-data-${name}.json" { } ''
        ${py}/bin/python ${./processContent.py} ${toString path} ${toString options} > $out
      '';

      contentData = lib.importJSON jsonData;
    in
    {
      inherit (contentData) metadata content;
    };

  readContentDir =
    dir:
    let
      readMDDir =
        dir:
        lib.filterAttrs (
          name: type: type == "directory" || (type == "regular" && lib.hasSuffix ".md" name)
        ) (builtins.readDir dir);

      walkDir =
        prefix: dir:
        lib.concatMapAttrs (
          name: type:
          let
            key = if type == "regular" then lib.substring 0 ((lib.stringLength name) - 3) name else name;
          in
          {
            ${key} = if type == "regular" then "${prefix}/${dir}/${name}" else walkDir "${prefix}/${dir}" name;
          }
        ) (readMDDir "${prefix}/${dir}");
    in
    lib.concatMapAttrs (
      name: type:
      let
        key = if type == "regular" then lib.substring 0 ((lib.stringLength name) - 3) name else name;
      in
      {
        ${key} = if type == "regular" then "${dir}/${name}" else walkDir "${dir}" name;
      }
    ) (readMDDir dir);
in
{
  options.website = with lib; {
    content = {
      dir = mkOption {
        type = types.path;
        description = "Path to a directory with markdown content.";
      };

      dateFormat = mkOption {
        type = types.str;
        default = "%b %-d, %Y";
        description = ''
          Format string for any datetime in content front matter.

          This is a format string for python's `strftime`. See: https://docs.python.org/3/library/datetime.html#strftime-strptime-behavior
        '';
      };

      mdProcessor = {
        settings.highlight.style = mkOption {
          type = types.str;
          default = "default";
          description = ''
            The pygments style to use for code block colorscheme.
          '';
        };
      };

      content =
        let
          recType = with types; either path (attrsOf path);
        in
        mkOption {
          type = types.attrsOf recType;
          internal = true;
        };

      output = mkOption {
        type =
          with types;
          attrsOf (
            submodule (
              { name, config, ... }:
              {
                options = {
                  filepath = mkOption {
                    type = types.path;
                  };

                  result = {
                    metadata = mkOption {
                      type = with types; attrsOf anything;
                      default = { };
                    };
                    content = mkOption {
                      type = types.str;
                    };
                  };
                };

                config = {
                  result = processContent (lib.concatStringsSep "-" (
                    lib.splitString "/" name
                  )) config.filepath dateFormat;
                };
              }
            )
          );
        default = { };
        internal = true;
      };
    };
  };

  config = {
    website = {
      content = {
        content = readContentDir config.website.content.dir;
        output = lib.listToAttrs (
          lib.mapAttrsToListRecursive (path: x: {
            name = "${lib.concatStringsSep "/" path}";
            value.filepath = x;
          }) config.website.content.content
        );
      };

      pages = lib.concatMapAttrs (name: value: {
        "${name}" = {
          extraContext = {
            inherit (value.result) metadata content;
            title = value.result.metadata.title or null;
          };
          lastModified = value.result.metadata.dateW3C or null;
          layout = if name == "index" then config.website.layouts.home else config.website.layouts.page;
        };
      }) config.website.content.output;
    };
  };
}
