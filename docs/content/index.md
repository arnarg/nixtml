---
title: Getting Started with nixtml
date: 2026-01-19T21:00:00
description: A step-by-step guide to creating your first website with nixtml
---

nixtml is a static website generator written in Nix, inspired by Hugo. This guide will walk you through creating your first website from scratch.

## Prerequisites

- **Nix** installed with flakes enabled
- Basic familiarity with Nix language
- A text editor

To enable flakes, add this to your `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## Project Structure

By the end of this guide, your project will look like this:

```
my-website/
├── flake.nix          # Main configuration
├── content/
│   ├── index.md       # Homepage
│   └── about.md       # About page
└── static/            # Static assets (CSS, images, etc.)
    └── css/
        └── style.css
```

## Step 1: Create a New Project

```bash
mkdir my-website
cd my-website
```

## Step 2: Create the Flake Configuration

Create a `flake.nix` file:

```nix
{
  description = "My website generated using nixtml.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixtml.url = "github:arnarg/nixtml";
  };

  outputs = {
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
          baseURL = "https://my-website.com";

          # Site-wide metadata available in templates
          metadata = {
            lang = "en";
            title = "My Website";
            description = "Welcome to my website";
          };

          # Directory containing markdown content
          content.dir = ./content;

          # Optional: Directory for static assets
          # static.dir = ./static;

          # Import layout configuration from separate file
          imports = [ ./layouts.nix ];
        };

        # Convenient local development server
        apps.serve = {
          type = "app";
          program =
            (pkgs.writeShellScript "serve" ''
              echo "Serving at http://localhost:8080"
              ${pkgs.python3}/bin/python -m http.server -d ${self.packages.${system}.default} 8080
            '').outPath;
        };
      }
    );
}
```

## Step 3: Create the Layouts

Create a `layouts.nix` file to define how your pages look:

```nix
{ lib, config, ... }:
let
  # Access site metadata defined in flake.nix
  inherit (config.website) metadata;

  # Import HTML helper functions
  inherit (lib.tags)
    html
    head
    body
    div
    h1
    p
    a
    nav
    ul
    li
    meta
    ;
  inherit (lib.tags) title link;
  inherit (lib) attrs;
in
{
  website.layouts = {
    # Base template wraps all pages
    base = { path, content, ... }:
      "<!DOCTYPE html>\n"
      + (html [ (attrs.lang metadata.lang) ] [
          (head [] [
            (meta [ (attrs.charset "UTF-8") ])
            (meta [
              (attrs.name "viewport")
              (attrs.content "width=device-width, initial-scale=1.0")
            ])
            (meta [
              (attrs.name "description")
              (attrs.content metadata.description)
            ])
            (title metadata.title)
            # Uncomment when you add static/css/style.css
            # (link [
            #   (attrs.rel "stylesheet")
            #   (attrs.href "/css/style.css")
            # ])
          ])
          (body [] [
            (nav [] [
              (ul [] [
                (li [] [ (a [ (attrs.href "/") ] [ "Home" ]) ])
                (li [] [ (a [ (attrs.href "/about") ] [ "About" ]) ])
              ])
            ])
            (div [ (attrs.class "container") ] [ content ])
          ])
        ]);

    # Template for index.md (homepage)
    home = { content, ... }: content;

    # Template for all other pages
    page = { metadata, content, ... }: [
      (h1 [] [ metadata.title ])
      content
    ];

    # Required for collections (can be minimal for now)
    collection = { pageNumber, totalPages, items, ... }:
      (div [] [
        (ul [] (map (item: li [] [ item.title ]) items))
        "Page ${toString pageNumber} of ${toString totalPages}"
      ]);

    # Required for taxonomies (can be minimal for now)
    taxonomy = { title, pageNumber, totalPages, items, ... }:
      (div [] [
        (h1 [] [ title ])
        (ul [] (map (item: li [] [ item.title ]) items))
        "Page ${toString pageNumber} of ${toString totalPages}"
      ]);
  };
}
```

## Step 4: Create Content

Create the content directory and your first pages:

```bash
mkdir -p content
```

### Homepage (`content/index.md`)

```markdown
---
title: Home
date: 2026-01-19T00:00:00
---

# Welcome to My Website

This is the homepage of my nixtml-powered website.

Built with **Nix** for reproducible, declarative static site generation.
```

### About Page (`content/about.md`)

```markdown
---
title: About
date: 2026-01-19T00:00:00
---

This website was created using nixtml, a static site generator written in Nix.

## Why nixtml?

- Declarative configuration
- Reproducible builds
- Native Nix integration
- Markdown content with frontmatter
```

## Step 5: Build Your Website

```bash
nix build .#
```

This creates a `result` symlink pointing to your built website. Explore the output:

```bash
ls -la result/
```

You should see:

- `index.html` - Your homepage
- `about/index.html` - Your about page
- `sitemap.xml` - Auto-generated sitemap

## Step 6: Serve Locally

```bash
nix run .#serve
```

Open [http://localhost:8080](http://localhost:8080) in your browser to see your website.

## Step 7: Add Styling (Optional)

Create a static directory with CSS:

```bash
mkdir -p static/css
```

Create `static/css/style.css`:

```css
* {
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.6;
  color: #333;
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

nav ul {
  list-style: none;
  padding: 0;
  display: flex;
  gap: 20px;
  border-bottom: 1px solid #eee;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

nav a {
  text-decoration: none;
  color: #0066cc;
}

nav a:hover {
  text-decoration: underline;
}

h1 {
  color: #111;
}

.container {
  padding: 20px 0;
}
```

Then update your `flake.nix` to include static files:

```nix
# Uncomment this line in mkWebsite:
static.dir = ./static;
```

And uncomment the stylesheet link in `layouts.nix`.

Rebuild to see the changes:

```bash
nix run .#serve
```

## Understanding the Configuration

### `mkWebsite` Options

| Option | Description |
|--------|-------------|
| `name` | Website name (used in derivation name) |
| `baseURL` | Full URL where site will be hosted |
| `metadata` | Arbitrary data available in all templates |
| `content.dir` | Directory containing markdown files |
| `static.dir` | Directory with static assets |
| `layouts` | Template functions for rendering pages |
| `imports` | Additional Nix modules to import |

### Template Context

Each template receives a context object:

- **base**: `{ path, content, ... }` - receives rendered content from child templates
- **home**: `{ content, metadata, ... }` - receives parsed markdown content
- **page**: `{ content, metadata, ... }` - receives parsed markdown content
- **collection**: `{ pageNumber, totalPages, items, hasNext, hasPrev, ... }`
- **taxonomy**: `{ title, taxonomoy, pageNumber, totalPages, items, hasNext, hasPrev, ... }`

### Frontmatter

Markdown files support YAML frontmatter:

```markdown
---
title: Page Title
date: 2026-01-19T00:00:00
customField: any value
---

Content here...
```

The frontmatter is available as `metadata` in your templates.

## Next Steps

Now that you have a basic website running:

- **[Collections](/nixtml/collections)**: Create a blog with pagination and RSS feeds
- **[Taxonomies](/nixtml/taxonomies)**: Organize content with tags and categories  
- **[Advanced Templating](/nixtml/templating)**: Master the Nix HTML library and partials
- **[Nixtml Module Options](/nixtml/options)**: View all available module options in nixtml

## Complete Example

See the [examples directory](https://github.com/arnarg/nixtml/tree/main/examples) in the nixtml repository for complete working examples:

- **simple**: Basic website with pages
- **blog**: Full blog with collections, taxonomies, and RSS feeds
