---
title: Slopsmith Demo
emoji: 🎸
colorFrom: indigo
colorTo: purple
sdk: docker
app_port: 7860
pinned: false
---

# Slopsmith Demo

Public demo of [Slopsmith](https://github.com/slopsmith/slopsmith) — a web app for browsing, playing, and editing Rocksmith 2014 CDLC.

Hosted on [Hugging Face Spaces](https://huggingface.co/spaces/gamatos/slopsmith-demo) (free CPU tier).

## What works

- Full plugin suite (editor, NAM tone engine, karaoke playback, drums, piano, and more)
- One pre-prepared demo song with stems, lyrics, and vocal pitch data already built in
- Read-only — edits are session-local and not persisted to disk

## What's blocked

| Action | Why |
|---|---|
| Save / build CDLC | Read-only demo |
| Upload audio / art | Read-only demo |
| Install / update plugins | Prevents arbitrary git clones |
| Lyrics alignment / pitch extraction | Requires demucs server not present in demo |

## Local build

```bash
docker build -t slopsmith-demo .
docker run --rm -p 7860:7860 slopsmith-demo
```

Open `http://localhost:7860`.

## Analytics

[GoatCounter](https://www.goatcounter.com/) runs in the same container at `/goatcounter/`. No cookies, no personal data.

## Adding the demo song

Drop a pre-prepared `.sloppak` into `dlc/` before building the image. The sloppak should already contain split stems, `lyrics.json`, and `vocal_pitch.json` so no demucs server is needed at runtime.
