// Color scheme switcher for the nixtml docs theme.
//
// The chosen scheme ("system", "light" or "dark") is saved in localStorage.
// "system" follows the reader's system preference by removing `data-theme`
// from the root element, while "light" and "dark" set it. An inline script
// in <head> applies the saved scheme before the page is rendered.
(function () {
  var root = document.documentElement;
  var switchers = document.querySelectorAll(".docs-color-scheme");
  if (switchers.length === 0) {
    return;
  }

  var key = switchers[0].dataset.storageKey;
  var fallback = switchers[0].dataset.default;
  var schemes = ["system", "light", "dark"];

  var load = function () {
    try {
      var scheme = window.localStorage.getItem(key);
      return schemes.indexOf(scheme) === -1 ? fallback : scheme;
    } catch (error) {
      return fallback;
    }
  };

  var save = function (scheme) {
    try {
      window.localStorage.setItem(key, scheme);
    } catch (error) {
      // Storage may be unavailable, e.g. in private browsing.
    }
  };

  var apply = function (scheme) {
    if (scheme === "system") {
      root.removeAttribute("data-theme");
    } else {
      root.setAttribute("data-theme", scheme);
    }

    document.querySelectorAll("[data-color-scheme]").forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.dataset.colorScheme === scheme));
    });
  };

  document.querySelectorAll("[data-color-scheme]").forEach(function (button) {
    button.addEventListener("click", function () {
      var scheme = button.dataset.colorScheme;
      save(scheme);
      apply(scheme);
    });
  });

  // Keep other open pages of the website in sync.
  window.addEventListener("storage", function (event) {
    if (event.key === key) {
      apply(load());
    }
  });

  apply(load());

  switchers.forEach(function (switcher) {
    switcher.hidden = false;
  });
})();
