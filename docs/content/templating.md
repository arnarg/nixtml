---
title: Advanced Templating
date: 2026-01-19T21:00:00
description: Learn about nixtml's powerful templating system
---

nixtml provides a flexible templating system using pure Nix functions. You can use either string interpolation for simple templates or the functional HTML library for type-safe markup.

## Template Types

nixtml requires these templates:

| Template | Purpose | Context |
|----------|---------|---------|
| `base` | Wraps all pages (HTML skeleton) | `path`, `content`, `title` |
| `home` | Renders `index.md` | `metadata`, `content` |
| `page` | Renders other markdown files | `metadata`, `content` |
| `collection` | Renders collection pagination | `items`, `pageNumber`, etc. |
| `taxonomy` | Renders taxonomy pages | `title`, `items`, etc. |
| `partials` | Reusable components | User-defined |

## Two Approaches to Templating

### 1. String Templates (Simple)

Use Nix string interpolation:

```nix
website.layouts.base = { path, content, ... }: ''
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>My Website</title>
    </head>
    <body>
      ${content}
    </body>
  </html>
'';
```

### 2. Functional HTML (Fun?)

Use nixtml's tag functions:

```nix
{ lib, ... }:
let
  inherit (lib.tags) html head body meta title div;
  inherit (lib) attrs;
in
{
  website.layouts.base = { path, content, ... }:
    "<!DOCTYPE html>\n"
    + (html [ (attrs.lang "en") ] [
        (head [] [
          (meta [ (attrs.charset "UTF-8") ])
          (title "My Website")
        ])
        (body [] [ content ])
      ]);
}
```

## The Functional HTML Library

### How Tags Work

Tag functions have this signature:

```nix
tagName [ attributes ] [ children ]
```

- **First argument**: List of attributes (can be empty `[]`)
- **Second argument**: List of children (strings or nested tags)

```nix
# Examples
(div [] [ "Hello" ])                    # <div>Hello</div>
(div [ (attrs.class "box") ] [ "Hi" ])  # <div class="box">Hi</div>
(a [ (attrs.href "/") ] [ "Home" ])     # <a href="/">Home</a>
```

### Available Tags

#### Regular Tags (with closing tag)

```nix
inherit (lib.tags)
  # Document structure
  html head body

  # Sections
  header footer main nav section article aside

  # Headings
  h1 h2 h3 h4 h5 h6

  # Text content
  p div span pre blockquote

  # Lists
  ul ol li dl dt dd

  # Inline text
  a em strong code b i u s small

  # Tables
  table thead tbody tfoot tr th td

  # Forms
  form fieldset legend label button select option textarea

  # Media
  figure figcaption picture audio video

  # Other
  script style noscript template
  ;
```

#### Void Tags (self-closing)

```nix
inherit (lib.tags)
  meta link img input br hr
  area base col embed source track wbr
  ;
```

Void tags only take attributes:

```nix
(meta [ (attrs.charset "UTF-8") ])           # <meta charset="UTF-8">
(link [ (attrs.rel "stylesheet") (attrs.href "/style.css") ])
(img [ (attrs.src "/logo.png") (attrs.alt "Logo") ])
(br [])                                       # <br>
```

#### Special: title Tag

The `title` tag has a convenience form:

```nix
(title "My Page Title")   # <title>My Page Title</title>
```

### Attributes Library

The `attrs` module provides attribute helpers:

```nix
inherit (lib) attrs;

# Common attributes
(attrs.id "main")           # id="main"
(attrs.class "container")   # class="container"
(attrs.href "/about")       # href="/about"
(attrs.src "/image.png")    # src="/image.png"
(attrs.alt "Description")   # alt="Description"
(attrs.type "text")         # type="text"
(attrs.name "email")        # name="email"
(attrs.content "value")     # content="value"
(attrs.rel "stylesheet")    # rel="stylesheet"
(attrs.lang "en")           # lang="en"
(attrs.charset "UTF-8")     # charset="UTF-8"
(attrs.target "_blank")     # target="_blank"
(attrs.title "Hover text")  # title="Hover text"

# Width/height (accepts int or string)
(attrs.width 100)           # width="100"
(attrs.height "auto")       # height="auto"

# Multiple classes
(attrs.classes [ "flex" "items-center" "gap-4" ])  # class="flex items-center gap-4"

# Data attributes
(attrs.data "theme" "dark")   # data-theme="dark"
(attrs.data "count" "5")      # data-count="5"

# ARIA attributes
(attrs.aria "label" "Menu")   # aria-label="Menu"
(attrs.aria "hidden" "true")  # aria-hidden="true"

# Meta attributes
(attrs.property "og:title")   # property="og:title"
(attrs.httpEquiv "refresh")   # http-equiv="refresh"
(attrs.itemprop "name")       # itemprop="name"
```

