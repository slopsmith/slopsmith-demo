# Feature Specification: Public Demo Site

**Feature Branch**: `001-public-demo-site` (retrospective)
**Created**: 2026-05-09
**Status**: Implemented (documented after the fact)
**Input**: A single-container, public-facing showcase of Slopsmith
running on Hugging Face Spaces with one pre-prepared song and the
full plugin suite enabled.

## User Scenarios & Testing

### User Story 1 — Curious visitor tries Slopsmith without installing (Priority: P1)

A first-time visitor opens the HF Spaces page, lands on the demo,
and within seconds can browse the song library (one entry), open it,
see the 3D highway, and play with the embedded plugins.

**Why this priority**: This is literally the only reason the demo
exists. Without it the demo has no audience.

**Independent Test**: Open `http://localhost:7860` after
`docker run`, observe the "DEMO MODE" banner, click on the bundled
song, confirm the highway renders with the bundled video backdrop,
play the song, switch arrangements.

**Acceptance Scenarios**:

1. **Given** the demo container is running, **When** a visitor opens
   port 7860, **Then** Slopsmith's standard UI is served with a
   banner reading "DEMO MODE — your edits are temporary and not
   saved" injected at the top of `<body>`.
2. **Given** the visitor opens the bundled song, **When** the highway
   loads, **Then** the 3D background defaults to the bundled
   `current.mp4` video on first visit, and the visitor's choice
   persists for subsequent visits (via `localStorage.h3d_bg_style`).
3. **Given** the visitor has not yet picked a background style,
   **When** Slopsmith reads `localStorage.h3d_bg_style`, **Then**
   `demo.js` has already seeded `'video'` synchronously *before*
   `highway.js` runs.

---

### User Story 2 — Plugin showcase (Priority: P1)

The visitor can demonstrate all of the byrongamatos plugins (and
selected community plugins) without an install step.

**Why this priority**: The plugin ecosystem is the differentiator
the demo exists to communicate.

**Independent Test**: Open the Plugins menu after the song loads.
Confirm `drums`, `editor`, `fretboard`, `lyrics_karaoke`,
`lyrics_sync`, `metronome`, `midi`, `multiplayer`, `nam_tone`,
`notedetect`, `piano`, `player_guide`, `practice`, `sectionmap`,
`setlist`, `stepmode`, `studio`, `tabimport`, `tabview`, `tones`
appear, plus community plugins listed in the Dockerfile.

**Acceptance Scenarios**:

1. **Given** the image build, **When** plugin clones run, **Then**
   each plugin lands under `/app/plugins/<name>` with hyphens
   replaced by underscores.
2. **Given** a plugin ships its own `requirements.txt`, **When** the
   image builds, **Then** those deps are pip-installed.
3. **Given** the demo is in `SLOPSMITH_DEMO_MODE=1`, **When** the
   Plugin Manager UI loads, **Then** install / update / remove
   actions are blocked.

---

### User Story 3 — Read-only by design (Priority: P2)

The demo MUST refuse all write operations (CDLC build, audio /
artwork upload, plugin install) so that visitors cannot corrupt or
escalate state inside the shared HF Spaces container.

**Why this priority**: Safety + cost — without read-only the demo
becomes an attractive nuisance.

**Independent Test**: Attempt to save / build a CDLC, attempt to
upload audio, attempt to install a plugin. All MUST surface a clear
"demo mode" rejection.

**Acceptance Scenarios**:

1. **Given** `SLOPSMITH_DEMO_MODE=1`, **When** the user clicks
   "Build CDLC", **Then** Slopsmith refuses and shows a demo
   message.
2. **Given** the user clicks "Install plugin", **Then** the action
   is rejected.
3. **Given** the user invokes a feature requiring the Demucs server
   (lyrics alignment, pitch extraction), **Then** the feature is
   either disabled or falls back to the pre-baked
   `lyrics.json` / `vocal_pitch.json` already in the bundled
   `.sloppak`.

---

### User Story 4 — Anonymous analytics (Priority: P3)

Maintainer can see how many people opened which page, without
tracking individuals.

**Independent Test**: Visit the demo, then load
`/goatcounter/` and confirm a hit was recorded with no PII.

**Acceptance Scenarios**:

1. **Given** GoatCounter runs in the same container, **When** a
   visitor opens any page, **Then** path-level analytics are recorded
   without cookies.
