---
title: Content and Frontmatter
description: Add Markdown pages, metadata, static files, and explicit content entries
---

nixtml discovers Markdown files, parses their YAML frontmatter, and renders them through the `md` content processor. Content remains separate from layouts: a page supplies text and metadata, while a layout decides how to present them.

## Content Directory

Set `content.dir` in `mkWebsite`, or `website.content.dir` in a nixtml module:

```nix
nixtml.lib.mkWebsite {
  inherit pkgs;

  name = "my-website";
  baseURL = "https://example.com";
  content.dir = ./content;

  imports = [ nixtml.themes.minima ];
}
```

nixtml recursively finds files ending in `.md`:

```text
content/
├── index.md
├── about.md
└── guides/
    └── first-steps.md
```

These files normally produce:

```text
index.html
about/index.html
guides/first-steps/index.html
```

The root `index.md` uses `website.layouts.home`. Other discovered files use `website.layouts.page`. The rendered path is available to layouts as a list of path segments.

## YAML Frontmatter

Put frontmatter at the beginning of each Markdown file:

```markdown
---
title: About this site
description: Why this site exists and who maintains it
---

The Markdown body starts here.
```

Frontmatter becomes `metadata` in home and page layouts. Common fields are:

| Field | Used for |
| --- | --- |
| `title` | Page heading, HTML title, collection listings, and feeds |
| `description` | Page-specific metadata or a summary rendered by a layout |
| `date` | Collection sorting, formatted dates, sitemaps, and feeds |

Standalone pages do not use every standard field. Collection items need the title and date values required by collection processing.

For dates, use an unquoted ISO 8601 datetime so the YAML parser produces a datetime value:

```markdown
---
title: A dated post
date: 2026-01-19T10:00:00
---
```

Other fields are preserved for custom layouts:

```markdown
---
title: A tagged post
date: 2026-01-19T10:00:00
tags:
  - nix
  - websites
featured: true
---
```

Inside a page layout, for example, `metadata.featured` is `true` and `metadata.tags` is a list of strings. In collection listings, custom fields are under `item.metadata`.

Use defaults for optional fields:

```nix
metadata.description or ""
metadata.tags or [ ]
```

The [Markdown reference](/nixtml/reference/markdown/) covers date formatting, tables of contents, and highlighting settings.

## Site Metadata Versus Page Metadata

Site-wide values are separate from page frontmatter:

```nix
metadata = {
  lang = "en";
  title = "My Website";
  description = "Notes about Nix";
};
```

In a layout, `config.website.metadata` contains these site-wide values. The `metadata` function argument contains the current page's frontmatter. Naming a local binding `siteMetadata` and the argument `metadata` can make that distinction clear.

## Explicit Content Pages

In addition to directory discovery, modules can define content directly under `website.content.pages`.

Use a source file:

```nix
website.content.pages."guides/custom" = {
  source = ./custom.md;
  processor = "md";
};
```

Or provide text inline:

```nix
website.content.pages."about" = {
  text = ''
    ---
    title: About
    ---

    This page is declared directly in Nix.
  '';
  processor = "md";
};
```

The attribute name determines the output page path. This mechanism is also useful for generated Markdown, such as the configuration reference on this site.

## Static Assets

Set `static.dir` to copy files into the final website without processing them:

```nix
nixtml.lib.mkWebsite {
  # Other settings...
  static.dir = ./static;
}
```

For example:

```text
static/
├── css/
│   └── main.css
├── images/
│   └── cover.png
└── robots.txt
```

These are emitted as `css/main.css`, `images/cover.png`, and `robots.txt` in the website output. Prefix internal links with `config.website.baseURI` so they also work when the site is hosted below a URL path:

```nix
lib.tags.link [
  (lib.attrs.rel "stylesheet")
  (lib.attrs.href (config.website.baseURI + "css/main.css"))
]
```

For individual generated or copied files, modules can also use `website.files`. A file entry accepts either `source` or `text` and can override its output `path`.

## Sitemaps

nixtml generates `sitemap.xml` by default. Disable it in a module when needed:

```nix
website.sitemap.enable = false;
```

Pages with a usable date can provide a last-modified value to the sitemap. Use `website.pages.<name>.lastModified` for explicitly declared pages when automatic content metadata is not available.

## Next Steps

- Use [Layouts and partials](/nixtml/templating/) to render page metadata and content.
- Build dated listings with [Collections and pagination](/nixtml/collections/).
- Classify collection items with [Taxonomies and RSS](/nixtml/taxonomies/).
- Consult the [Template Context Reference](/nixtml/reference/templates/) for all standard values.
