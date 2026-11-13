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

The processor always enables:

- Fenced code blocks through `pymdownx.superfences`.
- Syntax highlighting through `pymdownx.highlight` and inline code highlighting through `pymdownx.inlinehilite`.
- Heading identifiers and generated tables of contents through the `toc` extension.

The following features are enabled by default. Each has a setting under `website.content.processors.md.settings` with an `enable` option, and most also have an `extraConfig` option for passing extra config to the underlying extension:

| Setting | Extension | Syntax |
| --- | --- | --- |
| `tables` | `tables` | Pipe tables |
| `footnotes` | `footnotes` | `[^1]` references and definitions |
| `attrList` | `attr_list` | `{: .class #id }` attributes |
| `quotes` | `pymdownx.quotes` | Blockquotes, with optional `> [!NOTE]` callouts |
| `fancylists` | `pymdownx.fancylists` | Ordered lists using `a.`, `i.` or `#.` |
| `tasklist` | `pymdownx.tasklist` | `- [x]` task lists |
| `magiclink` | `pymdownx.magiclink` | Automatic links for URLs and email addresses |
| `admonition` | `pymdownx.blocks.admonition` | `/// note` blocks |
| `details` | `pymdownx.blocks.details` | `/// details` collapsible blocks |
| `tab` | `pymdownx.blocks.tab` | `/// tab` blocks |
| `definition` | `pymdownx.blocks.definition` | `/// define` definition lists |
| `caption` | `pymdownx.blocks.caption` | `/// caption` blocks |

For example, a fenced code block can specify its language and, optionally, a title such as a file name:

````markdown
```nix title="flake.nix"
{
  website.sitemap.enable = true;
}
```
````

`pymdownx.quotes` handles blockquotes differently from plain Python-Markdown: consecutive blockquotes separated by a blank line stay separate instead of being merged. `pymdownx.fancylists` treats lines starting with `a.` or `i.` as list items.

### Blocks

Admonitions, details, tabs, definitions and captions use PyMdown's `///` block syntax. See the [PyMdown blocks documentation](https://facelessuser.github.io/pymdown-extensions/extensions/blocks/) for all options.

```markdown
/// note | Title
Admonition content.
///

/// details | Summary
    open: true
Collapsible content.
///

/// tab | Nix
Tab content.
///

/// tab | Python
More tab content.
///

/// define
Term

- Definition of the term.
///
```

/// note | Example
This is a `note` admonition.
///

/// details | A collapsible `details` block
Hidden until opened.
///

/// tab | Nix
```nix
{ website.sitemap.enable = true; }
```
///

/// tab | Markdown
```markdown
/// tab | Nix
...
///
```
///

/// define
Admonition

- A block that draws attention to its content.
///

The `admonition.types` and `details.types` settings define shorthand block names such as `/// warning`:

```nix
website.content.processors.md.settings = {
  admonition.types = [
    "note"
    "warning"
    { name = "example"; title = "Try it"; }
  ];
  details.types = [ "faq" ];
};
```

With `quotes.callouts` enabled, which is the default, GitHub style callouts render as admonitions, and as collapsible details when followed by `-` or `+`:

```markdown
> [!TIP]
> Shown as a `tip` admonition.

> [!WARNING]-
> Shown as a collapsed `warning` details block.
```

> [!TIP]
> This is a callout.

Tabs use the [alternate style](https://facelessuser.github.io/pymdown-extensions/extensions/blocks/plugins/tab/#alternate-style) markup by default, controlled by `tab.alternateStyle`.

### Styling

Admonitions, details, tabs and task lists need CSS. The `minima` theme includes styles for all of them. Custom layouts need to style the following classes:

| Feature | Markup |
| --- | --- |
| Admonitions | `div.admonition.<type>` with a `p.admonition-title` |
| Details | `details.<type>` with a `summary` |
| Tabs | `div.tabbed-set.tabbed-alternate` containing `input`s, `div.tabbed-labels` and `div.tabbed-content > div.tabbed-block` |
| Task lists | `ul.task-list > li.task-list-item` with a checkbox `input` |
| Captions | `figure` with a `figcaption` and an optional `span.caption-prefix` |

Tabs in particular don't work without CSS. See the [tab styling documentation](https://facelessuser.github.io/pymdown-extensions/extensions/blocks/plugins/tab/#styling-with-css) for an example.

### Additional Extensions

Other Python-Markdown extensions are enabled through `extensions`, keyed by their import name:

```nix
website.content.processors.md.settings.extensions = {
  abbr = { };
  "pymdownx.arithmatex".config.generic = true;
  "pymdownx.emoji".enable = false;
};
```

Extensions from other Python packages also need the package in [`extraPythonPackages`](#additional-python-packages).

Extensions that nixtml manages through named settings, such as `toc` or `pymdownx.blocks.tab`, can't be added to `extensions`. Some older extensions provide the same feature as an enabled built-in one and conflict with it:

| Extension | Conflicts with | Result |
| --- | --- | --- |
| `def_list` | `definition` | Error, adjacent definition lists merge |
| `pymdownx.tabbed` | `tab` | Error, tab sets merge and share element IDs |
| `sane_lists` | `fancylists` | Error, both replace the list parsers |
| `admonition` | `admonition` | Warning |
| `pymdownx.details` | `details` | Warning |

Bundles such as `extra` and `pymdownx.extra` are checked for the extensions they include. To use an older extension, disable the conflicting setting, e.g. `definition.enable = false;`.

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

The package must provide or extend functionality used by the configured Markdown and highlighting setup. Adding a package alone does not enable a new Markdown extension, add it to [`extensions`](#additional-extensions) as well.

## Post Summaries

The HTML before an exact `<!--more-->` marker becomes `item.summary` in collection and taxonomy layouts. Without the marker, the summary contains the entire rendered item.

See [Collections and pagination](/nixtml/collections/) for item values and listing templates.
