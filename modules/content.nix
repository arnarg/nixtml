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
        settings = {
          toc = {
            marker = mkOption {
              type = types.str;
              default = "[TOC]";
              description = ''
                Text to find and replace with the Table of Contents.

                Set to an empty string to disable searching for a marker, which may save some time, especially on long documents.
              '';
            };
            title = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                Title to insert in the Table of Contents’ `<div>`.
              '';
            };
            titleClass = mkOption {
              type = types.str;
              default = "toctitle";
              description = ''
                CSS class used for the title contained in the Table of Contents.
              '';
            };
            tocClass = mkOption {
              type = types.str;
              default = "toc";
              description = ''
                CSS class(es) used for the `<div>` containing the Table of Contents.
              '';
            };
            anchorlink = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Set to `true` to cause all headers to link to themselves.
              '';
            };
            anchorlinkClass = mkOption {
              type = types.str;
              default = "toclink";
              description = ''
                CSS class(es) used for the link.
              '';
            };
            permalink = mkOption {
              type = with types; either bool str;
              default = false;
              description = ''
                Set to True or a string to generate permanent links at the end of each header. Useful with Sphinx style sheets.

                When set to `true` the paragraph symbol (¶ or “`&para;`”) is used as the link text. When set to a string, the provided string is used as the link text.
              '';
            };
            permalinkClass = mkOption {
              type = types.str;
              default = "headerlink";
              description = ''
                CSS class(es) used for the link.
              '';
            };
          };
          highlight = {
            style = mkOption {
              type = types.str;
              default = "default";
              description = ''
                The pygments style to use for code block colorscheme.
              '';
            };
          };
        };
        extraPythonPackages = mkOption {
          type = with types; listOf package;
          default = [ ];
          description = ''
            Extra python packages to use for processing markdown content.
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
                    internal = true;
                  };

                  result = {
                    metadata = mkOption {
                      type = with types; attrsOf anything;
                      default = { };
                      internal = true;
                    };
                    content = mkOption {
                      type = types.str;
                      internal = true;
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
