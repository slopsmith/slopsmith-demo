(function () {
  if (!window.SLOPSMITH_DEMO) return;

  window.slopsmithDemoTrack = function (event) {
    if (typeof window.goatcounter === 'undefined') return;
    window.goatcounter.count({ path: event, title: event, event: true });
  };

  // Watch #nav-plugins for content changes and log a stack trace so we
  // can identify what is clearing the plugins dropdown.
  document.addEventListener('DOMContentLoaded', function () {
    var nav = document.getElementById('nav-plugins');
    if (!nav) return;
    var obs = new MutationObserver(function (mutations) {
      mutations.forEach(function (m) {
        if (m.type === 'childList') {
          console.log('[demo] nav-plugins mutation — added:', m.addedNodes.length, 'removed:', m.removedNodes.length, '\nStack:', new Error().stack);
        }
      });
    });
    obs.observe(nav, { childList: true });
  });
})();
