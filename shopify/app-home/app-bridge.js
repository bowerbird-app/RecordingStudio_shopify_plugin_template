(function () {
  var hostBase = window.HOST_BASE_URL || "";
  var params = new URLSearchParams(window.location.search);
  var shop = params.get("shop") || "";
  var connectPath = "/shopify_plugin_demo/connect";
  var iframe = document.getElementById("rs-connect");

  function connectUrl(sessionToken) {
    var url = new URL(connectPath, hostBase || window.location.origin);
    if (shop) url.searchParams.set("shop", shop);
    if (sessionToken) url.searchParams.set("shopify_session_token", sessionToken);
    return url.toString();
  }

  iframe.src = connectUrl(null);

  if (window.shopify && typeof window.shopify.idToken === "function") {
    window.shopify.idToken().then(function (token) {
      iframe.src = connectUrl(token);
    }).catch(function () {
      iframe.src = connectUrl(null);
    });
  }
})();
