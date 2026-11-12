---
title: Collections and Pagination
description: Group dated content into sorted listings, paginated pages, summaries, and RSS feeds
nav:
  section: guides
  order: 40
  label: Collections and pagination
---

Collections gather dated pages from a content directory and generate sorted listing pages. Use them for blogs, portfolios, release notes, or other content that readers browse as a series.

For a ready-made blog presentation, Minima provides collection, pagination, and feed layouts. The configuration is the same with a custom theme.

## Create a Collection

Add a collection to `mkWebsite`:

```nix
nixtml.lib.mkWebsite {
  # Other settings...
  collections.blog = {
    path = "blog/posts";
    pagination.perPage = 5;
    taxonomies = [ "tags" ];
    rss.enable = true;
  };
}
```

Inside a nixtml module, use the equivalent option path:

```nix
website.collections.blog = {
  path = "blog/posts";
  pagination.perPage = 5;
};
```

The collection's attribute name (`blog` here) identifies it in configuration. Its `path` identifies the content location and influences generated listing URLs.

## Paths and Generated Pages

Collection listing pages are created in the parent of the configured content path:

| `path` | Content read from | First listing page |
| --- | --- | --- |
| `"posts"` | `content/posts/` | `index.html` |
| `"blog/posts"` | `content/blog/posts/` | `blog/index.html` |
| `"writing/articles"` | `content/writing/articles/` | `writing/index.html` |

Additional pages use `page/2`, `page/3`, and so on beneath the listing path.

For `path = "blog/posts"`, this input:

```text
content/
├── about.md
└── blog/
    └── posts/
        ├── first-post.md
        └── second-post.md
```

produces the individual post pages plus:

```text
blog/index.html          # First collection page
blog/index.xml           # RSS, when enabled
blog/posts/first-post/index.html
blog/posts/second-post/index.html
```

With enough items for another listing page, nixtml also produces `blog/page/2/index.html`.

The special root collection path `"posts"` creates its listing at `index.html`. Avoid combining that with a separate `content/index.md`, because both would target the homepage.

## Write Collection Items

Give each item a title and an unquoted ISO 8601 datetime:

```markdown
---
title: My first post
date: 2026-01-19T10:00:00
tags:
  - nix
  - tutorial
---

This introduction becomes the summary in collection listings.

<!--more-->

This additional content appears on the full post page.
```

Items are sorted by date, newest first. Dates also supply the formatted values used by layouts, feeds, and sitemaps.

The exact HTML comment `<!--more-->` separates the summary from the rest of the post. `item.summary` contains the rendered content before that marker. Without a marker, it contains the full rendered content.

See [Content and frontmatter](/nixtml/content/) for metadata handling and [Taxonomies and RSS](/nixtml/taxonomies/) for tags such as those in this example.

## Render a Listing

The `website.layouts.collection` function receives the current page's `items`. Minimal post-preview markup might look like this:

```nix
map (item:
  lib.tags.article [ ] [
    (lib.tags.h2 [ ] [
      (lib.tags.a [
        (lib.attrs.href item.url)
      ] [ item.title ])
    ])
    (lib.tags.time [
      (lib.mkAttr "datetime" item.dateW3C)
    ] [ item.date ])
    (lib.tags.div [
      (lib.attrs.class "summary")
    ] [ item.summary ])
    (lib.tags.a [
      (lib.attrs.href item.url)
    ] [ "Read more" ])
  ]
) items
```

Commonly used item values are `title`, `date`, `dateW3C`, `url`, `permalink`, `content`, `summary`, and `metadata`. Custom frontmatter such as `tags` is available through `item.metadata`; see the [Template Context Reference](/nixtml/reference/templates/) for the complete table.

The layout also receives `pageNumber`, `totalPages`, `hasNext`, `hasPrev`, `nextPageURL`, and `prevPageURL`. [Layouts and partials](/nixtml/templating/#collection-layouts) includes pagination controls and explains how to guard the next and previous URLs.

Themes such as Minima already implement this layout, including pagination and optional excerpts.

## Taxonomies

Set `taxonomies` to a list of frontmatter keys used to group collection items:

```nix
website.collections.blog = {
  path = "blog/posts";
  taxonomies = [ "tags" "categories" ];
};
```

nixtml then generates listing and feed pages for each declared taxonomy term. The dedicated [Taxonomies and RSS guide](/nixtml/taxonomies/) covers their URLs and templates without repeating the collection setup here.

## RSS Feeds

Collection RSS generation is enabled by default. Disable it when a collection does not need a feed:

```nix
website.collections.portfolio.rss.enable = false;
```

The feed location follows the listing path:

| Collection path | Feed output |
| --- | --- |
| `"posts"` | `index.xml` |
| `"blog/posts"` | `blog/index.xml` |
| `"writing/articles"` | `writing/index.xml` |

Add feed discovery to the base layout when appropriate:

```nix
lib.tags.link [
  (lib.attrs.rel "alternate")
  (lib.attrs.type "application/rss+xml")
  (lib.attrs.title "Blog RSS feed")
  (lib.attrs.href (config.website.baseURI + "blog/index.xml"))
]
```

Minima emits this discovery link when `themes.minima.feedPath` matches the generated feed path.

## Multiple Collections

Collections are independent and can use different page sizes, taxonomies, and feed settings:

```nix
website.collections = {
  blog = {
    path = "blog/posts";
    pagination.perPage = 5;
    taxonomies = [ "tags" ];
  };

  projects = {
    path = "portfolio/projects";
    pagination.perPage = 12;
    rss.enable = false;
  };
};
```

All content paths remain relative to `website.content.dir`.

## Complete Examples

Rather than maintaining duplicate full flakes in each guide, use the buildable repository examples:

- [Blog example](https://github.com/arnarg/nixtml/tree/main/examples/blog)
- [Minima blog example](https://github.com/arnarg/nixtml/tree/main/examples/minima)

From a nixtml checkout, run `nix build .#examples.blog` or `nix build .#examples.minima`.
