# Minima for nixtml

A proof-of-concept port of [Minima 2.5.2](https://github.com/jekyll/minima/tree/v2.5.2), Jekyll's default theme.

The layouts are implemented as nixtml template functions. Minima's Sass and social icon sprite are fetched at a pinned commit and compiled or copied by the Nix build. The upstream MIT license is preserved in `LICENSE.txt` and in the generated asset package.

## Usage

```nix
{
  inputs.nixtml.url = "github:arnarg/nixtml";

  outputs = { self, nixpkgs, nixtml, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      packages.x86_64-linux.blog = nixtml.lib.mkWebsite {
        inherit pkgs;

        name = "my-blog";
        baseURL = "https://example.com";
        content.dir = ./content;

        metadata = {
          lang = "en";
          title = "My blog";
          description = "Notes about Nix";
          author = "Ada";
          email = "ada@example.com"; # Optional
        };

        # A collection whose path is "posts" produces the root index,
        # matching Minima's homepage-as-post-list behavior.
        collections.posts = {
          path = "posts";
          pagination.perPage = 5;
          taxonomies = [ "tags" ];
          rss.enable = true;
        };

        imports = [ nixtml.themes.minima ];

        themes.minima = {
          feedPath = "index.xml";
          showExcerpts = true;
          navigation = [
            { title = "About"; path = "about/"; }
          ];
          socialLinks = [
            {
              platform = "github";
              username = "ada";
              url = "https://github.com/ada";
            }
          ];
        };
      };
    };
}
```

Build the included example from this repository with:

```sh
nix build .#examples.minima
```

## Configuration

| Option | Default | Purpose |
| --- | --- | --- |
| `themes.minima.navigation` | `[]` | Header links with `title` and site-relative `path` fields. |
| `themes.minima.showExcerpts` | `false` | Render each post's summary in collection and taxonomy lists. |
| `themes.minima.feedPath` | `null` | Site-relative RSS path. Also enables feed discovery in `<head>`. |
| `themes.minima.socialLinks` | `[]` | Footer profiles with `platform`, `username`, and `url` fields. |

The global `website.metadata` values `lang`, `title`, `description`, `author`, and `email` configure the corresponding Minima site elements. Per-page `author` and `date` frontmatter values appear in the page header when present. Excerpts use everything before `<!--more-->`.

## Proof-of-concept scope

Included:

- Site header, responsive navigation, footer, and social icons
- Home and static-page layouts
- Dated post layouts and optional per-post authors
- Collection and taxonomy post lists with optional excerpts
- Pagination and RSS subscription/discovery links
- Original Minima styling, including mobile layouts and syntax highlighting styles

Not yet ported:

- Disqus and Google Analytics integrations
- Jekyll SEO tag metadata beyond the page title and description
- Minima skin customization
- Automatic navigation from the content directory

The theme layouts use `lib.mkDefault`, so sites can override individual layouts or partials through the normal nixtml module options.

## Upstream source

- Version: Minima 2.5.2
- Commit: `c6e74bbfe7a0d0ae8c806cb38b012d01b25b1f7d`
- License: MIT; copyright Parker Moore and the Minima contributors
