---
title: Minima
description: A blog theme with posts, collections, taxonomies, pagination and RSS
nav:
  section: themes
  order: 10
---

Minima is a proof-of-concept port of Jekyll's Minima 2.5.2. It provides a responsive header, static-page and post layouts, collection and taxonomy listings, pagination, footer links, and RSS discovery.

See [Using themes](/nixtml/themes/) for how themes work in general.

## Import Minima

```nix
nixtml.lib.mkWebsite {
  inherit pkgs;

  name = "my-website";
  baseURL = "https://example.com";
  content.dir = ./content;
  imports = [ nixtml.themes.minima ];

  metadata = {
    lang = "en";
    title = "My Website";
    description = "Notes about Nix";
  };
}
```

The [getting-started guide](/nixtml/) contains a complete flake with a preview server.

## Configure Minima

Minima's settings live under `themes.minima`:

```nix
themes.minima = {
  feedPath = "index.xml";
  showExcerpts = true;

  navigation = [
    { title = "About"; path = "about/"; }
  ];

  socialLinks = [
    {
      platform = "github";
      username = "arnarg/nixtml";
      url = "https://github.com/arnarg/nixtml";
    }
  ];
};
```

| Option | Default | Purpose |
| --- | --- | --- |
| `navigation` | `[ ]` | Header links with `title` and site-relative `path` fields |
| `showExcerpts` | `false` | Show each item's `summary` in collection and taxonomy listings |
| `feedPath` | `null` | Site-relative RSS path used for collection subscription and feed-discovery links; `null` disables those links |
| `socialLinks` | `[ ]` | Footer profiles with `platform`, `username`, and absolute `url` fields |

Paths in theme options are relative to `website.baseURI`, not full public URLs. For example, use `about/`, not `/about/` or `https://example.com/about/`.

`feedPath` should match the actual collection feed. If RSS is disabled for every collection, leave it `null`.

## Homepage Styles

Minima supports both ordinary content homepages and a homepage containing the latest posts.

### Static Homepage

With no root collection, `content/index.md` uses Minima's home layout:

```markdown
---
title: Welcome
---

Welcome to my website.
```

Other content files, such as `content/about.md`, use the page layout.

### Homepage Post List

A collection whose path is `posts` places its first listing at the root index:

```nix
collections.posts = {
  path = "posts";
  pagination.perPage = 5;
  taxonomies = [ "tags" ];
  rss.enable = true;
};

themes.minima.feedPath = "index.xml";
```

Store its posts in `content/posts/`. Do not also define `content/index.md`, because that would target the same homepage path as the collection listing.

For a listing at `blog/index.html` instead, use `path = "blog/posts"`, enable its feed, and set `themes.minima.feedPath = "blog/index.xml"`.

## Dates, Authors, and Excerpts

Minima displays an item's formatted date on collection listings. On individual pages it can display a date and optional author when their frontmatter is present:

```markdown
---
title: A dated post
date: 2026-01-19T10:00:00
author: Ada
---

The introduction appears in listings when excerpts are enabled.

<!--more-->

The rest of the post appears here and on its full page.
```

`showExcerpts = true` uses the content before `<!--more-->` as the listing excerpt. Without the marker, the full rendered content becomes the summary. Without `showExcerpts`, Minima still lists posts but omits the summary body.

Site-wide `website.metadata.author` and `website.metadata.email` also appear in the footer. Use the page's `author` field for a per-post byline.

## Override a Layout or Partial

Minima's layouts and partials can be replaced individually, as described in [Using themes](/nixtml/themes/#override-a-layout-or-partial). For example, replace only the footer while retaining the other Minima layouts:

```nix
{ lib, config, ... }:
{
  website.layouts.partials.siteFooter =
    _:
    lib.tags.footer [ (lib.attrs.class "site-footer") ] [
      (lib.tags.div [ (lib.attrs.class "wrapper") ] [
        (lib.tags.p [ ] [
          "Built with ${config.website.metadata.title} and nixtml"
        ])
      ])
    ];
}
```

Minima's module shows each partial's specific signature.

## Assets and Reproducibility

Minima compiles its pinned upstream Sass sources during the Nix build and emits its stylesheet and social icon sprite under `assets/`. The upstream source revision and hash are fixed in the theme module, and its MIT license is retained in the theme source and generated asset package.

The current proof-of-concept does not port Jekyll integrations such as Disqus or Google Analytics, every SEO metadata feature, or Minima's skin customization. Its default styling is intended to be overridden through layouts and site assets where necessary.

## Buildable Example

The repository includes a complete Minima blog with navigation, pagination, tags, excerpts, social links, and RSS:

```bash
nix build .#examples.minima
```

Its source is in [`examples/minima`](https://github.com/arnarg/nixtml/tree/main/examples/minima), and the theme implementation is in [`themes/minima`](https://github.com/arnarg/nixtml/tree/main/themes/minima).
