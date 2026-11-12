---
title: Hello, nixtml!
date: 2025-11-12T15:00:00
tags:
  - nix
  - release
---
Minima's familiar post layout now renders through nixtml's functional HTML templates.

<!--more-->

The theme implements the base, page, collection, and taxonomy layouts. All styles are compiled from Minima's pinned Sass sources during the Nix build.

```nix
{
  imports = [ nixtml.themes.minima ];
}
```
