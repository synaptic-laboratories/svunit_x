# Technology Stack

**Analysis Date:** 2026-04-11

## Languages

**Primary:**
- SystemVerilog / Verilog - The framework itself lives in `svunit_base/` and `src/experimental/sv/`, with usage examples in `examples/` and simulator fixtures in `test/`.

**Secondary:**
- Perl 5.x (system Perl) - The main command-line tooling is implemented in `bin/runSVUnit`, `bin/buildSVUnit`, `bin/create_unit_test.pl`, `bin/create_testrunner.pl`, `bin/create_testsuite.pl`, and `bin/cleanSVUnit`.
- Python 3.6+ - Regression tests and support scripts live in `test/*.py`, `sv_test/run`, and `bin/wavedromSVUnit.py`; documentation builds on Python 3.11 in `.readthedocs.yaml`.
- POSIX shell, `csh`, and `zsh` - Environment bootstrap and helper scripts are in `Setup.bsh`, `Setup.csh`, `Setup.zsh`, `.envrc`, `test/.envrc`, and `bin/create_docs.sh`.
- reStructuredText - End-user documentation is authored in `docs/source/*.rst`.
- VHDL - Mixed-language coverage appears in fixtures such as `test/sim_12/dut.vhd` and `test/sim_12/vhdl.f`.

## Runtime

**Environment:**
- This repo is not a long-running service. The executable surface is a local HDL toolchain driven by `bin/runSVUnit` and `bin/buildSVUnit`.
- At least one simulator executable is expected on `PATH`; `bin/runSVUnit` auto-detects `xrun`, `irun`, `qrun`, `vsim`, `vcs`, `dsim`, `verilator`, or `xsim`, and normalizes simulator aliases such as `questa`, `modelsim`, `ius`, and `xcelium`.
- Python 3.6+ is the stated minimum for the regression suite in `test/README`; GitHub Actions pins Python `3.6` in `.github/workflows/ci.yml`; Read the Docs uses Python `3.11` in `.readthedocs.yaml`.
- System Perl is required for the CLI scripts in `bin/`; the repo does not declare CPAN dependencies beyond modules used directly in `bin/runSVUnit`, `bin/buildSVUnit`, and `bin/create_unit_test.pl`.
- `direnv` is part of the expected developer flow in `CONTRIBUTING.md`, `.envrc`, and `test/.envrc`.

**Package Manager:**
- No application package manager is declared for the HDL or Perl code: there is no `package.json`, `pyproject.toml`, `Cargo.toml`, or `go.mod` at the repo root.
- Python dependencies are installed with `pip` from pinned requirement files in `docs/requirements.txt` and `test/requirements.txt`.
- Lockfile: missing. No `package-lock.json`, `poetry.lock`, `Pipfile.lock`, `uv.lock`, `pnpm-lock.yaml`, `yarn.lock`, or similar lockfile is present in the repository.

## Frameworks

