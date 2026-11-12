---
title: Layouts and Partials
description: Build page layouts with Nix functions, reusable partials, and HTML helpers
nav:
  section: guides
  order: 30
  label: Layouts and partials
---

nixtml layouts are ordinary Nix functions. They receive page data as an attribute set and return HTML as a string or a list of strings. This guide focuses on composing layouts; the linked references list the available contexts and HTML helpers.

## Layout Types

| Layout | Purpose |
| --- | --- |
| `website.layouts.base` | HTML document shell shared by every page |
| `website.layouts.home` | Root `content/index.md` |
| `website.layouts.page` | Other Markdown pages |
| `website.layouts.collection` | Collection pagination pages |
| `website.layouts.taxonomy` | Taxonomy pagination pages |
| `website.layouts.partials` | Reusable functions called by other layouts |

A page-specific layout renders first. Its result is then passed to `base` as `content`, together with the original page context.

## A Minimal Page Shell

The following module defines layouts for a site with ordinary pages. Themes provide these same layouts as configurable defaults, so defining them yourself is only necessary when you want custom markup.

```nix
{ lib, config, ... }:
let
  inherit (config.website) baseURI metadata;
  inherit (lib) attrs;
  inherit (lib.tags)
    article
    body
    div
    h1
    head
    html
    link
    main
    meta
    ;
in
{
  website.layouts = {
    base =
      { path, content, title, ... }:
      let
        pageTitle =
          if title != null && path != [ "index.html" ] then
            "${title} | ${metadata.title}"
          else
            metadata.title;
      in
      "<!DOCTYPE html>\n"
      + (html [ (attrs.lang (metadata.lang or "en")) ] [
        (head [ ] [
          (meta [ (attrs.charset "UTF-8") ])
          (meta [
            (attrs.name "viewport")
            (attrs.content "width=device-width, initial-scale=1")
          ])
          (lib.tags.title pageTitle)
          (link [
            (attrs.rel "stylesheet")
            (attrs.href (baseURI + "css/main.css"))
          ])
        ])
        (body [ ] [
          (main [ ] [ content ])
        ])
      ]);

    home = { metadata, content, ... }:
      article [ ] [
        (h1 [ ] [ metadata.title ])
        (div [ (attrs.class "content") ] [ content ])
      ];

    page = { metadata, content, ... }:
      article [ ] [
        (h1 [ ] [ metadata.title ])
        (div [ (attrs.class "content") ] [ content ])
      ];
  };
}
```

The `home` and `page` layouts can differ whenever the homepage needs distinct markup. Both receive the page frontmatter as `metadata` and the rendered Markdown as `content`.

## String Templates

HTML helpers are optional. A simple base layout can use Nix string interpolation instead:

```nix
website.layouts.base = { content, ... }: ''
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>${config.website.metadata.title}</title>
    </head>
    <body>
      <main>${content}</main>
    </body>
  </html>
'';
```

Both approaches can be mixed. HTML helpers are useful for building element and attribute lists programmatically; interpolation can be clearer for a small, mostly static shell.

## Partials

Extract repeated markup into partial functions. A partial chooses its own arguments; nixtml does not impose a context shape on it.

```nix
{ lib, config, ... }:
let
  inherit (lib) attrs;
  inherit (lib.tags) a body head html li nav ul;
  inherit (config.website) baseURI metadata;
  inherit (config.website.layouts) partials;
in
{
  website.layouts = {
    partials = {
      head = { title, ... }: [
        (lib.tags.meta [ (attrs.charset "UTF-8") ])
        (lib.tags.title title)
      ];

      navigation = { }:
        nav [ (attrs.aria "label" "Main navigation") ] [
          (ul [ ] [
            (li [ ] [
              (a [ (attrs.href baseURI) ] [ "Home" ])
            ])
            (li [ ] [
              (a [ (attrs.href (baseURI + "about/")) ] [ "About" ])
            ])
          ])
        ];
    };

    base = { content, title, ... }@context:
      let
        pageTitle = if title != null then title else metadata.title;
      in
      "<!DOCTYPE html>\n"
      + (html [ (attrs.lang (metadata.lang or "en")) ] [
        (head [ ] [
          (partials.head { title = pageTitle; })
        ])
        (body [ ] [
          (partials.navigation { })
          content
        ])
      ]);
  };
}
```

Pass the complete context with `@context` when a partial needs values beyond the layout's explicit arguments:

```nix
partials.head context
```

See the [HTML helper reference](/nixtml/reference/html/) for tags, attributes, conditional attributes, and escaping.

## Collection Layouts

Collection layouts map over `items` and render pagination controls:

```nix
website.layouts.collection =
  {
    items,
    pageNumber,
    totalPages,
    hasNext,
    hasPrev,
    nextPageURL,
    prevPageURL,
    ...
  }:
  [
    (lib.tags.h1 [ ] [ "Posts" ])
    (lib.tags.ul [ ] (
      map (item:
        lib.tags.li [ ] [
          (lib.tags.a [
            (lib.attrs.href item.url)
          ] [ item.title ])
        ]) items
    ))
    (lib.tags.nav [ (lib.attrs.aria "label" "Pagination") ] [
      (lib.optionalString hasPrev
        (lib.tags.a [ (lib.attrs.href prevPageURL) ] [ "Previous" ]))
      "Page ${toString pageNumber} of ${toString totalPages}"
      (lib.optionalString hasNext
        (lib.tags.a [ (lib.attrs.href nextPageURL) ] [ "Next" ]))
    ])
  ];
```

Guard `nextPageURL` and `prevPageURL` with their corresponding Boolean values. Accessing a URL for a page that does not exist throws an evaluation error.

[Collections and pagination](/nixtml/collections/) explains item summaries, dates, and collection configuration.

## Taxonomy Layouts

Taxonomy layouts receive collection-style pagination data plus `title` for the term and `taxonomy` for its type:

```nix
website.layouts.taxonomy = { taxonomy, title, items, ... }:
  [
    (lib.tags.h1 [ ] [ "${taxonomy}: ${title}" ])
    (lib.tags.ul [ ] (
      map (item:
        lib.tags.li [ ] [
          (lib.tags.a [
            (lib.attrs.href item.url)
          ] [ item.title ])
        ]) items
    ))
  ];
```

See [Taxonomies and RSS](/nixtml/taxonomies/) for term setup and feed links.

## Site Configuration in Layouts

Access site-wide settings from the module's `config` argument:

```nix
{ lib, config, ... }:
let
  inherit (config.website) baseURL baseURI metadata;
in
{
  # baseURL:  "https://example.com"
  # baseURI:  "/", or a path such as "/nixtml/"
  # metadata: arbitrary site-wide values
}
```

Use `baseURI` for internal asset and navigation links so sites hosted below a URL path continue to work. Use `baseURL` for absolute permalinks and external metadata.

## Escaping and Rendered HTML

The HTML helpers return raw strings and do not automatically escape children. Keep rendered Markdown and intentionally generated tags unescaped:

```nix
div [ ] [ content ]
```

Escape arbitrary plain-text values before inserting them into HTML:

```nix
lib.tags.p [ ] [
  (lib.escapeHTML userInput)
]
```

Do not use escaping as a substitute for validating untrusted URLs or other attribute values.

## Reference and Next Steps

- [Template Context Reference](/nixtml/reference/templates/) for every standard layout value.
- [HTML Tags and Attributes](/nixtml/reference/html/) for helper signatures.
- [Content and frontmatter](/nixtml/content/) for page metadata and content discovery.
- [Configuration options](/nixtml/options/) for all layout and content options.
