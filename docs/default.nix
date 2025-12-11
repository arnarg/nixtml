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
                    [ (attrs.classes [ "hero" ]) ]
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
                              (img [ (attrs.src (config.website.baseURI + "logo.svg")) ])
                            ]
                          )
                        ]
                      )
                    ]
                  )
                  (section
                    [ (attrs.classes [ "section" ]) ]
                    [
                      (div
                        [
                          (attrs.classes [
                            "container"
                            "is-max-desktop"
                          ])
                        ]
                        [ content ]
                      )
                    ]
                  )
                  (footer
                    [ (attrs.classes [ "footer" ]) ]
                    [
                      (div
                        [
                          (attrs.classes [
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

      home = { content, ... }: content;

      page =
        { metadata, content, ... }:
        [
          (h1 [ (attrs.classes [ "title" ]) ] [ metadata.title ])
          (div
            [ (attrs.classes [ "content" ]) ]
            [
              content
            ]
          )
        ];

      partials = {
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
              (attrs.href "/favicon.png")
            ])
            (partials.meta context)
          ];

        meta =
          { path, title, ... }:
          let
            pageTitle =
              if title != null && path != [ "index.html" ] then
                "${title} | ${metadata.title}"
              else
                metadata.title;
          in
          [
            (lib.tags.title pageTitle)
            (meta [
              (attrs.name "description")
              (attrs.content metadata.description)
            ])
            (meta [
              (attrs.property "og:title")
              (attrs.content metadata.title)
            ])
            (meta [
              (attrs.property "twitter:title")
              (attrs.content metadata.title)
            ])
            (meta [
              (attrs.itemprop "name")
              (attrs.content metadata.title)
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

    content.mdProcessor = {
      settings = {
        toc = {
          permalink = "#";
          permalinkClass = "headerlink mx-2";
        };
        highlight.style = "catppuccin-latte";
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

      deps = pkgs.linkFarm "nixtml-docs-stylesheet-deps" [
        {
          name = "bulma";
          path = bulma;
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
        sass --load-path "${deps}" main.scss main.css
      '';

      installPhase = ''
        mkdir -p $out/css

        cp main.css $out/css/main.css
      '';
    };
}
