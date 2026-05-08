(function () {
  if (!window.SLOPSMITH_DEMO) return;

  // Seed the 3D highway plugin to default to the bundled demo video
  // backdrop on first visit. Only writes when h3d_bg_style is unset, so
  // returning visitors who picked a different style keep their pick.
  // Runs synchronously at script-load time (before highway.js) so the
  // renderer's first read sees the seeded values instead of falling
  // back to BG_DEFAULTS.style ('particles').
  try {
    if (localStorage.getItem('h3d_bg_style') === null) {
      localStorage.setItem('h3d_bg_style', 'video');
      localStorage.setItem('h3d_bg_customVideoName', 'current.mp4');
    }
  } catch (_) { /* private mode — renderer falls through to BG_DEFAULTS */ }

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
