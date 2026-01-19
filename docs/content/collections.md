---
title: Collections in nixtml
date: 2026-01-19T21:00:00
description: Learn how to organize content with collections
---

Collections allow you to group, paginate, and list related content such as blog posts, portfolio pieces, or any other content type that benefits from organization and pagination.

## What Collections Do

When you create a collection, nixtml automatically:

1. **Gathers content** from a specified directory
2. **Sorts items** by date (newest first)
3. **Creates pagination pages** for browsing items
4. **Generates RSS feeds** for syndication
5. **Creates taxonomy pages** for tags, categories, etc.

## Basic Collection Setup

Add a collection to your website configuration:

```nix
{
  website.collections.blog = {
    path = "posts";
    pagination.perPage = 5;
  };
}
```

### Understanding the Path

The `path` option determines both where content is read from and where pagination pages are created:

| `path` Value | Content Directory | Pagination URLs |
|--------------|-------------------|-----------------|
| `"posts"` | `./content/posts/` | `/index.html`, `/page/2/index.html` |
| `"blog/posts"` | `./content/blog/posts/` | `/blog/index.html`, `/blog/page/2/index.html` |
| `"writing/articles"` | `./content/writing/articles/` | `/writing/index.html`, `/writing/page/2/index.html` |

The pagination pages are created in the **parent directory** of the path.

## Directory Structure

A typical blog setup looks like this:

```
my-website/
├── flake.nix
├── layouts.nix
└── content/
    ├── index.md              # Homepage
    ├── about.md              # About page
    └── blog/
        └── posts/            # Collection content
            ├── first-post.md
            ├── second-post.md
            └── third-post.md
```

With the configuration:

```nix
website.collections.blog = {
  path = "blog/posts";
  pagination.perPage = 2;
};
```

This generates:

```
result/
├── index.html                # Homepage
├── about/index.html          # About page
├── blog/
│   ├── index.html            # Collection page 1 (2 posts)
│   ├── index.xml             # RSS feed
│   └── page/
│       └── 2/
│           └── index.html    # Collection page 2 (1 post)
└── blog/posts/
    ├── first-post/index.html
    ├── second-post/index.html
    └── third-post/index.html
```

## Writing Collection Content

Each markdown file in the collection needs proper frontmatter:

```markdown
---
title: My First Blog Post
date: 2026-01-15T10:00:00
tags:
  - nix
  - tutorial
---

This is the introduction paragraph that appears in listings.

<!--more-->

This content only appears on the full post page, not in summaries.
```

### Required Frontmatter

| Field | Description |
|-------|-------------|
| `title` | Post title (displayed in listings) |
| `date` | Publication date in ISO 8601 format |

### The `<!--more-->` Tag

Use `<!--more-->` to mark where the summary ends:

```markdown
---
title: Understanding Nix Flakes
date: 2026-01-19
---

Nix flakes provide a standard way to write Nix expressions
with better reproducibility and composability.

<!--more-->

## What are Flakes?

Flakes are an experimental feature...
```

The `item.summary` in templates contains everything **before** the `<!--more-->` tag. If omitted, `summary` contains the entire content.

## Collection Configuration Options

```nix
website.collections.<name> = {
  # Required: Path to content within content.dir
  path = "posts";

  # Pagination settings
  pagination.perPage = 5;  # Default: 5

  # Taxonomy groupings
  taxonomies = [ "tags" "categories" ];  # Default: []

  # RSS feed settings
  rss.enable = true;   # Default: true
  rss.limit = 50;      # Default: 50
};
```

## Collection Item Properties

Each item in a collection has these properties available in templates:

| Property | Type | Description |
|----------|------|-------------|
| `title` | string | Post title from frontmatter |
| `date` | string | Formatted date (e.g., "Jan 15, 2026") |
| `dateEpoch` | number | Unix timestamp |
| `dateRFC822` | string | RFC 822 date for RSS feeds |
| `dateW3C` | string | W3C date format (YYYY-MM-DD) |
| `url` | string | Relative URL (e.g., `/blog/posts/my-post`) |
| `permalink` | string | Full URL (e.g., `https://example.com/blog/posts/my-post`) |
| `content` | string | Full HTML content |
| `summary` | string | Content before `<!--more-->` |
| `metadata` | attrs | All other frontmatter fields |

