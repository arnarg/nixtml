---
title: Template Context Reference
description: The values passed to nixtml page, collection, taxonomy, and base layouts
---

Every nixtml layout is a function that receives an attribute set. The available attributes depend on the kind of page being rendered.

Layout functions can return either a string or a list of strings. Nested HTML helper calls return strings, so they can be included directly in those lists.

## Rendering Order

nixtml renders a page-specific layout first and then passes its output to `website.layouts.base` as `content`:

```text
content file or generated page
  → home, page, collection, or taxonomy layout
  → base layout
  → formatted HTML file
```

The base layout receives the original page context as well as the rendered `content`. It can therefore use values such as `path`, `title`, and `metadata` when they are present.

## Common Values

| Value | Type | Description |
| --- | --- | --- |
| `path` | list of strings | Output path segments, including the final `index.html` or other filename |
| `title` | string or `null` | Page title, collection `null` value, or taxonomy term |

Markdown page layouts also receive `content` as HTML produced by the content processor. In the base layout, `content` is instead the already-rendered result of every kind of page-specific layout.

## Home and Page Layouts

`website.layouts.home` renders `content/index.md`. Other Markdown files use `website.layouts.page`.

Both layouts receive:

| Value | Description |
| --- | --- |
| `path` | Homepage: `[ "index.html" ]`; other pages: their output path segments |
| `metadata` | All parsed YAML frontmatter |
| `content` | HTML produced from the Markdown body |
| `title` | `metadata.title`, or `null` when no title is present |

For example, `content/about.md` normally has this path:

```nix
[ "about" "index.html" ]
```

Frontmatter can contain arbitrary values. Access optional fields with a default instead of assuming they exist:

```nix
website.layouts.page = { metadata, content, ... }:
  let
    description = metadata.description or "";
    tags = metadata.tags or [ ];
  in
  [
    # Render the page using these values.
    content
  ];
```

## Collection Layouts

`website.layouts.collection` receives one pagination page at a time:

| Value | Type | Description |
| --- | --- | --- |
| `path` | list of strings | Current collection output path |
| `pageNumber` | integer | Current one-based page number |
| `totalPages` | integer | Total pages in this collection |
| `items` | list | Collection items on this page |
| `hasNext` | Boolean | Whether a later page exists |
| `hasPrev` | Boolean | Whether an earlier page exists |
| `nextPageURL` | string | URL of the next page; only access it when `hasNext` is true |
| `prevPageURL` | string | URL of the previous page; only access it when `hasPrev` is true |
| `title` | `null` | Collections do not have a taxonomy term title |

A first page at `blog/index.html` has `[ "blog" "index.html" ]` as its path. A later page can have a path such as `[ "blog" "page" "2" "index.html" ]`.

See [Collections and pagination](/nixtml/collections/) for configuration and a rendering example.

## Taxonomy Layouts

Taxonomy layouts receive the same pagination values as collection layouts, plus:

| Value | Description |
| --- | --- |
| `title` | The current taxonomy term, such as `nix` |
| `taxonomy` | The taxonomy name, such as `tags` |

For a collection at `blog/posts`, a taxonomy page might have this path:

```nix
[ "blog" "tags" "nix" "index.html" ]
```

See [Taxonomies and RSS](/nixtml/taxonomies/) for term setup and generated URLs.

## Collection Item Values

Each value in `items` contains:

| Value | Type | Description |
| --- | --- | --- |
| `title` | string | Item title from frontmatter |
| `date` | string | Date formatted with the configured Markdown date format |
| `dateEpoch` | number | Timestamp used for newest-first sorting |
| `dateRFC822` | string | RFC 822 date used in RSS |
| `dateW3C` | string | W3C date (`YYYY-MM-DD`) |
| `url` | string | Base-URI-aware item URL |
| `permalink` | string | Absolute item URL based on `website.baseURL` |
| `content` | string | Full rendered item HTML |
| `summary` | string | Rendered content before `<!--more-->`, or all content without a marker |
| `metadata` | attribute set | Remaining frontmatter after standard item values are removed |

Taxonomy lists and other custom fields are available through `item.metadata`:

```nix
let
  tags = item.metadata.tags or [ ];
in
# Render tags for this item.
tags
```

Collection items require the standard title and date fields used by collection processing.

## Partials

`website.layouts.partials` is an attribute set of reusable functions. Partials do not have a fixed context: each partial defines its own arguments.

```nix
website.layouts.partials.pageHeading =
  { title, description ? null }:
  [
    (lib.tags.h1 [ ] [ title ])
    (lib.optionalString (description != null)
      (lib.tags.p [ ] [ description ]))
  ];
```

Call a partial with the values it declares:

```nix
partials.pageHeading {
  title = metadata.title;
  description = metadata.description or null;
}
```

The [Layouts and partials guide](/nixtml/templating/) shows how to include partials in complete layouts.
