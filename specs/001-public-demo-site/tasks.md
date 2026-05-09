# Tasks: Public Demo Site

**Input**: Retrospective documentation of the existing implementation.
**Organization**: Tasks grouped by user story. **DONE** = present in
the repo; **OPEN** = real gap.

## Phase 1: Setup

- [x] **DONE** T001 `python:3.12-slim` base + apt deps
  (`ffmpeg`, `git`, `nginx`, `supervisor`, `fluidsynth`,
  `fluid-soundfont-gm`, `libsndfile1`) — `Dockerfile`
- [x] **DONE** T002 GoatCounter v2.7.0 install — `Dockerfile`
- [x] **DONE** T003 vgmstream-cli install — `Dockerfile`
- [x] **DONE** T004 Cache-bust line
  `ADD https://api.github.com/.../refs/heads/main /tmp/build_ref`
  — `Dockerfile`

## Phase 2: Foundational

- [x] **DONE** T010 Clone `byrongamatos/slopsmith` into `/app` —
  `Dockerfile`
- [x] **DONE** T011 [P] Clone byrongamatos plugins (drums, editor,
  fretboard, lyrics-karaoke, lyrics-sync, metronome, midi,
  multiplayer, nam-tone, notedetect, piano, player-guide, practice,
  sectionmap, setlist, stepmode, studio, tabimport, tabview, tones)
  with hyphen→underscore rename — `Dockerfile`
- [x] **DONE** T012 [P] Clone community plugins (transpose-chords,
  invert-highway, the-daily, themes, stem-mixer, jumpingtab,
  guitar-theory, splitscreen, stems) — `Dockerfile`
- [x] **DONE** T013 pip install Slopsmith requirements + per-plugin
  requirements — `Dockerfile`
- [x] **DONE** T014 supervisord + nginx config — `supervisord.conf`,
  `nginx.conf`
- [x] **DONE** T015 `start.sh` entrypoint with `/config` seeding —
  `start.sh`

## Phase 3: User Story 1 — First-time visitor (P1)

- [x] **DONE** T020 Patch `static/index.html` to inject `demo.css`
  in `<head>` — `Dockerfile` heredoc
- [x] **DONE** T021 Patch to inject `<div id="demo-banner">` after
  `<body>` — `Dockerfile` heredoc
- [x] **DONE** T022 Patch to inject `SLOPSMITH_DEMO=true` and
  `demo.js` BEFORE `highway.js` — `Dockerfile` heredoc
- [x] **DONE** T023 [P] `overlay/static/demo.js` synchronous
  `localStorage.h3d_bg_style = 'video'` seeding — `demo.js`
- [x] **DONE** T024 [P] `overlay/static/demo.css` banner styling —
  `demo.css`
- [x] **DONE** T025 Bundled highway-bg.mp4 fetched from GitHub
  release at build time — `Dockerfile`
- [x] **DONE** T026 `cp -n` of highway-bg.mp4 into
  `/config/plugin_uploads/highway_3d/current.mp4` on start —
  `start.sh`

**Checkpoint**: First-time visitor MVP ships.

## Phase 4: User Story 2 — Plugin showcase (P1)

- [x] **DONE** T030 Plugin set installed (T011, T012)
- [x] **DONE** T031 Hyphen→underscore plugin dir naming
  (`${plugin//-/_}`) — `Dockerfile`
- [ ] **OPEN** T032 [P] Build-time assertion that every advertised
  plugin actually cloned. Today
  `|| echo "skip $plugin"` masks failures.
- [ ] **OPEN** T033 [P] Document the plugin set in this repo's
  README so the list isn't only in the Dockerfile.

**Checkpoint**: Plugin showcase ships.

## Phase 5: User Story 3 — Read-only by design (P2)

- [x] **DONE** T040 `ENV SLOPSMITH_DEMO_MODE=1` — `Dockerfile`
- [x] **DONE** T041 `window.SLOPSMITH_DEMO=true` injected before
  `highway.js` — `Dockerfile`
- [x] **DONE** T042 Bundled `.sloppak` carries pre-baked stems,
  lyrics, pitch (no Demucs at runtime) — `dlc/SS_PonyIcon.sloppak`
- [ ] **OPEN** T043 Audit upstream Slopsmith for write paths NOT yet
  gated by `SLOPSMITH_DEMO_MODE`. Spec FR-008 / Constitution III
  depend on completeness here.

**Checkpoint**: Read-only ships, modulo any unaudited write paths.

## Phase 6: User Story 4 — Anonymous analytics (P3)

- [x] **DONE** T050 GoatCounter program in supervisord —
  `supervisord.conf`
- [x] **DONE** T051 nginx route `/goatcounter/` → `127.0.0.1:8081`
  — `nginx.conf`
- [x] **DONE** T052 [P] `slopsmithDemoTrack(event)` JS shim —
  `demo.js`
- [ ] **OPEN** T053 GoatCounter first-run admin setup procedure
  documented in README (currently undocumented — see clarify.md).

## Phase 7: Cross-cutting / Polish

- [x] **DONE** T060 Env vars (`DLC_DIR`, `NAM_PROFILES_DIR`,
  `CONFIG_DIR`, `PYTHONPATH`) — `Dockerfile`
- [x] **DONE** T061 NAM profiles bundled — `nam-profiles/`
- [ ] **OPEN** T062 Smoke-test job in CI that builds the image and
  hits `/health`. Today the only signal is HF Spaces' own build
  status.
- [ ] **OPEN** T063 Remove the `#nav-plugins` `MutationObserver`
  debug shim in `demo.js` once the underlying bug is confirmed
  fixed.
- [ ] **OPEN** T064 Spec-driven test of the index.html patcher: an
  upstream change to the `<script src="/static/highway.js">` tag
  should be detected before it lands in production.

## Parallel-Safe Sets

- T011 and T012 are independent; safe to reorder.
- T023, T024, T052 (in `demo.js` / `demo.css`) are independent of
  the Dockerfile patcher work.
