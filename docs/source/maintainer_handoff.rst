Maintainer Handoff
==================

This fork is synced to upstream SVUnit ``v3.38.1`` at commit
``8e70653e2cbfe3ebe154a863a46bf482ded4bc19``. The fork version qualified in
this repository is ``3.38.1-x0.3.0`` under the SLL tool identity
``g_svunit_x / r_v3_38_1_x0_3_0``. Version ``x0.3.0`` supersedes ``x0.2.0``
by adding four opt-in runtime extensions (``--reuse-build``,
``--sim-debug-level``, ``--sim-runtime-stats``, ``--xsim-run-mode``); the
default deterministic sign-off path is unchanged.

Sign-off Boundary
-----------------

The current sign-off boundary is the complete certify target set registered in
``nix/registry.nix``:

.. list-table::
   :header-rows: 1

   * - Target
     - Coverage
   * - ``quartus-23-4-qrun``
     - Quartus Pro 23.4.0.79 / Questa FPGA Edition 2023.3, qrun path
   * - ``quartus-23-4-modelsim``
     - Quartus Pro 23.4.0.79 / Questa FPGA Edition 2023.3, modelsim path
   * - ``quartus-25-1-sim-only-qrun``
     - Quartus Pro 25.1.1.125 sim-only / Questa FPGA Edition 2025.1, qrun path
   * - ``quartus-25-1-sim-only-modelsim``
     - Quartus Pro 25.1.1.125 sim-only / Questa FPGA Edition 2025.1, modelsim path
   * - ``verilator-5-044``
     - Verilator 5.044 native path
   * - ``vivado-2025-2-1-synth-sim-full-xsim``
     - Vivado 2025.2.1 ``synth-sim-full`` through ``buildFHSEnv`` wrappers, xsim path

The current ``x0.3.0`` two-mode, six-target sign-off session is recorded in
``.planning/sign-off-v3.38.1-x0.3.0.md`` (session stamp captured there after
the fresh certify run). Each target runs the existing per-fixture regression
and the compile-once multi-fixture regression. The prior ``x0.2.0`` session
``20260419-155633-5ca6b545`` remains archived at:

* ``.planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off.md``
* ``.planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off-manifest.tsv``
* ``.planning/phases/04-xilinx-vivado-xsim-integration/04-performance-summary.tsv``

The current flake inputs for the promoted external toolchains are pinned to
pushed qualified SSH repositories:

* ``quartus-podman-25-1``:
  ``1fe7d0c5ff46c62e130accaabc3377187afb4271``
* ``xilinx-vivado``:
  ``83072bfe622493a11eb713afd01ba952412ee7f3``

Reproduce the final evidence manifest from the stored artefacts with:

.. code-block:: shell

   bash .planning/phases/04-xilinx-vivado-xsim-integration/04-reproduce.sh --reuse-session 20260419-155633-5ca6b545

Run a fresh current-state sign-off with:

.. code-block:: shell

   nix run .#svunit-certify-all

Review Trail
------------

Use these files as the entry points when auditing this catch-up round:

* ``.planning/phases/01-fork-delta-baseline-intent-record/01-upstream-baseline.json`` records the upstream tag object, peeled target commit, and derived merge-base.
* ``.planning/phases/01-fork-delta-baseline-intent-record/01-fork-delta-matrix.md`` classifies fork-only changes as ``keep``, ``superseded``, ``rewrite``, or ``human-review``.
* ``.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md`` preserves ancestry and Xilinx/Vivado questions that required maintainer awareness.
* ``.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md`` records each non-trivial merge decision and its rationale.
* ``.planning/phases/02-history-aware-upstream-integration/02-integration-summary.md`` gives the short maintainer-facing account of what was kept, replaced, or superseded.
* ``.planning/phases/03-quartus-verification-sign-off/03-sign-off.md`` records the original Quartus/Verilator sign-off and gap matrix.
* ``.planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off.md`` records the promoted Vivado xsim sign-off and final six-target boundary.

Future Work
-----------

The current milestone intentionally does not claim these dimensions:

* Device-family synthesis coverage for Agilex, Stratix, Arria, or other FPGA families.
* Quartus UVM tests gated by an unavailable ``svverification`` license.
* A Vivado container target. The current Vivado target is native
  ``buildFHSEnv``; add a separate target when the Xilinx flake exposes a
  container image.
* Flake input drift. Quartus 25.1 and Vivado are pinned through
  ``git+ssh://`` qualified repositories in ``flake.lock``; any revision move is
  a new sign-off event.
* Quartus UVM tests gated by an unavailable ``svverification`` license.
  (The ``--sim-debug-level`` / ``--sim-runtime-stats`` / ``--xsim-run-mode`` /
  ``--reuse-build`` switches added in ``x0.3.0`` are opt-in developer
  conveniences; the deterministic sign-off path still runs without them.)

Future Upstream Catch-up
------------------------

For the next upstream tag, repeat the same control flow rather than rebasing
blindly:

#. Pin the exact upstream tag object, peeled commit, and merge-base.
#. Rebuild the fork-delta matrix from git history and preserve all
   Xilinx/Vivado intent rows.
#. Resolve overlaps through a decision ledger tied to the intent record.
#. Re-run the complete certify target set and cite explicit session-stamped
   evidence paths, never ``latest`` symlinks.
#. Update this handoff page with the new sync point, sign-off session, and
   remaining future-work list.
