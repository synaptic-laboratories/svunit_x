# Coding Conventions

**Analysis Date:** 2026-04-11

## Naming Patterns

**Files:**
- Name SystemVerilog unit-test modules `<uut>_unit_test.sv`; examples include `src/test/sv/string_utils_unit_test.sv`, `examples/modules/apb_slave/apb_slave_unit_test.sv`, and `test/sim_13/dut_unit_test.sv`. `bin/create_unit_test.pl` enforces the `_unit_test.sv` suffix.
- Name generated suite and runner files `<dir>_testsuite.sv` and `testrunner.sv`, then dot-prefix the build artifacts in the run directory: `.svunit.f`, `.<dir>_testsuite.sv`, and `.testrunner.sv` from `bin/buildSVUnit` and `bin/create_testrunner.pl`.
- Keep core SystemVerilog source and headers in lowercase snake_case: `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_filter.svh`, `src/experimental/sv/full_name_extraction.svh`.
- Keep Python and Perl helper files in lowercase snake_case when the filename is not a historical command name, for example `test/test_run_script.py`, `test/utils.py`, and `bin/create_unit_test.pl`. Preserve established mixed-case CLI entrypoints such as `bin/runSVUnit` and `bin/buildSVUnit`.
- Use shell-specific setup filenames for environment bootstrapping: `Setup.bsh`, `Setup.csh`, and `test/frmwrk_14/run.csh`.

**Functions:**
- Use lower_snake_case for SystemVerilog methods and tasks such as `get_error_count`, `add_junit_test_case`, `get_testsuites`, and `replace_double_colon_with_dot` in `svunit_base/svunit_testcase.sv`, `src/experimental/sv/test_registry.svh`, and `src/experimental/sv/full_name_extraction.svh`.
- Name `SVTEST` blocks with behavior-oriented snake_case. Double underscores are used to separate condition and expectation, for example `do_something__performs_action0` in `examples/classes/mock/client_unit_test.sv` and `two_tests_under_package__registers_only_one_tc` in `src/testExperimental/sv/test_registry_unit_test.sv`.
- Name Python tests `test_*` and make the full name describe the scenario, as in `test_called_without_simulator__nothing_on_path` in `test/test_frmwrk.py`.
- Preserve the older Perl subroutine style already used by the generators: `PrintHelp`, `CheckArgs`, `ValidArgs`, `CreateTestSuite`, `OpenFiles`, and `CloseFiles` in `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl`. Newer scripts such as `bin/buildSVUnit` and `bin/runSVUnit` use lowercase helpers like `usage`, `clean`, and `getUnittests`.

**Variables:**
- Use lower_snake_case for local variables across SystemVerilog and Python: `error_count`, `current_junit_test_case`, `tmp_path`, `datafiles`, `simulator`.
- Keep the canonical SVUnit handle names `name` and `svunit_ut` inside test modules; see `src/test/sv/string_utils_unit_test.sv` and the generated skeleton in `test/templates/class_unit_test.gold`.
- Keep framework-wide macros and enum values uppercase: `FAIL_IF`, `FAIL_UNLESS_EQUAL`, `SVUNIT_TESTS_BEGIN`, `PASS`, and `FAIL` in `svunit_base/svunit_defines.svh` and `svunit_base/svunit_types.svh`.
- Perl scripts use descriptive sigiled globals such as `$output_file`, `$run_self_registered_tests`, `@files_to_add`, and `@tests`.

**Types:**
- Use lower_snake_case for core SystemVerilog classes and packages: `svunit_base`, `svunit_testcase`, `svunit_testsuite`, `test_registry`, `testcase`, and `full_name_extraction` in `svunit_base/` and `src/experimental/sv/`.
- Use PascalCase only where the XML helper API or a third-party package already establishes it, for example `junit_xml::TestCase`, `junit_xml::TestSuite`, and `XmlElement` in `svunit_base/junit-xml/`.
- Prefer suffixes that explain role: `_testcase`, `_testsuite`, `_testrunner`, `_mock`, `_pkg`, and `_types`.

## Code Style

