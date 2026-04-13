# SVUnit X

SLL fork of [SVUnit](https://github.com/svunit/svunit), the open-source
SystemVerilog unit-test framework.

| Field | Value |
|-------|-------|
| Upstream | https://github.com/svunit/svunit |
| Synced to | v3.38.1 (`8e70653e2cbfe3ebe154a863a46bf482ded4bc19`) |
| Fork version | 3.38.1-x0.2.0 |
| Qualified as | `g_svunit_x / r_v3_38_1_x0_2_0` |

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

Run the full SVUnit qualification against a simulator:

```shell
nix run .#svunit-certify -- --simulator qrun
nix run .#svunit-certify -- --simulator verilator
```

Artefacts are written to `g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/`
with run folders named per the SLL qualification standard
(`YYYYMMDD-HHMM--nixos-<ver>--nix-<ver>--kernel-<ver>`).

Supported simulators:

| Simulator | Status | Runtime |
|-----------|--------|---------|
| `qrun` | Qualified | Quartus Pro 23.4.0.79 / Questa FPGA Edition 2023.3 (container) |
| `modelsim` | Qualified | Quartus Pro 23.4.0.79 / Questa FPGA Edition 2023.3 (container) |
| `verilator` | Qualified | Verilator 5.044 (native, from `g_verilator/r_v5_044`) |
| `xsim` | Planned | Vivado (not yet implemented) |

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

The `svunit-certify` command bundles all simulator runtimes into a single Nix
closure.  This avoids duplicating shared logic (argument parsing, artefact
generation, JUnit XML parsing) across per-simulator packages.

| Simulator | Execution model | Host deps used? |
|-----------|----------------|-----------------|
| `qrun` / `modelsim` | Inside Podman container | No -- container has isolated filesystem with its own python3; host-side Verilator/pytest deps are on PATH but invisible to the container |
| `verilator` | Native on host | Yes -- uses Verilator, gcc, make, and python3-with-pytest from the Nix closure |
| `xsim` (planned) | Inside Podman container | Will follow the container pattern |

The Verilator flake (`g_verilator/r_v5_044`) uses `nixos-unstable` internally;
this flake does **not** follow its nixpkgs -- we consume only its binaries.
Test runner dependencies (pytest, pytest-datafiles) are bundled via
`python3.withPackages` in the SVUnit flake, not in the Verilator flake, because
they are SVUnit's concern, not Verilator's.

## Quartus Podman workflow

This repo includes a `flake.nix` that consumes the qualified Altera Quartus Pro Podman source at `g_altera_quartus_pro_podman/r_src_v23_4_0_79` and exposes repo-local wrappers.

Build or refresh the local container image:

```shell
nix run .#quartus-tools -- build-image
```

Check that the container exposes the expected Quartus and Questa commands:

```shell
nix run .#svunit-quartus-check
```

Open a shell inside the Quartus container with this repo mounted at `/sll`:

```shell
nix run .#svunit-quartus-podman
```

Launch the Quartus GUI when `DISPLAY` is available:

```shell
nix run .#svunit-quartus-podman -- --quartus
```

By default the wrapper:

- uses `localhost/quartus-pro-linux:23.4.0.79`
- mounts the repo root into the container at `/sll`
- persists container root state under `.quartus/root`
- looks for `quartus_license.dat` and `questa_license.dat` in `/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch`


## Feedback

Tell us about what you like,
what you don't like,
new features you'd like to see...
basically anything
you think would make SVUnit more valuable to you.

The best place for feedback is https://github.com/svunit/svunit/discussions.
If you don't have a GitHub account, you can send an email to *contact[at]svunit[dot]org*.