### Creating Custom Attributes

Use `lib.mkAttr` for attributes not in the library:

```nix
let
  customAttr = lib.mkAttr "data-custom" "value";
in
(div [ customAttr ] [ "Content" ])
# <div data-custom="value">Content</div>
```

## Template Context Reference

### Base Template

```nix
website.layouts.base = {
  path,      # List of path segments: [ "about" "index.html" ]
  content,   # Rendered HTML from child template
  title,     # Page title (null for collection/taxonomy pages)
  ...        # Additional context passed from child templates
}: ...;
```

### Home Template

```nix
website.layouts.home = {
  path,       # Always [ "index.html" ]
  metadata,   # Frontmatter from index.md
  content,    # HTML from markdown
  title,      # metadata.title
  ...
}: ...;
```

### Page Template

```nix
website.layouts.page = {
  path,       # [ "about" "index.html" ]
  metadata,   # Frontmatter from markdown file
  content,    # HTML from markdown
  title,      # metadata.title
  ...
}: ...;
```

### Collection Template

```nix
website.layouts.collection = {
  path,         # [ "blog" "index.html" ] or [ "blog" "page" "2" "index.html" ]
  pageNumber,   # Current page (1, 2, 3...)
  totalPages,   # Total number of pages
  items,        # List of posts on this page
  hasNext,      # true if next page exists
  hasPrev,      # true if previous page exists
  nextPageURL,  # URL string (throws if !hasNext)
  prevPageURL,  # URL string (throws if !hasPrev)
  title,        # Always null for collections
  ...
}: ...;
```

### Taxonomy Template

```nix
website.layouts.taxonomy = {
  path,         # [ "blog" "tags" "nix" "index.html" ]
  title,        # The taxonomy term ("nix")
  pageNumber,   # Current page number
  totalPages,   # Total pages for this term
  items,        # Posts with this term
  hasNext,      # true if next page exists
  hasPrev,      # true if previous page exists
  nextPageURL,  # URL to next page
  prevPageURL,  # URL to previous page
  ...
}: ...;
```

## Partials

Partials are reusable template functions:

```nix
{ lib, config, ... }:
let
  inherit (lib.tags) header nav ul li a footer p div;
  inherit (lib) attrs;
  inherit (config.website) metadata;
  inherit (config.website.layouts) partials;
in
{
  website.layouts = {
    partials = {
      # Navigation partial
      navigation = { currentPath }:
        let
          isActive = href: if href == currentPath then "active" else "";
          navItem = href: label:
            li [ (attrs.class (isActive href)) ] [
              (a [ (attrs.href href) ] [ label ])
            ];
        in
        nav [ (attrs.class "main-nav") ] [
          (ul [] [
            (navItem "/" "Home")
            (navItem "/blog" "Blog")
            (navItem "/about" "About")
          ])
        ];

      # Footer partial
      siteFooter = { }:
        footer [ (attrs.class "site-footer") ] [
          (p [] [ "© 2026 ${metadata.title}" ])
          (p [] [ "Built with nixtml" ])
        ];

      # Meta tags partial
      metaTags = { title, description ? metadata.description }:
        [
          (meta [ (attrs.charset "UTF-8") ])
          (meta [ (attrs.name "viewport") (attrs.content "width=device-width, initial-scale=1") ])
          (meta [ (attrs.name "description") (attrs.content description) ])
          (lib.tags.title title)
        ];
    };

    # Use partials in base template
    base = { path, content, title, ... }:
      let
        pageTitle = if title != null then "${title} - ${metadata.title}" else metadata.title;
        currentPath = "/" + lib.concatStringsSep "/" (lib.init path);
      in
      "<!DOCTYPE html>\n"
      + (html [ (attrs.lang "en") ] [
          (head [] (partials.metaTags { title = pageTitle; }))
          (body [] [
            (partials.navigation { inherit currentPath; })
            (div [ (attrs.class "content") ] [ content ])
            (partials.siteFooter {})
          ])
        ]);
  };
}
```

## Conditional Rendering

### Simple Conditionals

