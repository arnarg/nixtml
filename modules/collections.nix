{ lib, config, ... }:
let
  inherit (config.website) baseURL metadata;
  contentOutput = config.website.content.output;
in
{
  options.website = with lib; {
    collections = mkOption {
      type =
        with types;
        attrsOf (
          submodule (
            { name, config, ... }:
            {
              options = {
                path = mkOption {
                  type = types.str;
                  description = ''
                    Path to folder in `config.website.content.dir` that contains items for the collection.

                    For example if all blog posts are kept in ./content/blog/posts and `config.website.content.dir = ./content;`, setting this option to `"blog/posts"` will create a collection for the blog posts.
                    The collection will automatically create pages (such as `blog/page/1`, `blog/page/2`, etc.) using template `config.website.layouts.collection` and an RSS feed for the collection (by default `<name>.xml`).
                  '';
                };
                pagination = {
                  perPage = mkOption {
                    type = types.int;
                    default = 5;
                    description = ''
                      Number of collection item per page when rendering the pagination.
                    '';
                  };
                };
                taxonomies = mkOption {
                  type = with types; listOf str;
                  default = [ ];
                  example = [ "tags" ];
                  description = ''
                    Taxonomies to enable for the collection.
                  '';
                };
                rss = {
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = ''
                      Whether or not to automatically create an RSS feed for this collection.
                    '';
                  };
                  limit = mkOption {
                    type = types.int;
                    default = 50;
                    description = ''
                      Max number of collection items to include in the RSS feed.
                    '';
                  };

                  path = mkOption {
                    type = types.str;
                    internal = true;
                  };
                  result = mkOption {
                    type = types.str;
                    internal = true;
                  };
                };

                items = mkOption {
                  type = with types; listOf (attrsOf anything);
                  default = [ ];
                  internal = true;
                };

                pages = mkOption {
                  type =
                    with types;
                    attrsOf (
                      submodule {
                        options = {
                          path = mkOption {
                            type = types.str;
                          };
                          context = mkOption {
                            type = with types; attrsOf anything;
                          };
                        };
                      }

                    );
                  internal = true;
                };

                taxonomyPages = mkOption {
                  type =
                    with types;
                    attrsOf (
                      attrsOf (
                        attrsOf (submodule {
                          options = {
                            path = mkOption {
                              type = types.str;
                            };
                            context = mkOption {
                              type = with types; attrsOf anything;
                            };
                          };
                        })
                      )
                    );
                  internal = true;
                };
              };

              config = {
                items = lib.pipe contentOutput [
                  (lib.filterAttrs (n: v: lib.hasPrefix config.path n))
                  (lib.mapAttrsToList (
                    n: v:
                    let
                      inherit (v) result;
                    in
                    {
                      inherit (result) content;
                      inherit (result.metadata)
                        title
                        dateEpoch
                        dateRFC822
                        dateW3C
                        date
                        ;
                      permalink = "${baseURL}/${n}";
                      url = "/" + n;
                      metadata = lib.removeAttrs result.metadata [
                        "title"
                        "dateEpoch"
                        "dateRFC822"
                        "dateW3C"
                        "date"
                      ];
                      summary = with lib; head (splitString "<!--more-->" result.content);
                    }
                  ))
                  (lib.sort (a: b: a.dateEpoch > b.dateEpoch))
                ];

                pages =
                  let
                    inherit (config.pagination) perPage;
                    prefix = lib.pipe config.path [
                      (lib.splitString "/")
                      (p: if p == [ ] then p else lib.take (lib.length p - 1) p)
                      (
                        p:
                        let
                          joined = lib.concatStringsSep "/" p;
                        in
                        if lib.length p < 1 then joined else joined + "/"
                      )
                    ];
                    pagination = lib.paginate perPage config.items;
                  in
                  lib.listToAttrs (
                    lib.map (
                      page:
                      let
                        context = {
                          inherit (pagination) totalPages;
                          inherit (page) pageNumber items;
                        };
                        path =
                          if page.pageNumber == 1 then "${prefix}index.html" else "${prefix}page/${toString page.pageNumber}";
                      in
                      {
                        name = toString page.pageNumber;
                        value = {
                          inherit context;
                          path = lib.mkDefault path;
                        };
                      }
                    ) pagination.pages
                  );

                taxonomyPages = lib.listToAttrs (
                  lib.map (
                    taxonomy:
                    let
                      sorted = lib.sortTaxonomy [ "metadata" taxonomy ] config.items;
                    in
                    {
                      name = taxonomy;
                      value = lib.mapAttrs (
                        tag: items:
                        let
                          inherit (config.pagination) perPage;
                          prefix = lib.pipe config.path [
                            (lib.splitString "/")
                            (p: if p == [ ] then p else lib.take (lib.length p - 1) p)
                            (
                              p:
                              p
                              ++ [
                                taxonomy
                                tag
                              ]
                            )
                            (p: (lib.concatStringsSep "/" p) + "/")
                          ];
                          pagination = lib.paginate perPage items;
                        in
                        lib.listToAttrs (
                          lib.map (
                            page:
                            let
                              context = {
                                inherit (pagination) totalPages;
                                inherit (page) pageNumber items;
                              };
                              path =
                                if page.pageNumber == 1 then "${prefix}index.html" else "${prefix}page/${toString page.pageNumber}";
                            in
                            {
                              name = toString page.pageNumber;
                              value = {
                                inherit context;
                                path = lib.mkDefault path;
                              };
                            }
                          ) pagination.pages
                        )
                      ) sorted;
                    }
                  ) config.taxonomies
                );

                rss.path = lib.pipe config.path [
                  (lib.splitString "/")
                  (p: if p == [ ] then p else lib.take (lib.length p - 1) p)
                  (p: p ++ [ "index.xml" ])
                  (lib.concatStringsSep "/")
                ];

                rss.result = lib.mkRSSFeed {
                  inherit (config) items;
                  link = baseURL;
                  selfLink = "${baseURL}/${config.rss.path}";
                  title = metadata.title or null;
                  lang = metadata.lang or null;
                };
              };
            }
          )
        );
      default = { };
    };
  };

  config = {
    website.files = lib.concatMapAttrs (n: v: {
      ${v.rss.path}.text = v.rss.result;
    }) config.website.collections;

    website.pages =
      let
        collectionPages = lib.concatMapAttrs (
          n: v:
          lib.concatMapAttrs (_: page: {
            ${page.path} =
              let
                inherit (page) context;
                cfg = config.website.collections.${n};
                nextNumber = toString (context.pageNumber + 1);
                prevNumber = toString (context.pageNumber - 1);
                hasNext = cfg.pages ? "${nextNumber}";
                hasPrev = cfg.pages ? "${prevNumber}";
                nextPageURL =
                  if hasNext then
                    "/" + cfg.pages."${nextNumber}".path
                  else
                    builtins.throw "Next page '${nextNumber}' does not exist. Use `hasNext` from context to check if next page exists.";
                prevPageURL =
                  if hasPrev then
                    "/" + cfg.pages."${prevNumber}".path
                  else
                    builtins.throw "Previous page '${prevNumber}' does not exist. Use `hasPrev` from context to check if previous page exists.";
              in
              {
                extraContext = context // {
                  inherit
                    hasNext
                    hasPrev
                    nextPageURL
                    prevPageURL
                    ;
                  title = null;
                };
                lastModified = page.dateW3C or null;
                layout = config.website.layouts.collection;
              };
          }) v.pages
        ) config.website.collections;

        taxonomyPages = lib.concatMapAttrs (
          n: v:
          (lib.listToAttrs (
            lib.mapAttrsToListRecursiveCond (path: _: lib.length path < 3) (path: page: {
              name = page.path;
              value =
                let
                  inherit (page) context;
                  taxonomy = lib.elemAt path 0;
                  title = lib.elemAt path 1;
                  cfg = config.website.collections.${n}.taxonomyPages.${taxonomy}.${title};
                  nextNumber = toString (context.pageNumber + 1);
                  prevNumber = toString (context.pageNumber - 1);
                  hasNext = cfg ? "${nextNumber}";
                  hasPrev = cfg ? "${prevNumber}";
                  nextPageURL =
                    if hasNext then
                      "/" + cfg."${nextNumber}".path
                    else
                      builtins.throw "Next page '${nextNumber}' does not exist. Use `hasNext` from context to check if next page exists.";
                  prevPageURL =
                    if hasPrev then
                      "/" + cfg."${prevNumber}".path
                    else
                      builtins.throw "Previous page '${prevNumber}' does not exist. Use `hasPrev` from context to check if previous page exists.";
                in
                {
                  extraContext = context // {
                    inherit
                      hasNext
                      hasPrev
                      nextPageURL
                      prevPageURL
                      title
                      ;
                  };
                  layout = config.website.layouts.taxonomy;
                };
            }) v.taxonomyPages
          ))
        ) config.website.collections;
      in
      taxonomyPages // collectionPages;
  };
}
