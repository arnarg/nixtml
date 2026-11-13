{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.themes.docs.fonts;

  # Unicode ranges of the subsets Google Fonts splits fonts into.
  knownSubsets = {
    latin = "U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD";
    latin-ext = "U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C4, U+2113, U+2C60-2C7F, U+A720-A7FF";
    cyrillic = "U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116";
    cyrillic-ext = "U+0460-052F, U+1C80-1C8A, U+20B4, U+2DE0-2DFF, U+A640-A69F, U+FE2E-FE2F";
    greek = "U+0370-0377, U+037A-037F, U+0384-038A, U+038C, U+038E-03A1, U+03A3-03FF";
    greek-ext = "U+1F00-1FFF";
    vietnamese = "U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB";
  };

  firaSans = "${pkgs.fira-sans.src}/Download_Folder_FiraSans_4301/Fonts/Fira_Sans_WEB_4301/Normal";
  firaMono = "${pkgs.fira-mono.src}/Fonts/FiraMono_WEB_32";

  firaSansFace = weight: style: file: {
    family = "Fira Sans";
    inherit weight style;
    source = "${firaSans}/${if style == "italic" then "Italic" else "Roman"}/${file}";
  };

  formats = {
    woff2 = "woff2";
    woff = "woff";
    ttf = "truetype";
    otf = "opentype";
  };

  extensionOf =
    source:
    lib.last (lib.splitString "." (builtins.unsafeDiscardStringContext (baseNameOf (toString source))));

  slug = lib.flip lib.pipe [
    lib.toLower
    (lib.replaceStrings [ " " ] [ "-" ])
  ];

  subsets = map (
    subset:
    if lib.isString subset then
      {
        name = subset;
        unicodeRange = knownSubsets.${subset};
      }
    else
      subset
  ) cfg.subset;

  # Every font file to produce, along with its `@font-face` rule.
  fontFiles = lib.concatMap (
    face:
    let
      base = "${slug face.family}-${toString face.weight}-${face.style}";
      mkFile = file: format: subset: {
        inherit
          face
          file
          format
          subset
          ;
      };
    in
    if cfg.subset == null then
      let
        ext = extensionOf face.source;
      in
      [
        (mkFile "${base}.${ext}" (formats.${ext}
          or (throw "Unsupported font format '${ext}' for '${toString face.source}'.")
        ) null)
      ]
    else
      map (subset: mkFile "${base}-${subset.name}.woff2" "woff2" subset) subsets
  ) cfg.faces;

  fontFaceRule =
    {
      face,
      file,
      format,
      subset,
    }:
    ''
      @font-face {
        font-family: "${face.family}";
        font-style: ${face.style};
        font-weight: ${toString face.weight};
        font-display: swap;
        src: url("../fonts/${file}") format("${format}");
    ''
    + lib.optionalString (subset != null) ''
      unicode-range: ${subset.unicodeRange};
    ''
    + ''
      }
    '';

  fontTools = pkgs.python3.withPackages (ps: [
    ps.fonttools
    ps.brotli
  ]);

  fontFileCommand =
    {
      face,
      file,
      subset,
      ...
    }:
    if subset == null then
      ''
        cp ${lib.escapeShellArg face.source} $out/fonts/${lib.escapeShellArg file}
      ''
    else
      # Keeps the same OpenType features as Google Fonts: pyftsubset's
      # defaults plus fractions and numeral spacing.
      ''
        ${fontTools}/bin/pyftsubset ${lib.escapeShellArg face.source} \
          --unicodes=${lib.escapeShellArg (lib.replaceStrings [ " " ] [ "" ] subset.unicodeRange)} \
          --layout-features+=dnom,frac,numr,pnum,tnum \
          --flavor=woff2 \
          --output-file=$out/fonts/${lib.escapeShellArg file}
      '';
in
{
  options.themes.docs.fonts = with lib; {
    primary = mkOption {
      type = with types; nullOr str;
      default = ''"Fira Sans", sans-serif'';
      description = ''
        CSS `font-family` for body text and headings. `null` uses Bulma's default system font stack.
      '';
    };

    code = mkOption {
      type = with types; nullOr str;
      default = ''"Fira Mono", Inconsolata, Hack, "SF Mono", "Roboto Mono", "Source Code Pro", "Ubuntu Mono", monospace'';
      description = ''
        CSS `font-family` for code. `null` uses Bulma's default monospace font stack.
      '';
    };

    faces = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            family = mkOption {
              type = types.str;
              description = "Font family name, as used in `primary` and `code`.";
            };
            weight = mkOption {
              type = types.ints.between 1 1000;
              default = 400;
              description = "Font weight of this face.";
            };
            style = mkOption {
              type = types.enum [
                "normal"
                "italic"
              ];
              default = "normal";
              description = "Font style of this face.";
            };
            source = mkOption {
              type = types.path;
              description = ''
                Path to the font file. Can be `woff2`, `woff`, `ttf` or `otf`.
              '';
            };
          };
        }
      );
      default = [
        (firaSansFace 300 "normal" "FiraSans-Light.woff2")
        (firaSansFace 400 "normal" "FiraSans-Regular.woff2")
        (firaSansFace 400 "italic" "FiraSans-Italic.woff2")
        (firaSansFace 600 "normal" "FiraSans-SemiBold.woff2")
        (firaSansFace 700 "normal" "FiraSans-Bold.woff2")
        (firaSansFace 800 "normal" "FiraSans-ExtraBold.woff2")
        {
          family = "Fira Mono";
          source = "${firaMono}/FiraMono-Regular.woff2";
        }
      ];
      defaultText = literalMD "Fira Sans (weights 300, 400, 400 italic, 600, 700 and 800) and Fira Mono, from the `fira-sans` and `fira-mono` packages.";
      description = ''
        Font faces to include in the website. Each face is copied into the website, or subset according to `subset`, and gets an `@font-face` rule.

        Browsers only download a face when the page uses its family, weight and style.
      '';
    };

    subset = mkOption {
      type =
        with types;
        nullOr (
          listOf (
            either (enum (attrNames knownSubsets)) (submodule {
              options = {
                name = mkOption {
                  type = str;
                  description = "Name of the subset, used in the font file name.";
                };
                unicodeRange = mkOption {
                  type = str;
                  description = "Comma separated unicode ranges, in CSS `unicode-range` syntax.";
                  example = "U+0000-00FF, U+0131";
                };
              };
            })
          )
        );
      default = [
        "latin"
        "latin-ext"
      ];
      example = [
        "latin"
        "latin-ext"
        "cyrillic"
      ];
      description = ''
        Subsets to split each font face into, using the same unicode ranges as Google Fonts. Each subset becomes a separate `woff2` file with a
        `unicode-range`, so browsers only download the subsets a page needs. Characters outside all subsets fall back to the next font in the font stack.

        Known subsets are ${
          concatMapStringsSep ", " (s: "`${s}`") (attrNames knownSubsets)
        }. Custom subsets can be given as `{ name; unicodeRange; }`.

        `null` disables subsetting and includes each face's source file as is.
      '';
    };
  };

  options.themes.docs.internal.fonts = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    description = "Font files and their `@font-face` rules in `fonts.scss`.";
  };

  config.themes.docs.internal.fonts = pkgs.runCommand "nixtml-docs-theme-fonts" { } ''
    mkdir -p $out/fonts
    ${lib.concatMapStrings fontFileCommand fontFiles}
    cp ${
      pkgs.writeText "fonts.scss" (lib.concatMapStringsSep "\n" fontFaceRule fontFiles)
    } $out/fonts.scss
  '';
}
