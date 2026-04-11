# Architecture

**Analysis Date:** 2026-04-11

## Pattern Overview

**Overall:** File-system-driven SystemVerilog unit-test framework with generated harnesses, simulator adapters, and an experimental self-registering API.

**Key Characteristics:**
- User-facing execution starts from shell bootstrap scripts like `Setup.bsh`, `Setup.csh`, and `Setup.zsh`, then flows through command tools in `bin/`.
- The standard runtime is generated around discovered `*_unit_test.sv` files: `bin/buildSVUnit` emits hidden suite and runner files, and `bin/runSVUnit` compiles them with a chosen simulator.
- Stable framework primitives live in `svunit_base/`, while a newer self-registering model is isolated in `src/experimental/sv/`.
- Verification of the framework itself is layered outside the shipped runtime: `test/` provides pytest regressions, `sv_test/run` builds a compatibility harness, and `docs/source/` documents the intended workflow.

## Layers

**Bootstrap Layer:**
- Purpose: Establish the repo as an installed SVUnit toolchain for the current shell session.
- Location: `Setup.bsh`, `Setup.csh`, `Setup.zsh`, and usage notes in `README.md`.
- Contains: Environment-variable setup for `SVUNIT_INSTALL` and `PATH`.
- Depends on: The repository root being the current directory.
- Used by: Developers, examples, regression tests, and CI before invoking `bin/runSVUnit` or `bin/create_unit_test.pl`.

**Command and Generator Layer:**
- Purpose: Turn user source files into runnable SVUnit harnesses.
- Location: `bin/create_unit_test.pl`, `bin/buildSVUnit`, `bin/create_testsuite.pl`, `bin/create_testrunner.pl`, and `bin/cleanSVUnit`.
- Contains: Template generation, recursive discovery, filelist assembly, hidden harness generation, and cleanup logic.
- Depends on: Naming conventions such as `*_unit_test.sv`, optional `svunit.f` manifests, and the stable runtime in `svunit_base/svunit_pkg.sv`.
- Used by: `bin/runSVUnit`, contributors in `test/test_frmwrk.py`, and end users following `README.md`.

**Simulator Orchestration Layer:**
- Purpose: Normalize simulator selection and execute compile/run commands.
- Location: `bin/runSVUnit`.
- Contains: Command-line parsing, simulator name normalization, optional UVM/Wavedrom/experimental switches, and simulator-specific command construction.
- Depends on: `bin/buildSVUnit`, generated `.svunit.f`, external simulator binaries on `PATH`, and optional VHDL/filelist inputs.
- Used by: End users, examples in `examples/`, pytest regressions in `test/test_run_script.py` and `test/test_sim.py`, and CI in `.github/workflows/ci.yml`.

