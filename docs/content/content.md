---
title: Content and Frontmatter
description: Add Markdown pages, metadata, static files, and explicit content entries
nav:
  section: guides
  order: 20
  label: Content and frontmatter
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

## Navigation Metadata on This Site

The nixtml documentation theme uses an optional `nav` frontmatter attribute to include pages in its sidebar and guide pagination:

```yaml
nav:
  section: guides
  order: 20
  label: Content and frontmatter
```

- `section` selects a section declared in `docs/navigation.nix`.
- `order` controls ordering within that section. Leave gaps between numbers to make later insertions easier.
- `label` optionally overrides the page title in navigation.

Pages without `nav` metadata are left out of the sidebar. Section titles and section ordering remain in `docs/navigation.nix`; page paths and previous/next guide links are derived automatically from discovered content.

This is a convention of this documentation theme, not a built-in nixtml navigation option. Other themes can use different metadata or navigation models.

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

## Links Between Pages

Relative URLs in Markdown are resolved against the page's URL by default, so a link from `guides/first-steps.md` to `about.md` has to be written as `../../about/`. Enable `relativeLinks` to write them relative to the Markdown file instead, the way they work when browsing the files on GitHub:

```nix
nixtml.lib.mkWebsite {
  # Other settings...
  content.processors.md.settings.relativeLinks.enable = true;
}
```

Links to Markdown files are then rewritten to the URL of their page, keeping any `#anchor`:

```markdown
<!-- In guides/first-steps.md -->
Read [about this site](../about.md#history) or the [next guide](./second-steps.md).
```

```html
<a href="../../about/#history">about this site</a>
<a href="../second-steps/">next guide</a>
```

Other relative URLs, such as images from the static directory, are rewritten the same way, so `![Cover](../images/cover.png)` in `guides/first-steps.md` points to `images/cover.png` at the root of the site. Absolute URLs, URLs starting with `/` and `#anchor` links are left alone.

The rewrite assumes pages are at their default path, and links to files that don't exist are not reported.

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
