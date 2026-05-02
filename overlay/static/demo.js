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
    var desc = Object.getOwnPropertyDescriptor(Element.prototype, 'innerHTML');
    Object.defineProperty(nav, 'innerHTML', {
      get: function () { return desc.get.call(this); },
      set: function (v) {
        console.log('[demo] nav-plugins innerHTML set — new length:', v.length, '\n' + new Error().stack);
        desc.set.call(this, v);
      }
    });
  });
})();
