{ lib, config, ... }:
let
  inherit (lib.tags)
    a
    aside
    details
    li
    nav
    p
    span
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
          title = "Content and frontmatter";
          path = "content";
        }
        {
          title = "Layouts and partials";
          path = "templating";
        }
        {
          title = "Collections and pagination";
          path = "collections";
        }
        {
          title = "Taxonomies and RSS";
          path = "taxonomies";
        }
        {
          title = "Using themes and Minima";
          path = "themes";
        }
      ];
    }
    {
      title = "Reference";
      items = [
        {
          title = "Template contexts";
          path = "reference/templates";
        }
        {
          title = "HTML tags and attributes";
          path = "reference/html";
        }
        {
          title = "Markdown and highlighting";
          path = "reference/markdown";
        }
        {
          title = "Configuration options";
          path = "options";
        }
      ];
    }
  ];

  guideItems = (lib.head navigation).items;

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
  website.layouts.partials.docsPager =
    { path, ... }:
    let
      currentPath = pageKey path;
      indexedItems = lib.imap0 (index: item: item // { inherit index; }) guideItems;
      current = lib.findFirst (item: item.path == currentPath) null indexedItems;
      previous =
        if current != null && current.index > 0 then lib.elemAt guideItems (current.index - 1) else null;
      next =
        if current != null && current.index + 1 < lib.length guideItems then
          lib.elemAt guideItems (current.index + 1)
        else
          null;
    in
    if current == null then
      ""
    else
      nav
        [
          (attrs.class "docs-pager")
          (attrs.aria "label" "Guide pagination")
        ]
        (
          lib.optional (previous != null) (
            a
              [
                (attrs.classes [
                  "docs-pager-link"
                  "docs-pager-previous"
                ])
                (attrs.href (pageHref previous.path))
              ]
              [
                (span [ (attrs.class "docs-pager-label") ] [ "Previous guide" ])
                (span [ (attrs.class "docs-pager-title") ] [ previous.title ])
              ]
          )
          ++ lib.optional (next != null) (
            a
              [
                (attrs.classes [
                  "docs-pager-link"
                  "docs-pager-next"
                ])
                (attrs.href (pageHref next.path))
              ]
              [
                (span [ (attrs.class "docs-pager-label") ] [ "Next guide" ])
                (span [ (attrs.class "docs-pager-title") ] [ next.title ])
              ]
          )
        );

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
