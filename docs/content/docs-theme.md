---
title: Using the Docs Theme
description: Build a documentation site with sidebar navigation, self-hosted fonts and light and dark color schemes
nav:
  section: guides
  order: 65
  label: Using the docs theme
---

The docs theme is the theme used by this website. It provides a hero with a logo, a sidebar navigation built from page frontmatter, previous and next links between pages, edit links, light and dark color schemes and self-hosted fonts. It's built on [Bulma](https://bulma.io/), compiled from pinned Sass sources during the Nix build.

## Import the Theme

```nix
nixtml.lib.mkWebsite {
  inherit pkgs;

  name = "my-docs";
  baseURL = "https://example.com";
  content.dir = ./content;
  imports = [ nixtml.themes.docs ];

  metadata = {
    lang = "en";
    title = "My Project";
    description = "Documentation for my project";
  };
}
```

Theme settings live under `themes.docs`:

```nix
themes.docs = {
  logo.source = ./logo.svg;

  colors = {
    primary = "#3e7cb1";
    link = "#f2545b";
  };

  navigation.sections = [
    { id = "guides"; title = "Guides"; pager = true; }
    { id = "reference"; title = "Reference"; }
  ];

  editLink.baseURL = "https://github.com/me/my-project/edit/main/docs/content/";
  footer = ''Built with <a href="https://github.com/arnarg/nixtml">nixtml</a>.'';
};
```

## Navigation

Pages are added to the sidebar through their frontmatter:

```yaml
---
title: Getting Started
nav:
  section: guides
  order: 10
  label: Getting started # Optional, defaults to the title
---
```

`section` refers to the `id` of one of `themes.docs.navigation.sections`, which also defines the order of the sections. Within a section, pages are sorted by `order`. Pages without `nav` frontmatter aren't listed, and using an undefined section is an error.

Pages in sections with `pager = true` link to the previous and next page in the same section.

| Option | Default | Purpose |
| --- | --- | --- |
| `navigation.sections` | `guides` with a pager, `reference` | Navigation sections, as `{ id; title; pager; }` |
| `navigation.links` | `[ ]` | Extra links at the end of the navigation, as `{ title; url; }` |
| `navigation.linksTitle` | `"Links"` | Title above `links` |
| `navigation.mobileLabel` | `"Browse documentation"` | Label of the collapsible navigation on small screens |
| `pager.previousLabel` | `"Previous"` | Label of the link to the previous page |
| `pager.nextLabel` | `"Next"` | Label of the link to the next page |

## Logo and Colors

`logo.source` is copied into the website and displayed at the top of every page. It's also used as the favicon unless `logo.favicon` is `false`. Without a logo, the site title is displayed instead.

The colors are [Bulma's colors](https://bulma.io/documentation/customize/concepts/), given as Sass color values. `primary` and `link` default to the colors of this website, and setting any color to `null` uses Bulma's default:

| Option | Default |
| --- | --- |
| `colors.primary` | `"#8a4d76"` |
| `colors.link` | `"#fa7c91"` |
| `colors.info`, `colors.success`, `colors.warning`, `colors.danger` | `null` |
| `colors.themeColor` | `null`, using `primary` for the `theme-color` meta tag |

The `info`, `success`, `warning` and `danger` colors are also used by [admonitions](/nixtml/reference/markdown/#blocks).

`colorScheme` follows the reader's system preference by default. Set it to `"light"` or `"dark"` to always use one of them.

Code blocks are highlighted with the Pygments styles in `codeStyles.light` and `codeStyles.dark`, which default to `default` and `monokai`. Styles from other Python packages need the package in [`extraPythonPackages`](/nixtml/reference/markdown/#additional-python-packages).

## Fonts

The theme uses Fira Sans and Fira Mono by default. The fonts are taken from the `fira-sans` and `fira-mono` packages in nixpkgs and served by the website itself, so pages don't load anything from third parties.

Fonts are split into the same subsets as Google Fonts serves them, each with a `unicode-range`, so browsers only download the files for the characters a page uses. By default, the `latin` and `latin-ext` subsets are included:

```nix
themes.docs.fonts.subset = [ "latin" "latin-ext" "cyrillic" ];
```

Set `fonts.subset = null` to include the font files as they are.

Other fonts can be used by replacing `fonts.faces` and the font stacks:

```nix
themes.docs.fonts = {
  primary = ''"Inter", sans-serif'';
  code = ''"JetBrains Mono", monospace'';
  faces = [
    { family = "Inter"; weight = 400; source = ./fonts/Inter-Regular.woff2; }
    { family = "Inter"; weight = 700; source = ./fonts/Inter-Bold.woff2; }
    { family = "JetBrains Mono"; source = ./fonts/JetBrainsMono-Regular.woff2; }
  ];
};
```

Setting `fonts.primary` or `fonts.code` to `null` uses Bulma's system font stacks.

## Edit Links, Footer and 404 Page

With `editLink.baseURL` set, every page from `website.content.dir` links to its source file. The page's path within the content directory is appended to the base URL, e.g. `guides/intro.md`.

`footer` is the HTML content of the footer, and `null` removes it.

The theme also generates `404.html`, configured through `notFoundPage.title` and `notFoundPage.content`, or disabled with `notFoundPage.enable = false`.

## Customizing Styles

Other [Bulma Sass variables](https://bulma.io/documentation/customize/list-of-sass-variables/) can be set through `sassVariables`, without the `$`:

```nix
themes.docs.sassVariables = {
  radius = "0.5rem";
  weight-extrabold = "700";
};
```

`extraScss` is appended to the theme's stylesheet, after the code highlighting styles. Bulma's modules can be loaded with `@use`:

```nix
themes.docs.extraScss = ''
  @use "bulma/sass/utilities/mixins";

  @include mixins.mobile {
    .docs-hero img {
      width: 10rem;
    }
  }
'';
```

## Override Layouts and Partials

Like Minima, the docs theme defines its layouts and partials with `lib.mkDefault`, so a site can replace any of them. The base layout is composed of these partials:

| Partial | Purpose |
| --- | --- |
| `head` and `meta` | Contents of `<head>` |
| `docsHero` | Logo or title at the top of the page |
| `docsSidebar` | Navigation, called with `mobile = true` for small screens |
| `pageHeader` | Page title and description |
| `docsEditLink` | Edit link below the content |
| `docsPager` | Previous and next links |
| `docsFooter` | Footer |

See [Using themes and Minima](/nixtml/themes/#override-a-layout-or-partial) for an example.
