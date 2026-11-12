{ lib, config, ... }:
let
  inherit (lib.tags)
    a
    aside
    details
    li
    nav
    p
    summary
    ul
    ;
  inherit (lib) attrs;

  navigation = [
    {
      title = "Guides";
      items = [
        {
          title = "Getting started";
          path = "";
        }
        {
          title = "Collections";
          path = "collections";
        }
        {
          title = "Taxonomies";
          path = "taxonomies";
        }
        {
          title = "Templating";
          path = "templating";
        }
      ];
    }
    {
      title = "Reference";
      items = [
        {
          title = "Configuration options";
          path = "options";
        }
      ];
    }
  ];

  pageKey =
    path:
    lib.pipe path [
      (lib.concatStringsSep "/")
      (lib.removeSuffix "index.html")
      (lib.removeSuffix "/")
    ];

  pageHref = path: config.website.baseURI + lib.optionalString (path != "") "${path}/";

  navigationMenu =
    currentPath:
    nav
      [
        (attrs.class "menu")
        (attrs.aria "label" "Documentation")
      ]
      (
        lib.concatMap (group: [
          (p [ (attrs.class "menu-label") ] [ group.title ])
          (ul [ (attrs.class "menu-list") ] (
            map (
              item:
              let
                isActive = currentPath == item.path;
              in
              li
                [ ]
                [
                  (a (
                    [ (attrs.href (pageHref item.path)) ]
                    ++ lib.optional isActive (attrs.class "is-active")
                    ++ lib.optional isActive (attrs.aria "current" "page")
                  ) [ item.title ])
                ]
            ) group.items
          ))
        ]) navigation
      );
in
{
  website.layouts.partials.docsSidebar =
    {
      path,
      mobile ? false,
      ...
    }:
    let
      menu = navigationMenu (pageKey path);
    in
    if mobile then
      details
        [
          (attrs.classes [
            "docs-mobile-nav"
            "is-hidden-desktop"
          ])
        ]
        [
          (summary [ ] [ "Browse documentation" ])
          menu
        ]
    else
      aside
        [
          (attrs.classes [
            "docs-sidebar"
            "column"
            "is-one-quarter-desktop"
            "is-hidden-touch"
          ])
        ]
        [ menu ];
}
