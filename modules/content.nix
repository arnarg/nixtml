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

  pymdownxDocs = path: "https://facelessuser.github.io/pymdown-extensions/extensions/${path}/";
  pythonMarkdownDocs = name: "https://python-markdown.github.io/extensions/${name}/";

  mkFeatureEnable =
    feature: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Whether to enable ${feature}.";
    };

  mkExtraConfig =
    module: docs:
    lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = ''
        Extra config passed to the `${module}` extension. Takes precedence over the other settings for this extension.

        See: ${docs}
      '';
    };

  # A block type is either a name, or a name with an optional CSS class and
  # title. Used by the admonition and details blocks.
  blockType = lib.types.either lib.types.str (
    lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name of the block, e.g. `note` for `/// note`.";
        };
        class = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "CSS class for the block. Defaults to `name`.";
        };
        title = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "Default title for the block. Defaults to a title cased `class`.";
        };
      };
    }
  );

  captionType = lib.types.either lib.types.str (
    lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name of the caption block, e.g. `figure-caption`.";
        };
        prefix = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "Prefix template for the caption. Must contain `{}` where the number goes.";
        };
      };
    }
  );

  toPythonType = value: if lib.isString value then value else lib.filterAttrs (_: v: v != null) value;

  # Markdown extensions managed by nixtml through named settings, in the order
  # they're passed to Python-Markdown.
  #
  # `supersedes` lists older extensions providing the same feature. Adding one
  # of those to `settings.extensions` while the newer one is enabled is an error
  # when `strict` is set, as they produce broken output together, and a warning
  # otherwise.
  builtinFeatures = [
    {
      name = "tables";
      module = "tables";
      toConfig = cfg: cfg.extraConfig;
    }
    {
      name = "footnotes";
      module = "footnotes";
      toConfig = cfg: cfg.extraConfig;
    }
    {
      name = "attrList";
      module = "attr_list";
      toConfig = _: { };
    }
    {
      name = "quotes";
      module = "pymdownx.quotes";
      toConfig = cfg: { inherit (cfg) callouts; } // cfg.extraConfig;
    }
    {
      name = "fancylists";
      module = "pymdownx.fancylists";
      supersedes = [ "sane_lists" ];
      strict = true;
      toConfig =
        cfg:
        {
          additional_ordered_styles = cfg.additionalOrderedStyles;
          inject_style = cfg.injectStyle;
          inject_class = cfg.injectClass;
        }
        // cfg.extraConfig;
    }
    {
      name = "tasklist";
      module = "pymdownx.tasklist";
      toConfig =
        cfg:
        {
          custom_checkbox = cfg.customCheckbox;
          clickable_checkbox = cfg.clickableCheckbox;
        }
        // cfg.extraConfig;
    }
    {
      name = "magiclink";
      module = "pymdownx.magiclink";
      toConfig =
        cfg:
        {
          inherit (cfg) provider;
          hide_protocol = cfg.hideProtocol;
          repo_url_shortener = cfg.repoUrlShortener;
          repo_url_shorthand = cfg.repoUrlShorthand;
        }
        // lib.optionalAttrs (cfg.user != null) { inherit (cfg) user; }
        // lib.optionalAttrs (cfg.repo != null) { inherit (cfg) repo; }
        // cfg.extraConfig;
    }
    {
      name = "admonition";
      module = "pymdownx.blocks.admonition";
      supersedes = [ "admonition" ];
      toConfig = cfg: { types = map toPythonType cfg.types; } // cfg.extraConfig;
    }
    {
      name = "details";
      module = "pymdownx.blocks.details";
      supersedes = [ "pymdownx.details" ];
      toConfig = cfg: { types = map toPythonType cfg.types; } // cfg.extraConfig;
    }
    {
      name = "tab";
      module = "pymdownx.blocks.tab";
      supersedes = [ "pymdownx.tabbed" ];
      strict = true;
      toConfig = cfg: { alternate_style = cfg.alternateStyle; } // cfg.extraConfig;
    }
    {
      name = "definition";
      module = "pymdownx.blocks.definition";
      supersedes = [ "def_list" ];
      strict = true;
      toConfig = _: { };
    }
    {
      name = "caption";
      module = "pymdownx.blocks.caption";
      toConfig =
        cfg:
        {
          types = map toPythonType cfg.types;
          inherit (cfg) prepend auto;
          auto_level = cfg.autoLevel;
        }
        // cfg.extraConfig;
    }
  ];

  # Extensions that are always enabled, configured through `toc` and `highlight`.
  alwaysEnabledModules = [
    "toc"
    "pymdownx.superfences"
    "pymdownx.highlight"
    "pymdownx.inlinehilite"
  ];

  # Extensions that bundle other extensions.
  extensionBundles = {
    "extra" = [
      "abbr"
      "attr_list"
      "def_list"
      "fenced_code"
      "footnotes"
      "md_in_html"
      "tables"
    ];
    "pymdownx.extra" = [
      "pymdownx.betterem"
      "pymdownx.superfences"
      "footnotes"
      "attr_list"
      "def_list"
      "tables"
      "abbr"
      "md_in_html"
    ];
  };

  normalizeModule = lib.removePrefix "markdown.extensions.";
  expandModule =
    name:
    let
      module = normalizeModule name;
    in
    [ module ] ++ (extensionBundles.${module} or [ ]);

  # Resolves the markdown settings into the list of Python-Markdown extensions
  # and their configs, after checking for conflicting extensions.
  resolveMarkdownExtensions =
    settings:
    let
      managedModules = alwaysEnabledModules ++ map (feature: feature.module) builtinFeatures;
      enabledFeatures = lib.filter (feature: settings.${feature.name}.enable) builtinFeatures;

      extraExtensions = lib.filterAttrs (_: ext: ext.enable) settings.extensions;
      extraModules = lib.concatMap expandModule (lib.attrNames extraExtensions);

      managedErrors = lib.concatMap (
        name:
        lib.optional (lib.elem (normalizeModule name) managedModules) "`${name}` in `website.content.processors.md.settings.extensions` is managed by nixtml, configure it through its named setting instead."
      ) (lib.attrNames settings.extensions);

      supersededBy =
        feature: lib.filter (module: lib.elem module extraModules) (feature.supersedes or [ ]);
      supersededMessage =
        feature: module:
        "`${module}` (enabled through `website.content.processors.md.settings.extensions`) "
        + "conflicts with `${feature.module}`. Set `website.content.processors.md.settings.${feature.name}.enable = false` to use it.";

      supersededErrors = lib.concatMap (
        feature:
        lib.optionals (feature.strict or false) (map (supersededMessage feature) (supersededBy feature))
      ) enabledFeatures;
      supersededWarnings = lib.concatMap (
        feature:
        lib.optionals (!(feature.strict or false)) (map (supersededMessage feature) (supersededBy feature))
      ) enabledFeatures;

      errors = managedErrors ++ supersededErrors;

      inherit (settings) toc highlight;

      result = {
        extensions =
          alwaysEnabledModules
          ++ map (feature: feature.module) enabledFeatures
          ++ lib.attrNames extraExtensions;
        configs = {
          toc = {
            inherit (toc)
              marker
              title
              permalink
              anchorlink
              ;
            title_class = toc.titleClass;
            toc_class = toc.tocClass;
            anchorlink_class = toc.anchorlinkClass;
            permalink_class = toc.permalinkClass;
          };
          "pymdownx.highlight" = {
            inherit (highlight) noclasses linenums;
            use_pygments = true;
            pygments_style = baseHighlightStyle;
            linenums_style = highlight.linenumsStyle;
          }
          // highlight.extraConfig;
        }
        // lib.listToAttrs (
          map (
            feature: lib.nameValuePair feature.module (feature.toConfig settings.${feature.name})
          ) enabledFeatures
        )
        // lib.mapAttrs (_: ext: ext.config) extraExtensions;
      };
    in
    if errors != [ ] then
      throw ("nixtml: invalid markdown extensions:\n" + lib.concatMapStringsSep "\n" (e: "- ${e}") errors)
    else
      lib.foldr lib.warn result supersededWarnings;

  markdownExtensions = resolveMarkdownExtensions processors.md.settings;

  processorOptions = pkgs.writeText "nixtml-content-options.json" (
    builtins.toJSON {
      inherit (processors.md.settings) dateFormat;
      inherit (markdownExtensions) extensions configs;
      relativeLinks = processors.md.settings.relativeLinks.enable;
    }
  );

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

            relativeLinks = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to resolve relative links and image sources against the Markdown file's location, like on GitHub, instead of the page's URL.

                  Links to other Markdown files are rewritten to the URL of their page, e.g. `[Setup](./setup.md#install)` in `guide/intro.md` becomes `../setup/#install`
                  on the page at `guide/intro/`. Other relative URLs, e.g. images in `website.static.dir`, are rewritten to stay correct from the page's URL, so
                  `![Diagram](../images/diagram.png)` in `guide/intro.md` points to `/images/diagram.png`.

                  Absolute URLs, URLs starting with `/` and links to anchors on the same page are left alone. Pages are expected at their default path, i.e. `guide/setup.md`
                  at `guide/setup/` and `guide/index.md` at `guide/`. Links to missing files are not detected.
                '';
              };
            };

            tables = {
              enable = mkFeatureEnable "tables" true;
              extraConfig = mkExtraConfig "tables" (pythonMarkdownDocs "tables");
            };

            footnotes = {
              enable = mkFeatureEnable "footnotes" true;
              extraConfig = mkExtraConfig "footnotes" (pythonMarkdownDocs "footnotes");
            };

            attrList = {
              enable = mkFeatureEnable "attribute lists, e.g. `{: .class #id }`" true;
            };

            quotes = {
              enable = mkFeatureEnable "`pymdownx.quotes` blockquotes, which replace the default blockquote handling" true;
              callouts = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to enable GitHub/Obsidian style callouts, e.g. `> [!NOTE]`.

                  Callouts render with the same markup as admonitions, or as collapsible details when followed by `-` or `+`.
                '';
              };
              extraConfig = mkExtraConfig "pymdownx.quotes" (pymdownxDocs "quotes");
            };

            fancylists = {
              enable = mkFeatureEnable "`pymdownx.fancylists`, supporting alphabetical and roman numeral ordered lists" true;
              additionalOrderedStyles = mkOption {
                type =
                  with types;
                  listOf (enum [
                    "roman"
                    "alpha"
                    "generic"
                  ]);
                default = [
                  "roman"
                  "alpha"
                  "generic"
                ];
                description = ''
                  Ordered list styles to support in addition to decimal numbers. `generic` enables `#.` as a list marker.
                '';
              };
              injectStyle = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to inject a `list-style-type` style attribute on ordered lists.";
              };
              injectClass = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to inject a class indicating the `list-style-type` on ordered lists.";
              };
              extraConfig = mkExtraConfig "pymdownx.fancylists" (pymdownxDocs "fancylists");
            };

            tasklist = {
              enable = mkFeatureEnable "task lists, e.g. `- [x] done`" true;
              customCheckbox = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to add an empty `<label>` after each checkbox to allow for custom styling.";
              };
              clickableCheckbox = mkOption {
                type = types.bool;
                default = false;
                description = "Whether checkboxes can be checked and unchecked by the reader.";
              };
              extraConfig = mkExtraConfig "pymdownx.tasklist" (pymdownxDocs "tasklist");
            };

            magiclink = {
              enable = mkFeatureEnable "automatic linking of URLs and email addresses" true;
              hideProtocol = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to display links without the `https://` (or similar) prefix.";
              };
              provider = mkOption {
                type = types.enum [
                  "github"
                  "gitlab"
                  "bitbucket"
                ];
                default = "github";
                description = "Provider used for repository shorthand links.";
              };
              user = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Default user for repository shorthand links.";
              };
              repo = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Default repository for repository shorthand links.";
              };
              repoUrlShortener = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to shorten links to repository issues, pull requests and commits.";
              };
              repoUrlShorthand = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to convert shorthand references such as `#123` or `user/repo#123` to links. Requires `user` and `repo` to be set for the short forms.
                '';
              };
              extraConfig = mkExtraConfig "pymdownx.magiclink" (pymdownxDocs "magiclink");
            };

            admonition = {
              enable = mkFeatureEnable "admonition blocks, e.g. `/// note`" true;
              types = mkOption {
                type = types.listOf blockType;
                default = [
                  "note"
                  "attention"
                  "caution"
                  "danger"
                  "error"
                  "tip"
                  "hint"
                  "warning"
                  "important"
                ];
                example = literalExpression ''
                  [
                    "note"
                    "warning"
                    { name = "example"; title = "Try it"; }
                  ]
                '';
                description = ''
                  Admonition types to create shorthand blocks for, e.g. `note` allows `/// note` instead of `/// admonition | Note`.
                '';
              };
              extraConfig = mkExtraConfig "pymdownx.blocks.admonition" (pymdownxDocs "blocks/plugins/admonition");
            };

            details = {
              enable = mkFeatureEnable "collapsible details blocks, e.g. `/// details | Summary`" true;
              types = mkOption {
                type = types.listOf blockType;
                default = [ ];
                example = [
                  "note"
                  "warning"
                ];
                description = ''
                  Details types to create shorthand blocks for, e.g. `note` allows `/// note | Summary` as a collapsible block with the `note` class.

                  Note that these share names with admonition types, so a type should only be defined in one of them.
                '';
              };
              extraConfig = mkExtraConfig "pymdownx.blocks.details" (pymdownxDocs "blocks/plugins/details");
            };

            tab = {
              enable = mkFeatureEnable "tab blocks, e.g. `/// tab | Title`" true;
              alternateStyle = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to use the alternate tab markup, which is easier to style and handles overflowing tabs better.

                  See: https://facelessuser.github.io/pymdown-extensions/extensions/blocks/plugins/tab/#alternate-style
                '';
              };
              extraConfig = mkExtraConfig "pymdownx.blocks.tab" (pymdownxDocs "blocks/plugins/tab");
            };

            definition = {
              enable = mkFeatureEnable "definition list blocks, e.g. `/// define`" true;
            };

            caption = {
              enable = mkFeatureEnable "caption blocks, e.g. `/// caption`" true;
              types = mkOption {
                type = types.listOf captionType;
                default = [
                  "caption"
                  {
                    name = "figure-caption";
                    prefix = "Figure {}.";
                  }
                  {
                    name = "table-caption";
                    prefix = "Table {}.";
                  }
                ];
                description = ''
                  Caption types to create blocks for. Types with a `prefix` are numbered.
                '';
              };
              prepend = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to place captions before the content instead of after it.";
              };
              auto = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to automatically number captions of types with a `prefix`.";
              };
              autoLevel = mkOption {
                type = types.ints.unsigned;
                default = 0;
                description = ''
                  Depth of nested figures to automatically number. `0` numbers all levels, `1` only the outermost figures, and so on.
                '';
              };
              extraConfig = mkExtraConfig "pymdownx.blocks.caption" (pymdownxDocs "blocks/plugins/caption");
            };

            extensions = mkOption {
              type =
                with types;
                attrsOf (submodule {
                  options = {
                    enable = mkOption {
                      type = bool;
                      default = true;
                      description = "Whether to enable this extension.";
                    };
                    config = mkOption {
                      type = attrsOf anything;
                      default = { };
                      description = "Config passed to the extension.";
                    };
                  };
                });
              default = { };
              example = literalExpression ''
                {
                  "pymdownx.arithmatex".config.generic = true;
                  "pymdownx.emoji" = { };
                  abbr = { };
                }
              '';
              description = ''
                Additional Python-Markdown extensions to enable, keyed by their import name, along with their config.

                Extensions from packages other than `markdown` and `pymdown-extensions` need to be added to `website.content.processors.md.extraPythonPackages`.

                Extensions that nixtml manages through named settings, e.g. `toc` or `pymdownx.blocks.tab`, can't be added here. Older extensions superseded by the enabled
                built-in ones conflict with them: `def_list` with `definition`, `pymdownx.tabbed` with `tab` and `sane_lists` with `fancylists` are errors, while
                `admonition` and `pymdownx.details` only warn. Disable the built-in setting to use the older extension.
              '';
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
                    processor name config.source;
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
            jsonData = pkgs.runCommand "content-data-${lib.replaceStrings [ "/" ] [ "-" ] name}.json" { } ''
              ${pythonEnv}/bin/python ${./processContent.py} ${toString path} ${processorOptions} ${lib.escapeShellArg name} > $out
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