**Core:**
- SVUnit - The core SystemVerilog unit-testing framework is implemented in `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, and `svunit_base/svunit_testrunner.sv`.
- Optional UVM support - UVM-specific support and mocks live in `svunit_base/uvm-mock/` and are wired through flags in `bin/runSVUnit` and `bin/buildSVUnit`.
- Experimental self-registered flow - Experimental SystemVerilog support is gated by `--enable-experimental` and sources files from `src/experimental/sv/`.

**Testing:**
- `pytest` 5.3.2 - Primary regression runner for the repo's own tooling in `test/requirements.txt` and `test/README`.
- `pytest-datafiles` 2.0 - Fixture-copy helper used by tests under `test/` and configured by marker registration in `test/pytest.ini`.
- `pytest-html` 3.2.0 and `pytest-metadata` 1.11.0 - HTML report generation and metadata support for `pytest --html=report.html` documented in `test/README`.

**Build/Dev:**
- Sphinx 5.3.0 - Documentation build system configured in `docs/source/conf.py`, `docs/Makefile`, `docs/make.bat`, and `.readthedocs.yaml`.
- Alabaster 0.7.12 - HTML theme pinned in `docs/requirements.txt` and selected in `docs/source/conf.py`.
- GitHub Actions - CI orchestration is defined in `.github/workflows/ci.yml`.
- NaturalDocs - A legacy documentation generation path remains in `bin/create_docs.sh`, which invokes `/usr/local/NaturalDocs/NaturalDocs` against `svunit_base/`.

## Key Dependencies

**Critical:**
- Supported simulator CLIs - `bin/runSVUnit` shells out to vendor or open-source tools such as `xrun`, `irun`, `vlog`/`vsim`, `vcs`, `dsim`, `qrun`, `verilator`, and `xsim`; these executables are the real runtime backends.
- `pytest` stack - `test/requirements.txt` pins `pytest`, `pytest-datafiles`, `pytest-html`, and `pytest-metadata`, which together drive the regression suite in `test/`.
- Sphinx stack - `docs/requirements.txt` pins `sphinx`, `alabaster`, and supporting packages used by `docs/source/conf.py` and `.readthedocs.yaml`.
- System Perl core modules - `Getopt::Long`, `File::Find`, `File::Glob`, `IO::File`, `IO::Dir`, `Cwd`, and `File::Basename` are used directly by the scripts in `bin/`.
- `direnv` - The expected shell bootstrap layer is declared in `CONTRIBUTING.md`, `.envrc`, and `.github/workflows/ci.yml`.

**Infrastructure:**
- Verilator `v5.012` - CI fetches and builds this version from source in `.github/workflows/ci.yml`.
- GitHub Actions maintained actions - `.github/workflows/ci.yml` depends on `actions/checkout@v2`, `actions/cache@v3`, and `actions/setup-python@v2`.
- Python standard library - `bin/wavedromSVUnit.py`, `sv_test/run`, and the tests under `test/` rely on stdlib modules rather than a packaged Python application framework.

## Configuration

**Environment:**
- `SVUNIT_INSTALL` and `PATH` are the baseline runtime variables. `Setup.bsh` and `Setup.csh` export `SVUNIT_INSTALL` and append `bin/`; `Setup.zsh` exports `SVUNIT_INSTALL` and mutates `PATH` for zsh users; all three scripts are part of the setup surface referenced by `README.md`, `bin/buildSVUnit`, `test/utils.py`, and `test/test_example.py`.
- The repository-level `.envrc` sources `Setup.bsh`; `test/.envrc` creates a Python environment with `layout python3`, watches `test/requirements.txt`, and installs dependencies automatically.
- Simulator-specific optional variables exist but are not globally required: `UVM_HOME` is referenced in `bin/runSVUnit` for DSim UVM integration, and `INCISIV_HOME` appears in Cadence-specific test coverage in `test/test_mock.py`.
- No `.env` or secret-oriented configuration files are present; only non-secret `direnv` loaders exist in `.envrc` and `test/.envrc`.

**Build:**
- Documentation build configuration lives in `.readthedocs.yaml`, `docs/source/conf.py`, `docs/Makefile`, `docs/make.bat`, and `docs/requirements.txt`.
- Test configuration lives in `.github/workflows/ci.yml`, `test/pytest.ini`, `test/requirements.txt`, and `test/README`.
- Editor behavior is normalized with `.editorconfig`.
- There is no central project manifest for the full repo; the configuration surface is script-driven and file-based.

## Platform Requirements

**Development:**
- A Unix-like shell environment is the primary target. `README.md` documents `bash` and `csh` setup, and `Setup.zsh` provides a zsh-specific setup variant.
- Perl, Python, `pip`, and `direnv` are expected for local tooling as evidenced by `bin/`, `.envrc`, `test/.envrc`, and `CONTRIBUTING.md`.
- Meaningful simulation work requires at least one supported simulator on `PATH`; `test/utils.py` probes `irun`, `xrun`, `vcs`, `vlog`, `dsim`, `qrun`, `verilator`, and `xsim`.
- Documentation work requires Sphinx dependencies from `docs/requirements.txt`; the legacy NaturalDocs path in `bin/create_docs.sh` adds an additional local binary dependency when used.

**Production:**
- The repo is distributed as source and scripts rather than a hosted application. The operational target is a developer or CI environment with the expected simulator and scripting toolchain.
- Documentation publishing is delegated to Read the Docs using Ubuntu 22.04 and Python 3.11 as configured in `.readthedocs.yaml`.
- The reference CI environment is Ubuntu 20.04 with Verilator built from source in `.github/workflows/ci.yml`.

---

*Stack analysis: 2026-04-11*
