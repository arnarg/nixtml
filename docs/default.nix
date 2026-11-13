{ pkgs, ... }:
{
  imports = [
    ../themes/docs
    ./options.nix
  ];

  website = {
    name = "nixtml-docs";
    baseURL = "https://arnarg.github.io/nixtml";

    metadata = {
      lang = "en";
      title = "nixtml";
      description = "nixtml documentation";
    };

    content.dir = ./content;

    content.processors.md = {
      settings.toc = {
        permalink = "#";
        permalinkClass = "headerlink mx-2";
      };
      extraPythonPackages = [
        # Add pygments-styles: https://pygments-styles.org/
        (
          let
            pname = "pygments-styles";
            version = "0.3.0";
          in
          pkgs.python3Packages.buildPythonPackage {
            inherit pname version;
            pyproject = true;

            src = pkgs.fetchFromGitHub {
              owner = "lepture";
              repo = pname;
              rev = version;
              sha256 = "sha256-3tVbeoDCDwHczst9Z22iVBzXfCDoAPjHBYBFzt+CXDY=";
            };

            build-system = with pkgs.python3Packages; [
              setuptools
              setuptools-scm
            ];

            dependencies = with pkgs.python3Packages; [
              setuptools
              pygments
            ];
          }
        )
      ];
    };
  };

  themes.docs = {
    logo.source = ../logo.svg;

    repository.url = "https://github.com/arnarg/nixtml";

    navigation.sections = [
      {
        id = "guides";
        title = "Guides";
        pager = true;
      }
      {
        id = "themes";
        title = "Themes";
      }
      {
        id = "reference";
        title = "Reference";
      }
    ];

    codeStyles = {
      light = "catppuccin-latte";
      dark = "catppuccin-mocha";
    };

    pager = {
      previousLabel = "Previous guide";
      nextLabel = "Next guide";
    };

    editLink.baseURL = "https://github.com/arnarg/nixtml/edit/main/docs/content/";

    footer = ''This website is (obviously) generated with <a href="https://github.com/arnarg/nixtml">nixtml.</a>'';
  };
}
