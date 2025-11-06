{ lib, config, ... }:
let
  inherit (lib.tags)
    a
    body
    div
    h1
    h2
    head
    html
    li
    link
    meta
    title
    ul
    ;
  inherit (lib) attrs;
  inherit (config.website) metadata;
  inherit (config.website.layouts) partials;
in
{
  website = {
    name = "example-blog";
    baseURL = "https://example-blog.com";

    metadata = {
      lang = "en";
      title = "nixtml";
      description = "Example blog built with nixtml";
    };

    content.dir = ./content;

    collections.blog = {
      path = "posts";

      pagination.perPage = 2;

      taxonomies = [ "tags" ];

      rss = {
        enable = true;
        limit = 50;
      };
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
                [
                  (attrs.classes [
                    "font-sans"
                    "bg-white"
                  ])
                ]
                [
                  (div
                    [
                      (attrs.classes [ "container" ])
                    ]
                    [ content ]
                  )
                ]
              )
            ];

      home = { content, ... }: content;

      page =
        { metadata, content, ... }:
        [
          (h1 [ ] [ metadata.title ])
          content
        ];

      collection =
        {
          pageNumber,
          totalPages,
          items,
          hasNext,
          hasPrev,
          nextPageURL,
          prevPageURL,
          ...
        }:
        [
          (ul [ ] (map (post: li [ ] [ post.title ]) items))
          (div
            [ ]
            [
              (if hasPrev then (a [ (attrs.href prevPageURL) ] [ (lib.escapeHTML "< Prev") ]) else "")
              "Page ${toString pageNumber} of ${toString totalPages}"
              (if hasNext then (a [ (attrs.href nextPageURL) ] [ (lib.escapeHTML "Next >") ]) else "")
            ]
          )
        ];

      taxonomy =
        {
          title,
          pageNumber,
          totalPages,
          items,
          hasNext,
          hasPrev,
          nextPageURL,
          prevPageURL,
          ...
        }:
        [
          (h2 [ ] [ ("#" + title) ])
          (ul [ ] (map (post: li [ ] [ post.title ]) items))
          (div
            [ ]
            [
              (if hasPrev then (a [ (attrs.href prevPageURL) ] [ (lib.escapeHTML "< Prev") ]) else "")
              "Page ${toString pageNumber} of ${toString totalPages}"
              (if hasNext then (a [ (attrs.href nextPageURL) ] [ (lib.escapeHTML "Next >") ]) else "")
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
              (attrs.name "width=device-width, initial-scale=1.0")
            ])
            (meta [
              (attrs.name "msapplication-TileColor")
              (attrs.name "#da532c")
            ])
            (meta [
              (attrs.name "theme-color")
              (attrs.name "#ffffff")
            ])
            (link [
              (attrs.rel "icon")
              (attrs.href "/favicon.png")
            ])
            (partials.meta context)
          ];

        meta =
          { path, ... }:
          [
            (title metadata.title)
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
              (attrs.content (if path == [ "index" ] then "website" else "article"))
            ])
          ];
      };
    };
  };
}