## Collection Template

The `collection` layout renders pagination pages:

```nix
{ lib, config, ... }:
let
  inherit (lib.tags) div h1 h2 ul li a p span article;
  inherit (lib) attrs;
in
{
  website.layouts.collection = {
    pageNumber,    # Current page (1, 2, 3...)
    totalPages,    # Total number of pages
    items,         # List of posts on this page
    hasNext,       # true if next page exists
    hasPrev,       # true if previous page exists
    nextPageURL,   # URL to next page (throws if !hasNext)
    prevPageURL,   # URL to previous page (throws if !hasPrev)
    ...
  }:
    [
      (h1 [] [ "Blog" ])

      # List of posts
      (div [ (attrs.class "posts") ]
        (map (item:
          article [ (attrs.class "post-preview") ] [
            (h2 [] [ (a [ (attrs.href item.url) ] [ item.title ]) ])
            (p [ (attrs.class "date") ] [ item.date ])
            (p [ (attrs.class "summary") ] [ item.summary ])
            (a [ (attrs.href item.url) ] [ "Read more →" ])
          ]
        ) items)
      )

      # Pagination navigation
      (div [ (attrs.class "pagination") ] [
        (if hasPrev
          then (a [ (attrs.href prevPageURL) (attrs.class "prev") ] [ "← Newer" ])
          else (span [ (attrs.class "prev disabled") ] [ "← Newer" ]))

        (span [ (attrs.class "page-info") ]
          [ "Page ${toString pageNumber} of ${toString totalPages}" ])

        (if hasNext
          then (a [ (attrs.href nextPageURL) (attrs.class "next") ] [ "Older →" ])
          else (span [ (attrs.class "next disabled") ] [ "Older →" ]))
      ])
    ];
}
```

## Taxonomies

Taxonomies let readers browse content by category. See the [Taxonomies Guide](/nixtml/taxonomies) for full documentation.

### Quick Setup

```nix
website.collections.blog = {
  path = "blog/posts";
  taxonomies = [ "tags" "categories" ];
};
```

### In Content

```markdown
---
title: Getting Started with Nix
date: 2026-01-19
tags:
  - nix
  - beginner
categories:
  - tutorials
---
```

### Generated Pages

| Taxonomy Term | Page URL | RSS Feed |
|---------------|----------|----------|
| tags: nix | `/blog/tags/nix/index.html` | `/blog/tags/nix/index.xml` |
| tags: beginner | `/blog/tags/beginner/index.html` | `/blog/tags/beginner/index.xml` |
| categories: tutorials | `/blog/categories/tutorials/index.html` | `/blog/categories/tutorials/index.xml` |

### Taxonomy Template

```nix
website.layouts.taxonomy = {
  title,         # The taxonomy term (e.g., "nix")
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
    (h1 [] [ "Tagged: ${title}" ])
    (ul [] (map (item:
      li [] [ (a [ (attrs.href item.url) ] [ item.title ]) ]
    ) items))
    # ... pagination controls
  ];
```

## RSS Feeds

RSS feeds are generated automatically when `rss.enable = true` (the default).

### Feed Locations

| Collection Config | RSS Feed URL |
|-------------------|--------------|
| `path = "posts"` | `/index.xml` |
| `path = "blog/posts"` | `/blog/index.xml` |

### Linking to RSS

Add a link in your base template:

```nix
(link [
  (attrs.rel "alternate")
  (attrs.type "application/rss+xml")
  (attrs.title "RSS Feed")
  (attrs.href "/blog/index.xml")
])
```

## Complete Example

Here's a full blog setup:

### `flake.nix`

```nix
{
  description = "My blog";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixtml.url = "github:arnarg/nixtml";
  };

  outputs = { self, nixpkgs, flake-utils, nixtml }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = nixtml.lib.mkWebsite {
          inherit pkgs;
          name = "my-blog";
          baseURL = "https://my-blog.com";

          metadata = {
            lang = "en";
            title = "My Blog";
            description = "Thoughts on Nix and programming";
          };

          content.dir = ./content;

          collections.blog = {
            path = "blog/posts";
            pagination.perPage = 5;
            taxonomies = [ "tags" ];
            rss.enable = true;
          };

          imports = [ ./layouts.nix ];
        };
      }
    );
}
```

