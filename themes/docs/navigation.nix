{ lib, config, ... }:
let
  inherit (lib.tags)
    a
    aside
    button
    div
    li
    nav
    p
    span
    ul
    ;
  inherit (lib) attrs;

  cfg = config.themes.docs;
  inherit (cfg.navigation) sections;

  navigationPages = lib.pipe config.website.content.pages [
    (lib.filterAttrs (_: page: page.result.metadata ? nav))
    (lib.mapAttrsToList (
      name: page:
      let
        inherit (page.result) metadata;
        navMetadata = metadata.nav;
        sectionId =
          navMetadata.section
            or (throw "Content page '${name}' must define nav.section when it defines nav metadata.");
        item = {
          # Pages named `index` are rendered as their directory's index.
          path = if name == "index" then "" else lib.removeSuffix "/index" name;
          title = navMetadata.label or (metadata.title or name);
          order =
            navMetadata.order
              or (throw "Content page '${name}' must define nav.order when it defines nav metadata.");
          section = sectionId;
        };
      in
      if lib.any (section: section.id == sectionId) sections then
        item
      else
        throw "Content page '${name}' uses unknown navigation section '${sectionId}'. Known sections are defined in `themes.docs.navigation.sections`."
    ))
    (lib.sort (
      a: b:
      if a.order != b.order then
        a.order < b.order
      else if a.title != b.title then
        a.title < b.title
      else
        a.path < b.path
    ))
  ];

  navigation = lib.pipe sections [
    (map (
      section:
      section
      // {
        items = lib.filter (item: item.section == section.id) navigationPages;
      }
    ))
    (lib.filter (section: section.items != [ ]))
  ];

  pageKey =
    path:
    lib.pipe path [
      (lib.concatStringsSep "/")
      (lib.removeSuffix "index.html")
      (lib.removeSuffix "/")
    ];

  pageHref = path: config.website.baseURI + lib.optionalString (path != "") "${path}/";

  menuList =
    items:
    ul [ (attrs.class "menu-list") ] (
      map (
        item:
        li
          [ ]
          [
            (a (
              [ (attrs.href item.href) ]
              ++ lib.optional item.active (attrs.class "is-active")
              ++ lib.optional item.active (attrs.aria "current" "page")
            ) [ item.title ])
          ]
      ) items
    );

  navigationMenu =
    currentPath:
    nav
      [
        (attrs.class "menu")
        (attrs.aria "label" cfg.navigation.label)
      ]
      (
        lib.concatMap (group: [
          (p [ (attrs.class "menu-label") ] [ group.title ])
          (menuList (
            map (item: {
              inherit (item) title;
              href = pageHref item.path;
              active = currentPath == item.path;
            }) group.items
          ))
        ]) navigation
        ++ lib.optionals (cfg.navigation.links != [ ]) [
          (p [ (attrs.class "menu-label") ] [ cfg.navigation.linksTitle ])
          (menuList (
            map (link: {
              inherit (link) title;
              href = link.url;
              active = false;
            }) cfg.navigation.links
          ))
        ]
      );