**Stable Runtime Layer:**
- Purpose: Provide the object model and macros that actually execute and report tests.
- Location: `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_defines.svh`, `svunit_base/svunit_base.sv`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`.
- Contains: Assertion macros, lifecycle macros, pass/fail aggregation, JUnit XML emission, string/filter helpers, and optional UVM/util support.
- Depends on: SystemVerilog simulation and supporting include paths assembled by `bin/buildSVUnit`.
- Used by: Generated `*_unit_test.sv` modules, examples under `examples/`, compatibility tests in `src/test/sv`, and experimental code in `src/experimental/sv/svunit.sv`.

**Optional Integration Layer:**
- Purpose: Add specialized behavior without changing the core test model.
- Location: `svunit_base/junit-xml/`, `svunit_base/uvm-mock/`, `svunit_base/util/`, and `bin/wavedromSVUnit.py`.
- Contains: JUnit XML serialization, UVM mocking/reporting helpers, reusable utility includes, and JSON-to-SystemVerilog Wavedrom generation.
- Depends on: The stable runtime and feature switches passed through `bin/runSVUnit` or explicit `svunit.f` files.
- Used by: `svunit_testrunner::report()` in `svunit_base/svunit_testrunner.sv`, UVM examples in `examples/uvm/`, utility examples in `examples/modules/clk_and_reset/`, and Wavedrom examples in `examples/modules/wavedrom/`.

**Experimental Runtime Layer:**
- Purpose: Offer a self-registering test API that does not rely on directory-scanned `*_unit_test.sv` modules.
- Location: `src/experimental/sv/svunit.sv`, `src/experimental/sv/svunit.svh`, `src/experimental/sv/svunit_main.sv`, `src/experimental/sv/test.svh`, `src/experimental/sv/testcase.svh`, `src/experimental/sv/testsuite.svh`, `src/experimental/sv/test_registry.svh`, `src/experimental/sv/global_test_registry.svh`.
- Contains: `TEST_BEGIN`/`TEST_F_BEGIN` macros, self-registering builders, registry objects, and a package-level `run_all_tests()` entry point.
- Depends on: The stable runtime in `svunit_base/svunit_pkg.sv` for base classes, filters, and reporting.
- Used by: `examples/experimental/`, internal experimental tests in `src/testExperimental/sv/`, and `bin/buildSVUnit --enable-experimental`.

**Verification and Documentation Layer:**
- Purpose: Validate framework behavior and document the intended usage model.
- Location: `test/`, `sv_test/`, `src/test/sv/`, `src/testExperimental/sv/`, `examples/`, and `docs/source/`.
- Contains: Pytest regressions, fixture trees, golden files, example projects, stable-vs-experimental compatibility harnesses, and Sphinx docs.
- Depends on: The command layer, the stable runtime, and external simulators.
- Used by: Contributors, CI, and future changes to `bin/`, `svunit_base/`, or `src/experimental/sv/`.

## Data Flow

**Standard CLI-Driven Unit-Test Flow:**

1. A user initializes the environment with `Setup.bsh`, `Setup.csh`, or `Setup.zsh`, or manually sets `SVUNIT_INSTALL` and adds `bin/` to `PATH` as shown in `README.md`.
2. The user creates or edits one or more `*_unit_test.sv` modules, commonly by starting from `bin/create_unit_test.pl`.
3. Optional project-specific manifests such as `svunit.f`, `svunit-riviera.f`, `all.f`, or extra `-f` filelists add include paths and supporting RTL, as shown in `examples/` and `test/sim_*`.
4. `bin/runSVUnit` parses CLI switches, chooses or infers a simulator, normalizes names like `questa` to `modelsim` and `xcelium` to `xrun`, and constructs a simulator command.
5. Before simulation, `bin/runSVUnit` invokes `bin/buildSVUnit -o <dir>` to build the transient harness in the selected run directory.
6. `bin/buildSVUnit` writes `.svunit.f`, injects `svunit_base/junit-xml/junit_xml.sv` and `svunit_base/svunit_pkg.sv`, optionally injects `svunit_base/uvm-mock/svunit_uvm_mock_pkg.sv` or `src/experimental/sv/svunit.sv`, and recursively discovers `svunit.f` files and `*_unit_test.sv` modules.
7. For each directory containing discovered tests, `bin/create_testsuite.pl` generates a hidden `.*_testsuite.sv`; after discovery completes, `bin/create_testrunner.pl` generates `.testrunner.sv`.
8. The simulator compiles `.svunit.f` and runs the generated top-level `testrunner` module assembled by `bin/create_testrunner.pl`.
9. At runtime, `svunit_testcase`, `svunit_testsuite`, and `svunit_testrunner` in `svunit_base/` track lifecycle, pass/fail state, console output, and final `tests.xml` generation.

**Experimental Self-Registering Flow:**

1. Compilation includes `src/experimental/sv/svunit.sv`, either through `bin/buildSVUnit --enable-experimental` or explicit manifests like `sv_test/svunit.f`.
2. Experimental tests include `src/experimental/sv/svunit.svh`; `TEST_BEGIN`, `TEST_END`, `TEST_F_BEGIN`, and `TEST_F_END` expand into concrete classes derived from `svunit::test`.
3. Static builders in `src/experimental/sv/test.svh` register themselves through `src/experimental/sv/global_test_registry.svh` into `src/experimental/sv/test_registry.svh`.
4. `src/experimental/sv/svunit_main.sv` or the self-registered branch emitted by `bin/create_testrunner.pl --run-self-registered-tests` retrieves testsuites from the registry and runs them through the stable `svunit_testrunner`.

**Framework Self-Test Flow:**

1. Pytest modules in `test/` run CLI tools like `create_unit_test.pl`, `buildSVUnit`, and `runSVUnit` against fixture directories such as `test/frmwrk_23`, `test/sim_12`, and `test/wavedrom_1`.
2. Internal SystemVerilog tests in `src/test/sv/` and `src/testExperimental/sv/` are executed through `sv_test/run`, which clones a stable upstream SVUnit release, renames it to `svunit_stable_*`, and runs the repo’s new code against that reference runtime.
3. CI in `.github/workflows/ci.yml` installs Verilator and Python, then executes the pytest suite from `test/`.

**State Management:**
- Persistent project state is file-based, not service-based. The framework expects source files, manifests, and include paths to live in the user’s working tree.
- Run-specific state is ephemeral. Generated files such as `.svunit.f`, `.*_testsuite.sv`, `.testrunner.sv`, `run.log`, `compile.log`, `tests.xml`, and simulator work directories are written into the current directory or the `-o` directory and are ignored by `.gitignore`.
- In-simulation state is object-local. `svunit_testcase` owns error counts and running state, `svunit_testsuite` owns testcase collections, and `svunit_testrunner` owns suite aggregation. The experimental path adds a singleton registry in `src/experimental/sv/global_test_registry.svh`.

## Key Abstractions

**Generated Unit-Test Module:**
- Purpose: Wrap one class, module, or interface under test in a conventional SVUnit module shell.
- Examples: User-created files like `examples/modules/apb_slave/apb_slave_unit_test.sv`, `test/mock_uvm_report/basic_unit_test.sv`, and templates emitted by `bin/create_unit_test.pl`.
- Pattern: Module wrapper plus `svunit_testcase` instance, explicit `build()/setup()/teardown()`, and `SVUNIT_TESTS_BEGIN` / `SVTEST` / `SVTEST_END` macros.

**Testcase / Testsuite / Testrunner Object Model:**
- Purpose: Aggregate results from individual assertions up to testcase, suite, and whole-run status.
- Examples: `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`.
- Pattern: Small inheritance hierarchy rooted at `svunit_base/svunit_base.sv`, with queues of child objects and late reporting.

**Filelist Manifest:**
- Purpose: Define what gets compiled in addition to the auto-generated SVUnit harness.
- Examples: `svunit.f` files in user projects, `examples/all.f`, `examples/uvm/uvm_express/cov.f`, `sv_test/svunit.f`, and generated `.svunit.f`.
- Pattern: Flat compile manifest with `+incdir+` directives and source-file paths consumed by `bin/runSVUnit`.

**Experimental Test Builder Registry:**
- Purpose: Decouple test declaration from directory-scanned wrapper modules.
- Examples: `src/experimental/sv/test.svh`, `src/experimental/sv/test_registry.svh`, `src/experimental/sv/testsuite.svh`.
- Pattern: Static builder registration into a singleton registry, followed by runtime suite/testcase materialization.

**Feature-Specific Runtime Extensions:**
- Purpose: Keep optional integrations separate from the stable core.
- Examples: `svunit_base/uvm-mock/svunit_uvm_mock_pkg.sv`, `svunit_base/util/clk_and_reset.svh`, `svunit_base/junit-xml/junit_xml.sv`, `bin/wavedromSVUnit.py`.
- Pattern: Opt-in include path and filelist additions controlled by flags or project manifests.

## Entry Points

**Shell Bootstrap:**
- Location: `Setup.bsh`, `Setup.csh`, `Setup.zsh`
- Triggers: Developer shells, local editor sessions, and any workflow that needs `SVUNIT_INSTALL` and repo `bin/` on `PATH`.
- Responsibilities: Export `SVUNIT_INSTALL` and make the CLI scripts reachable.

**Template Generator:**
- Location: `bin/create_unit_test.pl`
- Triggers: Manual user invocation when starting or scaffolding a new unit-test wrapper.
- Responsibilities: Parse a Verilog/SystemVerilog file or explicit name, infer the UUT kind, and emit a `*_unit_test.sv` template.

**Standard Test Runner:**
- Location: `bin/runSVUnit`
- Triggers: User test runs, example README commands, pytest regression calls, and CI.
- Responsibilities: Parse flags, infer/select simulator, invoke `buildSVUnit`, and run the generated harness.

**Harness Builder:**
- Location: `bin/buildSVUnit`
- Triggers: Direct developer invocation or indirect invocation from `bin/runSVUnit`.
- Responsibilities: Build `.svunit.f`, gather manifests, generate hidden suites, and emit `.testrunner.sv`.

**Experimental HDL Main:**
- Location: `src/experimental/sv/svunit_main.sv`
- Triggers: Experimental flows that want a pure-SystemVerilog top module without the classic generated harness.
- Responsibilities: Call `svunit::run_all_tests()`.

**Compatibility Harness:**
- Location: `sv_test/run`
- Triggers: Internal framework development when validating `src/test/sv/` and `src/testExperimental/sv/`.
- Responsibilities: Clone a stable upstream SVUnit, rename its package/files to `svunit_stable_*`, and execute the repo’s internal SV tests against it.

**Documentation Build:**
- Location: `docs/Makefile`
- Triggers: Manual Sphinx builds and Read the Docs.
- Responsibilities: Route `make` targets to `sphinx-build` for `docs/source/`.

## Error Handling

**Strategy:** Fail fast in scripts, propagate simulator/tool errors upward, and convert assertion failures into structured testcase/suite/runner status inside the simulation.

**Patterns:**
- `bin/runSVUnit` validates CLI combinations, returns dedicated usage/internal error codes, and stops immediately if `buildSVUnit` or the simulator command fails.
- `bin/buildSVUnit`, `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl` enforce required arguments and stop on missing files or invalid output targets.
- `svunit_base/svunit_defines.svh` routes `FAIL_IF`, `FAIL_UNLESS`, and related macros through `svunit_pkg::current_tc.fail(...)`, increments error state, and aborts the current test body through `give_up()`.
- `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, and `svunit_base/svunit_testrunner.sv` aggregate status in `report()` rather than throwing simulator exceptions for every failure.
- The experimental code in `src/experimental/sv/testsuite.svh` and `src/experimental/sv/test_registry.svh` uses `$fatal` for structural inconsistencies such as unsupported nesting or failed casts.

## Cross-Cutting Concerns

**Logging:** Console logging is standardized through `INFO`, `ERROR`, and `LF` macros in `svunit_base/svunit_defines.svh`. `bin/runSVUnit` also prints the final simulator command string, and runs typically emit `run.log`, `compile.log`, and `tests.xml`.

**Validation:** Validation is mostly manual and centralized in scripts. CLI options are checked in `bin/runSVUnit` and `bin/buildSVUnit`; output filename conventions are enforced in `bin/create_unit_test.pl`; runtime structural assumptions are guarded with `$fatal` in `src/experimental/sv/`.

**Authentication:** Not applicable. The framework assumes local filesystem access and simulator binaries already available to the user or CI environment.

---

*Architecture analysis: 2026-04-11*
