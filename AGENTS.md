<!-- GSD:project-start source:PROJECT.md -->
## Project

**SVUnit X Upstream Catch-Up**

This project maintains a fork of SVUnit that already carries local Xilinx/Vivado support work and related fork-specific adjustments. The current goal is to catch this fork up to upstream `svunit/svunit` changes through the user-specified `3.38.1` target, while preserving the validated local behavior that makes this fork useful on this box.

The work is not a generic feature expansion. It is a careful upstream-sync and compatibility project for maintainers who need the fork to stay close to upstream without losing the local Xilinx/Vivado handling that was added here.

**Core Value:** Bring upstream SVUnit changes into this fork without regressing the fork's Xilinx/Vivado-specific behavior, using Quartus-based verification as the sign-off gate for this stage.

### Constraints

- **Compatibility**: Preserve validated Xilinx/Vivado-specific behavior in the fork — that local value is the reason the fork exists
- **Verification**: Quartus is the sign-off environment for this stage — the Xilinx flake is not ready yet
- **Workflow**: Sync decisions must be informed by git history and documented intent — text-only merging is insufficient for this repo
- **Scope**: This stage is an upstream catch-up, not a broad redesign of SVUnit internals — keep divergence minimal unless local behavior requires it
- **Review**: Complex merge outcomes may require human checking — do not force unclear resolutions just to keep momentum
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- SystemVerilog / Verilog - The framework itself lives in `svunit_base/` and `src/experimental/sv/`, with usage examples in `examples/` and simulator fixtures in `test/`.
- Perl 5.x (system Perl) - The main command-line tooling is implemented in `bin/runSVUnit`, `bin/buildSVUnit`, `bin/create_unit_test.pl`, `bin/create_testrunner.pl`, `bin/create_testsuite.pl`, and `bin/cleanSVUnit`.
- Python 3.6+ - Regression tests and support scripts live in `test/*.py`, `sv_test/run`, and `bin/wavedromSVUnit.py`; documentation builds on Python 3.11 in `.readthedocs.yaml`.
- POSIX shell, `csh`, and `zsh` - Environment bootstrap and helper scripts are in `Setup.bsh`, `Setup.csh`, `Setup.zsh`, `.envrc`, `test/.envrc`, `flake.nix`, and `bin/create_docs.sh`.
- reStructuredText - End-user documentation is authored in `docs/source/*.rst`.
- VHDL - Mixed-language coverage appears in fixtures such as `test/sim_12/dut.vhd` and `test/sim_12/vhdl.f`.
## Runtime
- This repo is not a long-running service. The executable surface is a local HDL toolchain driven by `bin/runSVUnit` and `bin/buildSVUnit`.
- At least one simulator executable is expected on `PATH`; `bin/runSVUnit` auto-detects `xrun`, `irun`, `qrun`, `vsim`, `vcs`, `dsim`, `verilator`, or `xsim`, and normalizes simulator aliases such as `questa`, `modelsim`, `ius`, and `xcelium`.
- Python 3.6+ is the stated minimum for the regression suite in `test/README`; GitHub Actions pins Python `3.6` in `.github/workflows/ci.yml`; Read the Docs uses Python `3.11` in `.readthedocs.yaml`.
- System Perl is required for the CLI scripts in `bin/`; the repo does not declare CPAN dependencies beyond modules used directly in `bin/runSVUnit`, `bin/buildSVUnit`, and `bin/create_unit_test.pl`.
- `direnv` is part of the expected developer flow in `CONTRIBUTING.md`, `.envrc`, and `test/.envrc`.
- Nix flake support is now present at the repo root through `flake.nix`, providing the qualified Quartus Podman workflow for this stage without changing the HDL or Perl packaging model.
- Python dependencies are installed with `pip` from pinned requirement files in `docs/requirements.txt` and `test/requirements.txt`.
- Lockfile: `flake.lock` is now part of the repo-level tool bootstrap for the qualified Quartus Podman workflow.
## Frameworks
- SVUnit - The core SystemVerilog unit-testing framework is implemented in `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, and `svunit_base/svunit_testrunner.sv`.
- Optional UVM support - UVM-specific support and mocks live in `svunit_base/uvm-mock/` and are wired through flags in `bin/runSVUnit` and `bin/buildSVUnit`.
- Experimental self-registered flow - Experimental SystemVerilog support is gated by `--enable-experimental` and sources files from `src/experimental/sv/`.
- `pytest` 5.3.2 - Primary regression runner for the repo's own tooling in `test/requirements.txt` and `test/README`.
- `pytest-datafiles` 2.0 - Fixture-copy helper used by tests under `test/` and configured by marker registration in `test/pytest.ini`.
- `pytest-html` 3.2.0 and `pytest-metadata` 1.11.0 - HTML report generation and metadata support for `pytest --html=report.html` documented in `test/README`.
- Sphinx 5.3.0 - Documentation build system configured in `docs/source/conf.py`, `docs/Makefile`, `docs/make.bat`, and `.readthedocs.yaml`.
- Alabaster 0.7.12 - HTML theme pinned in `docs/requirements.txt` and selected in `docs/source/conf.py`.
- GitHub Actions - CI orchestration is defined in `.github/workflows/ci.yml`.
- NaturalDocs - A legacy documentation generation path remains in `bin/create_docs.sh`, which invokes `/usr/local/NaturalDocs/NaturalDocs` against `svunit_base/`.
## Key Dependencies
- Supported simulator CLIs - `bin/runSVUnit` shells out to vendor or open-source tools such as `xrun`, `irun`, `vlog`/`vsim`, `vcs`, `dsim`, `qrun`, `verilator`, and `xsim`; these executables are the real runtime backends.
- `pytest` stack - `test/requirements.txt` pins `pytest`, `pytest-datafiles`, `pytest-html`, and `pytest-metadata`, which together drive the regression suite in `test/`.
- Sphinx stack - `docs/requirements.txt` pins `sphinx`, `alabaster`, and supporting packages used by `docs/source/conf.py` and `.readthedocs.yaml`.
- System Perl core modules - `Getopt::Long`, `File::Find`, `File::Glob`, `IO::File`, `IO::Dir`, `Cwd`, and `File::Basename` are used directly by the scripts in `bin/`.
- `direnv` - The expected shell bootstrap layer is declared in `CONTRIBUTING.md`, `.envrc`, and `.github/workflows/ci.yml`.
- Verilator `v5.012` - CI fetches and builds this version from source in `.github/workflows/ci.yml`.
- GitHub Actions maintained actions - `.github/workflows/ci.yml` depends on `actions/checkout@v2`, `actions/cache@v3`, and `actions/setup-python@v2`.
- Python standard library - `bin/wavedromSVUnit.py`, `sv_test/run`, and the tests under `test/` rely on stdlib modules rather than a packaged Python application framework.
## Configuration
- `SVUNIT_INSTALL` and `PATH` are the baseline runtime variables. `Setup.bsh` and `Setup.csh` export `SVUNIT_INSTALL` and append `bin/`; `Setup.zsh` exports `SVUNIT_INSTALL` and mutates `PATH` for zsh users; all three scripts are part of the setup surface referenced by `README.md`, `bin/buildSVUnit`, `test/utils.py`, and `test/test_example.py`.
- The repository-level `.envrc` now enters `use flake` before sourcing `Setup.bsh`; `test/.envrc` creates a Python environment with `layout python3`, watches `test/requirements.txt`, and installs dependencies automatically.
- Simulator-specific optional variables exist but are not globally required: `UVM_HOME` is referenced in `bin/runSVUnit` for DSim UVM integration, and `INCISIV_HOME` appears in Cadence-specific test coverage in `test/test_mock.py`.
- No `.env` or secret-oriented configuration files are present; only non-secret `direnv` loaders exist in `.envrc` and `test/.envrc`.
- Documentation build configuration lives in `.readthedocs.yaml`, `docs/source/conf.py`, `docs/Makefile`, `docs/make.bat`, and `docs/requirements.txt`.
- Test configuration lives in `.github/workflows/ci.yml`, `test/pytest.ini`, `test/requirements.txt`, and `test/README`.
- Editor behavior is normalized with `.editorconfig`.
- `flake.nix` is now part of the top-level configuration surface alongside the existing script-driven setup files.
## Platform Requirements
- A Unix-like shell environment is the primary target. `README.md` documents `bash` and `csh` setup, and `Setup.zsh` provides a zsh-specific setup variant.
- Perl, Python, `pip`, `direnv`, and Nix are expected for local tooling as evidenced by `bin/`, `.envrc`, `flake.nix`, `test/.envrc`, and `CONTRIBUTING.md`.
- Meaningful simulation work requires at least one supported simulator on `PATH`; `test/utils.py` probes `irun`, `xrun`, `vcs`, `vlog`, `dsim`, `qrun`, `verilator`, and `xsim`.
- Documentation work requires Sphinx dependencies from `docs/requirements.txt`; the legacy NaturalDocs path in `bin/create_docs.sh` adds an additional local binary dependency when used.
- The repo is distributed as source and scripts rather than a hosted application. The operational target is a developer or CI environment with the expected simulator and scripting toolchain.
- Documentation publishing is delegated to Read the Docs using Ubuntu 22.04 and Python 3.11 as configured in `.readthedocs.yaml`.
- The reference CI environment is Ubuntu 20.04 with Verilator built from source in `.github/workflows/ci.yml`.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Name SystemVerilog unit-test modules `<uut>_unit_test.sv`; examples include `src/test/sv/string_utils_unit_test.sv`, `examples/modules/apb_slave/apb_slave_unit_test.sv`, and `test/sim_13/dut_unit_test.sv`. `bin/create_unit_test.pl` enforces the `_unit_test.sv` suffix.
- Name generated suite and runner files `<dir>_testsuite.sv` and `testrunner.sv`, then dot-prefix the build artifacts in the run directory: `.svunit.f`, `.<dir>_testsuite.sv`, and `.testrunner.sv` from `bin/buildSVUnit` and `bin/create_testrunner.pl`.
- Keep core SystemVerilog source and headers in lowercase snake_case: `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_filter.svh`, `src/experimental/sv/full_name_extraction.svh`.
- Keep Python and Perl helper files in lowercase snake_case when the filename is not a historical command name, for example `test/test_run_script.py`, `test/utils.py`, and `bin/create_unit_test.pl`. Preserve established mixed-case CLI entrypoints such as `bin/runSVUnit` and `bin/buildSVUnit`.
- Use shell-specific setup filenames for environment bootstrapping: `Setup.bsh`, `Setup.csh`, and `test/frmwrk_14/run.csh`.
- Use lower_snake_case for SystemVerilog methods and tasks such as `get_error_count`, `add_junit_test_case`, `get_testsuites`, and `replace_double_colon_with_dot` in `svunit_base/svunit_testcase.sv`, `src/experimental/sv/test_registry.svh`, and `src/experimental/sv/full_name_extraction.svh`.
- Name `SVTEST` blocks with behavior-oriented snake_case. Double underscores are used to separate condition and expectation, for example `do_something__performs_action0` in `examples/classes/mock/client_unit_test.sv` and `two_tests_under_package__registers_only_one_tc` in `src/testExperimental/sv/test_registry_unit_test.sv`.
- Name Python tests `test_*` and make the full name describe the scenario, as in `test_called_without_simulator__nothing_on_path` in `test/test_frmwrk.py`.
- Preserve the older Perl subroutine style already used by the generators: `PrintHelp`, `CheckArgs`, `ValidArgs`, `CreateTestSuite`, `OpenFiles`, and `CloseFiles` in `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl`. Newer scripts such as `bin/buildSVUnit` and `bin/runSVUnit` use lowercase helpers like `usage`, `clean`, and `getUnittests`.
- Use lower_snake_case for local variables across SystemVerilog and Python: `error_count`, `current_junit_test_case`, `tmp_path`, `datafiles`, `simulator`.
- Keep the canonical SVUnit handle names `name` and `svunit_ut` inside test modules; see `src/test/sv/string_utils_unit_test.sv` and the generated skeleton in `test/templates/class_unit_test.gold`.
- Keep framework-wide macros and enum values uppercase: `FAIL_IF`, `FAIL_UNLESS_EQUAL`, `SVUNIT_TESTS_BEGIN`, `PASS`, and `FAIL` in `svunit_base/svunit_defines.svh` and `svunit_base/svunit_types.svh`.
- Perl scripts use descriptive sigiled globals such as `$output_file`, `$run_self_registered_tests`, `@files_to_add`, and `@tests`.
- Use lower_snake_case for core SystemVerilog classes and packages: `svunit_base`, `svunit_testcase`, `svunit_testsuite`, `test_registry`, `testcase`, and `full_name_extraction` in `svunit_base/` and `src/experimental/sv/`.
- Use PascalCase only where the XML helper API or a third-party package already establishes it, for example `junit_xml::TestCase`, `junit_xml::TestSuite`, and `XmlElement` in `svunit_base/junit-xml/`.
- Prefer suffixes that explain role: `_testcase`, `_testsuite`, `_testrunner`, `_mock`, `_pkg`, and `_types`.
## Code Style
- Follow `.editorconfig`: spaces everywhere, 4-space indentation by default, 2 spaces for `*.sv` and `*.svh`, LF line endings, trimmed trailing whitespace, and final newline.
- No formatter configuration was detected for Perl, Python, shell, or SystemVerilog. Match surrounding hand formatting instead of introducing a new style into an existing file.
- In `svunit_base/*.sv`, separate lifecycle sections with blank lines and banner comments, keep `class`, `function`, and `task` headers on one line, and indent bodies by two spaces.
- In Python files such as `test/utils.py` and `test/test_run_script.py`, use PEP 8 style spacing and 4-space indentation, but do not normalize away established patterns like `from utils import *` in the test tree.
- Generated SystemVerilog templates in `test/templates/*.gold` are part of the public style surface. If `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, or `bin/create_testrunner.pl` changes output, keep the section banners and placeholder comments aligned with those goldens.
- No lint configuration was detected for Python, shell, Perl, or SystemVerilog: `.flake8`, `ruff.toml`, `mypy.ini`, `perlcriticrc`, `shellcheckrc`, ESLint, and Prettier configs are absent at repo root.
- The practical quality gate is executable regression coverage. `.github/workflows/*` installs `test/requirements.txt`, enters `test/`, and runs `pytest`.
- Because style is not machine-enforced, follow local style exactly when editing old generator scripts or framework classes.
## Import Organization
- Keep related `` `include `` lines contiguous and above the declaration they support. `test/templates/class_unit_test.gold` and `src/experimental/sv/svunit.sv` are the clearest examples.
- In Python, group standard-library imports first, third-party imports next, and local helpers last. `test/utils.py` and `test/test_example.py` follow this loosely.
- The Python tests rely on `from utils import *` throughout `test/test_*.py`. Match that only when adding another regression file under `test/`; do not spread wildcard imports into unrelated Python code.
- No path alias system is used.
- Shell and Perl scripts rely on `PATH` and `SVUNIT_INSTALL`, as shown in `README.md`, `Setup.bsh`, `Setup.csh`, `bin/buildSVUnit`, and `bin/runSVUnit`.
- SystemVerilog discovery relies on `+incdir+` and `-f` entries written into `.svunit.f` by `bin/buildSVUnit`.
## Error Handling
- In SystemVerilog, route assertion failures through the macros in `svunit_base/svunit_defines.svh`. They delegate to `svunit_base/svunit_testcase.sv::fail`, increment `error_count`, add JUnit failure data, emit an `ERROR:` log, and stop the active test with `give_up()`.
- Use `$fatal` only for framework invariants or unsupported internal states. Examples include `src/experimental/sv/testsuite.svh` and `src/experimental/sv/test_registry.svh`.
- In Perl CLIs, validate arguments early, print a human-readable `ERROR:` or usage message, and exit non-zero. File I/O failures still use `die`, as in `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl`.
- `bin/runSVUnit` is the clearest command-line error model: it defines `INTERNAL_EXECUTION_ERROR => 3` and `CMDLINE_USAGE_ERROR => 4`, rejects unsupported combinations early, and exits with those codes.
- Python tests use `subprocess.check_call()` for success-path assertions and `subprocess.call()` or `subprocess.run()` when the exit code itself is part of the contract, as in `test/test_run_script.py` and `test/test_frmwrk.py`.
- `die` or exit on unreadable files and failed open/close operations in the Perl generators.
- Return specific command-line usage errors in `bin/runSVUnit` for unsupported modes such as Verilator + UVM, Verilator + VHDL, or absolute `--directory` paths.
- Treat simulator incompatibilities as test skips in Python rather than framework errors; examples appear in `test/test_sim.py`, `test/test_util.py`, `test/test_example.py`, and `test/test_wavedrom.py`.
## Logging
- SystemVerilog logging is standardized through `` `INFO ``, `` `ERROR ``, and `` `LF `` in `svunit_base/svunit_defines.svh`.
- Perl scripts print progress with a `SVUNIT:` prefix in `bin/create_testsuite.pl`, `bin/create_testrunner.pl`, and `bin/runSVUnit`.
- Python regression tests use plain `print()` only for scenario narration in `test/test_run_script.py` and `test/test_sim.py`; there is no structured Python logger.
- Preserve the exact `INFO:  [time][name]: message` and `ERROR: [time][name]: message` formats because the Python suite parses `run.log` with regexes in `test/utils.py` and `test/test_sim.py`.
- Let the testrunner own summary reporting. `svunit_base/svunit_testsuite.sv` and `svunit_base/svunit_testrunner.sv` emit PASS/FAIL summaries and write `tests.xml`.
- `bin/runSVUnit` prints the fully expanded simulator command before execution. Keep that behavior when changing invocation logic because debugging and regression expectations depend on it.
## Comments
- Use banner comments to separate lifecycle phases and generated sections in SystemVerilog test modules. The canonical examples are `test/templates/class_unit_test.gold` and `examples/uvm/uvm_express/apb_coverage_agent_unit_test.sv`.
- In framework classes under `svunit_base/`, prefer NaturalDocs-style block comments that name the class, method, parameters, or variable purpose.
- Comment simulator-specific caveats inline where behavior diverges. Examples: the coverage caveat in `examples/uvm/uvm_express/apb_coverage_agent_unit_test.sv` and dynamic-array comments in `svunit_base/svunit_testcase.sv`, `src/experimental/sv/testcase.svh`, and `src/test/sv/string_utils_unit_test.sv`.
- In Python tests, comments are sparse and usually explain a skip, a known gap, or a test intent. Keep them short and tied to the fixture behavior.
- Not applicable. This repo uses NaturalDocs-style comments in SystemVerilog and ordinary comments/docstrings in Python.
- Python docstrings are uncommon; `test/utils.py::working_directory` is the current minimal style.
- TODOs are plain `TODO` comments without owner tags or issue references, for example in `bin/runSVUnit`, `src/experimental/sv/full_name_extraction.svh`, `test/test_example.py`, and `test/test_sim.py`.
- If you add a TODO, keep it short, describe the broken behavior concretely, and place it next to the affected branch.
## Function Design
- Keep SystemVerilog lifecycle hooks small and push test logic into discrete `SVTEST` blocks. `src/test/sv/string_utils_unit_test.sv` and `examples/classes/mock/client_unit_test.sv` are the baseline.
- Generator scripts are still large procedural files. When editing `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, or `bin/create_testrunner.pl`, prefer adding narrowly scoped subs over expanding the main linear flow further.
- Python regression helpers are centralized in `test/utils.py`; add reusable subprocess or log helpers there instead of duplicating them across `test/test_*.py`.
- SystemVerilog APIs frequently use explicit `input` directions and typed parameters, as in `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testrunner.sv`, and `svunit_base/junit-xml/*.svh`.
- Python helper functions prefer short positional parameter lists with descriptive names, such as `expect_passing_example(dir, sim, args=[])` and `verify_testrunner(testrunner, ts0, ts1='', ts2='', ts3='', tr='')` in `test/utils.py`.
- Perl CLIs parse options into globals and arrays rather than passing configuration objects.
- SystemVerilog functions return status or collections explicitly and use guard clauses for invalid internal states, for example `get_results()`, `get_testcases()`, and `get_testsuites()`.
- Python tests assert side effects rather than returning values.
- Perl helpers commonly signal failure by printing and exiting instead of bubbling errors through multiple layers.
## Module Design
- `svunit_base/svunit_pkg.sv` is the stable package entry point for framework consumers. Add new stable framework types there when they belong in the public package.
- `src/experimental/sv/svunit.sv` is the experimental aggregation point. New experimental DSL pieces belong there, not in `svunit_base/`.
- Python shared helpers live in `test/utils.py`; test files do not define a broader public API.
- SystemVerilog packages act as barrel files through `` `include `` aggregation: `svunit_base/svunit_pkg.sv`, `svunit_base/uvm-mock/svunit_uvm_mock_pkg.sv`, and `src/experimental/sv/svunit.sv`.
- There are no Python barrel modules beyond `test/utils.py`.
## Code Generation Patterns
- Treat `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl` as the canonical source of generated SystemVerilog structure. The golden expectations in `test/templates/*.gold` show the required output shape.
- `bin/buildSVUnit` generates transient discovery/build artifacts in the run directory: `.svunit.f`, `.<dir>_testsuite.sv`, and `.testrunner.sv`.
- `bin/wavedromSVUnit.py` is the only Python-based code generator; it scans JSON files in the current directory and emits per-method `.svh` files plus a top-level `wavedrom.svh`.
- Preserve generated section banners, naming, and placeholder comments when updating generators. `test/test_frmwrk.py` compares generator output to `test/templates/*.gold` with whitespace-insensitive diffing.
## Contributor Expectations
- Initialize the repo environment through `nix develop` plus `Setup.bsh`, or export `SVUNIT_INSTALL` and add `bin/` to `PATH` as described in `README.md`.
- For host-side regression work, follow `test/README`: Python 3.6+ virtual environment, `pip install -r test/requirements.txt`, then run `pytest` from `test/`. The `test/` directory also contains a `.envrc` used by the existing direnv-based workflow.
- Expect simulator-sensitive behavior. Many tests and examples only run meaningfully when one of `irun`, `xrun`, `vcs`, `vlog`, `dsim`, `qrun`, `verilator`, or `xsim` is on `PATH`; detection lives in `test/utils.py`.
- Keep backward compatibility with older simulators and shells. Support code exists for `bash`, `csh`, and `tcsh` in `Setup.bsh`, `Setup.csh`, and `test/frmwrk_14/run.csh`.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- User-facing execution starts from shell bootstrap scripts like `Setup.bsh`, `Setup.csh`, and `Setup.zsh`, then flows through command tools in `bin/`.
- The standard runtime is generated around discovered `*_unit_test.sv` files: `bin/buildSVUnit` emits hidden suite and runner files, and `bin/runSVUnit` compiles them with a chosen simulator.
- Stable framework primitives live in `svunit_base/`, while a newer self-registering model is isolated in `src/experimental/sv/`.
- Verification of the framework itself is layered outside the shipped runtime: `test/` provides pytest regressions, `sv_test/run` builds a compatibility harness, and `docs/source/` documents the intended workflow.
## Layers
- Purpose: Establish the repo as an installed SVUnit toolchain for the current shell session.
- Location: `Setup.bsh`, `Setup.csh`, `Setup.zsh`, and usage notes in `README.md`.
- Contains: Environment-variable setup for `SVUNIT_INSTALL` and `PATH`.
- Depends on: The repository root being the current directory.
- Used by: Developers, examples, regression tests, and CI before invoking `bin/runSVUnit` or `bin/create_unit_test.pl`.
- Purpose: Turn user source files into runnable SVUnit harnesses.
- Location: `bin/create_unit_test.pl`, `bin/buildSVUnit`, `bin/create_testsuite.pl`, `bin/create_testrunner.pl`, and `bin/cleanSVUnit`.
- Contains: Template generation, recursive discovery, filelist assembly, hidden harness generation, and cleanup logic.
- Depends on: Naming conventions such as `*_unit_test.sv`, optional `svunit.f` manifests, and the stable runtime in `svunit_base/svunit_pkg.sv`.
- Used by: `bin/runSVUnit`, contributors in `test/test_frmwrk.py`, and end users following `README.md`.
- Purpose: Normalize simulator selection and execute compile/run commands.
- Location: `bin/runSVUnit`.
- Contains: Command-line parsing, simulator name normalization, optional UVM/Wavedrom/experimental switches, and simulator-specific command construction.
- Depends on: `bin/buildSVUnit`, generated `.svunit.f`, external simulator binaries on `PATH`, and optional VHDL/filelist inputs.
- Used by: End users, examples in `examples/`, pytest regressions in `test/test_run_script.py` and `test/test_sim.py`, and CI in `.github/workflows/ci.yml`.
- Purpose: Provide the object model and macros that actually execute and report tests.
- Location: `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_defines.svh`, `svunit_base/svunit_base.sv`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`.
- Contains: Assertion macros, lifecycle macros, pass/fail aggregation, JUnit XML emission, string/filter helpers, and optional UVM/util support.
- Depends on: SystemVerilog simulation and supporting include paths assembled by `bin/buildSVUnit`.
- Used by: Generated `*_unit_test.sv` modules, examples under `examples/`, compatibility tests in `src/test/sv`, and experimental code in `src/experimental/sv/svunit.sv`.
- Purpose: Add specialized behavior without changing the core test model.
- Location: `svunit_base/junit-xml/`, `svunit_base/uvm-mock/`, `svunit_base/util/`, and `bin/wavedromSVUnit.py`.
- Contains: JUnit XML serialization, UVM mocking/reporting helpers, reusable utility includes, and JSON-to-SystemVerilog Wavedrom generation.
- Depends on: The stable runtime and feature switches passed through `bin/runSVUnit` or explicit `svunit.f` files.
- Used by: `svunit_testrunner::report()` in `svunit_base/svunit_testrunner.sv`, UVM examples in `examples/uvm/`, utility examples in `examples/modules/clk_and_reset/`, and Wavedrom examples in `examples/modules/wavedrom/`.
- Purpose: Offer a self-registering test API that does not rely on directory-scanned `*_unit_test.sv` modules.
- Location: `src/experimental/sv/svunit.sv`, `src/experimental/sv/svunit.svh`, `src/experimental/sv/svunit_main.sv`, `src/experimental/sv/test.svh`, `src/experimental/sv/testcase.svh`, `src/experimental/sv/testsuite.svh`, `src/experimental/sv/test_registry.svh`, `src/experimental/sv/global_test_registry.svh`.
- Contains: `TEST_BEGIN`/`TEST_F_BEGIN` macros, self-registering builders, registry objects, and a package-level `run_all_tests()` entry point.
- Depends on: The stable runtime in `svunit_base/svunit_pkg.sv` for base classes, filters, and reporting.
- Used by: `examples/experimental/`, internal experimental tests in `src/testExperimental/sv/`, and `bin/buildSVUnit --enable-experimental`.
- Purpose: Validate framework behavior and document the intended usage model.
- Location: `test/`, `sv_test/`, `src/test/sv/`, `src/testExperimental/sv/`, `examples/`, and `docs/source/`.
- Contains: Pytest regressions, fixture trees, golden files, example projects, stable-vs-experimental compatibility harnesses, and Sphinx docs.
- Depends on: The command layer, the stable runtime, and external simulators.
- Used by: Contributors, CI, and future changes to `bin/`, `svunit_base/`, or `src/experimental/sv/`.
## Data Flow
- Persistent project state is file-based, not service-based. The framework expects source files, manifests, and include paths to live in the user’s working tree.
- Run-specific state is ephemeral. Generated files such as `.svunit.f`, `.*_testsuite.sv`, `.testrunner.sv`, `run.log`, `compile.log`, `tests.xml`, and simulator work directories are written into the current directory or the `-o` directory and are ignored by `.gitignore`.
- In-simulation state is object-local. `svunit_testcase` owns error counts and running state, `svunit_testsuite` owns testcase collections, and `svunit_testrunner` owns suite aggregation. The experimental path adds a singleton registry in `src/experimental/sv/global_test_registry.svh`.
## Key Abstractions
- Purpose: Wrap one class, module, or interface under test in a conventional SVUnit module shell.
- Examples: User-created files like `examples/modules/apb_slave/apb_slave_unit_test.sv`, `test/mock_uvm_report/basic_unit_test.sv`, and templates emitted by `bin/create_unit_test.pl`.
- Pattern: Module wrapper plus `svunit_testcase` instance, explicit `build()/setup()/teardown()`, and `SVUNIT_TESTS_BEGIN` / `SVTEST` / `SVTEST_END` macros.
- Purpose: Aggregate results from individual assertions up to testcase, suite, and whole-run status.
- Examples: `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`.
- Pattern: Small inheritance hierarchy rooted at `svunit_base/svunit_base.sv`, with queues of child objects and late reporting.
- Purpose: Define what gets compiled in addition to the auto-generated SVUnit harness.
- Examples: `svunit.f` files in user projects, `examples/all.f`, `examples/uvm/uvm_express/cov.f`, `sv_test/svunit.f`, and generated `.svunit.f`.
- Pattern: Flat compile manifest with `+incdir+` directives and source-file paths consumed by `bin/runSVUnit`.
- Purpose: Decouple test declaration from directory-scanned wrapper modules.
- Examples: `src/experimental/sv/test.svh`, `src/experimental/sv/test_registry.svh`, `src/experimental/sv/testsuite.svh`.
- Pattern: Static builder registration into a singleton registry, followed by runtime suite/testcase materialization.
- Purpose: Keep optional integrations separate from the stable core.
- Examples: `svunit_base/uvm-mock/svunit_uvm_mock_pkg.sv`, `svunit_base/util/clk_and_reset.svh`, `svunit_base/junit-xml/junit_xml.sv`, `bin/wavedromSVUnit.py`.
- Pattern: Opt-in include path and filelist additions controlled by flags or project manifests.
## Entry Points
- Location: `Setup.bsh`, `Setup.csh`, `Setup.zsh`
- Triggers: Developer shells, local editor sessions, and any workflow that needs `SVUNIT_INSTALL` and repo `bin/` on `PATH`.
- Responsibilities: Export `SVUNIT_INSTALL` and make the CLI scripts reachable.
- Location: `bin/create_unit_test.pl`
- Triggers: Manual user invocation when starting or scaffolding a new unit-test wrapper.
- Responsibilities: Parse a Verilog/SystemVerilog file or explicit name, infer the UUT kind, and emit a `*_unit_test.sv` template.
- Location: `bin/runSVUnit`
- Triggers: User test runs, example README commands, pytest regression calls, and CI.
- Responsibilities: Parse flags, infer/select simulator, invoke `buildSVUnit`, and run the generated harness.
- Location: `bin/buildSVUnit`
- Triggers: Direct developer invocation or indirect invocation from `bin/runSVUnit`.
- Responsibilities: Build `.svunit.f`, gather manifests, generate hidden suites, and emit `.testrunner.sv`.
- Location: `src/experimental/sv/svunit_main.sv`
- Triggers: Experimental flows that want a pure-SystemVerilog top module without the classic generated harness.
- Responsibilities: Call `svunit::run_all_tests()`.
- Location: `sv_test/run`
- Triggers: Internal framework development when validating `src/test/sv/` and `src/testExperimental/sv/`.
- Responsibilities: Clone a stable upstream SVUnit, rename its package/files to `svunit_stable_*`, and execute the repo’s internal SV tests against it.
- Location: `docs/Makefile`
- Triggers: Manual Sphinx builds and Read the Docs.
- Responsibilities: Route `make` targets to `sphinx-build` for `docs/source/`.
## Error Handling
- `bin/runSVUnit` validates CLI combinations, returns dedicated usage/internal error codes, and stops immediately if `buildSVUnit` or the simulator command fails.
- `bin/buildSVUnit`, `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl` enforce required arguments and stop on missing files or invalid output targets.
- `svunit_base/svunit_defines.svh` routes `FAIL_IF`, `FAIL_UNLESS`, and related macros through `svunit_pkg::current_tc.fail(...)`, increments error state, and aborts the current test body through `give_up()`.
- `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, and `svunit_base/svunit_testrunner.sv` aggregate status in `report()` rather than throwing simulator exceptions for every failure.
- The experimental code in `src/experimental/sv/testsuite.svh` and `src/experimental/sv/test_registry.svh` uses `$fatal` for structural inconsistencies such as unsupported nesting or failed casts.
## Cross-Cutting Concerns
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
