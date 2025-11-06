{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep;
  inherit (config) website;

  strOrListOfStr =
    with lib;
    types.coercedTo (types.listOf types.str) (concatStringsSep "\n") types.str;

  formatHTML =
    name: html:
    pkgs.stdenv.mkDerivation {
      inherit html name;

      passAsFile = [ "html" ];

      phases = [ "buildPhase" ];

      buildPhase = ''
        cat $htmlPath | ${pkgs.superhtml}/bin/superhtml fmt --stdin > $out
      '';
    };
in
{
  options.website = with lib; {
    name = mkOption {
      type = types.str;
      description = "Name of the website.";
    };

    baseURL = mkOption {
      type = types.str;
      description = "Base URL of the generated website. Used for generating permalinks.";
    };

    metadata = mkOption {
      type = with types; attrsOf anything;
      default = { };
      description = "Website wide metadata to be used for templating the website.";
    };

    sitemap.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to automatically generate a sitemap.xml file in the website build output.";
    };

    layouts = {
      base = mkOption {
        type = with types; functionTo strOrListOfStr;
        example = literalExpression ''
          let
            inherit (lib.tags)
              html
              head
              body
              title
              div
              meta
              ;
            inherit (lib) attrs;
            inherit (config.website) metadata;
          in {path, content, ...}:
            "<!DOCTYPE html>\n"
            +
              html
                [ (attrs.lang metadata.lang) ]
                [
                  (head
                    [ ]
                    [
                      (title metadata.title)
                      (meta [
                        (attrs.property "og:type")
                        (attrs.content (if path == [ "index" ] then "website" else "article"))
                      ])
                    ]
                  )
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
                ]
        '';
        description = ''
          Base template used as the skeleton for every page defined in `config.website.pages`.
        '';
      };

      home = mkOption {
        type = with types; functionTo strOrListOfStr;
        description = ''
          Template used for rendering `index.md` inside `config.website.content.dir`.
        '';
      };

      page = mkOption {
        type = with types; functionTo strOrListOfStr;
        description = ''
          Template used for rendering any parsed markdown file (apart from `index.md`) inside `config.website.content.dir`.
        '';
      };

      collection = mkOption {
        type = with types; functionTo strOrListOfStr;
        description = ''
          Template used for rendering pagination of items in a collection. See `config.website.collections`.
        '';
      };

      taxonomy = mkOption {
        type = with types; functionTo strOrListOfStr;
        description = ''
          Template used for rendering pagination of items in a taxonomy of a collection. See `config.website.collections.<name>.taxonomies`.
        '';
      };

      partials = mkOption {
        type = with types; attrsOf (functionTo strOrListOfStr);
        default = { };
        description = ''
          Arbritary attribute set of templates to be used in the main layouts.
        '';
      };
    };

    pages = mkOption {
      type =
        with types;
        attrsOf (
          submodule (
            { name, config, ... }:
            {
              options = {
                path = mkOption {
                  type = types.str;
                  default = name;
                  # Makes sure the path ends with "index.html"
                  apply =
                    p:
                    let
                      normalized = lib.pipe p [
                        (lib.splitString "/")
                        (lib.filter (x: x != ""))
                        (lib.concatStringsSep "/")
                      ];
                    in
                    if lib.hasSuffix "index.html" normalized then
                      normalized
                    else if lib.hasSuffix "index" normalized then
                      normalized + ".html"
                    else
                      normalized + "/index.html";
                };
                layout = mkOption {
                  type = with types; functionTo strOrListOfStr;
                };
                extraContext = mkOption {
                  type = with types; lazyAttrsOf anything;
                  default = { };
                };
                lastModified = mkOption {
                  type = with types; nullOr str;
                  default = null;
                  description = ''
                    Date in the [W3C Datetime](https://www.w3.org/TR/NOTE-datetime) format. This is used for generating sitemap.xml.
                  '';
                };
                result = mkOption {
                  type = types.package;
                  internal = true;
                };
              };

              config = {
                result =
                  let
                    path = lib.splitString "/" config.path;

                    context = {
                      inherit path;
                    }
                    // config.extraContext;

                    content = config.layout context;

                    html = website.layouts.base (context // { inherit content; });
                  in
                  formatHTML "nixtml-${website.name}-${lib.concatStringsSep "-" path}" html;
              };
            }
          )
        );
      default = { };
      description = ''
        Attribute set of pages to be templated and put in the final build output. Keep in mind that setting `config.website.content.dir` and `config.website.collections` populates this attribute set with pages it generates.

        Templated pages are automatically passed to `config.website.files` and included in the final website build derivation.
      '';
    };

    files = mkOption {
      type = types.attrsOf (
        types.submodule (
          {
            name,
            config,
            options,
            ...
          }:
          {
            options = {
              path = mkOption {
                type = types.str;
                default = name;
                description = "Path of output file.";
              };
              text = mkOption {
                type = with types; nullOr lines;
                default = null;
                description = "Text of the output file.";
              };
              source = mkOption {
                type = types.path;
                description = "Path of the source file.";
              };
            };

            config = {
              source = lib.mkIf (config.text != null) (
                let
                  name' = "nixtml-" + lib.replaceStrings [ "/" ] [ "-" ] name;
                in
                lib.mkDerivedConfig options.text (pkgs.writeText name')
              );
            };
          }
        )
      );
      default = { };
      description = "Files written to the website build output.";
    };
  };

  config = {
    website.files = lib.mkMerge [
      (lib.concatMapAttrs (n: v: {
        ${v.path}.source = v.result;
      }) config.website.pages)
      (lib.mkIf config.website.sitemap.enable {
        "sitemap.xml".text = lib.mkSitemap { inherit (config.website) baseURL pages; };
      })
    ];
  };
}
