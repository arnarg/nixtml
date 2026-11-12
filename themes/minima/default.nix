{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.tags)
    a
    article
    body
    div
    footer
    h1
    h2
    h3
    head
    header
    html
    input
    label
    li
    link
    main
    meta
    nav
    p
    span
    time
    ul
    ;
  inherit (lib) attrs;

  cfg = config.themes.minima;
  inherit (config.website) baseURI metadata;
  inherit (config.website.layouts) partials;

  siteTitle = metadata.title or "Untitled site";
  description = metadata.description or "";

  # Attribute values need quotes escaped in addition to the characters escaped
  # by lib.escapeHTML. Replacement happens in one pass to avoid double escaping.
  escape =
    value: builtins.replaceStrings [ "&" "<" ">" "\"" ] [ "&amp;" "&lt;" "&gt;" "&quot;" ] value;

  # Minima 2.5.2. Pinning the source makes theme updates explicit and keeps
  # generated sites reproducible.
  upstream = pkgs.fetchFromGitHub {
    name = "minima-2.5.2-source";
    owner = "jekyll";
    repo = "minima";
    rev = "c6e74bbfe7a0d0ae8c806cb38b012d01b25b1f7d";
    hash = "sha256-VXc89SpOnesmWWQxZVaI8t0rvZY/KDYyC33hOSDVsvw=";
  };

  themeAssets = pkgs.runCommand "nixtml-theme-minima-2.5.2" { } ''
    mkdir -p $out/assets $out/share/doc/minima

    ${pkgs.dart-sass}/bin/sass \
      --no-source-map \
      --load-path=${upstream}/_sass \
      ${./main.scss} \
      $out/assets/main.css

    cp ${upstream}/assets/minima-social-icons.svg $out/assets/minima-social-icons.svg
    cp ${./LICENSE.txt} $out/share/doc/minima/LICENSE.txt
  '';

  pageTitle =
    title:
    escape (if title == null || title == siteTitle then siteTitle else "${title} | ${siteTitle}");

  socialIcon =
    platform:
    ''<svg class="svg-icon" aria-hidden="true"><use href="${
      escape (baseURI + "assets/minima-social-icons.svg")
    }#${escape platform}"></use></svg>'';

  pagination =
    {
      pageNumber,
      totalPages,
      hasNext,
      hasPrev,
      nextPageURL,
      prevPageURL,
      ...
    }:
    if totalPages <= 1 then
      ""
    else
      nav
        [
          (attrs.class "pagination")
          (lib.mkAttr "aria-label" "Pagination")
        ]
        (
          (lib.optional hasPrev (
            a
              [
                (attrs.class "previous-page")
                (attrs.href (escape prevPageURL))
              ]
              [ (escape "< Prev") ]
          ))
          ++ [
            (span
              [ (attrs.class "page-number") ]
              [
                "Page ${toString pageNumber} of ${toString totalPages}"
              ]
            )
          ]
          ++ (lib.optional hasNext (
            a
              [
                (attrs.class "next-page")
                (attrs.href (escape nextPageURL))
              ]
              [ (escape "Next >") ]
          ))
        );

  postList =
    items:
    ul [ (attrs.class "post-list") ] (
      map (
        post:
        li
          [ ]
          [
            (time
              [
                (attrs.class "post-meta")
                (lib.mkAttr "datetime" (escape post.dateW3C))
              ]
              [ (escape post.date) ]
            )
            (h3
              [ ]
              [
                (a
                  [
                    (attrs.class "post-link")
                    (attrs.href (escape post.url))
                  ]
                  [ (escape post.title) ]
                )
              ]
            )
            (lib.optionalString cfg.showExcerpts (div [ (attrs.class "post-excerpt") ] [ post.summary ]))
          ]
      ) items
    );

  rssSubscribe =
    { pageNumber }:
    if cfg.feedPath == null || pageNumber != 1 then
      ""
    else
      p
        [ (attrs.class "rss-subscribe") ]
        [
          "subscribe "
          (a [ (attrs.href (escape (baseURI + cfg.feedPath))) ] [ "via RSS" ])
        ];
