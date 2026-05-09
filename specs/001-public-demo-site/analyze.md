# Cross-Artifact Consistency Report

## Coverage

| Spec FR | Constitution | Plan | Tasks |
|---|---|---|---|
| FR-001 clone slopsmith at build | I | Build time / patch | T010 |
| FR-002 plugin set | IV | Build time | T011, T012 |
| FR-003 patch index.html | I, II | Design / Patcher Python | T020–T022 |
| FR-004 supervisord runs all 3 | V | Runtime | T014 |
| FR-005 nginx routing | V | Runtime | T014, T051 |
| FR-006 start.sh /config seed | V | Runtime / `cp -n` | T015, T026 |
| FR-007 ENV vars | II, V | Build / Constraints | T040, T060 |
| FR-008 no demucs runtime dep | III | Slopsmith Ecosystem note | T042 |
| FR-009 h3d_bg seeding | I | Design / synchronous script | T023 |
| FR-010 ToS plugin exclusion | IV | Constitution IV | implicit (Dockerfile comment) |

All FRs map to constitution principles, plan sections, and tasks.

## Drift

- **README "What's blocked" vs spec**: README lists "Lyrics
  alignment / pitch extraction" as blocked because the demucs server
  is absent. Spec FR-008 + Tasks T042 capture the same constraint.
  Consistent.
- **Constitution IV vs Dockerfile**: Constitution IV pins the
  byrongamatos plugin list and the exclusion list. The Dockerfile
  matches both. If a new plugin is added upstream, the Dockerfile
  list AND Constitution IV must both update.
- **Spec FR-002 vs constitution IV**: Both list the plugin set, but
  the canonical list is the Dockerfile. Risk of three-way drift —
  see Recommendations.

## Gaps

1. **Plugin clone failure is silent (T032).** A network blip during
   build lets the image ship without an advertised plugin and the
   only signal is `echo "skip $plugin"`. Should at minimum fail the
   build if any of the byrongamatos plugins fails to clone.
2. **No CI smoke test (T062).** Today the only failure detector is
   HF Spaces' own build, after which the demo is already live.
3. **Patcher fragility (T064).** Three `str.replace(..., count=1)`
   calls anchor to upstream Slopsmith strings. They will fail loudly
   on drift, but only at HF Spaces build time. Local pre-build
   smoke would catch it earlier.
4. **GoatCounter setup (T053).** First-run admin password / login
   flow is undocumented; on a fresh HF Space deployment this is
   guess-and-check.
5. **Write-path audit (T043).** Constitution II + Spec FR-008 assume
   every write path in upstream Slopsmith honours
   `SLOPSMITH_DEMO_MODE=1`. There's no checklist showing which paths
   were verified.
6. **`#nav-plugins` debug shim (T063).** Code in `demo.js` exists
   only to diagnose a past bug. If the bug is fixed, the shim is
   noise.
7. **Three places list plugins** — Dockerfile, constitution
   (Principle IV), spec FR-002 — only one is the source of truth.
   See recommendation 1.

## Recommendations

1. **Pick one canonical plugin list.** The Dockerfile is currently
   the source of truth, but a top-level `plugins.txt` consumed by
   the Dockerfile would let the constitution and spec link to it
   instead of restating it.
2. **Strict-mode build flag.** Replace `|| echo "skip $plugin"`
   with `|| exit 1` when `STRICT_BUILD=1`. Use strict in CI;
   permissive locally.
3. **CI smoke test.** GitHub Actions: build the image, run it,
   curl `/`, assert "DEMO MODE" banner appears in HTML and the
   plugin menu lists ≥ 25 entries.
4. **Document GoatCounter setup** in README — at minimum the
   `/setup` URL, the secret name in HF Spaces, and the recovery
   procedure on `/config` wipe.
5. **Audit / list write paths** in upstream Slopsmith that respect
   `SLOPSMITH_DEMO_MODE`. Pin the audit date in the constitution
   so future changes can re-audit cheaply.
6. **Remove the `#nav-plugins` MutationObserver shim** unless the
   underlying bug is still open. If still open, link the upstream
   issue from `demo.js`.
7. **Patch a comment marker** above the three `str.replace` calls
   in the Dockerfile pointing at the upstream Slopsmith file/line
   they target, so a contributor knows what to update on drift.
