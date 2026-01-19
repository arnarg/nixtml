---
title: Taxonomies in nixtml
date: 2026-01-19T21:00:00
description: Organize your content with tags, categories, and custom taxonomies
---

Taxonomies provide a way to classify and organize your content, making it easier for readers to find related posts. nixtml supports custom taxonomies like tags, categories, authors, series, and any other grouping you need.

## What Are Taxonomies?

Taxonomies are classification systems for your content. Each taxonomy has **terms** (values), and content can have multiple terms per taxonomy.

**Common taxonomy examples:**

| Taxonomy | Terms | Use Case |
|----------|-------|----------|
| `tags` | nix, tutorial, beginner | Specific keywords |
| `categories` | programming, guides | Broad topics |
| `authors` | john-doe, jane-smith | Content creators |
| `series` | nix-basics, advanced-flakes | Multi-part content |
| `difficulty` | beginner, intermediate | Skill levels |

## Quick Start

### 1. Enable Taxonomies

Add taxonomies to your collection:

```nix
website.collections.blog = {
  path = "blog/posts";
  taxonomies = [ "tags" ];
};
```

### 2. Add Terms to Content

In your markdown frontmatter:

```markdown
---
title: Getting Started with Nix
date: 2026-01-19
tags:
  - nix
  - beginner
  - tutorial
---

Your content here...
```

### 3. Define the Taxonomy Template

```nix
website.layouts.taxonomy = { title, items, ... }:
  [
    (h1 [] [ "Posts tagged: ${title}" ])
    (ul [] (map (item: li [] [ item.title ]) items))
  ];
```

That's it! nixtml automatically generates pages for each tag.

## Generated URLs

Taxonomy pages are created based on your collection's path:

### Example: `path = "blog/posts"`

| Content | Generated URL |
|---------|---------------|
| Tag page: nix | `/blog/tags/nix/index.html` |
| Tag page 2: nix | `/blog/tags/nix/page/2/index.html` |
| RSS feed: nix | `/blog/tags/nix/index.xml` |
| Category page | `/blog/categories/tutorials/index.html` |

### Example: `path = "posts"`

| Content | Generated URL |
|---------|---------------|
| Tag page: nix | `/tags/nix/index.html` |
| RSS feed: nix | `/tags/nix/index.xml` |

The pattern is: `/{collection-prefix}/{taxonomy}/{term}/`

## Taxonomy Template

The `taxonomy` layout receives these context variables:

| Variable | Type | Description |
|----------|------|-------------|
| `title` | string | The taxonomy term (e.g., "nix") |
| `pageNumber` | int | Current page number (1-indexed) |
| `totalPages` | int | Total number of pages |
| `items` | list | Posts on this page |
| `hasNext` | bool | Whether next page exists |
| `hasPrev` | bool | Whether previous page exists |
| `nextPageURL` | string | URL to next page |
| `prevPageURL` | string | URL to previous page |

### Complete Template Example

```nix
{ lib, config, ... }:
let
  inherit (lib.tags) div h1 h2 ul li a p span article;
  inherit (lib) attrs;
in
{
  website.layouts.taxonomy = {
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
      # Header with term name
      (h1 [] [ "Posts tagged: #${title}" ])

      # Post count
      (p [ (attrs.class "taxonomy-meta") ]
        [ "${toString (builtins.length items)} posts" ])

      # List of posts
      (div [ (attrs.class "post-list") ]
        (map (item:
          article [ (attrs.class "post-preview") ] [
            (h2 [] [
              (a [ (attrs.href item.url) ] [ item.title ])
            ])
            (div [ (attrs.class "post-meta") ] [
              (span [ (attrs.class "date") ] [ item.date ])
            ])
            (p [ (attrs.class "summary") ] [ item.summary ])
          ]
        ) items)
      )

      # Pagination
      (div [ (attrs.class "pagination") ] [
        (if hasPrev
          then (a [ (attrs.href prevPageURL) (attrs.class "prev") ] [ "← Newer Posts" ])
          else (span [ (attrs.class "prev disabled") ] [ "← Newer Posts" ]))

        (span [ (attrs.class "page-info") ]
          [ "Page ${toString pageNumber} of ${toString totalPages}" ])

        (if hasNext
          then (a [ (attrs.href nextPageURL) (attrs.class "next") ] [ "Older Posts →" ])
          else (span [ (attrs.class "next disabled") ] [ "Older Posts →" ]))
      ])
    ];
}
```

## Displaying Tags on Posts

To show tags on individual posts, access them via `metadata`:

### In the Page Template

```nix
website.layouts.page = { metadata, content, ... }:
  let
    # Get tags, defaulting to empty list
    tags = metadata.tags or [];
  in
  [
    (h1 [] [ metadata.title ])

    # Show tags if present
    (if tags != [] then
      (div [ (attrs.class "tags") ]
        (map (tag:
          a [
            (attrs.href "/blog/tags/${tag}")
            (attrs.class "tag")
          ] [ "#${tag}" ]
        ) tags)
      )
    else "")

    # Post content
    (div [ (attrs.class "content") ] [ content ])
  ];
```

### In Collection Listings

```nix
website.layouts.collection = { items, ... }:
  (div []
    (map (item:
      article [] [
        (h2 [] [ item.title ])
        (p [] [ item.date ])

        # Tags from item.metadata
        (if (item.metadata.tags or []) != [] then
          (div [ (attrs.class "tags") ]
            (map (tag:
              a [ (attrs.href "/blog/tags/${tag}") ] [ "#${tag}" ]
            ) item.metadata.tags)
          )
        else "")
      ]
    ) items)
  );
```

