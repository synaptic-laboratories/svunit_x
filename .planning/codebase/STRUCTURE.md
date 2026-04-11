# Codebase Structure

**Analysis Date:** 2026-04-11

## Directory Layout

```text
svunit_x/
├── bin/                    # User-facing generators, builders, runners, and helper scripts
├── docs/                   # Sphinx documentation source and docs build config
├── examples/               # Runnable sample projects for classes, modules, UVM, and experimental APIs
├── src/                    # Experimental runtime plus internal SystemVerilog tests
│   ├── experimental/sv/    # Self-registering experimental SVUnit implementation
│   ├── test/sv/            # Stable-runtime compatibility tests for library internals
│   └── testExperimental/sv/# Tests for experimental registry and macro behavior
├── sv_test/                # Harness that clones stable upstream SVUnit and runs src/* tests against it
├── svunit_base/            # Stable shipped runtime package and optional helper subpackages
│   ├── junit-xml/          # JUnit XML support classes
│   ├── util/               # Reusable helper includes such as clock/reset helpers
│   └── uvm-mock/           # UVM mock and reporting support
├── test/                   # Pytest regression suite, fixtures, goldens, and simulator scenarios
├── .github/workflows/      # CI automation
├── Setup.bsh               # Bash environment bootstrap
├── Setup.csh               # csh environment bootstrap
├── Setup.zsh               # zsh environment bootstrap
└── README.md               # User-facing entry documentation
```

## Directory Purposes

**`bin/`:**
- Purpose: Houses the commands users and tests actually invoke.
- Contains: `bin/runSVUnit`, `bin/buildSVUnit`, `bin/create_unit_test.pl`, `bin/create_testsuite.pl`, `bin/create_testrunner.pl`, `bin/cleanSVUnit`, `bin/wavedromSVUnit.py`, `bin/create_docs.sh`.
- Key files: `bin/runSVUnit` is the main entry point; `bin/buildSVUnit` owns harness generation; `bin/create_unit_test.pl` owns wrapper scaffolding.
- Subdirectories: None. This is a flat command directory.

