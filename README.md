# SVUnit X

SLL fork of [SVUnit](https://github.com/svunit/svunit), the open-source
SystemVerilog unit-test framework.

| Field | Value |
|-------|-------|
| Upstream | https://github.com/svunit/svunit |
| Synced to | v3.38.1 (`8e70653e2cbfe3ebe154a863a46bf482ded4bc19`) |
| Fork version | 3.38.1-x0.3.0 |
| Qualified as | `g_svunit_x / r_v3_38_1_x0_3_0` |

SVUnit is automated, fast, lightweight and easy to use making it the only SystemVerilog test
framework in existence suited to both design and verification engineers that aspire to high quality
code and low bug rates.

NOTE: for instructions on how to get going with SVUnit, go to
      www.agilesoc.com/svunit.

NOTE: Refer also to the FAQ at: www.agilesoc.com/svunit/svunit-FAQ


## Release Notes

Go [here](CHANGELOG.md) for release notes.

## Documentation

Read the [latest documentation](https://docs.svunit.org/en/latest/)

## Maintainer Handoff

This fork is synced to upstream SVUnit `v3.38.1`
(`8e70653e2cbfe3ebe154a863a46bf482ded4bc19`) and qualified as
`g_svunit_x / r_v3_38_1_x0_3_0`.

The maintainer entry point for this catch-up round is
[`docs/source/maintainer_handoff.rst`](docs/source/maintainer_handoff.rst).
It names the final sign-off boundary, the two-mode six-target sign-off session,
the history-aware sync trail, and the future-work items that remain outside this
stage. The current sign-off record is
[`.planning/sign-off-v3.38.1-x0.3.0.md`](.planning/sign-off-v3.38.1-x0.3.0.md)
(the prior x0.2.0 record remains at
[`.planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off.md`](.planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off.md)).

## Step-by-step instructions to get a first unit test going

### 1. Set up the `SVUNIT_INSTALL` and `PATH` environment variables

```shell
export SVUNIT_INSTALL=`pwd`
export PATH=$PATH:$SVUNIT_INSTALL"/bin"
```

You can source `Setup.bsh` if you use the bash shell.

```shell
source Setup.bsh
```

You can source `Setup.csh` if you use the csh shell.

```shell
source Setup.csh
```

On this box, you can also enter the qualified Quartus Podman workflow through the repo flake.

```shell
nix develop
```

### 2. Go somewhere outside `SVUNIT_INSTALL` (i.e. where you are right now)

Start a class-under-test:


    // file: bogus.sv
    class bogus;
    endclass

### 3. Generate the unit test

```shell
create_unit_test.pl bogus.sv
```

### 4. Add tests using the helper macros

    // file: bogus_unit_test.sv
    `SVUNIT_TESTS_BEGIN

      //===================================
      // Unit test: test_mytest
      //===================================
      `SVTEST(test_mytest)
      `SVTEST_END

    `SVUNIT_TESTS_END

### 5. Run the unit tests

```shell
runSVUnit -s <simulator> # simulator is ius, questa, modelsim, riviera, vcs, dsim, verilator or xsim
```

### 6. Repeat steps 4 and 5 until done

### 7. Pat self on back

## Qualification

Each qualification *target* is one concrete `(simulator, version, variant)`
combination and has its own Nix package.  Run one:

```shell
nix run .#svunit-certify-quartus-23-4-qrun
nix run .#svunit-certify-quartus-25-1-sim-only-qrun
nix run .#svunit-certify-verilator-5-044
nix run .#svunit-certify-vivado-2025-2-1-synth-sim-full-xsim
```

Or run every registered target sequentially and get a cross-target timing
report at the end:

```shell
nix run .#svunit-certify-all
```

Each certify target runs two SVUnit regression modes: the normal per-fixture
pytest flow used for clean sign-off isolation, and a compile-once multi-fixture
pytest flow that covers the local developer workflow where several unit-test
files are compiled into one generated suite.

Artefacts are written to `g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_3_0_artefacts/`
with run folders named per the SLL qualification standard
(`YYYYMMDD-HHMM--nixos-<ver>--nix-<ver>--kernel-<ver>`).

Supported targets (registered in `nix/registry.nix`):

| Target | Status | Runtime |
|--------|--------|---------|
| `quartus-23-4-qrun` | Qualified | Quartus Pro 23.4.0.79 / Questa FPGA Edition 2023.3 (container) |
| `quartus-23-4-modelsim` | Qualified | Quartus Pro 23.4.0.79 / Questa FPGA Edition 2023.3 (container) |
| `quartus-25-1-sim-only-qrun` | Qualified | Quartus Pro 25.1.1.125 *sim-only* image / Questa FPGA Edition 2025.1 (container) |
| `quartus-25-1-sim-only-modelsim` | Qualified | Quartus Pro 25.1.1.125 *sim-only* image / Questa FPGA Edition 2025.1 (container) |
| `verilator-5-044` | Qualified | Verilator 5.044 (native, from `g_verilator/r_v5_044`) |
| `vivado-2025-2-1-synth-sim-full-xsim` | Qualified | Vivado 2025.2.1 `synth-sim-full` via `buildFHSEnv` (native xsim) |

To add a Quartus version: append an attribute to `nix/registry.nix`, add
the matching flake input, and `nix flake lock`.  The per-target packages
and apps are generated automatically.

The Vivado target deliberately performs two checks in one certify run.  First,
`scripts/certify.sh` runs a direct Vivado package smoke with a temporary
`HOME` and a tiny `xvlog -> xelab -> xsim` Verilog flow.  That proves the
`g_xilinx_vivado` `synth-sim-full` package and wrappers are usable.  It then
runs the normal SVUnit pytest regression with `-k xsim` in both per-fixture and
compile-once modes, which proves this fork's `runSVUnit -s xsim` path works
with that package.  The future Vivado container image should add another
execution shape, not replace this native flake path.  Vivado runs also write
`vivado-tool-timing/tool-invocations.tsv` so wrapper/tool startup, compile,
elaboration, and simulation process time can be compared against the pytest
timing summary.  The timing TSV records start/end UTC timestamps, epoch
millisecond bounds, duration, exit code, cwd, args, and regression mode; the
certifier also emits `tool-summary.tsv` and `tool-by-cwd.tsv` rollups for
quick xsim/xelab/xvlog comparisons.

For non-sign-off xsim performance experiments, the Vivado certify app accepts
`--xsim-reuse-build`.  That opt-in switch sets `SVUNIT_XSIM_REUSE_BUILD=1`
inside pytest, allowing `runSVUnit -s xsim --xsim-reuse-build` to reuse a
matching compile/elaboration snapshot when the generated SVUnit harness inputs
have not changed.  The normal commands above do not enable this mode; keep them
as the deterministic clean qualification path unless the reuse mode is being
measured separately.

The certifier also accepts `--sim-debug-level none|low|medium|med|high|all`,
which forwards `SVUNIT_SIM_DEBUG_LEVEL` into the pytest runs.  Vivado xsim maps
that level to `xelab --debug`: `none` maps to `off`, `low` to `line`,
`medium`/`med` to `typical`, and `high`/`all` to `all`.  ModelSim/Questa maps
requested levels to documented vopt visibility and vsim debug options:
`low` uses `+access+r` plus `-lineinfo`, `medium` uses `+access+rw` plus
`-lineinfo`, and `high`/`all` uses `+access+rw` plus `-lineinfo`,
`-classdebug`, and `-assertdebug`.  Verilator maps requested levels to its
documented runtime-debug surface: `low`/`medium` add `--runtime-debug`, runtime
`+verilator+debug`, and medium also adds `+verilator+debugi+1`; `high`/`all`
also add Verilator `--debug` and runtime `+verilator+debugi+3`.  Plain
`runSVUnit -s xsim` still defaults to `--debug all` for compatibility with the
diagnostic-heavy local Vivado path; other simulator targets warn instead of
guessing vendor-specific flags.

For runtime profiling, `runSVUnit` and the certifier accept
`--sim-runtime-stats` (or `SVUNIT_SIM_RUNTIME_STATS=1`).  Today this maps
Vivado xsim to `-stats`, ModelSim/Questa `vsim` to `-printsimstats`, and qrun
to `-stats=all`; Verilator maps it to `--stats`.  The xsim mapping adds kernel
memory and CPU usage to `run.log`; ModelSim/Questa adds memory,
vopt/elaboration/simulation, and total time statistics; qrun adds separate
`vlog`, `vopt`, and `vsim` phase statistics; Verilator retains
`obj_dir/*__stats*.txt` and the certifier parses the generated model's standard
simulation report for wall time, CPU, thread count, and allocated memory.
Certifier runs retain the pytest workspaces under `pytest-per-fixture/` and
`pytest-compile-once/`, then parse supported simulator stats into
`sim-runtime-stats.tsv` and `sim-runtime-stats.json`.
Simulator targets without a known mapping warn instead of guessing a
vendor-specific flag.

For xsim performance experiments, `runSVUnit -s xsim --xsim-run-mode
standalone` uses AMD's `xelab -standalone -R` path instead of a separate
`xsim --R` process.  This is intentionally narrow: it is rejected with
`--filter`, `--list-tests`, `--reuse-build`, `--sim-runtime-stats`, or explicit
xsim runtime args because `xelab -standalone -R` does not accept the xsim
runtime plusarg channel that SVUnit uses for those modes.

The xsim runner deliberately keeps `run.log` enabled.  Vivado xsim has been
observed to print simulator-startup failures such as `ERROR: unexpected
exception when evaluating tcl command` or `ERROR: [Simtcl ...] Simulation engine
failed to start` while still returning process exit code 0, so `runSVUnit -s
xsim` scans the run log after a nominally successful invocation and fails the
run if those vendor errors are present.  For that reason, xsim runtime args
containing `-nolog` or `--nolog` are rejected instead of being forwarded.

### Verilator parallel compilation

SVUnit X automatically parallelises Verilator's C++ compilation step.  When
`runSVUnit -s verilator` is invoked, the script detects the number of hardware
threads via `nproc` and passes `-j <nproc>` to Verilator.  The compilation runs
at reduced scheduling priority (`nice 10`) so it uses all available cores
without starving interactive processes.

Override the job count with the `SVUNIT_VERILATOR_JOBS` environment variable:

```shell
SVUNIT_VERILATOR_JOBS=4 runSVUnit -s verilator   # limit to 4 jobs
SVUNIT_VERILATOR_JOBS=1 runSVUnit -s verilator   # disable parallelism
```

Observed impact on slldev01 (24 threads):

| | Questa (qrun) | Verilator (no -j) | Verilator (-j 24, nice 10) |
|---|---|---|---|
| Wall time | 55.6s | 279s | 130s |
| Avg per test | 1.16s | 5.91s | 2.77s |
| Ratio vs Questa | 1.0x | 5.74x | 2.72x |

### Timing report

Each certification run produces a `timing-summary.json` with per-test durations.
Generate a cross-simulator comparison:

```shell
nix run .#svunit-timing-report
```

The report finds the latest run per simulator per hostname and produces a
markdown table with per-test durations, ratios, and aggregate statistics.

### Dependency architecture

Targets are declared once in `nix/registry.nix` and consumed by factory
modules (`nix/mk-certify.nix`, `nix/mk-quartus-shell.nix`) to generate
per-target packages.  Three adapter shapes are supported:

| Adapter | Used by | Execution model | Host deps used? |
|---------|---------|-----------------|-----------------|
| `container` | `quartus-*-qrun`, `quartus-*-modelsim` | Inside Podman container | No — container has its own python3; host-side deps are not visible inside the container |
| `native` | `verilator-*` | Native on host | Yes — Verilator, gcc, make, and python3-with-pytest from the Nix closure |
| `fhs` | `vivado-2025-2-1-synth-sim-full-xsim` | Native with `buildFHSEnv` wrappers | Yes — tools wrapped per `g_xilinx_vivado/r_src_v2025_1` |

The Verilator flake (`g_verilator/r_v5_044`) uses `nixos-unstable` internally;
this flake does **not** follow its nixpkgs — we consume only its binaries.
Test runner dependencies (pytest, pytest-datafiles) are bundled via
`python3.withPackages` in the SVUnit flake, not in the Verilator flake, because
they are SVUnit's concern, not Verilator's.

## Quartus Podman workflow

Each Quartus container *base* (e.g. 23.4.0.79 Pro, 25.1.1.125 sim-only) has
its own interactive-shell launcher and its own `quartus-tools` wrapper,
generated from the registry.

Build or refresh the container image for a given base:

```shell
nix run .#svunit-quartus-tools-quartus-23-4 -- build-image
nix run .#svunit-quartus-tools-quartus-25-1-sim-only -- build-image
```

Open a shell inside the Quartus container with this repo mounted at `/sll`:

```shell
nix run .#svunit-quartus-shell-quartus-23-4
nix run .#svunit-quartus-shell-quartus-25-1-sim-only
```

Launch the Quartus GUI when `DISPLAY` is available (only valid for bases
that include Quartus, i.e. not sim-only):

```shell
nix run .#svunit-quartus-shell-quartus-23-4 -- --quartus
```

By default each shell wrapper:

- uses the base's default image tag (e.g. `localhost/quartus-pro-linux:23.4.0.79` or
  `localhost/quartus-pro-linux:25.1.1.125-sim-only`)
- mounts the repo root into the container at `/sll`
- persists container root state under `.quartus/root`
- looks for `quartus_license.dat` and `questa_license.dat` in
  `/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch`
  (one license set covers all Quartus/Questa versions)


## Feedback

Tell us about what you like,
what you don't like,
new features you'd like to see...
basically anything
you think would make SVUnit more valuable to you.

The best place for feedback is https://github.com/svunit/svunit/discussions.
If you don't have a GitHub account, you can send an email to *contact[at]svunit[dot]org*.
