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
    div
    footer
    h1
    head
    html
    img
    link
    main
    meta
    p
    section
    ;
  inherit (lib) attrs;
  inherit (config.website) metadata;
  inherit (config.website.layouts) partials;
in
{
  imports = [
    ./navigation.nix
    ./options.nix
  ];

  website = {
    name = "nixtml-docs";
    baseURL = "https://arnarg.github.io/nixtml";

    metadata = {
      lang = "en";
      title = "nixtml";
      description = "nixtml documentation";
    };

    content.dir = ./content;

    files."logo.svg".source = ../logo.svg;

    pages."404.html" = {
      extraContext =
        let
          title = "Page Not Found";
        in
        {
          inherit title;
          metadata = { inherit title; };
          content = "This page does not exist!";
        };
      layout = config.website.layouts.page;
    };

    layouts = {
      base =
        { path, content, ... }@context:
        "<!DOCTYPE html>\n"
        +
          html
            [ (attrs.lang metadata.lang) ]
            [
              (head [ ] [ (partials.head context) ])
              (body
                [ ]
                [
                  (section
                    [
                      (attrs.classes [
                        "hero"
                        "docs-hero"
                        "mt-5"
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
                              (a
                                [ (attrs.href config.website.baseURI) ]
                                [
                                  (img [
                                    (attrs.src (config.website.baseURI + "logo.svg"))
                                    (attrs.alt metadata.title)
                                  ])
                                ]
                              )
                            ]
                          )
                        ]
                      )
                    ]
                  )
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
                          (attrs.classes [
                            "container"
                            "is-max-widescreen"
                          ])
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
                                  (partials.docsPager context)
                                ]
                              )
                            ]
                          )
                        ]
                      )
                    ]
                  )
                  (footer
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
                        [
                          (p
                            [ ]
                            [
                              "This website is (obviously) generated with "
                              (a
                                [
                                  (attrs.href "https://github.com/arnarg/nixtml")
                                ]
                                [ "nixtml." ]
                              )
                            ]
                          )
                        ]
                      )
                    ]
                  )
                ]
              )
            ];

      home =
        { content, ... }@context:
        [
          (partials.pageHeader context)
          (div [ (attrs.classes [ "content" ]) ] [ content ])
        ];

      page =
        { content, ... }@context:
        [
          (partials.pageHeader context)
          (div [ (attrs.classes [ "content" ]) ] [ content ])
        ];

      partials = {
        pageHeader =
          { metadata, ... }:
          [
            (h1 [ (attrs.classes [ "title" ]) ] [ metadata.title ])
            (lib.optionalString (metadata ? description && metadata.description != "") (
              p [ (attrs.classes [ "docs-lede" ]) ] [ metadata.description ]
            ))
          ];

        head =
          {
            path,
            ...
          }@context:
          [
            (link [
              (attrs.rel "stylesheet")
              (attrs.href (config.website.baseURI + "css/main.css"))
            ])
            (meta [
              (attrs.httpEquiv "Content-Type")
              (attrs.content "text/html")
              (attrs.charset "UTF-8")
            ])
            (meta [
              (attrs.httpEquiv "X-UA-Compatible")
              (attrs.content "IE=edge,chrome=1")
            ])
            (meta [
              (attrs.name "viewport")
              (attrs.content "width=device-width, initial-scale=1.0")
            ])
            (meta [
              (attrs.name "msapplication-TileColor")
              (attrs.content "#da532c")
            ])
            (meta [
              (attrs.name "theme-color")
              (attrs.content "#ffffff")
            ])
            (link [
              (attrs.rel "icon")
              (attrs.type "image/svg+xml")
              (attrs.href (config.website.baseURI + "logo.svg"))
            ])
            (partials.meta context)
          ];

        meta =
          { path, title, ... }@context:
          let
            pageTitle =
              if title != null && path != [ "index.html" ] then
                "${title} | ${metadata.title}"
              else
                metadata.title;
            pageDescription = context.metadata.description or metadata.description;
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
              (attrs.content metadata.title)
            ])
            (meta [
              (attrs.property "og:site_name")
              (attrs.content metadata.title)
            ])
            (meta [
              (attrs.property "og:locale")
              (attrs.content metadata.lang)
            ])
            (meta [
              (attrs.property "og:type")
              (attrs.content (if path == [ "index.html" ] then "website" else "article"))
            ])
          ];
      };
    };

    content.processors.md = {
      settings = {
        toc = {
          permalink = "#";
          permalinkClass = "headerlink mx-2";
        };
        highlight = {
          style = "catppuccin-latte";
          noclasses = false;
        };
      };
      extraPythonPackages = [
        # Add pygments-styles: https://pygments-styles.org/
        (
          let
            pname = "pygments-styles";
            version = "0.3.0";
          in
          pkgs.python3Packages.buildPythonPackage {
            inherit pname version;
            pyproject = true;

            src = pkgs.fetchFromGitHub {
              owner = "lepture";
              repo = pname;
              rev = version;
              sha256 = "sha256-3tVbeoDCDwHczst9Z22iVBzXfCDoAPjHBYBFzt+CXDY=";
            };

            build-system = with pkgs.python3Packages; [
              setuptools
              setuptools-scm
            ];

            dependencies = with pkgs.python3Packages; [
              setuptools
              pygments
            ];
          }
        )
      ];
    };
  };

  build.extraPackages.stylesheetPackage =
    let
      bulma = pkgs.fetchFromGitHub {
        owner = "jgthms";
        repo = "bulma";
        rev = "1.0.4";
        hash = "sha256-hlejqBI6ayzhm15IymrzhTevkl3xffMfdTasZ2CmAas=";
      };

      highlightPython = pkgs.python3.withPackages (
        ps: [ ps.pygments ] ++ config.website.content.processors.md.extraPythonPackages
      );

      highlightStylesheet =
        name: style: selector:
        pkgs.runCommand "nixtml-highlight-${name}.css" { } ''
          ${highlightPython}/bin/pygmentize -S ${lib.escapeShellArg style} -f html -a ${lib.escapeShellArg selector} > $out
        '';

      deps = pkgs.linkFarm "nixtml-docs-stylesheet-deps" [
        {
          name = "bulma";
          path = bulma;
        }
        {
          name = "highlight-light.css";
          path = config.website.content.processors.md.highlightStylesheet;
        }
        {
          name = "highlight-dark.css";
          path = highlightStylesheet "dark" "catppuccin-mocha" ".highlight";
        }
        {
          name = "highlight-light-explicit.css";
          path =
            highlightStylesheet "light-explicit" "catppuccin-latte"
              ":where([data-theme=light], .theme-light) .highlight";
        }
        {
          name = "highlight-dark-explicit.css";
          path =
            highlightStylesheet "dark-explicit" "catppuccin-mocha"
              ":where([data-theme=dark], .theme-dark) .highlight";
        }
      ];
    in
    pkgs.stdenv.mkDerivation {
      name = "nixtml-docs-stylesheet";

      src = ./stylesheet;

      buildInputs = with pkgs; [
        dart-sass
      ];

      buildPhase = ''
        sass --style=compressed --load-path "${deps}" main.scss main.css
      '';

      installPhase = ''
        mkdir -p $out/css

        cp main.css $out/css/main.css
      '';
    };
}
