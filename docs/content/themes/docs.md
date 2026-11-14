---
title: Docs
description: A documentation theme with sidebar navigation, self-hosted fonts and light and dark color schemes
nav:
  section: themes
  order: 20
---

The docs theme is the theme used by this website. It provides a logo on the landing page, a bar with the site title on other pages, a sidebar navigation built from page frontmatter, previous and next links between pages, edit links, light and dark color schemes and self-hosted fonts. It's built on [Bulma](https://bulma.io/), compiled from pinned Sass sources during the Nix build.

See [Using themes](/nixtml/themes/) for how themes work in general.

## Import the Docs Theme

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
| `navigation.closeLabel` | `"Close navigation"` | Label of the button closing the navigation on small screens |
| `pager.previousLabel` | `"Previous"` | Label of the link to the previous page |
| `pager.nextLabel` | `"Next"` | Label of the link to the next page |

## Logo and Colors

Every page except the landing page has the site title, linking to the landing page, in the bar at the top. `logo.source` is copied into the website and displayed above the content of the landing page. It's also used as the favicon unless `logo.favicon` is `false`. Without a logo, the landing page displays the site title in large text instead.

Set `logo.compact.source` to a small logo, such as an icon, to display it in front of the site title in the bar. The compact logo is then also used as the favicon.

```nix
themes.docs.logo = {
  source = ./logo.svg;
  compact.source = ./icon.svg;
};
```

`hero.content` is HTML displayed below the logo on the landing page, such as badges or a tagline:

```nix
themes.docs.hero.content = ''
  <p>Documentation for my project.</p>
'';
```

The logo's size can be changed with [`extraScss`](#customizing-styles), through the `docs-hero-logo` class.

The colors are [Bulma's colors](https://bulma.io/documentation/customize/concepts/), given as Sass color values. `primary` and `link` default to the colors of this website, and setting any color to `null` uses Bulma's default:

| Option | Default |
| --- | --- |
| `colors.primary` | `"#8a4d76"` |
| `colors.link` | `"#fa7c91"` |
| `colors.info`, `colors.success`, `colors.warning`, `colors.danger` | `null` |
| `colors.themeColor` | `null`, using `primary` for the `theme-color` meta tag |

The `info`, `success`, `warning` and `danger` colors are also used by [admonitions](/nixtml/reference/markdown/#blocks).

## Color Schemes

The theme has a light and a dark color scheme, and follows the reader's system preference by default. Buttons in the top right corner let readers choose between the system, light and dark color schemes. Their choice is saved in their browser and applied before each page is rendered, so pages don't flash in the wrong color scheme.

| Option | Default | Purpose |
| --- | --- | --- |
| `colorScheme` | `"auto"` | Color scheme used until the reader chooses one: `"auto"` follows the system preference, `"light"` or `"dark"` |
| `colorSchemeSwitcher.enable` | `true` | Display the color scheme buttons |
| `colorSchemeSwitcher.storageKey` | `"<website.name>-color-scheme"` | `localStorage` key of the reader's choice |
| `colorSchemeSwitcher.labels` | `group`, `system`, `light` and `dark` labels | Accessible labels of the switcher and its buttons |

The switcher requires JavaScript and is hidden without it, leaving the color scheme from `colorScheme`. To always use one color scheme, set `colorScheme` and disable the switcher:

```nix
themes.docs = {
  colorScheme = "dark";
  colorSchemeSwitcher.enable = false;
};
```

Websites served from the same origin share their browser storage. For example, all GitHub Pages project sites of a user are served from `<user>.github.io`. The default `storageKey` includes `website.name` to keep their choices separate.

Code blocks are highlighted with the Pygments styles in `codeStyles.light` and `codeStyles.dark`, which default to `default` and `monokai`. Styles from other Python packages need the package in [`extraPythonPackages`](/nixtml/reference/markdown/#additional-python-packages).

## Repository

The theme can link to the project's repository in the bar at the top of every page, next to the color scheme buttons. Linking to a repository is opt-in:

```nix
themes.docs.repository.url = "https://github.com/arnarg/nixtml";
```

The link displays the provider's icon and the repository's name, followed by its latest release, number of stars and number of forks. On small screens, it's displayed at the top of the navigation instead, with only the icon and stats.

The stats are fetched from the provider's API by the reader's browser, and cached in their browser for an hour. This means readers' browsers send requests to the provider, which can be turned off with `repository.stats.enable = false`, leaving only the link. Values that can't be fetched, e.g. because the API's rate limit is reached, are left out. Repositories without releases don't display a version.

| Provider | Detected hosts | API |
| --- | --- | --- |
| `github` | `github.com` | `api.github.com`, or `/api/v3` on GitHub Enterprise |
| `gitlab` | Hosts containing `gitlab`, e.g. `gitlab.com` | `/api/v4` |
| `forgejo` | `codeberg.org` | `/api/v1` |
| `gitea` | `gitea.com` | `/api/v1` |

Repositories on other hosts need their provider set, e.g. `repository.provider = "forgejo";` for a self-hosted Forgejo instance. Self-hosted Forgejo and Gitea instances don't allow requests from other websites by default, so their stats are only displayed when [CORS](https://forgejo.org/docs/latest/admin/config-cheat-sheet/#cors-cors) is enabled on the instance.

| Option | Default | Purpose |
| --- | --- | --- |
| `repository.url` | `null` | URL of the repository; `null` hides the link |
| `repository.provider` | Detected from `url` | `"github"`, `"gitlab"`, `"forgejo"` or `"gitea"` |
| `repository.name` | Path of `url` | Name displayed in the link |
| `repository.stats.enable` | `true` | Display the latest release, stars and forks |
| `repository.stats.version` | `true` | Display the latest release |
| `repository.stats.storageKey` | `"<website.name>-repository"` | `localStorage` key of the cached stats |
| `repository.stats.labels` | `version`, `stars` and `forks` labels | Accessible labels of the stats |

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

The width of the content and of the sidebar are set by the `--docs-content-width` and `--docs-sidebar-width` CSS variables, `75ch` and `18rem` by default. Pages are as wide as the two together, so the bar at the top lines up with the edges of the sidebar and the content.

`extraScss` is appended to the theme's stylesheet, after the code highlighting styles. Bulma's modules can be loaded with `@use`:

```nix
themes.docs.extraScss = ''
  @use "bulma/sass/utilities/mixins";

  @include mixins.mobile {
    .docs-hero-logo {
      width: 10rem;
    }
  }
'';
```

## Override Layouts and Partials

The docs theme's layouts and partials can be replaced individually, as described in [Using themes](/nixtml/themes/#override-a-layout-or-partial). The base layout is composed of these partials:

| Partial | Purpose |
| --- | --- |
| `head` and `meta` | Contents of `<head>` |
| `docsTopbar` | Bar at the top of every page, containing the mobile navigation toggle, `docsBrand`, `docsRepository` and `docsColorSchemeSwitcher` |
| `docsBrand` | Site title linking to the landing page, with the compact logo in front of it. Empty on the landing page |
| `docsHero` | Logo, or title without one, and `hero.content` on the landing page |
| `docsMobileNavToggle` | Hamburger button for the off-canvas navigation on small screens |
| `docsRepository` | Repository link and stats |
| `docsColorSchemeSwitcher` | Color scheme buttons |
| `docsSidebar` | Navigation, called with `mobile = true` for the off-canvas menu on small screens |
| `pageHeader` | Page title and description |
| `docsEditLink` | Edit link below the content |
| `docsPager` | Previous and next links |
| `docsFooter` | Footer |
