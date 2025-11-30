# nixtml

A static website generator written in nix. Inspired by hugo.

## Getting started

```nix
{
  description = "My website generated using nixtml.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.blog = nixtml.lib.mkWebsite {
          inherit pkgs;

          name = "my-blog";
          baseURL = "https://my-blog.com";

          # Arbitrary metdata to be used in
          # templates.
          metadata = {
            lang = "en";
            title = "My Blog";
            description = "This is my blog";
          };

          # Walk a directory of markdown files
          # and create a page for each of them.
          content.dir = ./content; 

          # Copy an entire directory and symlink
          # in the final website derivation.
          static.dir = ./static;

          # Collections are for paginating content
          # and generating RSS feeds.
          collections.blog = {
            path = "posts";

            # Posts in the collection should be
            # grouped by optional tags in posts'
            # frontmatter.
            taxonomies = [ "tags" ];
          };

          # Import any nixtml modules (good for
          # "themes").
          imports = [ ./theme.nix ];
        };

        # Quickly build and serve website with
        # `nix run .#serve`.
        apps.serve = {
          type = "app";
          program =
            (pkgs.writeShellScript "serve-blog" ''
              ${pkgs.python3}/bin/python -m http.server -d ${self.packages.${system}.blog} 8080
            '').outPath;
        };
      }
    ));
}
```

## Templates

Templates should be defined under `website.layouts`. All templates should be a function to a string (or list of strings, that is automatically coerced to a string).

### Nix functional HTML

In nixtml's lib there are functions for most commonly used HTML tags which can be used like this:

```nix
{lib, ...}: let
  inherit (lib.tags)
    html
    head
    body
    div
    ;
  inherit (lib) attrs;
in {
  website.layouts.base =
    { path, content, ... }@context:
    "<!DOCTYPE html>\n"
    +
      html
        [ (attrs.lang metadata.lang) ]
        [
          (head [ ] [ (partials.head context) ])
          (body
            [
              (attrs.classes [
                "font-sans"
                "bg-white"
              ])
            ]
            [
              (div
                [
                  (attrs.classes [ "container" ])
                ]
                [ content ]
              )
            ]
          )
        ];
}
```

### Normal string templating

The above is equivalent to defining the markup using strings in nix:

```nix
{lib, ...}: {
  website.layouts.base =
    { path, content, ... }@context: ''
      <!DOCTYPE html>
      <html lang="${metadata.lang}">
        <head>
          ${partials.head context}
        </head>
        <body class="font-sant bg-white">
          <div class="container">
            ${content}
          </div>
        </body>
      </html>
    '';
}
```

### Standard templates

Each template in `website.layouts` has a specific purpose.

- `website.layouts.base`: Used for the skeleton of each HTML file for the website. It gets passed the result of other rendered templates.
- `website.layouts.hom`: Used for `./index.md`, if found in `website.content.dir`. It gets passed the metadata in the markdown frontmatter as well as the HTML content generated from markdown.
- `website.layouts.page`: Used for any other markdown file found in `website.content.dir`. It gets passed the metadata in the markdown frontmatter as well as the HTML content generated from markdown.
- `website.layouts.collection`: Used for pagination pages for collections.
- `website.layouts.taxonomy`: Used for pagination pages for taxonomies in collections.
- `website.layouts.partials`: An attribute set of templates (functions to string or list of strings) that can be used to reduce repitition in the other standard templates.

## Content

By setting `website.content.dir` nixtml will traverse that directory, transform any markdown file it finds and output an HTML file in the final website derivation with the same path. For example, `${content.dir}/about.md` becomes `about/index.html` in the final website derivation.

## Collections

Collections allow you to group, paginate and list related content such as blog posts or portfolio pieces.

Create a collection under `website.collections.<name>` and point it to a folder inside `website.content.dir`.

```nix
website.collections.blog = {
  path = "blog/posts";     # ./content/blog/posts/
  pagination.perPage = 5;  # Number of items each listing page shows
  rss.enable = true;       # Generate /blog/index.xml
};
```

nixtml automatically produces listing pages hosting `pagination.perPage` items per page (`blog/index.html`, `blog/page/2/index.html`, …) rendered with the `collection` layout template.

### Taxonomies

You may want to allow readers to explore entries by common key–words such as tags, categories or authors. Activate any number of taxonomies with the list key `taxonomies`:

```nix
website.collections.blog = {
  path = "blog/posts";
  taxonomies = [ "tags" "series" ];
};
```

In every markdown file inside that collection you can now list these terms in the YAML frontmatter:

```markdown
---
title: "My Emacs Setup"
date: 2024-07-15
tags:
  - emacs
  - productivity
series:
  - dotfiles
---
Post body…
```

nixtml will then create pages such as `/blog/tags/emacs/index.html`, `/blog/tags/emacs/page/2/index.html` and so on using the `taxonomy` layout template.

Inside collection or taxonomy templates you always receive the same context attribute set:

```nix
{
  # --- collection & taxonomy -------------
  pageNumber,     # Current page number
  totalPages,     # Total amount of pages
  items,          # List of posts in this page
  hasNext,        # A next page exists (bool)
  hasPrev,        # A previous page exists (bool)
  nextPageURL,    # URL to next page
  prevPageURL,    # URL to previous page
  # --- only taxonomy --------------------
  title,          # The tag or term being shown
}
```

## Examples

Look at the examples directory to see how to work with nixtml. They can be built with `nix build .#examples.simple` and `nix build .#examples.blog`.
