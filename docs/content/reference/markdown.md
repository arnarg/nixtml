---
title: Markdown and Syntax Highlighting
description: Markdown extensions, tables of contents, code highlighting, and processor settings
nav:
  section: reference
  order: 30
  label: Markdown and highlighting
---

nixtml's built-in `md` content processor turns Markdown with YAML frontmatter into HTML. Its settings live under `website.content.processors.md.settings` when using nixtml modules directly.

See [Content and frontmatter](/nixtml/content/) for content discovery and metadata.

## Enabled Markdown Features

The processor enables support for:

- Tables and footnotes.
- Fenced code blocks through `pymdownx.superfences`.
- Syntax highlighting through `pymdownx.highlight`.
- Inline code highlighting through `pymdownx.inlinehilite`.
- Automatic links through `pymdownx.magiclink`.
- Heading identifiers and generated tables of contents through the `toc` extension.
- Admonition and caption blocks through the corresponding PyMdown extensions.

For example, a fenced code block can specify its language:

````markdown
```nix
{
  website.sitemap.enable = true;
}
```
````

Consult the processor implementation when using extension-specific syntax, especially for PyMdown block plugins.

## Tables of Contents

Insert the configured marker where a table of contents should appear:

```markdown
[TOC]

## First section

## Second section
```

The default marker is `[TOC]`. Configure its behavior under `toc`:

```nix
website.content.processors.md.settings.toc = {
  marker = "[TOC]";
  title = "On this page";
  tocClass = "toc";
  permalink = "#";
  permalinkClass = "headerlink";
};
```

| Setting | Default | Purpose |
| --- | --- | --- |
| `marker` | `"[TOC]"` | Text replaced by the table of contents; use an empty string to disable marker processing |
| `title` | `null` | Optional title inside the generated TOC |
| `titleClass` | `"toctitle"` | CSS class for the TOC title |
| `tocClass` | `"toc"` | CSS class for the TOC container |
| `anchorlink` | `false` | Make headings link to themselves |
| `anchorlinkClass` | `"toclink"` | CSS class for heading links |
| `permalink` | `false` | Add a permanent link to headings; accepts a Boolean or link text |
| `permalinkClass` | `"headerlink"` | CSS class for permanent links |

Heading identifiers are generated even when the page does not contain a `[TOC]` marker, so headings can be linked directly.

## Syntax Highlighting

Highlighting is configured under `website.content.processors.md.settings.highlight`:

```nix
website.content.processors.md.settings.highlight = {
  style = "default";
  linenums = true;
  linenumsStyle = "table";
};
```

| Setting | Default | Purpose |
| --- | --- | --- |
| `style` | `"default"` | Pygments style name or an ordered list of style variants |
| `noclasses` | `true` | Inline Pygments styles instead of relying on a separate stylesheet |
| `linenums` | `null` | Enable line numbers globally, or allow each code block to choose |
| `linenumsStyle` | `"table"` | Line number rendering: `table`, `inline`, or `pymdownx-inline` |
| `extraConfig` | `{ }` | Additional `pymdownx.highlight` options; these override other highlight settings |

With the default `noclasses = true`, generated code contains inline styles and no additional highlighting stylesheet is required.

When `noclasses = false`, provide CSS for the selected Pygments style. nixtml exposes a generated stylesheet as `website.content.processors.md.highlightStylesheet`; include it in the site output and link it from the base layout. The `pymdownx-inline` line number style also requires `noclasses = false`.

### Light and Dark Styles

The `style` setting also accepts an ordered list of variants for class-based highlighting. Each variant has a Pygments `name`, an optional CSS `selector` defaulting to `.highlight`, and an optional `media` feature condition without parentheses:

```nix
website.content.processors.md.settings.highlight = {
  noclasses = false;
  style = [
    {
      name = "default";
    }
    {
      name = "monokai";
      media = "prefers-color-scheme: dark";
    }
    {
      name = "default";
      selector = ":where([data-theme=light], .theme-light) .highlight";
    }
    {
      name = "monokai";
      selector = ":where([data-theme=dark], .theme-dark) .highlight";
    }
  ];
};
```

The generated `highlightStylesheet` contains all variants in their configured order. Later variants can therefore override earlier ones for explicit theme selectors. A string such as `style = "default";` remains shorthand for one variant with the default selector and no media condition.

The first variant supplies the style used for inline highlighting. Additional variants are useful with `noclasses = false`, where their CSS can respond to the active theme.

### Per-Block Line Numbers

When global `linenums` is `null`, individual code blocks can enable line numbers using the highlight extension's fenced-code options, such as `linenums="1"`.

## Date Formatting

Date values in frontmatter are made available in several formats for collections and feeds. The ordinary `metadata.date` string uses `dateFormat`:

```nix
website.content.processors.md.settings.dateFormat = "%Y-%m-%d";
```

The value is a Python `strftime` format string. Its default is `"%b %-d, %Y"`.

## Additional Python Packages

A site can extend the processor's Python environment:

```nix
website.content.processors.md.extraPythonPackages = [
  pkgs.python3Packages.pygments-styles
];
```

The package must provide or extend functionality used by the configured Markdown and highlighting setup. Adding a package alone does not enable a new Markdown extension.

## Post Summaries

The HTML before an exact `<!--more-->` marker becomes `item.summary` in collection and taxonomy layouts. Without the marker, the summary contains the entire rendered item.

See [Collections and pagination](/nixtml/collections/) for item values and listing templates.