**Formatting:**
- Follow `.editorconfig`: spaces everywhere, 4-space indentation by default, 2 spaces for `*.sv` and `*.svh`, LF line endings, trimmed trailing whitespace, and final newline.
- No formatter configuration was detected for Perl, Python, shell, or SystemVerilog. Match surrounding hand formatting instead of introducing a new style into an existing file.
- In `svunit_base/*.sv`, separate lifecycle sections with blank lines and banner comments, keep `class`, `function`, and `task` headers on one line, and indent bodies by two spaces.
- In Python files such as `test/utils.py` and `test/test_run_script.py`, use PEP 8 style spacing and 4-space indentation, but do not normalize away established patterns like `from utils import *` in the test tree.
- Generated SystemVerilog templates in `test/templates/*.gold` are part of the public style surface. If `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, or `bin/create_testrunner.pl` changes output, keep the section banners and placeholder comments aligned with those goldens.

**Linting:**
- No lint configuration was detected for Python, shell, Perl, or SystemVerilog: `.flake8`, `ruff.toml`, `mypy.ini`, `perlcriticrc`, `shellcheckrc`, ESLint, and Prettier configs are absent at repo root.
- The practical quality gate is executable regression coverage. `.github/workflows/*` installs `test/requirements.txt`, enters `test/`, and runs `pytest`.
- Because style is not machine-enforced, follow local style exactly when editing old generator scripts or framework classes.

## Import Organization

**Order:**
1. SystemVerilog `` `include `` directives for macros or direct source inclusion, usually at file top, as in `svunit_base/svunit_pkg.sv` and `examples/classes/mock/client_unit_test.sv`.
2. Package or symbol imports immediately inside the `module`, `package`, or `class`, for example `import svunit_pkg::svunit_testcase;` and `import svunit::test_registry;`.
3. Local declarations, then `build/setup/teardown/run` implementations or `SVTEST` blocks.

**Grouping:**
- Keep related `` `include `` lines contiguous and above the declaration they support. `test/templates/class_unit_test.gold` and `src/experimental/sv/svunit.sv` are the clearest examples.
- In Python, group standard-library imports first, third-party imports next, and local helpers last. `test/utils.py` and `test/test_example.py` follow this loosely.
- The Python tests rely on `from utils import *` throughout `test/test_*.py`. Match that only when adding another regression file under `test/`; do not spread wildcard imports into unrelated Python code.

**Path Aliases:**
- No path alias system is used.
- Shell and Perl scripts rely on `PATH` and `SVUNIT_INSTALL`, as shown in `README.md`, `Setup.bsh`, `Setup.csh`, `bin/buildSVUnit`, and `bin/runSVUnit`.
- SystemVerilog discovery relies on `+incdir+` and `-f` entries written into `.svunit.f` by `bin/buildSVUnit`.

## Error Handling

**Patterns:**
- In SystemVerilog, route assertion failures through the macros in `svunit_base/svunit_defines.svh`. They delegate to `svunit_base/svunit_testcase.sv::fail`, increment `error_count`, add JUnit failure data, emit an `ERROR:` log, and stop the active test with `give_up()`.
- Use `$fatal` only for framework invariants or unsupported internal states. Examples include `src/experimental/sv/testsuite.svh` and `src/experimental/sv/test_registry.svh`.
- In Perl CLIs, validate arguments early, print a human-readable `ERROR:` or usage message, and exit non-zero. File I/O failures still use `die`, as in `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl`.
- `bin/runSVUnit` is the clearest command-line error model: it defines `INTERNAL_EXECUTION_ERROR => 3` and `CMDLINE_USAGE_ERROR => 4`, rejects unsupported combinations early, and exits with those codes.
- Python tests use `subprocess.check_call()` for success-path assertions and `subprocess.call()` or `subprocess.run()` when the exit code itself is part of the contract, as in `test/test_run_script.py` and `test/test_frmwrk.py`.

**Error Types:**
- `die` or exit on unreadable files and failed open/close operations in the Perl generators.
- Return specific command-line usage errors in `bin/runSVUnit` for unsupported modes such as Verilator + UVM, Verilator + VHDL, or absolute `--directory` paths.
- Treat simulator incompatibilities as test skips in Python rather than framework errors; examples appear in `test/test_sim.py`, `test/test_util.py`, `test/test_example.py`, and `test/test_wavedrom.py`.

## Logging

**Framework:**
- SystemVerilog logging is standardized through `` `INFO ``, `` `ERROR ``, and `` `LF `` in `svunit_base/svunit_defines.svh`.
- Perl scripts print progress with a `SVUNIT:` prefix in `bin/create_testsuite.pl`, `bin/create_testrunner.pl`, and `bin/runSVUnit`.
- Python regression tests use plain `print()` only for scenario narration in `test/test_run_script.py` and `test/test_sim.py`; there is no structured Python logger.

**Patterns:**
- Preserve the exact `INFO:  [time][name]: message` and `ERROR: [time][name]: message` formats because the Python suite parses `run.log` with regexes in `test/utils.py` and `test/test_sim.py`.
- Let the testrunner own summary reporting. `svunit_base/svunit_testsuite.sv` and `svunit_base/svunit_testrunner.sv` emit PASS/FAIL summaries and write `tests.xml`.
- `bin/runSVUnit` prints the fully expanded simulator command before execution. Keep that behavior when changing invocation logic because debugging and regression expectations depend on it.

## Comments

**When to Comment:**
- Use banner comments to separate lifecycle phases and generated sections in SystemVerilog test modules. The canonical examples are `test/templates/class_unit_test.gold` and `examples/uvm/uvm_express/apb_coverage_agent_unit_test.sv`.
- In framework classes under `svunit_base/`, prefer NaturalDocs-style block comments that name the class, method, parameters, or variable purpose.
- Comment simulator-specific caveats inline where behavior diverges. Examples: the coverage caveat in `examples/uvm/uvm_express/apb_coverage_agent_unit_test.sv` and dynamic-array comments in `svunit_base/svunit_testcase.sv`, `src/experimental/sv/testcase.svh`, and `src/test/sv/string_utils_unit_test.sv`.
- In Python tests, comments are sparse and usually explain a skip, a known gap, or a test intent. Keep them short and tied to the fixture behavior.

**JSDoc/TSDoc:**
- Not applicable. This repo uses NaturalDocs-style comments in SystemVerilog and ordinary comments/docstrings in Python.
- Python docstrings are uncommon; `test/utils.py::working_directory` is the current minimal style.

**TODO Comments:**
- TODOs are plain `TODO` comments without owner tags or issue references, for example in `bin/runSVUnit`, `src/experimental/sv/full_name_extraction.svh`, `test/test_example.py`, and `test/test_sim.py`.
- If you add a TODO, keep it short, describe the broken behavior concretely, and place it next to the affected branch.

## Function Design

**Size:**
- Keep SystemVerilog lifecycle hooks small and push test logic into discrete `SVTEST` blocks. `src/test/sv/string_utils_unit_test.sv` and `examples/classes/mock/client_unit_test.sv` are the baseline.
- Generator scripts are still large procedural files. When editing `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, or `bin/create_testrunner.pl`, prefer adding narrowly scoped subs over expanding the main linear flow further.
- Python regression helpers are centralized in `test/utils.py`; add reusable subprocess or log helpers there instead of duplicating them across `test/test_*.py`.

**Parameters:**
- SystemVerilog APIs frequently use explicit `input` directions and typed parameters, as in `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testrunner.sv`, and `svunit_base/junit-xml/*.svh`.
- Python helper functions prefer short positional parameter lists with descriptive names, such as `expect_passing_example(dir, sim, args=[])` and `verify_testrunner(testrunner, ts0, ts1='', ts2='', ts3='', tr='')` in `test/utils.py`.
- Perl CLIs parse options into globals and arrays rather than passing configuration objects.

**Return Values:**
- SystemVerilog functions return status or collections explicitly and use guard clauses for invalid internal states, for example `get_results()`, `get_testcases()`, and `get_testsuites()`.
- Python tests assert side effects rather than returning values.
- Perl helpers commonly signal failure by printing and exiting instead of bubbling errors through multiple layers.

## Module Design

**Exports:**
- `svunit_base/svunit_pkg.sv` is the stable package entry point for framework consumers. Add new stable framework types there when they belong in the public package.
- `src/experimental/sv/svunit.sv` is the experimental aggregation point. New experimental DSL pieces belong there, not in `svunit_base/`.
- Python shared helpers live in `test/utils.py`; test files do not define a broader public API.

**Barrel Files:**
- SystemVerilog packages act as barrel files through `` `include `` aggregation: `svunit_base/svunit_pkg.sv`, `svunit_base/uvm-mock/svunit_uvm_mock_pkg.sv`, and `src/experimental/sv/svunit.sv`.
- There are no Python barrel modules beyond `test/utils.py`.

## Code Generation Patterns

- Treat `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl` as the canonical source of generated SystemVerilog structure. The golden expectations in `test/templates/*.gold` show the required output shape.
- `bin/buildSVUnit` generates transient discovery/build artifacts in the run directory: `.svunit.f`, `.<dir>_testsuite.sv`, and `.testrunner.sv`.
- `bin/wavedromSVUnit.py` is the only Python-based code generator; it scans JSON files in the current directory and emits per-method `.svh` files plus a top-level `wavedrom.svh`.
- Preserve generated section banners, naming, and placeholder comments when updating generators. `test/test_frmwrk.py` compares generator output to `test/templates/*.gold` with whitespace-insensitive diffing.

## Contributor Expectations

- Initialize the repo environment through `Setup.bsh` or `Setup.csh`, or export `SVUNIT_INSTALL` and add `bin/` to `PATH` as described in `README.md`.
- For host-side regression work, follow `test/README`: Python 3.6+ virtual environment, `pip install -r test/requirements.txt`, then run `pytest` from `test/`. The `test/` directory also contains a `.envrc` used by the existing direnv-based workflow.
- Expect simulator-sensitive behavior. Many tests and examples only run meaningfully when one of `irun`, `xrun`, `vcs`, `vlog`, `dsim`, `qrun`, `verilator`, or `xsim` is on `PATH`; detection lives in `test/utils.py`.
- Keep backward compatibility with older simulators and shells. Support code exists for `bash`, `csh`, and `tcsh` in `Setup.bsh`, `Setup.csh`, and `test/frmwrk_14/run.csh`.

---

*Convention analysis: 2026-04-11*
*Update when patterns change*