```nix
website.layouts.page = { metadata, content, ... }:
  [
    # Show title if it exists
    (if metadata ? title then (h1 [] [ metadata.title ]) else "")

    content

    # Show date if present
    (if metadata ? date then (p [ (attrs.class "date") ] [ metadata.date ]) else "")
  ];
```

### With Default Values

```nix
website.layouts.page = { metadata, content, ... }:
  let
    # Provide defaults
    pageTitle = metadata.title or "Untitled";
    showToc = metadata.toc or false;
    tags = metadata.tags or [];
  in
  [
    (h1 [] [ pageTitle ])

    (if showToc then (div [ (attrs.class "toc") ] [ "Table of Contents..." ]) else "")

    content

    (if tags != [] then
      (div [ (attrs.class "tags") ]
        (map (tag: span [ (attrs.class "tag") ] [ tag ]) tags))
    else "")
  ];
```

## Working with Lists

### Mapping Over Items

```nix
# Simple list
(ul []
  (map (item: li [] [ item.title ]) items))

# With links
(ul []
  (map (item:
    li [] [
      (a [ (attrs.href item.url) ] [ item.title ])
    ]
  ) items))

# Complex items
(div [ (attrs.class "posts") ]
  (map (item:
    article [ (attrs.class "post") ] [
      (h2 [] [ (a [ (attrs.href item.url) ] [ item.title ]) ])
      (p [ (attrs.class "date") ] [ item.date ])
      (p [ (attrs.class "summary") ] [ item.summary ])
    ]
  ) items))
```

## String Returns vs List Returns

Templates can return either strings or lists:

```nix
# String return
website.layouts.page = { content, ... }:
  "<article>${content}</article>";

# List return (automatically joined with newlines)
website.layouts.page = { metadata, content, ... }:
  [
    (h1 [] [ metadata.title ])
    content
  ];

# Mixed (nested lists are flattened)
website.layouts.base = { content, ... }:
  [
    "<!DOCTYPE html>"
    (html [] [
      (head [] [ ... ])
      (body [] [ content ])
    ])
  ];
```

## Escaping HTML

Use `lib.escapeHTML` to escape user content:

```nix
let
  inherit (lib) escapeHTML;

  # Escape special characters
  userInput = escapeHTML "<script>alert('xss')</script>";
  # Result: "&lt;script&gt;alert('xss')&lt;/script&gt;"
in
(p [] [ userInput ])
```

## Accessing Site Configuration

```nix
{ lib, config, ... }:
let
  # Access website configuration
  inherit (config.website) metadata baseURL baseURI;

  # metadata contains your custom fields
  siteTitle = metadata.title;
  siteLang = metadata.lang;

  # URLs
  fullUrl = baseURL;       # "https://example.com"
  basePath = baseURI;      # "/" or "/blog/" if baseURL has path
in
{
  website.layouts.base = { path, content, ... }:
    ...;
}
```

## Complete Example

