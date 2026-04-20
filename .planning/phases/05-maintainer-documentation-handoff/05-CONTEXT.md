# Phase 5 Context: Maintainer Documentation & Handoff

## Source State

Phase 5 starts after the final Phase 4 sign-off session
`20260419-155633-5ca6b545`. The project is synced to upstream SVUnit
`v3.38.1` at peeled commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`, with
the fork qualified as `g_svunit_x / r_v3_38_1_x0_2_0`.

## Documentation Contract

The handoff should be maintainer-facing, not a broad rewrite of the public
SVUnit user guide. It must give a future maintainer a single path into:

- the final sign-off boundary: four Quartus targets, Verilator, and Vivado
  xsim, each with per-fixture and compile-once regression evidence;
- the final evidence session and reproduction command;
- the fork-delta and upstream-sync review trail;
- the future-work dimensions that are intentionally outside this stage.

README should stay concise and point at the canonical handoff page. The Sphinx
docs should carry the fuller maintainer handoff page so the repo documentation
itself satisfies `DOCS-01` and `DOCS-02`.

## Locked Decisions

- Treat `docs/source/maintainer_handoff.rst` as the durable maintainer entry
  point for this milestone.
- Update README only enough to expose that entry point and mark the Vivado xsim
  target as qualified after Phase 4.
- Do not duplicate the full sign-off matrices in README. Link to the canonical
  `.planning/phases/*/*-sign-off.md` records instead.
- Keep fast xsim reuse/cache mode as a future opt-in performance item, not as a
  qualified sign-off behavior.

## Acceptance Focus

Phase 5 is complete when:

- repository docs name the final sign-off target set and cite the Phase 4
  session;
- docs point maintainers to Phase 1 fork-delta, Phase 2 decision-ledger, and
  Phase 3/4 sign-off artifacts;
- docs list future-work dimensions without implying they block the current
  sign-off;
- `DOCS-01` and `DOCS-02` are marked complete in planning state.
