{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.tags)
    a
    body
    button
    div
    footer
    h1
    head
    header
    html
    img
    link
    main
    meta
    p
    script
    section
    span
    ;
  inherit (lib) attrs;

  cfg = config.themes.docs;
  inherit (config.website) baseURI metadata;
  inherit (config.website.layouts) partials;

  siteTitle = metadata.title or "Untitled site";

  # Bulma 1.0.4. Pinning the source makes theme updates explicit and keeps
  # generated sites reproducible.
  bulma = pkgs.fetchFromGitHub {
    owner = "jgthms";
    repo = "bulma";
    rev = "1.0.4";
    hash = "sha256-hlejqBI6ayzhm15IymrzhTevkl3xffMfdTasZ2CmAas=";
  };

  # Sass load path, allowing `@use "bulma/sass/..."`.
  sassLoadPath = pkgs.linkFarm "nixtml-docs-theme-sass" [
    {
      name = "bulma";
      path = bulma;
    }
  ];

  fileExtension =
    source:
    lib.last (lib.splitString "." (builtins.unsafeDiscardStringContext (baseNameOf (toString source))));

  logoFile = if cfg.logo.source == null then null else "logo.${fileExtension cfg.logo.source}";
  compactLogoFile =
    if cfg.logo.compact.source == null then
      null
    else
      "logo-compact.${fileExtension cfg.logo.compact.source}";

  # The compact logo is preferred for the favicon, as it's usually the one
  # that's legible at small sizes.
  faviconFile = if compactLogoFile != null then compactLogoFile else logoFile;
  logoMimeTypes = {
    svg = "image/svg+xml";
    png = "image/png";
    ico = "image/x-icon";
    webp = "image/webp";
    jpg = "image/jpeg";
    jpeg = "image/jpeg";
    gif = "image/gif";
  };
  faviconMimeType = logoMimeTypes.${lib.last (lib.splitString "." faviconFile)} or null;

  themeColor = if cfg.colors.themeColor != null then cfg.colors.themeColor else cfg.colors.primary;

  # Sass string literal, for values such as font stacks that contain commas
  # and quotes.
  sassString = value: "'${lib.replaceStrings [ "\\" "'" ] [ "\\\\" "\\'" ] value}'";

  bulmaVariables =
    lib.mapAttrs (_: value: "(${value})") (
      lib.filterAttrs (_: value: value != null) {
        inherit (cfg.colors)
          primary
          link
          info
          success
          warning
          danger
          ;
      }
      // cfg.sassVariables
    )
    // lib.optionalAttrs (cfg.fonts.primary != null) { family-primary = sassString cfg.fonts.primary; }
    // lib.optionalAttrs (cfg.fonts.code != null) { family-code = sassString cfg.fonts.code; };

  # Entrypoint configuring Bulma, followed by the fonts, the theme's
  # stylesheet, code highlighting styles and the site's extra styles.
  entrypoint = pkgs.writeText "nixtml-docs-theme.scss" ''
    @use "sass:meta";
    ${
      if bulmaVariables == { } then
        ''@use "bulma/sass/utilities";''
      else
        ''
          @use "bulma/sass/utilities" with (
          ${lib.concatStringsSep ",\n" (
            lib.mapAttrsToList (name: value: "  \$${name}: ${value}") bulmaVariables
          )}
          );''
    }
    @use "fonts";
    @use "main";
    @include meta.load-css("highlight.css");
    @include meta.load-css("extra");
  '';

  stylesheet =
    pkgs.runCommand "nixtml-docs-theme-stylesheet" { nativeBuildInputs = [ pkgs.dart-sass ]; }
      ''
        mkdir -p src $out/css
        cp ${entrypoint} src/index.scss
        cp ${./stylesheet}/*.scss src/
        cp ${cfg.internal.fonts}/fonts.scss src/fonts.scss
        cp ${config.website.content.processors.md.highlightStylesheet} src/highlight.css
        cp ${pkgs.writeText "extra.scss" cfg.extraScss} src/extra.scss

        sass --no-source-map --style=compressed --load-path=${sassLoadPath} src/index.scss $out/css/main.css
      '';

  themeAssets = pkgs.symlinkJoin {
    name = "nixtml-docs-theme-assets";
    paths = [
      stylesheet
      (pkgs.runCommand "nixtml-docs-theme-font-files" { } ''
        mkdir -p $out
        cp -r ${cfg.internal.fonts}/fonts $out/fonts
      '')
    ]
    ++ lib.optional scriptEnabled (
      pkgs.runCommand "nixtml-docs-theme-scripts" { } ''
        mkdir -p $out/js
        cp ${./docs.js} $out/js/docs.js
      ''
    );
  };

  # The mobile navigation always needs the theme's script.
  scriptEnabled = true;

  defaultColorScheme = if cfg.colorScheme == "auto" then "system" else cfg.colorScheme;

  # Applies the saved color scheme before the page is rendered, avoiding a
  # flash of the default color scheme.
  colorSchemeScript = ''
    (function () {
      try {
        var scheme = window.localStorage.getItem(${builtins.toJSON cfg.colorSchemeSwitcher.storageKey});
        if (scheme === "system") {
          document.documentElement.removeAttribute("data-theme");
        } else if (scheme === "light" || scheme === "dark") {
          document.documentElement.setAttribute("data-theme", scheme);
        }
      } catch (error) {}
    })();
  '';

  # Paths of the source files of content pages, relative to the content
  # directory, keyed by their output path.
  contentSources =
    let
      # Content pages from `website.content.dir` are read from its copy in
      # the store.
      contentDir = builtins.unsafeDiscardStringContext "${config.website.content.dir}";
    in
    lib.concatMapAttrs (
      name: page:
      let
        source = builtins.unsafeDiscardStringContext (toString page.source);
      in
      lib.optionalAttrs (lib.hasPrefix "${contentDir}/" source) {
        ${config.website.pages.${name}.path} = lib.removePrefix "${contentDir}/" source;
      }
    ) config.website.content.pages;
in
{
  imports = [
    ./fonts.nix
    ./navigation.nix
    ./repository.nix
  ];

  options.themes.docs = with lib; {
    logo = {
      source = mkOption {
        type = with types; nullOr path;
        default = null;
        example = literalExpression "./logo.svg";
        description = ''
          Logo displayed at the top of the landing page. When `null` the site title is displayed instead.
        '';
      };
      alt = mkOption {
        type = types.str;
        default = siteTitle;
        defaultText = literalExpression "config.website.metadata.title";
        description = "Alternative text of the logo.";
      };
      favicon = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to use the logo as the favicon. Uses `compact.source` when set.";
      };
      compact.source = mkOption {
        type = with types; nullOr path;
        default = null;
        example = literalExpression "./icon.svg";
        description = ''
          Small logo, such as an icon, displayed in front of the site title in the bar at the top of every page.
        '';
      };
    };

    colors =
      let
        mkColor =
          name: default:
          mkOption {
            type = with types; nullOr str;
            inherit default;
            description = ''
              Bulma's `${name}` color, as a Sass color value. `null` uses Bulma's default.
            '';
          };
      in
      {
        primary = mkColor "primary" "#8a4d76";
        link = mkColor "link" "#fa7c91";
        info = mkColor "info" null;
        success = mkColor "success" null;
        warning = mkColor "warning" null;
        danger = mkColor "danger" null;
        themeColor = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            Value of the `theme-color` meta tag, used by some browsers to color their interface. Defaults to `primary`.
          '';
        };
      };

    colorScheme = mkOption {
      type = types.enum [
        "auto"
        "light"
        "dark"
      ];
      default = "auto";
      description = ''
        Color scheme of the website. `auto` follows the reader's system preference.

        With `colorSchemeSwitcher` enabled, this is the color scheme used until the reader chooses another one.
      '';
    };

    colorSchemeSwitcher = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to display a button for cycling through the system, light and dark color schemes. The reader's choice is saved in their browser.

          The switcher requires JavaScript, and is hidden when it's unavailable.
        '';
      };
      storageKey = mkOption {
        type = types.str;
        default = "${config.website.name}-color-scheme";
        defaultText = literalExpression ''"''${config.website.name}-color-scheme"'';
        description = ''
          Key of the `localStorage` item storing the chosen color scheme.

          Websites served from the same origin, such as GitHub Pages project sites of the same user, share their storage. Different keys keep their choices separate.
        '';
      };
      labels = {
        group = mkOption {
          type = types.str;
          default = "Color scheme";
          description = "Accessible label of the switcher.";
        };
        system = mkOption {
          type = types.str;
          default = "System color scheme";
          description = "Accessible label for the system color scheme.";
        };
        light = mkOption {
          type = types.str;
          default = "Light color scheme";
          description = "Accessible label for the light color scheme.";
        };
        dark = mkOption {
          type = types.str;
          default = "Dark color scheme";
          description = "Accessible label for the dark color scheme.";
        };
      };
    };

    codeStyles = {
      light = mkOption {
        type = types.str;
        default = "default";
        description = "Pygments style for code blocks in the light color scheme.";
      };
      dark = mkOption {
        type = types.str;
        default = "monokai";
        description = ''
          Pygments style for code blocks in the dark color scheme.

          Styles from other packages need to be added to `website.content.processors.md.extraPythonPackages`.
        '';
      };
    };

    sassVariables = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = {
        radius = "0.5rem";
        weight-extrabold = "700";
      };
      description = ''
        Extra [Bulma Sass variables](https://bulma.io/documentation/customize/list-of-sass-variables/), without the `$`. Values are inserted into Sass as is.
      '';
    };

    extraScss = mkOption {
      type = types.lines;
      default = "";
      example = ''
        @use "bulma/sass/utilities/mixins";

        .docs-hero-logo {
          width: 12rem;
        }
      '';
      description = ''
        Extra Sass appended to the theme's stylesheet. Bulma can be loaded with `@use "bulma/sass/..."`.
      '';
    };

    editLink = {
      baseURL = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "https://github.com/arnarg/nixtml/edit/main/docs/content/";
        description = ''
          Base URL to link to each content page's source file for editing. The page's path within `website.content.dir` is appended to it.

          When `null`, no edit links are displayed.
        '';
      };
      label = mkOption {
        type = types.str;
        default = "Edit this page";
        description = "Text of the edit link.";
      };
    };

    hero.content = mkOption {
      type = with types; nullOr str;
      default = null;
      example = ''
        <p>Documentation for my project.</p>
      '';
      description = "HTML content displayed below the logo on the landing page, such as badges or a tagline.";
    };

    footer = mkOption {
      type = with types; nullOr str;
      default = ''Generated with <a href="https://github.com/arnarg/nixtml">nixtml</a>.'';
      description = "HTML content of the footer. `null` removes the footer.";
    };

    notFoundPage = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to generate a `404.html` page.";
      };
      title = mkOption {
        type = types.str;
        default = "Page Not Found";
        description = "Title of the 404 page.";
      };
      content = mkOption {
        type = types.str;
        default = "This page does not exist!";
        description = "HTML content of the 404 page.";
      };
    };
  };

  config = {
    build.extraPackages.docsTheme = themeAssets;

    website = {
      files =
        lib.optionalAttrs (logoFile != null) {
          ${logoFile}.source = cfg.logo.source;
        }
        // lib.optionalAttrs (compactLogoFile != null) {
          ${compactLogoFile}.source = cfg.logo.compact.source;
        };

      pages."404.html" = lib.mkIf cfg.notFoundPage.enable {
        extraContext = {
          inherit (cfg.notFoundPage) title content;
          metadata = { inherit (cfg.notFoundPage) title; };
        };
        layout = config.website.layouts.page;
      };

      content.processors.md.settings.highlight = {
        noclasses = lib.mkDefault false;
        style = lib.mkDefault [
          { name = cfg.codeStyles.light; }
          {
            name = cfg.codeStyles.dark;
            media = "prefers-color-scheme: dark";
          }
          {
            name = cfg.codeStyles.light;
            selector = ":where([data-theme=light], .theme-light) .highlight";
          }
          {
            name = cfg.codeStyles.dark;
            selector = ":where([data-theme=dark], .theme-dark) .highlight";
          }
        ];
      };

      layouts = {
        base = lib.mkDefault (
          { content, ... }@context:
          "<!DOCTYPE html>\n"
          +
            html
              (
                [ (attrs.lang (metadata.lang or "en")) ]
                ++ lib.optional (cfg.colorScheme != "auto") (attrs.data "theme" cfg.colorScheme)
              )
              [
                (head [ ] [ (partials.head context) ])
                (body
                  [ ]
                  [
                    (partials.docsTopbar context)
                    (partials.docsHero context)
                    (section
                      [
                        (attrs.classes [
                          "section"
                          "docs-section"
                        ])
                      ]
                      [
                        (div
                          [
                            (attrs.class "docs-container")
                          ]
                          [
                            (partials.docsSidebar (context // { mobile = true; }))
                            (div
                              [ (attrs.class "columns") ]
                              [
                                (partials.docsSidebar context)
                                (main
                                  [
                                    (attrs.classes [
                                      "docs-main"
                                      "column"
                                    ])
                                  ]
                                  [
                                    content
                                    (partials.docsEditLink context)
                                    (partials.docsPager context)
                                  ]
                                )
                              ]
                            )
                          ]
                        )
                      ]
                    )
                    (partials.docsFooter context)
                  ]
                )
              ]
        );

        home = lib.mkDefault (
          { content, ... }@context:
          [
            (partials.pageHeader context)
            (div [ (attrs.classes [ "content" ]) ] [ content ])
          ]
        );

        page = lib.mkDefault (
          { content, ... }@context:
          [
            (partials.pageHeader context)
            (div [ (attrs.classes [ "content" ]) ] [ content ])
          ]
        );

        partials = {
          # Large logo, or the site title without one, displayed only on the
          # landing page. Other pages show the site title in `docsTopbar`.
          docsHero = lib.mkDefault (
            context:
            lib.optionalString ((context.path or [ ]) == [ "index.html" ]) (
              section
                [
                  (attrs.classes [
                    "hero"
                    "docs-hero"
                  ])
                ]
                [
                  (div
                    [ (attrs.classes [ "hero-body" ]) ]
                    [
                      (div
                        [
                          (attrs.classes [
                            "container"
                            "is-max-desktop"
                            "has-text-centered"
                          ])
                        ]
                        [
                          (
                            if logoFile != null then
                              img [
                                (attrs.class "docs-hero-logo")
                                (attrs.src (baseURI + logoFile))
                                (attrs.alt cfg.logo.alt)
                              ]
                            else
                              p
                                [
                                  (attrs.classes [
                                    "title"
                                    "docs-hero-title"
                                  ])
                                ]
                                [ siteTitle ]
                          )
                          (lib.optionalString (cfg.hero.content != null) (
                            div [ (attrs.class "docs-hero-content") ] [ cfg.hero.content ]
                          ))
                        ]
                      )
                    ]
                  )
                ]
            )
          );

          # Site title linking to the landing page, with the compact logo in
          # front of it when one is configured. The landing page displays
          # `docsHero` instead.
          docsBrand = lib.mkDefault (
            context:
            lib.optionalString ((context.path or [ ]) != [ "index.html" ]) (
              a
                [
                  (attrs.class "docs-brand")
                  (attrs.href baseURI)
                ]
                [
                  (lib.optionalString (compactLogoFile != null) (img [
                    (attrs.src (baseURI + compactLogoFile))
                    (attrs.alt "")
                  ]))
                  (span [ (attrs.class "docs-brand-title") ] [ siteTitle ])
                ]
            )
          );

          docsFooter = lib.mkDefault (
            _:
            lib.optionalString (cfg.footer != null) (
              footer
                [ (attrs.classes [ "footer" ]) ]
                [
                  (div
                    [
                      (attrs.classes [
                        "container"
                        "content"
                        "is-max-desktop"
                        "has-text-centered"
                      ])
                    ]
                    [ (p [ ] [ cfg.footer ]) ]
                  )
                ]
            )
          );

          docsEditLink = lib.mkDefault (
            { path, ... }:
            let
              source = contentSources.${lib.concatStringsSep "/" path} or null;
            in
            lib.optionalString (cfg.editLink.baseURL != null && source != null) (
              p
                [ (attrs.class "docs-edit-link") ]
                [
                  (a [ (attrs.href (cfg.editLink.baseURL + source)) ] [ cfg.editLink.label ])
                ]
            )
          );

          pageHeader = lib.mkDefault (
            { metadata, ... }:
            [
              (lib.optionalString (metadata ? title) (
                h1 [ (attrs.classes [ "title" ]) ] [ metadata.title ]
              ))
              (lib.optionalString (metadata ? description && metadata.description != "") (
                p [ (attrs.classes [ "docs-lede" ]) ] [ metadata.description ]
              ))
            ]
          );

          docsTopbar = lib.mkDefault (
            context:
            header
              [ (attrs.class "docs-topbar") ]
              [
                (div
                  [
                    (attrs.class "docs-container")
                  ]
                  [
                    (partials.docsMobileNavToggle context)
                    (partials.docsBrand context)
                    (div
                      [ (attrs.class "docs-topbar-end") ]
                      [
                        (partials.docsRepository context)
                        (partials.docsColorSchemeSwitcher context)
                      ]
                    )
                  ]
                )
              ]
          );

          docsColorSchemeSwitcher = lib.mkDefault (
            _:
            let
              switcherButton =
                button
                  [
                    (attrs.type "button")
                    (attrs.classes [
                      "button"
                      "is-small"
                    ])
                    (attrs.data "color-scheme" defaultColorScheme)
                    (attrs.data "label-system" cfg.colorSchemeSwitcher.labels.system)
                    (attrs.data "label-light" cfg.colorSchemeSwitcher.labels.light)
                    (attrs.data "label-dark" cfg.colorSchemeSwitcher.labels.dark)
                    (attrs.aria "label" cfg.colorSchemeSwitcher.labels.${defaultColorScheme})
                    (attrs.title cfg.colorSchemeSwitcher.labels.${defaultColorScheme})
                  ]
                  [
                    (span
                      [
                        (attrs.classes [
                          "docs-icon"
                          "is-${defaultColorScheme}"
                        ])
                        (attrs.aria "hidden" "true")
                      ]
                      [ ]
                    )
                  ];
            in
            lib.optionalString cfg.colorSchemeSwitcher.enable (
              div
                [
                  (attrs.class "docs-color-scheme")
                  (lib.mkAttr "role" "group")
                  (attrs.aria "label" cfg.colorSchemeSwitcher.labels.group)
                  (attrs.data "storage-key" cfg.colorSchemeSwitcher.storageKey)
                  (attrs.data "default" defaultColorScheme)
                  (lib.mkAttr "hidden" "")
                ]
                [ switcherButton ]
            )
          );

          head = lib.mkDefault (
            context:
            [
              (meta [ (attrs.charset "UTF-8") ])
              (meta [
                (attrs.name "viewport")
                (attrs.content "width=device-width, initial-scale=1.0")
              ])
              (link [
                (attrs.rel "stylesheet")
                (attrs.href (baseURI + "css/main.css"))
              ])
            ]
            ++ lib.optional (themeColor != null) (meta [
              (attrs.name "theme-color")
              (attrs.content themeColor)
            ])
            ++ lib.optional (faviconFile != null && cfg.logo.favicon) (
              link (
                [
                  (attrs.rel "icon")
                  (attrs.href (baseURI + faviconFile))
                ]
                ++ lib.optional (faviconMimeType != null) (attrs.type faviconMimeType)
              )
            )
            ++ lib.optional cfg.colorSchemeSwitcher.enable (script [ ] [ colorSchemeScript ])
            ++ lib.optional scriptEnabled (
              script
                [
                  (attrs.src (baseURI + "js/docs.js"))
                  (lib.mkAttr "defer" "")
                ]
                [ ]
            )
            ++ [ (partials.meta context) ]
          );

          meta = lib.mkDefault (
            { path, title, ... }@context:
            let
              pageTitle =
                if title != null && path != [ "index.html" ] then "${title} | ${siteTitle}" else siteTitle;
              pageDescription = context.metadata.description or (metadata.description or "");
            in
            [
              (lib.tags.title pageTitle)
              (meta [
                (attrs.name "description")
                (attrs.content pageDescription)
              ])
              (meta [
                (attrs.property "og:title")
                (attrs.content pageTitle)
              ])
              (meta [
                (attrs.name "twitter:title")
                (attrs.content pageTitle)
              ])
              (meta [
                (attrs.itemprop "name")
                (attrs.content pageTitle)
              ])
              (meta [
                (attrs.property "og:description")
                (attrs.content pageDescription)
              ])
              (meta [
                (attrs.name "twitter:description")
                (attrs.content pageDescription)
              ])
              (meta [
                (attrs.name "application-name")
                (attrs.content siteTitle)
              ])
              (meta [
                (attrs.property "og:site_name")
                (attrs.content siteTitle)
              ])
              (meta [
                (attrs.property "og:locale")
                (attrs.content (metadata.lang or "en"))
              ])
              (meta [
                (attrs.property "og:type")
                (attrs.content (if path == [ "index.html" ] then "website" else "article"))
              ])
            ]
          );
        };
      };
    };
  };
}
