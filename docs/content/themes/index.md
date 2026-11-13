---
title: Using Themes
description: Import theme modules, configure them, and override individual layouts or partials
nav:
  section: guides
  order: 60
  label: Using themes
---

A nixtml theme is a Nix module that supplies layouts and, optionally, static assets and options. Themes use the same configuration mechanisms as any other nixtml module, so sites can adopt their defaults or replace individual pieces.

nixtml includes two themes:

- [Minima](/nixtml/themes/minima/), a blog theme with posts, collections, taxonomies, pagination and RSS.
- [Docs](/nixtml/themes/docs/), a documentation theme with sidebar navigation, used by this website.

## Import a Theme

Pass a theme module through `imports` in `mkWebsite`:

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

Each theme's settings live under `themes.<name>`, e.g. `themes.minima` or `themes.docs`.

The [getting-started guide](/nixtml/) contains a complete flake with a preview server.

## Override a Layout or Partial

Themes define their layouts and partials with `lib.mkDefault`, allowing site configuration to replace them without priority workarounds.

For example, replace a theme's page layout while keeping its other layouts:

```nix
{ lib, ... }:
{
  website.layouts.page =
    { metadata, content, ... }:
    lib.tags.article [ ] [
      (lib.tags.h1 [ ] [ metadata.title ])
      content
    ];
}
```

Partials are replaced the same way, through `website.layouts.partials.<name>`.

When overriding a function, preserve the arguments used by its callers. The [Template Context Reference](/nixtml/reference/templates/) lists standard layout values, and the theme's module shows each partial's specific signature.

## Write a Theme

A theme is an ordinary module, so writing one uses the same tools as building a site. See [Layouts and partials](/nixtml/templating/) for writing layouts. The included themes follow these conventions:

- **Layouts and partials** are set with `lib.mkDefault`, so sites can override them.
- **Options** are declared under `themes.<name>`, keeping them separate from `website` options and from other themes.
- **Assets**, such as compiled stylesheets, are built as packages and added to `build.extraPackages`, which joins them with the website output.
- **Sources** of third-party assets, such as Sass frameworks, are pinned with a fixed revision and hash.

A minimal theme module looks like this:

```nix
{ lib, config, pkgs, ... }:
let
  cfg = config.themes.simple;
in
{
  options.themes.simple = {
    accentColor = lib.mkOption {
      type = lib.types.str;
      default = "#8a4d76";
      description = "Accent color of the theme.";
    };
  };

  config = {
    build.extraPackages.simpleTheme = pkgs.writeTextDir "css/main.css" ''
      a { color: ${cfg.accentColor}; }
    '';

    website.layouts.base = lib.mkDefault (
      { content, ... }:
      "<!DOCTYPE html>\n"
      + lib.tags.html [ ] [
        (lib.tags.head [ ] [
          (lib.tags.link [
            (lib.attrs.rel "stylesheet")
            (lib.attrs.href (config.website.baseURI + "css/main.css"))
          ])
        ])
        (lib.tags.body [ ] [ content ])
      ]
    );
  };
}
```

The sources of [Minima](https://github.com/arnarg/nixtml/tree/main/themes/minima) and the [docs theme](https://github.com/arnarg/nixtml/tree/main/themes/docs) are complete examples.
