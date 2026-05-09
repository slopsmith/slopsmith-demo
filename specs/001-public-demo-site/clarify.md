# Clarifications: Public Demo Site

### Q: Why patch `index.html` at build time instead of shipping our own?

**A:** Constitution Principle I — track upstream, don't fork. Slopsmith
ships index.html updates frequently (new plugins, new menus). Forking
would silently bit-rot the demo. The patcher is intentionally narrow
(three `str.replace(...)` operations) and fails loudly if the targets
move.

### Q: Why is `cf` (CustomsForge) plugin excluded?

**A:** Terms of Service. Same reason `ug` (Ultimate Guitar) is
excluded. Listed explicitly in the Dockerfile comment so future
maintainers don't re-add them.

### Q: Why is `update-manager` excluded?

**A:** It would let the visitor mutate the container (install plugins
into a shared `/app`). Read-only constitution principle.

### Q: Why bundle one specific song (`SS_PonyIcon.sloppak`)?

**A:** It is licensed for redistribution by the SnowShovel project
and ships with high-quality stems, lyrics, and pitch already
extracted, which means no Demucs server is needed at runtime
(Constitution Principle III).

### Q: How does the demo handle a plugin clone failing during build?

**A:** [OPEN] — currently `|| echo "skip $plugin"` keeps the build
going. This may produce a demo missing an advertised plugin without
warning. A stricter policy ("hard-fail") would be safer.

### Q: Why fetch `highway-bg.mp4` from a release instead of committing
it?

**A:** The HF Spaces git remote rejects binaries. The release tarball
is the canonical out-of-band binary store.

### Q: Where does `SLOPSMITH_DEMO_MODE` actually take effect?

**A:** Inside upstream Slopsmith. This repo only sets the env var and
the JS flag. The list of write paths gated by that flag lives in the
`slopsmith` repo, not here. If a write path leaks into the demo,
the fix is upstream.

### Q: How is GoatCounter authenticated for admin access?

**A:** [OPEN] — first-run setup of GoatCounter on HF Spaces' ephemeral
filesystem is not documented in this repo. Likely a one-time
`/setup` flow against the deployed instance, with the admin password
stored in HF Spaces secrets. Worth adding to the README.

### Q: What is the upgrade path when Slopsmith ships a breaking change
the patcher relies on?

**A:** Patcher fails the build at `str.replace(..., count=1)` because
the substitution count drops to zero. Maintainer updates the patcher
strings. There is no automated regression detection beyond
build failure.

### Q: Can the demo run on a self-hosted Docker?

**A:** Yes — `docker build && docker run -p 7860:7860` per README.
HF Spaces specifics (port 7860, `spaces.yaml`) are no-ops elsewhere.
