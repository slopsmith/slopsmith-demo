# Slopsmith Demo Constitution

## Core Principles

### I. Track Upstream, Don't Fork

The demo MUST clone `byrongamatos/slopsmith` fresh at every build and
patch `index.html` *in-place* via a Python heredoc in the Dockerfile.
There is no overlay `index.html`. This is non-negotiable: forking
would bit-rot the demo within days and is the entire reason this
repo is one Dockerfile and not a vendored copy of Slopsmith.

### II. Read-Only by Convention, Not by Surgery

The demo flips behaviour with `window.SLOPSMITH_DEMO = true` (set in
`overlay/static/demo.js`) and the `SLOPSMITH_DEMO_MODE=1` env var,
both of which the upstream Slopsmith already understands. We MUST
NOT carry patches against Slopsmith source; if a write path is not
yet gated by `SLOPSMITH_DEMO_MODE`, fix it in upstream Slopsmith,
not here.

### III. One Pre-Baked Song, No Demucs

The demo ships exactly one `.sloppak` (`dlc/SS_PonyIcon.sloppak`)
that already contains split stems, `lyrics.json`, and
`vocal_pitch.json`. We MUST NOT depend on `slopsmith-demucs-server`
at runtime — the free Hugging Face CPU tier cannot run those models,
and we do not want to ship a public demo that hits a private GPU.

### IV. Plugin Suite Is the Pitch

Every public byrongamatos plugin (drums, editor, fretboard,
lyrics-karaoke, lyrics-sync, metronome, midi, multiplayer, nam-tone,
notedetect, piano, player-guide, practice, sectionmap, setlist,
stepmode, studio, tabimport, tabview, tones) plus the listed
community plugins MUST be installed in the demo image. The whole
point of the demo is "look at all this." Plugins that violate ToS
(`cf`, `ug`) or require server-side mutation (`update-manager`,
`rooms`, `find-more`) are explicitly excluded.

### V. Hugging Face Spaces Is the Only Target

The Dockerfile, the `spaces.yaml`, and the supervisord layout are
shaped for HF Spaces' free Docker SDK tier (port 7860, ephemeral
filesystem under `/config`, no GPU, no persistent storage). New
infrastructure choices MUST keep working there before they land,
even if they happen to also work on a self-hosted Docker.

### VI. Anonymous Analytics Only

GoatCounter at `/goatcounter/` MAY collect path-level counts. No
cookies, no IP logging beyond what GoatCounter does by default, no
third-party trackers. Demo-event tracking goes through
`window.slopsmithDemoTrack(event)` in `overlay/static/demo.js`.

### VII. Cache-Busting Is Deliberate

The line
`ADD https://api.github.com/repos/byrongamatos/slopsmith-demo/git/refs/heads/main /tmp/build_ref`
in the Dockerfile is load-bearing. It ensures every push to
`slopsmith-demo` busts the Docker layer cache so subsequent
`git clone slopsmith.git` layers run fresh. Don't move it; don't
"optimise" it.

## Operational Constraints

- Base image: `python:3.12-slim`.
- Process supervision: `supervisord` running `goatcounter`, `nginx`,
  `uvicorn server:app --host 0.0.0.0 --port 8000`.
- Public port: 7860 (HF Spaces convention). Internal: 8000 (Slopsmith),
  8081 (GoatCounter), 7860 (nginx fronting).
- `/config` is writable, ephemeral. `/app` is read-only at runtime.
- Demo binary assets (`highway-bg.mp4`) are fetched from a GitHub
  release at build time, NOT committed to the repo (HF Spaces' git
  remote rejects binaries).

## Development Workflow

- Iterate against the live demo by `docker build && docker run -p
  7860:7860`.
- Plugin behaviour changes belong in upstream plugin repos, not here.
- Slopsmith index.html changes belong in upstream Slopsmith, not in
  the in-place patcher (extend the patcher only when upstream cannot
  express the demo behaviour).
- The pre-baked `SS_PonyIcon.sloppak` is the canonical demo song;
  swap it by dropping a new `.sloppak` into `dlc/` before building.

## Governance

This repo is one of several in the Slopsmith ecosystem
(`slopsmith` core, `slopsmith-desktop`, `slopsmith-demucs-server`,
`slopsmith-ignition`, plus per-feature plugin repos). The demo is
the public showcase. Anything that breaks the demo on HF Spaces
free tier blocks releases of upstream Slopsmith. Constitution
amendments require a working demo build on top of `slopsmith`
`main` before merge.

**Version**: 1.0.0 | **Ratified**: 2026-05-09 | **Last Amended**: 2026-05-09
