{ lib, config, ... }:
let
  inherit (lib.tags) a span;
  inherit (lib) attrs;

  cfg = config.themes.docs.repository;

  # Splits the repository URL into its scheme, host and path.
  parsed =
    let
      match = lib.match "(https?)://([^/]+)/(.+)" cfg.url;
      path = lib.pipe (lib.elemAt match 2) [
        (lib.removeSuffix "/")
        (lib.removeSuffix ".git")
      ];
    in
    if match == null then
      throw "`themes.docs.repository.url` must be an http(s) URL to a repository, got '${cfg.url}'."
    else
      {
        scheme = lib.elemAt match 0;
        host = lib.elemAt match 1;
        inherit path;
        segments = lib.splitString "/" path;
      };

  detectedProvider =
    if parsed.host == "github.com" then
      "github"
    else if lib.hasInfix "gitlab" parsed.host then
      "gitlab"
    else if parsed.host == "codeberg.org" then
      "forgejo"
    else if parsed.host == "gitea.com" then
      "gitea"
    else
      throw "Can't detect the provider of '${cfg.url}'. Set `themes.docs.repository.provider` to one of github, gitlab, forgejo or gitea.";

  provider = if cfg.provider != null then cfg.provider else detectedProvider;

  # Owner and name of the repository, for providers that don't support
  # nested groups.
  ownerAndRepo =
    if lib.length parsed.segments < 2 then
      throw "`themes.docs.repository.url` must point to a repository, e.g. https://${parsed.host}/<owner>/<repo>, got '${cfg.url}'."
    else
      "${lib.elemAt parsed.segments 0}/${lib.elemAt parsed.segments 1}";

  base = "${parsed.scheme}://${parsed.host}";

  apiURL =
    {
      github =
        if parsed.host == "github.com" then
          "https://api.github.com/repos/${ownerAndRepo}"
        else
          "${base}/api/v3/repos/${ownerAndRepo}";
      gitlab = "${base}/api/v4/projects/${lib.replaceStrings [ "/" ] [ "%2F" ] parsed.path}";
      forgejo = "${base}/api/v1/repos/${ownerAndRepo}";
      gitea = "${base}/api/v1/repos/${ownerAndRepo}";
    }
    .${provider};

  fact =
    name:
    span
      [
        (attrs.class "docs-repo-fact")
        (attrs.data "fact" name)
        (lib.mkAttr "hidden" "")
      ]
      [
        (span
          [
            (attrs.classes [
              "docs-icon"
              "is-${name}"
            ])
            (attrs.aria "hidden" "true")
          ]
          [ ]
        )
        (span [ (attrs.class "docs-visually-hidden") ] [ cfg.stats.labels.${name} ])
        (span [ (attrs.class "docs-repo-fact-value") ] [ ])
      ];
in
{
  options.themes.docs.repository = with lib; {
    url = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "https://github.com/arnarg/nixtml";
      description = ''
        URL of the project's repository, displayed as a link in the top of every page. When `null`, no repository link is displayed.
      '';
    };

    provider = mkOption {
      type =
        with types;
        nullOr (enum [
          "github"
          "gitlab"
          "forgejo"
          "gitea"
        ]);
      default = null;
      description = ''
        Provider hosting the repository, used for its icon and for fetching stats.

        When `null`, it's detected from the host of `url`: `github.com`, hosts containing `gitlab`, `codeberg.org` (Forgejo) and `gitea.com`. Other hosts, such as
        self-hosted Forgejo or GitHub Enterprise instances, need it set.
      '';
    };

    name = mkOption {
      type = types.str;
      default = parsed.path;
      defaultText = literalMD "The path of `url`, e.g. `arnarg/nixtml`.";
      description = "Name displayed in the repository link.";
    };

    stats = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to display the repository's latest release, stars and forks.

          The stats are fetched from the provider's API by the reader's browser, and cached in their browser for an hour. Values that can't be fetched
          are left out. This requires the provider's API to allow cross-origin requests, which self-hosted Forgejo and Gitea instances don't by default.
        '';
      };

      version = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to display the tag of the latest release. Repositories without releases don't display a version.
        '';
      };

      storageKey = mkOption {
        type = types.str;
        default = "${config.website.name}-repository";
        defaultText = literalExpression ''"''${config.website.name}-repository"'';
        description = "Key of the `localStorage` item caching the stats.";
      };

      labels = {
        version = mkOption {
          type = types.str;
          default = "Latest release";
          description = "Accessible label of the latest release.";
        };
        stars = mkOption {
          type = types.str;
          default = "Stars";
          description = "Accessible label of the number of stars.";
        };
        forks = mkOption {
          type = types.str;
          default = "Forks";
          description = "Accessible label of the number of forks.";
        };
      };
    };
  };

  config.website.layouts.partials.docsRepository = lib.mkDefault (
    _:
    lib.optionalString (cfg.url != null) (
      a
        (
          [
            (attrs.classes [
              "docs-repo"
              "button"
              "is-small"
            ])
            (attrs.href cfg.url)
          ]
          ++ lib.optionals cfg.stats.enable [
            (attrs.data "provider" provider)
            (attrs.data "api" apiURL)
            (attrs.data "storage-key" cfg.stats.storageKey)
            (attrs.data "version" (lib.boolToString cfg.stats.version))
          ]
        )
        (
          [
            (span
              [
                (attrs.classes [
                  "docs-icon"
                  "is-${provider}"
                ])
                (attrs.aria "hidden" "true")
              ]
              [ ]
            )
            (span [ (attrs.class "docs-repo-name") ] [ cfg.name ])
          ]
          ++ lib.optional cfg.stats.enable (
            span
              [
                (attrs.class "docs-repo-facts")
                (lib.mkAttr "hidden" "")
              ]
              (
                lib.optional cfg.stats.version (fact "version")
                ++ [
                  (fact "stars")
                  (fact "forks")
                ]
              )
          )
        )
    )
  );
}
