---
title: Taxonomies and RSS
description: Classify collection items with tags, categories, authors, and other custom terms
---

Taxonomies classify the items in a collection. A taxonomy such as `tags` has terms such as `nix` or `tutorial`, and each term gets its own paginated listing and optional RSS feed.

Taxonomies always belong to a collection; they do not independently classify every Markdown page on a site.

## Enable a Taxonomy

Declare the frontmatter keys to use on a collection:

```nix
website.collections.blog = {
  path = "blog/posts";
  pagination.perPage = 5;
  taxonomies = [ "tags" "categories" ];
};
```

Then assign terms in each item's frontmatter:

```markdown
---
title: Getting started with nixtml
date: 2026-01-19T10:00:00
tags:
  - nix
  - beginner
  - tutorial
categories:
  - guides
---

Post content...
```

A post can belong to multiple terms. Terms under keys not listed in `taxonomies` remain ordinary metadata but do not generate taxonomy pages.

## Generated URLs

For a collection with `path = "blog/posts"`, the examples above generate:

| Content | First page | RSS feed |
| --- | --- | --- |
| Tag `nix` | `blog/tags/nix/index.html` | `blog/tags/nix/index.xml` |
| Tag `beginner` | `blog/tags/beginner/index.html` | `blog/tags/beginner/index.xml` |
| Category `guides` | `blog/categories/guides/index.html` | `blog/categories/guides/index.xml` |

Additional listing pages use paths such as `blog/tags/nix/page/2/index.html`. The collection's `pagination.perPage` setting also controls taxonomy pagination.

A root collection with `path = "posts"` omits the `blog` prefix: its term pages start at `tags/<term>/index.html`.

Feeds for a collection and all of its terms are included when that collection has `rss.enable = true`, which is the default.

## Render a Taxonomy Listing

`website.layouts.taxonomy` receives `title` for the current term, `taxonomy` for its type, and the collection pagination values:

```nix
website.layouts.taxonomy = { taxonomy, title, items, ... }:
  [
    (lib.tags.h1 [ ] [ "${taxonomy}: ${title}" ])
    (lib.tags.p [ ] [
      "${toString (builtins.length items)} items on this page"
    ])
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

Pagination uses the same `hasNext`, `hasPrev`, `nextPageURL`, and `prevPageURL` values as a collection layout. See [Layouts and partials](/nixtml/templating/#collection-layouts) for pagination controls and the [Template Context Reference](/nixtml/reference/templates/) for all values.

Minima supplies a ready-made taxonomy listing layout.

## Display Terms on Posts

Page layouts receive terms through frontmatter metadata. This example renders a post's tags for the blog collection used above:

```nix
{ lib, config, ... }:
{
  website.layouts.page = { metadata, content, ... }:
    let
      tags = metadata.tags or [ ];
    in
    [
      (lib.tags.h1 [ ] [ metadata.title ])
      (lib.optionalString (tags != [ ]) (
        lib.tags.ul [ (lib.attrs.class "tags") ] (
          map (tag:
            lib.tags.li [ ] [
              (lib.tags.a [
                (lib.attrs.href (
                  config.website.baseURI + "blog/tags/${tag}/"
                ))
              ] [ tag ])
            ]) tags
        )
      ))
      content
    ];
}
```

The URL prefix depends on the collection path and taxonomy name. Adjust `blog/tags` for your own setup.

In collection and taxonomy listings, access the same values through `item.metadata.tags` rather than `metadata.tags`.

## Multiple Taxonomy Types

A collection can use any frontmatter keys that contain lists of strings:

```nix
website.collections.blog = {
  path = "blog/posts";
  taxonomies = [ "tags" "categories" "authors" "series" ];
};
```

```markdown
---
title: Building a blog with Nix
date: 2026-01-19T10:00:00
tags:
  - nix
  - web
categories:
  - tutorials
authors:
  - jane-doe
series:
  - nix-web-development
---
```

This creates separate page families under `blog/tags`, `blog/categories`, `blog/authors`, and `blog/series`. The taxonomy layout can use `taxonomy` to adjust its heading or feed links rather than assuming every listing represents tags.

## Link a Term Feed

Add a term's feed to its taxonomy layout when readers may want to subscribe to that topic. This fragment assumes the surrounding module receives `config`:

```nix
website.layouts.taxonomy =
  { taxonomy, title, items, ... }:
  [
    (lib.tags.a [
      (lib.attrs.rel "alternate")
      (lib.attrs.type "application/rss+xml")
      (lib.attrs.href (
        config.website.baseURI
        + "blog/${taxonomy}/${title}/index.xml"
      ))
    ] [ "RSS feed for ${title}" ])
    # Render items and pagination...
  ];
```

Only generate this link when the collection's RSS support is enabled and its path is `blog/posts`.

## Naming Terms

Terms become URL path segments without slugification. Use consistent lowercase, hyphenated values:

```yaml
# Good
tags:
  - nix-flakes
  - getting-started
```

Avoid varying capitalization or punctuation for the same conceptual term, and avoid characters that need URL encoding. Keeping terms consistent prevents fragmented listings and makes generated URLs predictable.

## Examples

The [Minima example](https://github.com/arnarg/nixtml/tree/main/examples/minima) combines collection pagination, tags, excerpts, and feeds. Build it from a nixtml checkout with:

```bash
nix build .#examples.minima
```
