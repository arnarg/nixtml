{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.website.content) processors;

  pythonEnv = pkgs.python3.withPackages (
    ps:
    with ps;
    [
      markdown
      pymdown-extensions
      pyyaml
      pygments
    ]
    ++ processors.md.extraPythonPackages
  );

  highlightStyles = processors.md.settings.highlight.style;
  baseHighlightStyle = (lib.head highlightStyles).name;

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

      processors = {
        md = {
          settings = {
            dateFormat = mkOption {
              type = types.str;
              default = "%b %-d, %Y";
              description = ''
                Format string for any datetime in content front matter.

                This is a format string for python's `strftime`. See: https://docs.python.org/3/library/datetime.html#strftime-strptime-behavior
              '';
            };
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
                  Set to `true` or a string to generate permanent links at the end of each header.

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
                type =
                  with types;
                  coercedTo str (name: [ { inherit name; } ]) (
                    nonEmptyListOf (submodule {
                      options = {
                        name = mkOption {
                          type = str;
                          description = "The Pygments style name.";
                        };
                        selector = mkOption {
                          type = str;
                          default = ".highlight";
                          description = "The CSS selector to scope this style to.";
                        };
                        media = mkOption {
                          type = nullOr str;
                          default = null;
                          description = "An optional media feature condition, without parentheses.";
                        };
                      };
                    })
                  );
                default = [ { name = "default"; } ];
                description = ''
                  The Pygments styles to use for code block colorschemes.

                  A string is shorthand for a single style scoped to `.highlight`. A list can define
                  multiple styles with custom selectors and media feature conditions. The first style
                  is used for inline highlighting, and all styles are included in `highlightStylesheet`
                  in their configured order.
                '';
              };
              noclasses = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to inline the pygments styles in the generated HTML instead of using CSS classes.

                  When set to `false` a stylesheet for the chosen style is needed, see `website.content.processors.md.highlightStylesheet`.

                  Note that the `pymdownx-inline` line number style requires this to be `false`.
                '';
              };
              linenums = mkOption {
                type = with types; nullOr bool;
                default = null;
                description = ''
                  Enable line numbers for all code blocks. When `null` line numbers can still be enabled per code block with `linenums="1"`.
                '';
              };
              linenumsStyle = mkOption {
                type = types.enum [
                  "table"
                  "inline"
                  "pymdownx-inline"
                ];
                default = "table";
                description = ''
                  The line number style to use for code blocks.

                  See: https://facelessuser.github.io/pymdown-extensions/extensions/highlight/#line-number-styles
                '';
              };
              extraConfig = mkOption {
                type = with types; attrsOf anything;
                default = { };
                example = {
                  anchor_linenums = true;
                  line_spans = "__span";
                };
                description = ''
                  Extra config passed to the `pymdownx.highlight` extension. Takes precedence over other highlight settings.

                  See: https://facelessuser.github.io/pymdown-extensions/extensions/highlight/#options
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
          highlightStylesheet = mkOption {
            type = types.package;
            readOnly = true;
            description = ''
              A CSS file with the configured Pygments styles from `website.content.processors.md.settings.highlight.style`, in their configured order.

              Useful when `website.content.processors.md.settings.highlight.noclasses` is set to `false`.
            '';
          };
          processor = mkOption {
            type = with types; functionTo (functionTo (attrsOf anything));
            internal = true;
          };
        };
      };

      pages = mkOption {
        type =
          with types;
          attrsOf (
            submodule (
              {
                name,
                config,
                options,
                ...
              }:
              {
                options = {
                  text = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    description = ''
                      Content that should be processed with the desired processor.
                    '';
                  };
                  source = mkOption {
                    type = types.path;
                    description = ''
                      Path to to a source file with content that should be processed with the desired processor.
                    '';
                  };
                  processor = mkOption {
                    type = types.enum (lib.attrNames processors);
                    default = "md";
                    description = ''
                      Name of the processor to use to render the page content.
                    '';
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
                  source = lib.mkIf (config.text != null) (
                    let
                      name' = "nixtml-process-" + lib.replaceStrings [ "/" ] [ "-" ] name;
                    in
                    lib.mkDerivedConfig options.text (pkgs.writeText name')
                  );

                  result =
                    let
                      inherit (processors.${config.processor}) processor;
                    in
                    processor (lib.concatStringsSep "-" (lib.splitString "/" name)) config.source;
                };
              }
            )
          );
        default = { };
        example = literalExpression ''
          {
            "index" = {
              text = '''
                ---
                title: Homepage
                ---
                # Welcome!

                Welcome to the hompage
              ''';
              processor = "md";
            };
            "nested/page" = {
              source = ./path/to/page.md;
              processor = "md";
            };
          }
        '';
        description = ''
          Attribute set of pages to be processed by a content processor (see `config.website.content.processors`). The content can come either from `text` or `source`.

          Keep in mind that nixtml will automatically populate this by walking `config.website.content.dir` and finding content.
        '';
      };
    };
  };

  config = {
    website = {
      content = {
        pages = lib.listToAttrs (
          lib.mapAttrsToListRecursive (path: x: {
            name = "${lib.concatStringsSep "/" path}";
            value.source = x;
          }) (readContentDir config.website.content.dir)
        );

        processors.md.highlightStylesheet =
          let
            stylesheetCommands = lib.concatMapStringsSep "\n" (
              variant:
              let
                pygmentize = ''
                  ${pythonEnv}/bin/pygmentize -S ${lib.escapeShellArg variant.name} -f html -a ${lib.escapeShellArg variant.selector} >> $out
                '';
              in
              if variant.media == null then
                pygmentize
              else
                ''
                  printf '%s\n' ${lib.escapeShellArg "@media (${variant.media}) {"} >> $out
                  ${pygmentize}
                  printf '%s\n' '}' >> $out
                ''
            ) highlightStyles;
          in
          pkgs.runCommand "nixtml-highlight-${baseHighlightStyle}.css" { } ''
            : > $out
            ${stylesheetCommands}
          '';

        processors.md.processor =
          name: path:
          let
            py = pythonEnv;

            inherit (config.website.content.processors.md) settings;
            processorSettings = settings // {
              highlight = settings.highlight // {
                style = baseHighlightStyle;
              };
            };

            options = pkgs.writeText "content-options-${name}.json" (builtins.toJSON processorSettings);

            jsonData = pkgs.runCommand "content-data-${name}.json" { } ''
              ${py}/bin/python ${./processContent.py} ${toString path} ${toString options} > $out
            '';

            contentData = lib.importJSON jsonData;
          in
          {
            inherit (contentData) metadata content;
          };
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
      }) config.website.content.pages;
    };
  };
}
