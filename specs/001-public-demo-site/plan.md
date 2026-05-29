# Implementation Plan: Public Demo Site

**Branch**: `001-public-demo-site` (retrospective) | **Date**: 2026-05-09
**Spec**: [spec.md](./spec.md)

## Summary

A single Docker image that, at build time, clones upstream Slopsmith
plus the byrongamatos plugin suite (and a curated set of community
plugins), bakes in one demo song, patches `index.html` for demo-mode
behaviour, and runs Slopsmith + GoatCounter behind nginx on port 7860
for Hugging Face Spaces.

## Technical Context

**Language/Version**: Bash + Dockerfile + a tiny inline Python
heredoc for HTML patching.
**Primary Dependencies**: Slopsmith core (cloned at build), per-plugin
Python deps, nginx, supervisord, GoatCounter v2.7.0, vgmstream-cli,
fluidsynth + GM soundfont, ffmpeg.
**Storage**: Filesystem only. `/app` is read-only at runtime;
`/config` is writable and ephemeral on HF Spaces.
**Testing**: [NEEDS CLARIFICATION: there is no test suite. Smoke
test is a manual `docker build && docker run`.]
**Target Platform**: Hugging Face Spaces (Docker SDK, free CPU tier,
port 7860). Self-hosted Docker is best-effort.
**Project Type**: Container-image build / deploy.
**Performance Goals**: First paint within 5 s on HF free tier;
build under 5 min from a warm Docker cache.
**Constraints**: No GPU, no persistent storage, no Demucs server.
**Scale/Scope**: One song, ~25+ plugins, single container.

## Constitution Check

| Principle | Where it shows up |
|---|---|
| I. Track upstream, don't fork | `git clone --depth 1 slopsmith/slopsmith` + Python heredoc patcher in `Dockerfile`. |
| II. Read-only by convention | `ENV SLOPSMITH_DEMO_MODE=1`, `window.SLOPSMITH_DEMO=true` in `overlay/static/demo.js`. |
| III. One pre-baked song, no Demucs | `dlc/SS_PonyIcon.sloppak` carries stems + `lyrics.json` + `vocal_pitch.json`. |
| IV. Plugin suite is the pitch | Two `RUN` blocks in `Dockerfile` clone byrongamatos + community plugins. |
| V. HF Spaces is the only target | `spaces.yaml`, port 7860, `nginx.conf` listening on 7860. |
| VI. Anonymous analytics only | GoatCounter behind `/goatcounter/`; `slopsmithDemoTrack(event)` in `demo.js`. |
| VII. Cache-busting is deliberate | `ADD https://api.github.com/repos/.../refs/heads/main /tmp/build_ref` line. |

No deviations.

## Project Structure

```
slopsmith-demo/
├── Dockerfile           # The bulk of the work happens here
├── start.sh             # supervisord entrypoint + /config seeding
├── nginx.conf           # 7860 → uvicorn (8000) + goatcounter (8081)
├── supervisord.conf     # goatcounter, slopsmith, nginx
├── spaces.yaml          # HF Spaces metadata (sdk: docker, port: 7860)
├── overlay/static/
│   ├── demo.js          # SLOPSMITH_DEMO flag, h3d background seed, slopsmithDemoTrack
│   └── demo.css         # banner styling
├── dlc/
│   └── SS_PonyIcon.sloppak  # the one demo song
├── nam-profiles/
│   ├── *.nam, mesa_cab.wav  # for the nam-tone plugin
└── README.md / CLAUDE.md
```

## Architecture & Data Flow

### Build time

```
Dockerfile
   │
   ├─ apt: ffmpeg, git, nginx, supervisord, fluidsynth, libsndfile1
   ├─ curl-install: goatcounter, vgmstream-cli
   ├─ ADD GitHub refs/heads/main → /tmp/build_ref   # cache-bust
   ├─ git clone slopsmith.git → /app
   ├─ git clone <plugin>.git → /app/plugins/<plugin>  (×~25)
   ├─ pip install -r /app/requirements.txt
   ├─ pip install -r /app/plugins/*/requirements.txt
   ├─ COPY overlay/static/ → /app/static/
   ├─ python heredoc: patch /app/static/index.html
   │     - inject <link demo.css>
   │     - inject <div id="demo-banner">…
   │     - inject SLOPSMITH_DEMO + demo.js BEFORE highway.js
   ├─ COPY dlc/, nam-profiles/
   ├─ curl release tarball → /app/demo-assets/highway-bg.mp4
   ├─ COPY nginx.conf, supervisord.conf
   ├─ ENV SLOPSMITH_DEMO_MODE=1, CONFIG_DIR=/config, …
   └─ CMD /start.sh
```

### Runtime

```
container start
   │
   ▼
start.sh
   ├─ mkdir -p /config /config/plugin_uploads/highway_3d
   ├─ cp -n /app/demo-assets/highway-bg.mp4 → /config/plugin_uploads/highway_3d/current.mp4
   └─ exec supervisord
         ├─ goatcounter serve  (127.0.0.1:8081)
         ├─ uvicorn server:app (0.0.0.0:8000)
         └─ nginx (0.0.0.0:7860)
                 ├─ /goatcounter/ → 127.0.0.1:8081
                 └─ /              → 127.0.0.1:8000  (with WS upgrade)
```

## Design Decisions

### Patcher uses Python, not sed

`index.html` contains `<script>`, attribute strings, and HTML
entities. A Python heredoc operating on `str.replace(..., count=1)`
fails loudly if a target moves; sed would silently produce a broken
file. See `Dockerfile` patcher block.

### `cp -n` instead of `cp -f` in `start.sh`

If a visitor uploaded a different highway background and persisted
it across a restart that left `/config` intact, we MUST NOT clobber
it. On HF Spaces `/config` is ephemeral, so `cp -n` is also a no-op
performance optimization there.

### `demo.js` is a synchronous script, not a module

`demo.js` MUST seed `localStorage.h3d_bg_style` before `highway.js`
runs. The patcher therefore inserts it as a plain `<script>` (not
`type="module"`) immediately before the `highway.js` tag.

### A `MutationObserver`-style getter on `#nav-plugins.innerHTML`

Inside `demo.js`, the property descriptor wrap on `#nav-plugins`
exists to debug a regression where something clears the plugin
dropdown. It logs the call site. [NEEDS CLARIFICATION: is the
underlying bug fixed? If yes, the wrap should come out.]

### GoatCounter co-located in same container

Simpler than wiring an external endpoint, no cross-origin issues,
and HF Spaces gives us only one container per Space anyway.

## Slopsmith Ecosystem Integration

- Demo is the public face of `slopsmith` — every behavioural change
  in upstream Slopsmith potentially affects the demo on next build.
- Demo is **deliberately not a Demucs client**. See
  `slopsmith-demucs-server/specs/001-demucs-stem-server/spec.md`
  edge-case note.
- Demo is **not** a `slopsmith-desktop` substitute. The desktop app
  is for installation; the demo is for evaluation.
- Demo does not surface `slopsmith-ignition` (the song catalog
  / "slop shop") — visitors looking for more songs go from the demo
  to the `slopsmith-desktop` install page.

## Constraints Worth Restating

- HF Spaces filesystem is ephemeral. Anything written to `/config`
  may vanish at any restart. `start.sh` re-seeds.
- HF Spaces git remote rejects binaries; demo binary assets MUST be
  fetched at build time from the GitHub release.
- Build cache is busted by `ADD <github-refs>` on every push to
  THIS repo, not on every push to upstream Slopsmith. Pushing a
  no-op commit here is the supported "rebuild against latest
  Slopsmith" command.