## Multiple Taxonomy Types

You can have any number of taxonomies:

```nix
website.collections.blog = {
  path = "blog/posts";
  taxonomies = [
    "tags"
    "categories"
    "authors"
    "series"
  ];
};
```

### Content with Multiple Taxonomies

```markdown
---
title: Building a Blog with Nix
date: 2026-01-19
tags:
  - nix
  - web
categories:
  - tutorials
authors:
  - john-doe
series:
  - nix-web-dev
---
```

This creates pages at:

- `/blog/tags/nix/`
- `/blog/tags/web/`
- `/blog/categories/tutorials/`
- `/blog/authors/john-doe/`
- `/blog/series/nix-web-dev/`

## RSS Feeds for Taxonomies

Each taxonomy term automatically gets an RSS feed:

| Term | RSS Feed URL |
|------|--------------|
| tags: nix | `/blog/tags/nix/index.xml` |
| categories: tutorials | `/blog/categories/tutorials/index.xml` |

Link to taxonomy RSS feeds in your templates:

```nix
website.layouts.taxonomy = { title, ... }:
  [
    (h1 [] [ "Posts tagged: ${title}" ])

    # RSS feed link
    (a [
      (attrs.href "/blog/tags/${title}/index.xml")
      (attrs.class "rss-link")
    ] [ "RSS Feed for #${title}" ])

    # ... rest of template
  ];
```

## Taxonomy Naming Conventions

### Recommended Practices

| Do | Don't |
|----|-------|
| `nix-flakes` | `Nix Flakes` |
| `getting-started` | `Getting Started` |
| `javascript` | `JavaScript` |
| `john-doe` | `John Doe` |

- **Use lowercase**: Avoids case-sensitivity issues
- **Use hyphens**: Creates clean URLs
- **Be consistent**: Same term should always be spelled the same

### URL-Safe Terms

Terms become part of URLs, so keep them URL-friendly:

```markdown
# Good
tags:
  - nix-flakes
  - getting-started

# Avoid
tags:
  - "Nix Flakes"      # Spaces in URLs
  - "C++"             # Special characters
```

## Complete Example

### Directory Structure

```
my-blog/
├── flake.nix
├── layouts.nix
└── content/
    └── blog/
        └── posts/
            ├── nix-intro.md
            ├── flakes-deep-dive.md
            └── nixos-config.md
```

### `content/blog/posts/nix-intro.md`

```markdown
---
title: Introduction to Nix
date: 2026-01-15
tags:
  - nix
  - beginner
categories:
  - tutorials
---

A beginner-friendly introduction to Nix.

<!--more-->

## What is Nix?

Nix is a powerful package manager...
```

### `flake.nix`

```nix
{
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
          };

          content.dir = ./content;

          collections.blog = {
            path = "blog/posts";
            pagination.perPage = 5;
            taxonomies = [ "tags" "categories" ];
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
  inherit (lib.tags) html head body div h1 h2 ul li a p span article nav;
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
          ])
          (body [] [ content ])
        ]);

    home = { content, ... }: content;

    page = { metadata, content, ... }:
      let tags = metadata.tags or [];
      in [
        (h1 [] [ metadata.title ])
        (if tags != [] then
          (div [ (attrs.class "tags") ]
            (map (tag: a [ (attrs.href "/blog/tags/${tag}") ] [ "#${tag} " ]) tags)
          )
        else "")
        content
      ];

    collection = { pageNumber, totalPages, items, hasNext, hasPrev, nextPageURL, prevPageURL, ... }:
      [
        (h1 [] [ "Blog" ])
        (div [] (map (item:
          article [] [
            (h2 [] [ (a [ (attrs.href item.url) ] [ item.title ]) ])
            (p [] [ item.date ])
          ]
        ) items))
        (div [] [
          (if hasPrev then (a [ (attrs.href prevPageURL) ] [ "← Newer" ]) else "")
          " Page ${toString pageNumber}/${toString totalPages} "
          (if hasNext then (a [ (attrs.href nextPageURL) ] [ "Older →" ]) else "")
        ])
      ];

    taxonomy = { title, pageNumber, totalPages, items, hasNext, hasPrev, nextPageURL, prevPageURL, ... }:
      [
        (h1 [] [ "#${title}" ])
        (p [] [ "${toString (builtins.length items)} posts" ])
        (ul [] (map (item:
          li [] [
            (a [ (attrs.href item.url) ] [ item.title ])
            " - ${item.date}"
          ]
        ) items))
        (div [] [
          (if hasPrev then (a [ (attrs.href prevPageURL) ] [ "← Newer" ]) else "")
          " Page ${toString pageNumber}/${toString totalPages} "
          (if hasNext then (a [ (attrs.href nextPageURL) ] [ "Older →" ]) else "")
        ])
      ];
  };
}
```

## Best Practices

### Content Organization

- **Tags** (5-15 per post): Specific, descriptive keywords
- **Categories** (1-3 per post): Broad content types
- **Series**: Multi-part tutorials or related posts
- **Authors**: Multi-author blogs

### Performance

- Keep taxonomy count reasonable (3-5 types max)
- Use pagination for terms with many posts
- RSS feed limits help with large sites

### User Experience

- Display tags prominently on posts
- Provide navigation between related tags
- Consider a tag cloud or popular tags section
- Link to RSS feeds for individual tags

### SEO

- Use descriptive, keyword-rich terms
- Keep URLs clean with lowercase hyphenated terms
- Ensure taxonomy pages have good meta descriptions
