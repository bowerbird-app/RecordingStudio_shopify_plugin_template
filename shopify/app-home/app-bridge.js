(function () {
  var hostBase = window.HOST_BASE_URL || "";
  var params = new URLSearchParams(window.location.search);
  var shop = params.get("shop") || "";
  var pluginSettingsPath = "/plugin_settings";
  var iframe = document.getElementById("rs-connect");

  function pluginSettingsUrl(sessionToken) {
    var url = new URL(pluginSettingsPath, hostBase || window.location.origin);
    if (shop) url.searchParams.set("shop", shop);
    if (sessionToken) url.searchParams.set("shopify_session_token", sessionToken);
    return url.toString();
  }

  iframe.src = pluginSettingsUrl(null);

  if (window.shopify && typeof window.shopify.idToken === "function") {
    window.shopify.idToken().then(function (token) {
      iframe.src = pluginSettingsUrl(token);
    }).catch(function () {
      iframe.src = pluginSettingsUrl(null);
    });
  }
})();
