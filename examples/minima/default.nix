{
  imports = [ ../../themes/minima ];

  website = {
    name = "example-minima";
    baseURL = "https://example.com";

    metadata = {
      lang = "en";
      title = "nixtml + Minima";
      description = "A proof-of-concept Minima theme for nixtml";
      author = "nixtml contributors";
      email = "hello@example.com";
    };

    content.dir = ./content;

    collections.blog = {
      path = "posts";
      pagination.perPage = 2;
      taxonomies = [ "tags" ];

      rss = {
        enable = true;
        limit = 50;
      };
    };
  };

  themes.minima = {
    feedPath = "index.xml";
    showExcerpts = true;

    navigation = [
      {
        title = "About";
        path = "about/";
      }
    ];

    socialLinks = [
      {
        platform = "github";
        username = "arnarg/nixtml";
        url = "https://github.com/arnarg/nixtml";
      }
    ];
  };
}
