{ nixpkgslib }:
let
  lib = import ./default.nix { lib = nixpkgslib; };
in
{
  escapeHTML = {
    testSimpleString = {
      expr = lib.escapeHTML "< Prev & Next >";
      expected = "&lt; Prev &amp; Next &gt;";
    };
  };
  sortTaxonomy = {
    testSortTags = {
      expr =
        lib.sortTaxonomy
          [ "metadata" "tags" ]
          [
            {
              title = "Post 1";
              metadata.tags = [
                "tech"
                "nix"
                "linux"
              ];
            }
            {
              title = "Post 2";
              metadata.tags = [
                "tech"
              ];
            }
            {
              title = "Post 3";
              metadata.tags = [
                "linux"
              ];
            }
            {
              title = "Post 4";
              metadata = { };
            }
          ];
      expected = {
        linux = [
          {
            title = "Post 1";
            metadata.tags = [
              "tech"
              "nix"
              "linux"
            ];
          }
          {
            title = "Post 3";
            metadata.tags = [
              "linux"
            ];
          }
        ];
        nix = [
          {
            title = "Post 1";
            metadata.tags = [
              "tech"
              "nix"
              "linux"
            ];
          }
        ];
        tech = [
          {
            title = "Post 1";
            metadata.tags = [
              "tech"
              "nix"
              "linux"
            ];
          }
          {
            title = "Post 2";
            metadata.tags = [
              "tech"
            ];
          }
        ];
      };
    };
  };
  groupItems =
    let
      mkItem = title: dateEpoch: series: {
        inherit title dateEpoch;
        date = "d${toString dateEpoch}";
        dateRFC822 = "r${toString dateEpoch}";
        dateW3C = "w${toString dateEpoch}";
        metadata = if series == null then { } else { inherit series; };
      };
      a3 = mkItem "A part 3" 6 [ "a" ];
      other = mkItem "Other" 5 null;
      a2 = mkItem "A part 2" 4 [ "a" ];
      lone = mkItem "Lone" 3 [ "b" ];
      a1 = mkItem "A part 1" 2 [ "a" ];
      empty = mkItem "Empty" 1 [ ];
    in
    {
      testGroupSeries = {
        expr = lib.groupItems [ "metadata" "series" ] [
          a3
          other
          a2
          lone
          a1
          empty
        ];
        expected = [
          {
            isGroup = true;
            taxonomy = "series";
            term = "a";
            title = "a";
            date = "d6";
            dateEpoch = 6;
            dateRFC822 = "r6";
            dateW3C = "w6";
            items = [
              a1
              a2
              a3
            ];
          }
          other
          lone
          empty
        ];
      };
      testNoTerms = {
        expr = lib.groupItems [ "metadata" "series" ] [
          other
          empty
        ];
        expected = [
          other
          empty
        ];
      };
    };
  paginate = {
    testPaginate = {
      expr = lib.paginate 2 [
        "Post 1"
        "Post 2"
        "Post 3"
        "Post 4"
        "Post 5"
        "Post 6"
        "Post 7"
      ];
      expected = {
        totalPages = 4;
        pages = [
          {
            pageNumber = 1;
            items = [
              "Post 1"
              "Post 2"
            ];
          }
          {
            pageNumber = 2;
            items = [
              "Post 3"
              "Post 4"
            ];
          }
          {
            pageNumber = 3;
            items = [
              "Post 5"
              "Post 6"
            ];
          }
          {
            pageNumber = 4;
            items = [ "Post 7" ];
          }
        ];
      };
    };
  };
  extractBaseURI = {
    testHTTP = {
      expr = lib.extractBaseURI "http://example.com";
      expected = "/";
    };
    testHTTPS = {
      expr = lib.extractBaseURI "https://example.com";
      expected = "/";
    };
    testWithURI = {
      expr = lib.extractBaseURI "https://example.com/blog";
      expected = "/blog/";
    };
    testWithEmptyParts = {
      expr = lib.extractBaseURI "https://example.com//blog//";
      expected = "/blog/";
    };
  };
}