2. **Given** the demo wants to record a custom event, **When** code
   calls `window.slopsmithDemoTrack(name)`, **Then** GoatCounter
   records it as an event.

---

### Edge Cases

- HF Spaces tears down the container — `/config` is wiped. On next
  start, `start.sh` recreates the directory and re-seeds
  `current.mp4`.
- Slopsmith upstream changes the `<script src="/static/highway.js">`
  tag the patcher targets — the build fails loudly because the
  `str.replace(..., count=1)` produces no change. This is intended;
  failing loudly is preferable to a silently-broken demo.
- A plugin clone fails (network blip): the `|| echo "skip $plugin"`
  fallback keeps the build going. [NEEDS CLARIFICATION: should we
  fail the build instead so we never ship an incomplete demo?]
- Demo binary asset (`highway-bg.mp4`) release is missing or
  inaccessible: the build fails at the `curl -sLf` step. This is
  intended — no silent fallbacks.

## Requirements

### Functional Requirements

- **FR-001**: Image MUST clone `byrongamatos/slopsmith` at build
  time, not vendor it.
- **FR-002**: Image MUST clone the byrongamatos plugin set listed in
  the Dockerfile, plus the community plugin set, into
  `/app/plugins/<name>` (hyphens → underscores).
- **FR-003**: Build MUST patch `static/index.html` in place to
  inject `demo.css`, the `DEMO MODE` banner, and `demo.js` (along
  with `window.SLOPSMITH_DEMO = true`) before `highway.js`.
- **FR-004**: Container MUST run `goatcounter`, `nginx`, and
  `uvicorn` under `supervisord` and expose port 7860.
- **FR-005**: nginx MUST proxy `/goatcounter/` → `127.0.0.1:8081`
  and everything else → `127.0.0.1:8000`, with WebSocket upgrade
  support.
- **FR-006**: `start.sh` MUST ensure `/config` and the highway
  background directory exist on every start, and copy the bundled
  `highway-bg.mp4` only when not already present (`cp -n`).
- **FR-007**: Container env MUST set `SLOPSMITH_DEMO_MODE=1`,
  `DLC_DIR=/app/dlc`, `NAM_PROFILES_DIR=/app/nam-profiles`,
  `CONFIG_DIR=/config`, `PYTHONPATH=/app/lib:/app`.
- **FR-008**: Demo MUST NOT depend on `slopsmith-demucs-server` at
  runtime; bundled songs MUST carry their pre-baked stems / lyrics /
  pitch.
- **FR-009**: Demo MUST seed `localStorage.h3d_bg_style = 'video'`
  and `localStorage.h3d_bg_customVideoName = 'current.mp4'` once,
  before `highway.js` runs and only when those keys are unset.
- **FR-010**: ToS-violating plugins (`cf`, `ug`) and infrastructure
  plugins (`update-manager`, `rooms`, `find-more`,
  `rs-2d-highway`) MUST NOT be installed.

### Key Entities

- **Demo song**: `dlc/SS_PonyIcon.sloppak` with split stems,
  `lyrics.json`, and `vocal_pitch.json` baked in.
- **NAM profiles**: `nam-profiles/*.nam` + `mesa_cab.wav`,
  available to the NAM tone engine plugin.
- **Highway background asset**: `highway-bg.mp4` fetched from a
  GitHub release at build time; copied to
  `/config/plugin_uploads/highway_3d/current.mp4` on first start.

## Success Criteria

- **SC-001**: First page paint within 5 s of the container being
  reachable on HF Spaces free CPU tier.
- **SC-002**: Plugin menu lists ≥ 25 entries (byrongamatos +
  community).
- **SC-003**: Zero outbound network calls at runtime to anything
  except GoatCounter (no Demucs, no plugin auto-update).
- **SC-004**: Build is reproducible on `docker build .` from a
  clean checkout.

## Assumptions

- Hugging Face Spaces tier is the deployment target; behaviour on
  other Docker hosts MAY differ but should be best-effort
  identical.
- Upstream Slopsmith respects `SLOPSMITH_DEMO_MODE=1` for all
  write paths.
- Plugins listed in the Dockerfile remain compatible with whatever
  `slopsmith` HEAD looks like at build time.
- Visitors have modern browsers (the highway uses WebGL, modern
  ES, etc.).