**`svunit_base/`:**
- Purpose: Stores the stable SystemVerilog runtime shipped to users.
- Contains: Package assembly in `svunit_base/svunit_pkg.sv`, base/result classes, macros, filter/string helpers, and optional extensions.
- Key files: `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_defines.svh`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`.
- Subdirectories: `svunit_base/junit-xml/` for XML reporting, `svunit_base/util/` for helper includes, `svunit_base/uvm-mock/` for UVM-specific support.

**`src/`:**
- Purpose: Separates in-progress or internal framework work from the stable shipped runtime.
- Contains: Experimental implementation in `src/experimental/sv/` and internal validation code in `src/test/sv/` and `src/testExperimental/sv/`.
- Key files: `src/experimental/sv/svunit.sv`, `src/experimental/sv/svunit.svh`, `src/experimental/sv/svunit_main.sv`, `src/test/sv/string_utils_unit_test.sv`, `src/testExperimental/sv/test_registry_unit_test.sv`.
- Subdirectories: `src/experimental/sv/` mirrors a small runtime package; `src/test/sv/` and `src/testExperimental/sv/` are SVUnit-based internal tests rather than library code.

**`examples/`:**
- Purpose: Shows supported usage patterns and acts as user-facing navigation for common flows.
- Contains: Sample projects under `examples/classes/`, `examples/modules/`, `examples/uvm/`, and `examples/experimental/`.
- Key files: `examples/README`, `examples/all.f`, `examples/modules/apb_slave/apb_slave_unit_test.sv`, `examples/modules/wavedrom/svunit.f`, `examples/uvm/uvm_express/README`.
- Subdirectories: `examples/classes/mock/` for class mocking, `examples/modules/*` for RTL/module flows, `examples/uvm/*` for UVM flows, `examples/experimental/*` for the new self-registering API.

**`test/`:**
- Purpose: Holds the main regression suite for scripts, simulator invocation, fixtures, and generated text.
- Contains: Pytest modules such as `test/test_frmwrk.py`, `test/test_run_script.py`, `test/test_sim.py`, fixture trees like `test/frmwrk_23/` and `test/sim_12/`, and golden templates in `test/templates/`.
- Key files: `test/README`, `test/pytest.ini`, `test/utils.py`, `test/test_frmwrk.py`, `test/test_run_script.py`.
- Subdirectories: Scenario directories are grouped by concern, including `test/frmwrk_*`, `test/sim_*`, `test/junit-xml/`, `test/wavedrom_*`, `test/mock_uvm_report*`, and `test/templates/`.

**`sv_test/`:**
- Purpose: Runs internal SV tests against a cloned stable SVUnit release to avoid package-name collisions and validate compatibility.
- Contains: `sv_test/run` and `sv_test/svunit.f`.
- Key files: `sv_test/run` clones, rewrites, and executes the reference harness; `sv_test/svunit.f` includes both `../svunit_base` and `../src/experimental/sv`.
- Subdirectories: None in the committed tree. A generated `sv_test/svunit/` clone appears only when `sv_test/run` is executed.

**`docs/`:**
- Purpose: Stores Sphinx-based documentation source and build tooling.
- Contains: `docs/Makefile`, `docs/make.bat`, `docs/source/*.rst`, `docs/source/conf.py`, `docs/user_guide_files/`.
- Key files: `docs/source/index.rst`, `docs/source/structure_and_workflow.rst`, `docs/source/creating_a_unit_test_template.rst`, `docs/source/running_unit_tests.rst`.
- Subdirectories: `docs/source/` is the authored source tree; `docs/user_guide_files/` stores image assets; `docs/build/` is generated and ignored.

**`.github/workflows/`:**
- Purpose: Defines repository automation.
- Contains: `ci.yml`.
- Key files: `.github/workflows/ci.yml` installs Verilator and Python, then runs the pytest suite from `test/`.
- Subdirectories: None beyond workflow YAMLs.

**`.codex/` and `.planning/`:**
- Purpose: Workspace automation and generated planning artifacts for GSD/Codex workflows, not SVUnit runtime behavior.
- Contains: Templates, skills, commands, and generated mapping documents such as `.planning/codebase/`.
- Key files: `.codex/get-shit-done/templates/codebase/architecture.md`, `.codex/get-shit-done/templates/codebase/structure.md`.
- Subdirectories: These areas are tooling metadata; avoid placing framework source here.

## Key File Locations

**Entry Points:**
- `README.md`: First-stop user workflow and setup instructions.
- `Setup.bsh`: Bash bootstrap for `SVUNIT_INSTALL` and `PATH`.
- `Setup.csh`: csh bootstrap for `SVUNIT_INSTALL` and `PATH`.
- `Setup.zsh`: zsh bootstrap for `SVUNIT_INSTALL` and `PATH`.
- `bin/create_unit_test.pl`: Scaffolds new `*_unit_test.sv` files.
- `bin/runSVUnit`: Main command that users run to build and execute tests.
- `bin/buildSVUnit`: Lower-level builder that generates hidden harness files.
- `sv_test/run`: Developer-only compatibility harness for `src/test/sv/` and `src/testExperimental/sv/`.
- `docs/Makefile`: Documentation build entry point.

**Configuration:**
- `.github/workflows/ci.yml`: Continuous integration pipeline.
- `.readthedocs.yaml`: Read the Docs configuration.
- `docs/source/conf.py`: Sphinx configuration.
- `test/pytest.ini`: Pytest marker declaration.
- `test/requirements.txt`: Python test dependencies.
- `sv_test/svunit.f`: Internal compatibility filelist for mixed stable and experimental runtime compilation.

**Core Logic:**
- `bin/runSVUnit`: Simulator adaptation and end-to-end orchestration.
- `bin/buildSVUnit`: Discovery and hidden harness generation.
- `bin/create_testsuite.pl`: Directory-level suite generation.
- `bin/create_testrunner.pl`: Top-level testrunner generation.
- `bin/create_unit_test.pl`: User-facing wrapper generation.
- `svunit_base/svunit_pkg.sv`: Stable package assembly and include root.
- `svunit_base/svunit_defines.svh`: Runtime macros for assertions, logging, and lifecycle.
- `src/experimental/sv/svunit.sv`: Experimental package entry.
- `src/experimental/sv/test.svh`: Experimental self-registering test abstraction.

**Testing:**
- `test/`: Main Python regression suite and fixtures.
- `test/templates/`: Golden templates for generated wrapper, suite, and testrunner output.
- `src/test/sv/`: Stable-runtime compatibility tests for internal library behavior.
- `src/testExperimental/sv/`: Experimental runtime tests.
- `examples/`: End-user smoke/regression examples referenced by tests like `test/test_example.py`.

**Documentation:**
- `README.md`: Basic setup and quickstart.
- `CHANGELOG.md`: Release notes.
- `CONTRIBUTING.md`: Developer environment expectations.
- `docs/source/*.rst`: Full user guide chapters.
- `examples/*/README`: Feature-specific runnable examples.

## Naming Conventions

**Files:**
- Use `*_unit_test.sv` for stable SVUnit wrapper modules. Examples: `examples/modules/apb_slave/apb_slave_unit_test.sv`, `test/sim_13/dut_unit_test.sv`.
- Use the `svunit_*` prefix for stable shipped runtime files in `svunit_base/`. Examples: `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_testcase.sv`.
- Use hidden dot-prefixed names for generated harness artifacts. Examples: `.svunit.f`, `.testrunner.sv`, `.__subdir_testsuite.sv` patterns from `bin/buildSVUnit`.
- Use `svunit.f` or other `*.f` manifests for compile filelists. Examples: `examples/modules/wavedrom/svunit.f`, `examples/all.f`, `examples/uvm/uvm_express/cov.f`.
- Use `test_*.py` for pytest modules and `test_*.svh` or `*_test.sv` for experimental SystemVerilog tests. Examples: `test/test_run_script.py`, `examples/experimental/single_test_suite/factorial_test.sv`, `examples/experimental/multiple_test_classes/src/test/sv/test_queue.svh`.

**Directories:**
- Top-level directories are purpose-based, not layer-numbered. Use `bin/`, `svunit_base/`, `src/`, `examples/`, `test/`, and `docs/` according to responsibility.
- Example directories are grouped by domain under `examples/classes/`, `examples/modules/`, `examples/uvm/`, and `examples/experimental/`.
- Regression fixture directories under `test/` use scenario prefixes plus numeric suffixes, such as `test/frmwrk_23`, `test/sim_12`, and `test/wavedrom_1`.
- SystemVerilog source roots in `src/` use the `sv/` suffix, as in `src/experimental/sv/`, `src/test/sv/`, and `src/testExperimental/sv/`.

**Special Patterns:**
- Keep example-specific documentation next to the example directory, as in `examples/modules/apb_slave/README` and `examples/uvm/simple_model/README`.
- Keep simulator-specific manifests explicitly named when they differ from the default, as in `examples/uvm/simple_model/svunit-riviera.f`.
- Treat files under `test/templates/` as text goldens for regression assertions, not executable runtime sources.

## Where to Add New Code

**New Feature:**
- Stable end-user behavior in the shipped framework belongs in `svunit_base/` if it affects runtime semantics, or in `bin/` if it affects generation/build/run workflow.
- End-to-end regression coverage belongs in `test/`, usually as a new `test/test_*.py` case plus a focused fixture directory under `test/`.
- User-facing documentation for the feature belongs in `README.md`, `docs/source/*.rst`, or an example README under `examples/`.

**New Component/Module:**
- New stable runtime primitives belong in `svunit_base/` and must be wired into `svunit_base/svunit_pkg.sv`.
- New experimental primitives belong in `src/experimental/sv/` and should be covered from `src/testExperimental/sv/`.
- New helper includes that users may import directly belong in `svunit_base/util/` or `svunit_base/uvm-mock/`, depending on whether the feature is generic or UVM-specific.

**New Command / Generator Behavior:**
- Command implementation belongs in `bin/`, keeping the current flat-tool layout.
- Behavior changes to generation or run flow should usually be regression-tested in `test/test_frmwrk.py`, `test/test_run_script.py`, or `test/test_sim.py`.
- If the command changes the documented workflow, update `docs/source/creating_a_unit_test_template.rst`, `docs/source/running_unit_tests.rst`, or `README.md`.

**Utilities:**
- Shared SystemVerilog helpers belong in `svunit_base/util/`.
- Test-only Python helpers belong in `test/utils.py` or adjacent pytest support code, not in `bin/`.
- Developer-only compatibility tooling belongs in `sv_test/`.

## Special Directories

**`docs/build/`:**
- Purpose: Generated Sphinx output.
- Source: Built from `docs/Makefile` and `docs/source/`.
- Committed: No.

**`sv_test/svunit/`:**
- Purpose: Cloned stable upstream SVUnit used by `sv_test/run` for compatibility testing.
- Source: Generated by `sv_test/run`.
- Committed: No.

**Working-directory simulator outputs such as `work/`, `INCA_libs/`, `obj_dir/`, and `xsim.dir/`:**
- Purpose: Tool-specific compilation and run artifacts created during `runSVUnit`.
- Source: External simulators and helper scripts like `bin/runSVUnit` and `bin/cleanSVUnit`.
- Committed: No.

**Generated hidden harness files such as `.svunit.f`, `.testrunner.sv`, and `.*_testsuite.sv`:**
- Purpose: Intermediate build products that connect discovered tests to the stable runtime.
- Source: Generated by `bin/buildSVUnit`, `bin/create_testsuite.pl`, and `bin/create_testrunner.pl`.
- Committed: No.

**`.codex/` and `.planning/`:**
- Purpose: Local workflow metadata and generated analysis artifacts for Codex/GSD automation.
- Source: Repo tooling and mapper workflows.
- Committed: No.

---

*Structure analysis: 2026-04-11*
