{
  lib,
}:
lib.extend (
  self: old:
  let
    inherit (lib) length concatStringsSep;

    renderAttrs = attrs: if length attrs > 0 then " " + concatStringsSep " " attrs else "";

    params = {
      lib = self;
    };
  in
  {
    mkTag = name: attrs: content: ''
      <${name}${renderAttrs attrs}>
        ${concatStringsSep "\n" content}
      </${name}>'';

    mkVoid = name: attrs: "<${name}${renderAttrs attrs}>";

    mkAttr = name: value: "${name}=\"${value}\"";

    tags = import ./tags.nix params;
    attrs = import ./attrs.nix params;

    escapeHTML = html: builtins.replaceStrings [ "<" ">" "&" ] [ "&lt;" "&gt;" "&amp;" ] html;

    sortTaxonomy =
      path: items:
      lib.foldr (
        item: state:
        let
          taxonomy = lib.attrByPath path [ ] item;

          updated = lib.listToAttrs (
            map (t: {
              name = t;
              value = [ item ] ++ (lib.attrByPath [ t ] [ ] state);
            }) taxonomy
          );
        in
        state // updated
      ) { } items;

    paginate =
      perPage: items:
      let
        totalPages = builtins.ceil ((lib.length items) / (perPage * 1.0));
      in
      {
        inherit totalPages;
        pages = lib.genList (x: {
          pageNumber = x + 1;
          items = lib.sublist (x * perPage) perPage items;
        }) totalPages;
      };

    mkRSSFeed =
      {
        items,
        link,
        selfLink,
        title ? null,
        lang ? null,
      }:
      let
        newest = if builtins.length items > 0 then lib.head items else null;

        mkItem =
          item:
          lib.concatStrings [
            "<item>"
            "<title>${item.title}</title>"
            "<link>${item.permalink}</link>"
            "<guid>${item.permalink}</guid>"
            "<pubDate>${item.dateRFC822}</pubDate>"
            "<description>${self.escapeHTML item.summary}</description>"
            "</item>"
          ];
      in
      lib.concatStrings [
        "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"
        "<rss xmlns:atom=\"http://www.w3.org/2005/Atom\" version=\"2.0\">"
        "<channel>"
        (if title != null then "<title>${title}</title>" else "")
        "<link>${link}</link>"
        "<description>Recent content ${link}</description>"
        "<generator>nixtml</generator>"
        (if lang != null then "<language>${lang}</language>" else "")
        "<atom:link href=\"${selfLink}\" rel=\"self\" type=\"application/rss+xml\"/>"
        (if newest != null then "<lastBuildDate>${newest.dateRFC822}</lastBuildDate>" else "")
        (lib.concatStrings (map mkItem items))
        "</channel>"
        "</rss>"
      ];

    mkSitemap =
      { baseURL, pages }:
      let
        mkURL =
          path: page:
          let
            realpath = lib.pipe path [
              (lib.removeSuffix "index.html")
              (lib.removeSuffix "/")
              (p: if lib.stringLength p < 1 then p else p + "/")
            ];
          in
          lib.concatStrings [
            "<url>"
            "<loc>${lib.removeSuffix "/" baseURL}/${realpath}</loc>"
            (if page.lastModified != null then "<lastmod>${page.lastModified}</lastmod>" else "")
            "</url>"
          ];
      in
      lib.concatStrings [
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\">"
        (lib.concatStrings (lib.mapAttrsToList mkURL pages))
        "</urlset>"
      ];
  }
)
