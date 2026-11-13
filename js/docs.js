// Scripts for the nixtml docs theme. Each feature is only set up when its
// markup is present on the page.
(function () {
  var storage = {
    get: function (key) {
      try {
        return window.localStorage.getItem(key);
      } catch (error) {
        return null;
      }
    },
    set: function (key, value) {
      try {
        window.localStorage.setItem(key, value);
      } catch (error) {
        // Storage may be unavailable, e.g. in private browsing.
      }
    },
  };

  // Color scheme switcher.
  //
  // The chosen scheme ("system", "light" or "dark") is saved in localStorage.
  // "system" follows the reader's system preference by removing `data-theme`
  // from the root element, while "light" and "dark" set it. An inline script
  // in <head> applies the saved scheme before the page is rendered.
  var setupColorScheme = function (switcher) {
    var root = document.documentElement;
    var key = switcher.dataset.storageKey;
    var fallback = switcher.dataset.default;
    var schemes = ["system", "light", "dark"];
    var button = switcher.querySelector("[data-color-scheme]");
    var icon = button.querySelector(".docs-icon");

    var load = function () {
      var scheme = storage.get(key);
      return schemes.indexOf(scheme) === -1 ? fallback : scheme;
    };

    var apply = function (scheme) {
      if (scheme === "system") {
        root.removeAttribute("data-theme");
      } else {
        root.setAttribute("data-theme", scheme);
      }

      var next = schemes[(schemes.indexOf(scheme) + 1) % schemes.length];

      button.dataset.colorScheme = scheme;
      button.setAttribute("aria-label", button.getAttribute("data-label-" + scheme));
      button.title = button.getAttribute("data-label-" + scheme);
      schemes.forEach(function (name) {
        icon.classList.toggle("is-" + name, name === next);
      });
    };

    button.addEventListener("click", function () {
      var current = schemes.indexOf(button.dataset.colorScheme);
      var scheme = schemes[(current + 1) % schemes.length];
      storage.set(key, scheme);
      apply(scheme);
    });

    // Keep other open pages of the website in sync.
    window.addEventListener("storage", function (event) {
      if (event.key === key) {
        apply(load());
      }
    });

    apply(load());
    switcher.hidden = false;
  };

  // Repository stats.
  //
  // Fetches the latest release, stars and forks of the repository from its
  // provider's API, and caches them in localStorage. Values that can't be
  // fetched are left out, keeping the plain repository link.
  var providers = {
    github: {
      release: "/releases/latest",
      stars: "stargazers_count",
      forks: "forks_count",
    },
    gitlab: {
      release: "/releases/permalink/latest",
      stars: "star_count",
      forks: "forks_count",
    },
    forgejo: {
      release: "/releases/latest",
      stars: "stars_count",
      forks: "forks_count",
    },
  };
  providers.gitea = providers.forgejo;

  var cacheDuration = 60 * 60 * 1000;

  var fetchJSON = function (url) {
    return window.fetch(url).then(function (response) {
      if (!response.ok) {
        throw new Error(response.status + " " + url);
      }
      return response.json();
    });
  };

  var fetchFacts = function (provider, api, version) {
    var repository = fetchJSON(api).then(function (info) {
      return { stars: info[provider.stars], forks: info[provider.forks] };
    });
    var release = version
      ? fetchJSON(api + provider.release).then(
          function (info) {
            return info.tag_name;
          },
          function () {
            // Repositories without releases have no version.
            return null;
          }
        )
      : Promise.resolve(null);

    return Promise.all([repository, release]).then(function (results) {
      return {
        version: results[1],
        stars: results[0].stars,
        forks: results[0].forks,
      };
    });
  };

  var setupRepository = function (link) {
    var provider = providers[link.dataset.provider];
    var api = link.dataset.api;
    var key = link.dataset.storageKey;
    var version = link.dataset.version === "true";
    var container = link.querySelector(".docs-repo-facts");
    if (!provider || !api || !container) {
      return;
    }

    var format = new Intl.NumberFormat(document.documentElement.lang || undefined, {
      notation: "compact",
      maximumFractionDigits: 1,
    });

    var render = function (facts) {
      var shown = false;
      container.querySelectorAll("[data-fact]").forEach(function (element) {
        var value = facts[element.dataset.fact];
        var known = value !== null && value !== undefined;
        if (known) {
          element.querySelector(".docs-repo-fact-value").textContent =
            typeof value === "number" ? format.format(value) : value;
          shown = true;
        }
        element.hidden = !known;
      });
      container.hidden = !shown;
    };

    var cached = null;
    try {
      cached = JSON.parse(storage.get(key));
    } catch (error) {
      cached = null;
    }

    if (cached && cached.api === api && cached.version === version) {
      render(cached.facts);
      if (Date.now() - cached.time < cacheDuration) {
        return;
      }
    }

    // Failures, such as reaching the rate limit, aren't cached, so the next
    // page view tries again.
    fetchFacts(provider, api, version).then(
      function (facts) {
        storage.set(key, JSON.stringify({ api: api, version: version, time: Date.now(), facts: facts }));
        render(facts);
      },
      function () {}
    );
  };

  document.querySelectorAll(".docs-color-scheme").forEach(setupColorScheme);
  document.querySelectorAll(".docs-repo[data-api]").forEach(setupRepository);
})();