### `layouts.nix`

```nix
{ lib, config, ... }:
let
  inherit (config.website) metadata;
  inherit (lib.tags) html head body div h1 h2 ul li a p article nav span;
  inherit (lib.tags) title meta link;
  inherit (lib) attrs;
in
{
  website.layouts = {
    base = { path, content, ... }:
      "<!DOCTYPE html>\n"
      + (html [ (attrs.lang metadata.lang) ] [
          (head [] [
            (meta [ (attrs.charset "UTF-8") ])
            (title metadata.title)
            (link [
              (attrs.rel "alternate")
              (attrs.type "application/rss+xml")
              (attrs.href "/blog/index.xml")
            ])
          ])
          (body [] [
            (nav [] [
              (a [ (attrs.href "/") ] [ "Home" ])
              " | "
              (a [ (attrs.href "/blog") ] [ "Blog" ])
            ])
            (div [ (attrs.class "content") ] [ content ])
          ])
        ]);

    home = { content, ... }: content;

    page = { metadata, content, ... }: [
      (h1 [] [ metadata.title ])
      content
    ];

    collection = { pageNumber, totalPages, items, hasNext, hasPrev, nextPageURL, prevPageURL, ... }:
      [
        (h1 [] [ "Blog" ])
        (div [ (attrs.class "posts") ]
          (map (item:
            article [] [
              (h2 [] [ (a [ (attrs.href item.url) ] [ item.title ]) ])
              (p [] [ item.date ])
              (p [] [ item.summary ])
            ]
          ) items)
        )
        (div [ (attrs.class "pagination") ] [
          (if hasPrev then (a [ (attrs.href prevPageURL) ] [ "← Newer" ]) else "")
          " Page ${toString pageNumber}/${toString totalPages} "
          (if hasNext then (a [ (attrs.href nextPageURL) ] [ "Older →" ]) else "")
        ])
      ];

    taxonomy = { title, pageNumber, totalPages, items, hasNext, hasPrev, nextPageURL, prevPageURL, ... }:
      [
        (h1 [] [ "Tagged: ${title}" ])
        (ul []
          (map (item: li [] [ (a [ (attrs.href item.url) ] [ item.title ]) ]) items)
        )
        (div [] [
          (if hasPrev then (a [ (attrs.href prevPageURL) ] [ "← Prev" ]) else "")
          " Page ${toString pageNumber}/${toString totalPages} "
          (if hasNext then (a [ (attrs.href nextPageURL) ] [ "Next →" ]) else "")
        ])
      ];
  };
}
```

### `content/blog/posts/hello-world.md`

```markdown
---
title: Hello World
date: 2026-01-19T10:00:00
tags:
  - announcements
---

Welcome to my new blog! I'll be writing about Nix and programming.

<!--more-->

## What to Expect

I plan to cover topics like:
- Nix flakes
- NixOS configuration
- Functional programming

Stay tuned!
```

## Multiple Collections

You can have multiple independent collections:

```nix
website.collections = {
  blog = {
    path = "blog/posts";
    pagination.perPage = 5;
    taxonomies = [ "tags" ];
  };

  projects = {
    path = "portfolio/projects";
    pagination.perPage = 10;
    rss.enable = false;  # No RSS for portfolio
  };

  notes = {
    path = "notes";
    pagination.perPage = 20;
    taxonomies = [ "topics" ];
  };
};
```

Each collection operates independently with its own pagination, taxonomies, and RSS feeds.

## Best Practices

1. **Use descriptive paths**: `blog/posts` is clearer than just `posts`
2. **Set appropriate pagination**: 5-10 items for blogs, more for portfolios
3. **Always include dates**: Required for proper sorting
4. **Use `<!--more-->` tags**: Keeps listing pages clean
5. **Consistent taxonomy terms**: Use lowercase, hyphenated terms
6. **Limit RSS feeds**: 20-50 items is usually sufficient