in
{
  options.themes.docs = with lib; {
    navigation = {
      sections = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              id = mkOption {
                type = types.str;
                description = "Identifier used by pages in their `nav.section` frontmatter.";
              };
              title = mkOption {
                type = types.str;
                description = "Title displayed above the section in the navigation.";
              };
              pager = mkOption {
                type = types.bool;
                default = false;
                description = "Whether pages in this section link to the previous and next page in the section.";
              };
            };
          }
        );
        default = [
          {
            id = "guides";
            title = "Guides";
            pager = true;
          }
          {
            id = "reference";
            title = "Reference";
          }
        ];
        description = ''
          Sections of the navigation, in the order they're displayed.

          Content pages are added to the navigation through their frontmatter:

          ```yaml
          nav:
            section: guides # The `id` of a section
            order: 10       # Position within the section
            label: Intro    # Optional, defaults to the page title
          ```

          Sections without any pages are hidden. Using a section that isn't defined here is an error.
        '';
      };

      links = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              title = mkOption {
                type = types.str;
                description = "Link text.";
              };
              url = mkOption {
                type = types.str;
                description = "Link URL.";
              };
            };
          }
        );
        default = [ ];
        example = [
          {
            title = "GitHub";
            url = "https://github.com/arnarg/nixtml";
          }
        ];
        description = "Extra links displayed in a separate section after the pages in the navigation.";
      };

      linksTitle = mkOption {
        type = types.str;
        default = "Links";
        description = "Title of the navigation section containing `links`.";
      };

      label = mkOption {
        type = types.str;
        default = "Documentation";
        description = "Accessible label of the navigation.";
      };

      mobileLabel = mkOption {
        type = types.str;
        default = "Browse documentation";
        description = "Accessible label of the navigation button on small screens.";
      };
    };

    pager = {
      previousLabel = mkOption {
        type = types.str;
        default = "Previous";
        description = "Label above the link to the previous page.";
      };
      nextLabel = mkOption {
        type = types.str;
        default = "Next";
        description = "Label above the link to the next page.";
      };
    };
  };

  config.website.layouts.partials = {
    docsMobileNavToggle = lib.mkDefault (
      _:
      button
        [
          (attrs.type "button")
          (attrs.classes [
            "navbar-burger"
            "docs-mobile-nav-toggle"
            "is-hidden-desktop"
          ])
          (attrs.aria "label" cfg.navigation.mobileLabel)
          (attrs.aria "expanded" "false")
          (attrs.aria "controls" "docs-mobile-navigation")
          (lib.mkAttr "hidden" "")
        ]
        (lib.replicate 4 (span [ (attrs.aria "hidden" "true") ] [ ]))
    );

    docsPager = lib.mkDefault (
      { path, ... }:
      let
        currentPath = pageKey path;
        current = lib.findFirst (item: item.path == currentPath) null navigationPages;
        section = lib.findFirst (section: current != null && section.id == current.section) null navigation;
        items = if section != null && section.pager then section.items else [ ];
        indexedItems = lib.imap0 (index: item: item // { inherit index; }) items;
        currentItem = lib.findFirst (item: item.path == currentPath) null indexedItems;
        previous =
          if currentItem != null && currentItem.index > 0 then
            lib.elemAt items (currentItem.index - 1)
          else
            null;
        next =
          if currentItem != null && currentItem.index + 1 < lib.length items then
            lib.elemAt items (currentItem.index + 1)
          else
            null;
        pagerLink =
          direction: label: item:
          a
            [
              (attrs.classes [
                "docs-pager-link"
                "docs-pager-${direction}"
              ])
              (attrs.href (pageHref item.path))
            ]
            [
              (span [ (attrs.class "docs-pager-label") ] [ label ])
              (span [ (attrs.class "docs-pager-title") ] [ item.title ])
            ];
      in
      if currentItem == null then
        ""
      else
        nav
          [
            (attrs.class "docs-pager")
            (attrs.aria "label" "Pagination")
          ]
          (
            lib.optional (previous != null) (pagerLink "previous" cfg.pager.previousLabel previous)
            ++ lib.optional (next != null) (pagerLink "next" cfg.pager.nextLabel next)
          )
    );

    docsSidebar = lib.mkDefault (
      {
        path,
        mobile ? false,
        ...
      }:
      let
        menu = navigationMenu (pageKey path);
      in
      if mobile then
        div
          [
            (attrs.classes [
              "docs-mobile-nav"
              "is-hidden-desktop"
            ])
          ]
          [
            (div
              [
                (attrs.class "docs-mobile-nav-overlay")
                (attrs.aria "hidden" "true")
              ]
              [ ])
            (aside
              [
                (attrs.class "docs-mobile-nav-panel")
                (attrs.id "docs-mobile-navigation")
              ]
              [ menu ])
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
          [ menu ]
    );
  };
}
