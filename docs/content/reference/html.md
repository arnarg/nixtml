---
title: HTML Tags and Attributes
description: Reference for nixtml's functional HTML helpers
---

nixtml exposes HTML helpers through `lib.tags` and attribute helpers through `lib.attrs`. They produce strings that can be returned directly by layouts or combined with ordinary Nix string interpolation.

## Basic Usage

```nix
{ lib, ... }:
let
  inherit (lib.tags) a div;
  inherit (lib) attrs;
in
{
  website.layouts.partials.example =
    { }:
    div [ (attrs.class "container") ] [
      (a [ (attrs.href "/") ] [ "Home" ])
    ];
}
```

A regular tag has two arguments: a list of attributes and a list of child strings.

```nix
tagName [ attributes ] [ children ]
```

For example:

```nix
(div [ ] [ "Hello" ])
# <div>Hello</div>

(a [ (attrs.href "/about/") ] [ "About" ])
# <a href="/about/">About</a>
```

## Regular Tags

Regular tags have a closing tag and accept both attributes and children. Commonly used helpers include:

```nix
inherit (lib.tags)
  # Document structure
  html head body

  # Sections
  address article aside footer header hgroup main nav section search

  # Headings
  h1 h2 h3 h4 h5 h6

  # Grouping and text content
  blockquote dd div dl dt figcaption figure li menu ol p pre ul

  # Inline text
  a abbr b bdi bdo cite code data del dfn em i ins kbd mark q rp rt ruby
  s samp small span strong sub sup time u var

  # Tables
  caption colgroup table tbody td tfoot th thead tr

  # Forms
  button datalist fieldset form label legend meter optgroup option output
  progress select textarea

  # Media and embedded content
  audio canvas details dialog iframe map noscript object picture script
  summary template video
  ;
```

### Page Titles

`lib.tags.title` is a convenience function that accepts the title text directly:

```nix
lib.tags.title "My page"
```

## Void Tags

Void tags accept attributes but no children:

```nix
inherit (lib.tags)
  area base br col embed hr img input link meta source track wbr
  ;

meta [ (attrs.charset "UTF-8") ]
link [
  (attrs.rel "stylesheet")
  (attrs.href "/css/main.css")
]
img [
  (attrs.src "/logo.svg")
  (attrs.alt "Project logo")
]
br [ ]
```

## Attribute Helpers

Commonly used helpers include:

| Helper | Result |
| --- | --- |
| `attrs.id "main"` | `id="main"` |
| `attrs.class "container"` | `class="container"` |
| `attrs.classes [ "flex" "gap-4" ]` | `class="flex gap-4"` |
| `attrs.href "/about/"` | `href="/about/"` |
| `attrs.src "/image.png"` | `src="/image.png"` |
| `attrs.alt "Description"` | `alt="Description"` |
| `attrs.type "text"` | `type="text"` |
| `attrs.name "email"` | `name="email"` |
| `attrs.content "value"` | `content="value"` |
| `attrs.rel "stylesheet"` | `rel="stylesheet"` |
| `attrs.lang "en"` | `lang="en"` |
| `attrs.charset "UTF-8"` | `charset="UTF-8"` |
| `attrs.target "_blank"` | `target="_blank"` |
| `attrs.title "Hover text"` | `title="Hover text"` |
| `attrs.itemprop "name"` | `itemprop="name"` |

Width and height accept either integers or strings:

```nix
attrs.width 100
attrs.height "auto"
```

### Data and ARIA Attributes

The `data` and `aria` helpers take the suffix as their first argument:

```nix
attrs.data "theme" "dark"
# data-theme="dark"

attrs.aria "label" "Documentation"
# aria-label="Documentation"

attrs.aria "current" "page"
# aria-current="page"
```

Other specialized helpers include `attrs.property` for Open Graph metadata and `attrs.httpEquiv` for HTTP-equivalent meta tags.

### Custom Attributes

Use `lib.mkAttr` when no named helper exists:

```nix
div [
  (lib.mkAttr "data-custom" "value")
] [ "Content" ]
```

## Conditional Attributes and Children

Build attribute and child lists with normal Nix list operations:

```nix
a (
  [ (attrs.href item.url) ]
  ++ lib.optional isActive (attrs.class "is-active")
  ++ lib.optional isActive (attrs.aria "current" "page")
) [ item.title ]
```

Use `lib.optionalString` when a whole element is optional:

```nix
lib.optionalString (metadata ? description)
  (lib.tags.p [ ] [ metadata.description ])
```

## Escaping

HTML helpers do not automatically escape child strings. Markdown output and intentionally constructed tags must remain raw HTML, but untrusted or arbitrary plain text should be escaped with `lib.escapeHTML`:

```nix
lib.tags.p [ ] [
  (lib.escapeHTML userInput)
]
```

Do not escape rendered Markdown content before inserting it into a layout; doing so would display its HTML tags as text.

The [Layouts and partials guide](/nixtml/templating/) demonstrates these helpers in a complete page shell.
