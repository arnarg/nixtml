# Docs theme for nixtml

A documentation theme built on [Bulma](https://bulma.io/), used by [nixtml's documentation](https://arnarg.github.io/nixtml/).

- Sidebar navigation built from `nav` frontmatter, with previous and next links within sections.
- Configurable logo, colors, code highlighting styles, footer and edit links.
- Light and dark color schemes.
- Self-hosted Fira Sans and Fira Mono from nixpkgs, subset like Google Fonts.

## Usage

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

See [Using the docs theme](https://arnarg.github.io/nixtml/docs-theme/) for all options.

Bulma is fetched at a pinned release and compiled during the Nix build. Bulma is MIT licensed, and Fira Sans and Fira Mono are licensed under the SIL Open Font License 1.1.
