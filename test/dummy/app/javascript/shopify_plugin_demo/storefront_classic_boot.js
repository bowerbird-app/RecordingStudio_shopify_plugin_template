(function () {
  function tooltipNode(root) {
    return root.querySelector('[data-flat-pack--tooltip-target="tooltip"]');
  }

  function placeTooltip(trigger, tooltip) {
    tooltip.style.position = "fixed";
    tooltip.style.zIndex = "2147483646";
    var spacing = 8;
    var triggerRect = trigger.getBoundingClientRect();
    var tooltipRect = tooltip.getBoundingClientRect();
    var top = triggerRect.top - tooltipRect.height - spacing;
    if (top < 8) top = triggerRect.bottom + spacing;
    var left = triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2;
    if (left < 8) left = 8;
    if (left + tooltipRect.width > window.innerWidth - 8) {
      left = window.innerWidth - tooltipRect.width - 8;
    }
    tooltip.style.top = top + "px";
    tooltip.style.left = left + "px";
    tooltip.style.opacity = "1";
    tooltip.style.transform = "none";
  }

  function bindTooltip(el) {
    if (el.dataset.shopifyPluginDemoBound === "tooltip") return;
    var tip = tooltipNode(el);
    if (!tip) return;
    el.dataset.shopifyPluginDemoBound = "tooltip";

    function show() {
      tip.classList.remove("hidden");
      tip.style.transition = "none";
      tip.style.opacity = "0";
      placeTooltip(el, tip);
      tip.offsetHeight;
      tip.style.opacity = "1";
    }

    function hide() {
      tip.classList.add("hidden");
      tip.style.opacity = "0";
    }

    el.addEventListener("mouseenter", show);
    el.addEventListener("mouseleave", hide);
    el.addEventListener("focusin", show);
    el.addEventListener("focusout", hide);
  }

  function carouselSlides(el) {
    return Array.prototype.slice.call(
      el.querySelectorAll('[data-flat-pack--carousel-target="slide"]')
    );
  }

  function carouselFrame(el) {
    return el.querySelector('[data-flat-pack--carousel-target="frame"]');
  }

  function showCarouselIndex(el, index) {
    var slides = carouselSlides(el);
    if (!slides.length) return;
    var next = ((index % slides.length) + slides.length) % slides.length;
    el.dataset.shopifyPluginDemoIndex = String(next);
    var frame = carouselFrame(el);
    if (frame) {
      frame.style.transform = "translate3d(-" + next * 100 + "%, 0, 0)";
    }
    slides.forEach(function (slide, i) {
      slide.setAttribute("aria-hidden", i === next ? "false" : "true");
    });
    el.querySelectorAll('[data-flat-pack--carousel-target="indicator"]').forEach(function (indicator, i) {
      indicator.setAttribute("aria-current", i === next ? "true" : "false");
    });
  }

  function bindCarousel(el) {
    if (el.dataset.shopifyPluginDemoBound === "carousel") return;
    el.dataset.shopifyPluginDemoBound = "carousel";
    showCarouselIndex(el, 0);
    el.addEventListener("click", function (event) {
      var button = event.target.closest("[data-action]");
      if (!button || !el.contains(button)) return;
      var action = button.getAttribute("data-action") || "";
      var index = parseInt(el.dataset.shopifyPluginDemoIndex || "0", 10);
      if (action.indexOf("flat-pack--carousel#next") !== -1) {
        event.preventDefault();
        showCarouselIndex(el, index + 1);
      } else if (action.indexOf("flat-pack--carousel#prev") !== -1) {
        event.preventDefault();
        showCarouselIndex(el, index - 1);
      }
    });
  }

  function boot(root) {
    var scope = root || document;
    scope.querySelectorAll('[data-controller~="flat-pack--tooltip"]').forEach(bindTooltip);
    scope.querySelectorAll('[data-controller~="flat-pack--carousel"]').forEach(bindCarousel);
  }

  boot(document);
  if (typeof MutationObserver === "function") {
    new MutationObserver(function () {
      boot(document);
    }).observe(document.documentElement, { childList: true, subtree: true });
  }
})();
