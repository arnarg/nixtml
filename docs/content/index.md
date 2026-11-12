---
title: Getting Started with nixtml
description: Create, build, and serve your first nixtml website with the Minima theme
nav:
  section: guides
  order: 10
  label: Getting started
---

nixtml is a static website generator written in Nix and inspired by Hugo. This guide creates a small website with a homepage, an about page, and a local preview server.

The built-in Minima theme supplies the layouts and styling, so no template code is needed for this first site.

## Prerequisites

Install Nix and enable the `nix-command` and `flakes` experimental features:

```ini
# ~/.config/nix/nix.conf
experimental-features = nix-command flakes
```

Basic familiarity with Nix expressions is helpful, but every file needed for the example is shown below.

## 1. Create the Project

```bash
mkdir my-website
cd my-website
mkdir content
```

The project will contain:

```text
my-website/
├── flake.nix
└── content/
    ├── index.md
    └── about.md
```

## 2. Create the Flake

Create `flake.nix`:

```nix
{
  description = "My website generated with nixtml";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixtml.url = "github:arnarg/nixtml";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixtml,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = nixtml.lib.mkWebsite {
          inherit pkgs;

          name = "my-website";
          # Use your public URL when deploying the site.
          baseURL = "http://localhost:8080";

          metadata = {
            lang = "en";
            title = "My Website";
            description = "A website built with nixtml";
          };

          content.dir = ./content;
          imports = [ nixtml.themes.minima ];

          themes.minima.navigation = [
            { title = "About"; path = "about/"; }
          ];
        };

        apps.serve = {
          type = "app";
          program =
            (pkgs.writeShellScript "serve-my-website" ''
              ${pkgs.python3}/bin/python -m http.server 8080 \
                --directory ${self.packages.${system}.default}
            '').outPath;
        };
      }
    );
}
```

`mkWebsite` creates a website derivation. The `apps.serve` output serves that exact derivation, so the preview does not require a separate development build.

## 3. Add the Content

Create `content/index.md`:

```markdown
---
title: Home
description: Welcome to my website
---

Welcome to my nixtml-powered website.

It uses **Nix** for declarative configuration and reproducible builds.
```

Create `content/about.md`:

```markdown
---
title: About
description: About this website
---

This website was created using nixtml and its Minima theme.
```

The frontmatter is available to layouts as `metadata`. The Markdown body becomes the page's rendered `content`.

## 4. Build the Website

```bash
nix build
```

The `result` symlink points to the generated site. Its output includes:

```text
result/
├── index.html
├── about/
│   └── index.html
├── assets/
│   └── main.css
└── sitemap.xml
```

Inspect the generated HTML or asset files directly under `result/`. Rebuilding after a content or configuration change produces a new immutable website derivation.

## 5. Preview Locally

```bash
nix run .#serve
```

Open [http://localhost:8080](http://localhost:8080). Stop the server with <kbd>Ctrl</kbd>+<kbd>C</kbd>, make changes, and run the command again to serve the rebuilt site.

When deploying, change `baseURL` to the site's public URL. Internal links use the derived base URI, including a path prefix when the public URL contains one.

## Configuration Styles

nixtml examples use two related configuration styles:

- **`mkWebsite` arguments:** `content.dir`, `collections.blog`, and `themes.minima` are passed directly to `nixtml.lib.mkWebsite`.
- **Module options:** Inside an imported Nix module, the corresponding website settings are `website.content.dir`, `website.collections.blog`, and `themes.minima`.

The guides label or show the surrounding context for their snippets. See [Configuration options](/nixtml/options/) for the underlying module option reference.

## What to Learn Next

- [Content and frontmatter](/nixtml/content/) explains discovery, output paths, metadata, and static files.
- [Using themes and Minima](/nixtml/themes/) covers navigation, feeds, excerpts, and layout overrides.
- [Layouts and partials](/nixtml/templating/) shows how to replace the theme layouts with custom markup.
- [Collections and pagination](/nixtml/collections/) turns the site into a dated blog with listings and feeds.

## Buildable Examples

The repository contains complete examples that are built with the project's checks:

- [Simple website](https://github.com/arnarg/nixtml/tree/main/examples/simple): custom layouts and static pages.
- [Blog](https://github.com/arnarg/nixtml/tree/main/examples/blog): collections and content configuration.
- [Minima](https://github.com/arnarg/nixtml/tree/main/examples/minima): navigation, pagination, taxonomies, excerpts, and RSS.

From a checkout of nixtml, build one with `nix build .#examples.minima` (or replace `minima` with `simple` or `blog`).