```nix
{ lib, config, ... }:
let
  inherit (config.website) metadata baseURL;
  inherit (config.website.layouts) partials;

  inherit (lib.tags)
    html head body
    header main footer nav
    div section article
    h1 h2 h3
    p span a
    ul ol li
    meta link
    time img
    ;
  inherit (lib.tags) title;
  inherit (lib) attrs escapeHTML;
in
{
  website.layouts = {
    # Reusable partials
    partials = {
      head = { pageTitle, description ? metadata.description }:
        [
          (meta [ (attrs.charset "UTF-8") ])
          (meta [ (attrs.name "viewport") (attrs.content "width=device-width, initial-scale=1") ])
          (meta [ (attrs.name "description") (attrs.content description) ])
          (meta [ (attrs.property "og:title") (attrs.content pageTitle) ])
          (meta [ (attrs.property "og:type") (attrs.content "website") ])
          (title pageTitle)
          (link [ (attrs.rel "stylesheet") (attrs.href "/css/style.css") ])
          (link [ (attrs.rel "alternate") (attrs.type "application/rss+xml") (attrs.href "/blog/index.xml") ])
        ];

      header = { }:
        header [ (attrs.class "site-header") ] [
          (div [ (attrs.class "container") ] [
            (a [ (attrs.href "/") (attrs.class "logo") ] [ metadata.title ])
            (nav [ (attrs.class "main-nav") ] [
              (ul [] [
                (li [] [ (a [ (attrs.href "/") ] [ "Home" ]) ])
                (li [] [ (a [ (attrs.href "/blog") ] [ "Blog" ]) ])
                (li [] [ (a [ (attrs.href "/about") ] [ "About" ]) ])
              ])
            ])
          ])
        ];

      footer = { }:
        footer [ (attrs.class "site-footer") ] [
          (div [ (attrs.class "container") ] [
            (p [] [ "© 2026 ${metadata.title}. All rights reserved." ])
            (p [] [
              "Built with "
              (a [ (attrs.href "https://github.com/arnarg/nixtml") ] [ "nixtml" ])
            ])
          ])
        ];

      postMeta = { item }:
        div [ (attrs.class "post-meta") ] [
          (time [ (attrs.data "datetime" item.dateW3C) ] [ item.date ])
          (if (item.metadata.tags or []) != [] then
            (span [ (attrs.class "tags") ]
              (map (tag:
                a [ (attrs.href "/blog/tags/${tag}") (attrs.class "tag") ] [ "#${tag}" ]
              ) item.metadata.tags))
          else "")
        ];
    };

    # Base template
    base = { path, content, title, ... }:
      let
        pageTitle = if title != null
          then "${title} - ${metadata.title}"
          else metadata.title;
      in
      "<!DOCTYPE html>\n"
      + (html [ (attrs.lang metadata.lang) ] [
          (head [] (partials.head { inherit pageTitle; }))
          (body [ (attrs.class "page") ] [
            (partials.header {})
            (main [ (attrs.class "main-content") ] [
              (div [ (attrs.class "container") ] [ content ])
            ])
            (partials.footer {})
          ])
        ]);

    # Homepage
    home = { content, ... }:
      section [ (attrs.class "homepage") ] [
        content
      ];

    # Regular pages
    page = { metadata, content, ... }:
      article [ (attrs.class "page-content") ] [
        (header [] [
          (h1 [] [ metadata.title ])
          (if metadata ? date then
            (time [] [ metadata.date ])
          else "")
        ])
        (div [ (attrs.class "content") ] [ content ])
      ];

    # Collection listing
    collection = {
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
        (h1 [] [ "Blog" ])

        (div [ (attrs.class "posts") ]
          (map (item:
            article [ (attrs.class "post-preview") ] [
              (h2 [] [ (a [ (attrs.href item.url) ] [ item.title ]) ])
              (partials.postMeta { inherit item; })
              (p [ (attrs.class "summary") ] [ item.summary ])
              (a [ (attrs.href item.url) (attrs.class "read-more") ] [ "Read more →" ])
            ]
          ) items))

        (nav [ (attrs.class "pagination") ] [
          (if hasPrev
            then (a [ (attrs.href prevPageURL) (attrs.class "prev") ] [ "← Newer Posts" ])
            else (span [ (attrs.class "prev disabled") ] [ "← Newer Posts" ]))
          (span [ (attrs.class "page-info") ] [ "Page ${toString pageNumber} of ${toString totalPages}" ])
          (if hasNext
            then (a [ (attrs.href nextPageURL) (attrs.class "next") ] [ "Older Posts →" ])
            else (span [ (attrs.class "next disabled") ] [ "Older Posts →" ]))
        ])
      ];

    # Taxonomy pages
    taxonomy = {
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
        (h1 [] [ "Posts tagged #${title}" ])
        (p [ (attrs.class "taxonomy-meta") ] [ "${toString (builtins.length items)} posts" ])

        (ul [ (attrs.class "post-list") ]
          (map (item:
            li [] [
              (a [ (attrs.href item.url) ] [ item.title ])
              (span [ (attrs.class "date") ] [ " — ${item.date}" ])
            ]
          ) items))

        (nav [ (attrs.class "pagination") ] [
          (if hasPrev then (a [ (attrs.href prevPageURL) ] [ "← Newer" ]) else "")
          (span [] [ " Page ${toString pageNumber}/${toString totalPages} " ])
          (if hasNext then (a [ (attrs.href nextPageURL) ] [ "Older →" ]) else "")
        ])
      ];
  };
}
```

## Tips and Best Practices

1. **Start simple**: Begin with string templates, then refactor to functional HTML
2. **Use partials**: Extract repeated markup into partials
3. **Prefer functional HTML**: It catches typos and provides structure
4. **Escape user input**: Use `escapeHTML` for any dynamic content
5. **Keep templates focused**: Complex logic should live outside templates
6. **Test incrementally**: Build and check after each change