in
{
  options.themes.minima = with lib; {
    navigation = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            title = mkOption {
              type = types.str;
              description = "Label displayed in the site navigation.";
            };
            path = mkOption {
              type = types.str;
              description = "Site-relative path, without the website's base URI.";
              example = "about/";
            };
          };
        }
      );
      default = [ ];
      description = "Additional links displayed in the site header.";
    };

    showExcerpts = mkOption {
      type = types.bool;
      default = false;
      description = "Show post content before the `<!--more-->` marker in post lists.";
    };

    feedPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Site-relative RSS feed path, or `null` to disable RSS links.";
      example = "index.xml";
    };

    socialLinks = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            platform = mkOption {
              type = types.str;
              description = "Icon identifier from Minima's social icon sprite.";
              example = "github";
            };
            username = mkOption {
              type = types.str;
              description = "Label displayed next to the social icon.";
            };
            url = mkOption {
              type = types.str;
              description = "Absolute URL of the social profile.";
            };
          };
        }
      );
      default = [ ];
      description = "Social profiles displayed in the site footer.";
    };
  };

  config = {
    build.extraPackages.minima = themeAssets;

    website.layouts = {
      base = lib.mkDefault (
        { content, ... }@context:
        "<!DOCTYPE html>\n"
        + (html
          [ (attrs.lang (escape (metadata.lang or "en"))) ]
          [
            (head [ ] [ (partials.head context) ])
            (body
              [ ]
              [
                (partials.siteHeader context)
                (main
                  [
                    (attrs.class "page-content")
                    (lib.mkAttr "aria-label" "Content")
                  ]
                  [ (div [ (attrs.class "wrapper") ] [ content ]) ]
                )
                (partials.siteFooter context)
              ]
            )
          ]
        )
      );

      home = lib.mkDefault (
        { metadata, content, ... }:
        div
          [ (attrs.class "home") ]
          [
            (lib.optionalString (metadata ? title) (
              h1 [ (attrs.class "page-heading") ] [ (escape metadata.title) ]
            ))
            content
          ]
      );

      page = lib.mkDefault (
        { metadata, content, ... }:
        article
          [ (attrs.class "post") ]
          [
            (header
              [ (attrs.class "post-header") ]
              [
                (h1
                  [ (attrs.class "post-title") ]
                  [
                    (escape (metadata.title or "Untitled page"))
                  ]
                )
                (lib.optionalString (metadata ? date || metadata ? author) (
                  p [ (attrs.class "post-meta") ] (
                    (lib.optional (metadata ? date) (
                      time
                        [
                          (lib.mkAttr "datetime" (escape metadata.dateW3C))
                        ]
                        [ (escape metadata.date) ]
                    ))
                    ++ (lib.optional (metadata ? date && metadata ? author) " • ")
                    ++ (lib.optional (metadata ? author) (
                      span [ (attrs.itemprop "author") ] [ (escape metadata.author) ]
                    ))
                  )
                ))
              ]
            )
            (div [ (attrs.class "post-content") ] [ content ])
          ]
      );

      collection = lib.mkDefault (
        { items, ... }@context:
        div
          [ (attrs.class "home") ]
          [
            (h2 [ (attrs.class "post-list-heading") ] [ "Posts" ])
            (postList items)
            (pagination context)
            (rssSubscribe { inherit (context) pageNumber; })
          ]
      );

      taxonomy = lib.mkDefault (
        { title, items, ... }@context:
        div
          [ (attrs.class "home") ]
          [
            (h1 [ (attrs.class "post-list-heading") ] [ (escape "#${title}") ])
            (postList items)
            (pagination context)
          ]
      );

      partials = {
        head = lib.mkDefault (
          {
            title ? null,
            ...
          }:
          [
            (meta [ (attrs.charset "utf-8") ])
            (meta [
              (attrs.httpEquiv "X-UA-Compatible")
              (attrs.content "IE=edge")
            ])
            (meta [
              (attrs.name "viewport")
              (attrs.content "width=device-width, initial-scale=1")
            ])
            (lib.tags.title (pageTitle title))
            (lib.optionalString (description != "") (meta [
              (attrs.name "description")
              (attrs.content (escape description))
            ]))
            (link [
              (attrs.rel "stylesheet")
              (attrs.href (escape (baseURI + "assets/main.css")))
            ])
            (lib.optionalString (cfg.feedPath != null) (link [
              (attrs.rel "alternate")
              (attrs.type "application/rss+xml")
              (attrs.title (escape siteTitle))
              (attrs.href (escape (baseURI + cfg.feedPath)))
            ]))
          ]
        );

        siteHeader = lib.mkDefault (
          _:
          header
            [ (attrs.class "site-header") ]
            [
              (div
                [ (attrs.class "wrapper") ]
                [
                  (a
                    [
                      (attrs.class "site-title")
                      (attrs.rel "author")
                      (attrs.href (escape baseURI))
                    ]
                    [ (escape siteTitle) ]
                  )
                  (lib.optionalString (cfg.navigation != [ ]) (
                    nav
                      [ (attrs.class "site-nav") ]
                      [
                        (input [
                          (attrs.id "nav-trigger")
                          (attrs.class "nav-trigger")
                          (attrs.type "checkbox")
                          (attrs.aria "label" "Toggle navigation")
                        ])
                        (label
                          [ (lib.mkAttr "for" "nav-trigger") ]
                          [
                            (span
                              [ (attrs.class "menu-icon") ]
                              [
                                ''
                                  <svg viewBox="0 0 18 15" width="18px" height="15px" aria-hidden="true">
                                    <path d="M18,1.484c0,0.82-0.665,1.484-1.484,1.484H1.484C0.665,2.969,0,2.304,0,1.484l0,0C0,0.665,0.665,0,1.484,0 h15.032C17.335,0,18,0.665,18,1.484L18,1.484z M18,7.516C18,8.335,17.335,9,16.516,9H1.484C0.665,9,0,8.335,0,7.516l0,0 c0-0.82,0.665-1.484,1.484-1.484h15.032C17.335,6.031,18,6.696,18,7.516L18,7.516z M18,13.516C18,14.335,17.335,15,16.516,15H1.484 C0.665,15,0,14.335,0,13.516l0,0c0-0.82,0.665-1.483,1.484-1.483h15.032C17.335,12.031,18,12.695,18,13.516L18,13.516z"/>
                                  </svg>''
                              ]
                            )
                          ]
                        )
                        (div [ (attrs.class "trigger") ] (
                          map (
                            item:
                            a
                              [
                                (attrs.class "page-link")
                                (attrs.href (escape (baseURI + item.path)))
                              ]
                              [ (escape item.title) ]
                          ) cfg.navigation
                        ))
                      ]
                  ))
                ]
              )
            ]
        );

        siteFooter = lib.mkDefault (
          _:
          footer
            [ (attrs.class "site-footer") ]
            [
              (div
                [ (attrs.class "wrapper") ]
                [
                  (h2 [ (attrs.class "footer-heading") ] [ (escape siteTitle) ])
                  (div
                    [ (attrs.class "footer-col-wrapper") ]
                    [
                      (div
                        [
                          (attrs.classes [
                            "footer-col"
                            "footer-col-1"
                          ])
                        ]
                        [
                          (ul
                            [ (attrs.class "contact-list") ]
                            [
                              (li
                                [ (attrs.class "p-name") ]
                                [
                                  (escape (metadata.author or siteTitle))
                                ]
                              )
                              (lib.optionalString (metadata ? email) (
                                li
                                  [ ]
                                  [
                                    (a
                                      [ (attrs.href (escape "mailto:${metadata.email}")) ]
                                      [
                                        (escape metadata.email)
                                      ]
                                    )
                                  ]
                              ))
                            ]
                          )
                        ]
                      )
                      (div
                        [
                          (attrs.classes [
                            "footer-col"
                            "footer-col-2"
                          ])
                        ]
                        [
                          (lib.optionalString (cfg.socialLinks != [ ]) (
                            ul [ (attrs.class "social-media-list") ] (
                              map (
                                social:
                                li
                                  [ ]
                                  [
                                    (a
                                      [ (attrs.href (escape social.url)) ]
                                      [
                                        (socialIcon social.platform)
                                        (span [ (attrs.class "username") ] [ (escape social.username) ])
                                      ]
                                    )
                                  ]
                              ) cfg.socialLinks
                            )
                          ))
                        ]
                      )
                      (div
                        [
                          (attrs.classes [
                            "footer-col"
                            "footer-col-3"
                          ])
                        ]
                        [
                          (p [ ] [ (escape description) ])
                        ]
                      )
                    ]
                  )
                ]
              )
            ]
        );
      };
    };
  };
}
