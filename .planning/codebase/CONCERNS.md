# Codebase Concerns

**Analysis Date:** 2026-04-11

## Tech Debt

**Runner command construction and cleanup are shell-string based (Confirmed):**
- Files: `bin/runSVUnit`, `bin/buildSVUnit`, `bin/cleanSVUnit`
- Issue: User-controlled values such as `--out`, `--filelist`, `--directory`, `--test`, `--c_arg`, `--r_arg`, and `--mixedsim` are concatenated into shell command strings and executed via `system("$cmd")`.
- Why: The runner scripts are legacy Perl wrappers built around shell pipelines instead of structured process execution.
- Impact: Paths with spaces or shell metacharacters are brittle, Unix tool assumptions leak into the API, and any higher-level tool that forwards untrusted input inherits command-injection risk.
- Fix approach: Replace string-form `system(...)` calls with list-form execution, use Perl filesystem APIs instead of `rm`, `mv`, and `sed -i`, and centralize simulator argument escaping in one helper.

**Supported simulator matrix is defined in multiple places and has drifted (Confirmed):**
- Files: `README.md`, `docs/source/running_unit_tests.rst`, `bin/runSVUnit`, `test/utils.py`, `.github/workflows/ci.yml`
- Issue: The public docs, runtime script, pytest helper, and CI job all advertise or exercise different simulator sets.
- Why: Simulator support grew incrementally, but the repo kept separate documentation and test entrypoints instead of a single canonical matrix.
- Impact: Contributors cannot tell which backends are actively supported, and regressions on non-Verilator simulators can ship without detection.
- Fix approach: Define one source of truth for supported simulators, generate docs from it, and wire CI to reflect that matrix or explicitly mark backends as community-supported only.

**Optional feature paths bypass the normal build flow (Confirmed):**
- Files: `bin/buildSVUnit`, `bin/wavedromSVUnit.py`, `src/experimental/sv/svunit.sv`, `src/experimental/sv/full_name_extraction.svh`, `sv_test/run`
- Issue: WaveDrom generation, experimental self-registered tests, and stable-vs-experimental comparison flow each use separate ad hoc code paths.
- Why: New capabilities were layered on top of the original framework rather than integrated into a shared pipeline.
- Impact: Feature-specific regressions accumulate in corners that the main tests and documentation do not cover well.
- Fix approach: Move feature toggles behind common build interfaces, add contract tests per mode, and remove repo-rewriting setup from `sv_test/run`.

**Developer environment setup mutates the machine implicitly (Likely risk):**
- Files: `.envrc`, `test/.envrc`, `test/requirements.txt`, `CONTRIBUTING.md`
- Issue: Entering `test/` through `direnv` triggers `layout python3` and `pip install -r requirements.txt`.
- Why: The repository optimizes for convenience over reproducibility and explicit environment bootstrapping.
- Impact: Shell entry can write to local environments, require network access, and hide dependency drift until onboarding or CI failures occur.
- Fix approach: Replace implicit install-on-enter with an explicit bootstrap command, or pin a hermetic environment via Nix/uv/virtualenv lockfiles.

## Known Bugs

**`Setup.zsh` prepends the repository root instead of the `bin/` directory (Confirmed):**
- Files: `Setup.zsh`, `Setup.bsh`, `README.md`
- Symptoms: After sourcing `Setup.zsh`, helper commands such as `runSVUnit` and `buildSVUnit` are not guaranteed to be on `PATH`.
- Trigger: A Zsh user follows the repository setup flow via `source Setup.zsh`.
- Workaround: Export `PATH="$SVUNIT_INSTALL/bin:$PATH"` manually instead of relying on `Setup.zsh`.
- Root cause: `Setup.zsh` adds `${SVUNIT_INSTALL}` while `Setup.bsh` and `README.md` use `${SVUNIT_INSTALL}/bin`.

**The shared pytest simulator helper is syntactically invalid (Confirmed):**
- Files: `test/utils.py`
- Symptoms: `test/utils.py` contains `simulators = [$]`, which is not valid Python syntax and would prevent any test importing `utils` from collecting.
- Trigger: Running pytest in an environment where Python is available and test modules import `from utils import *`.
- Workaround: None in-repo; tests depend on this module.
- Root cause: The helper contains a literal invalid list initializer instead of `[]`.

**`test_example_uvm_uvm_express` passes vacuously on most simulators (Confirmed):**
- Files: `test/test_example.py`, `test/utils.py`
- Symptoms: The test only performs assertions for `irun` and `qverilog`, but `all_available_simulators()` never yields `qverilog`; most other simulators make the test return without exercising the example.
- Trigger: Running example tests on `qrun`, `modelsim`, `vcs`, `xrun`, `xsim`, or `verilator`.
- Workaround: None in the test itself; manual runs are required to verify those simulator/example combinations.
- Root cause: The simulator name used in `test/test_example.py` is stale and the test has no fallback assertion.

## Security Considerations

**CLI arguments are interpolated into shell commands (Confirmed):**
- Files: `bin/runSVUnit`, `bin/buildSVUnit`
- Risk: Wrapper scripts or CI jobs that pass unsanitized user input into `runSVUnit` or `buildSVUnit` can trigger unintended shell execution or argument splitting.
- Current mitigation: `bin/runSVUnit` rejects absolute paths for `--directory` and validates a few simulator combinations, but it does not escape arguments before shell execution.
- Recommendations: Treat all CLI fields as untrusted, switch to list-form child-process APIs, and add regression tests for spaces, quotes, and shell metacharacters in file paths and arguments.

**Cleanup commands delete generic artifacts from the current working directory (Confirmed):**
- Files: `bin/runSVUnit`, `bin/cleanSVUnit`
- Risk: Running cleanup from the wrong directory can remove unrelated local artifacts such as `run.log`, `compile.log`, `work`, `INCA_libs`, `xsim.dir`, `simv`, and generated `xsim*.*` files.
- Current mitigation: Cleanup targets a bounded set of filenames, but the default scope is still the caller's current directory and the default output directory is `.`.
- Recommendations: Confine cleanup to an explicit workspace under `--out`, refuse to run destructive cleanup outside that workspace, and replace shell globs with explicit path checks.

**Dependency installation is networked and unhashed during development (Likely risk):**
- Files: `test/.envrc`, `test/requirements.txt`, `.github/workflows/ci.yml`
- Risk: `pip install -r test/requirements.txt` pulls packages without hashes, both in local `direnv` flows and CI, which increases supply-chain exposure and reproducibility drift.
- Current mitigation: Versions are pinned in `test/requirements.txt`.
- Recommendations: Add hash-pinned lockfiles, move installation to an explicit bootstrap step, and avoid auto-installing dependencies on shell entry.

## Performance Bottlenecks

**Every `buildSVUnit` run rescans the working tree (Likely risk):**
- Files: `bin/buildSVUnit`
- Problem: `buildSVUnit` walks `.` to collect `svunit.f` files, globs for `*_unit_test.sv`, and recursively builds a suite per directory on every invocation.
- Measurement: Not benchmarked in-repo; the code path is proportional to the size of the test tree and does no incremental caching.
- Cause: Discovery is always filesystem-driven and starts from the current working directory.
- Improvement path: Cache discovery results, support manifest-based test selection, and narrow default scanning to explicit test roots instead of the entire CWD.

**WaveDrom generation does repeated front-of-list pops while iterating cycles (Likely risk):**
- Files: `bin/wavedromSVUnit.py`
- Problem: The generator walks every cycle and repeatedly calls `pop(0)` on signal data arrays while building one large output buffer.
- Measurement: Not benchmarked in-repo; the implementation is effectively quadratic for long signal/value lists.
- Cause: Python lists are used as queues in `writeSignals()` and `captureOutputs()`.
- Improvement path: Replace `pop(0)` with index counters or `collections.deque`, and stream output rather than assembling the whole task body in memory first.

**Stable-vs-experimental comparison setup is network-bound and rewrites a cloned tree (Confirmed bottleneck):**
- Files: `sv_test/run`
- Problem: A fresh comparison run clones `https://github.com/svunit/svunit.git`, checks out `v3.36.0`, deletes directories, renames files, and rewrites sources before any tests run.
- Measurement: Not benchmarked in-repo; runtime is bounded by network latency and full-tree file rewrites.
- Cause: The comparison flow is implemented as a mutable one-off preparatory script rather than a cached fixture.
- Improvement path: Prebuild a fixture artifact, vendor the comparison snapshot, or gate the flow behind an explicit cache-aware setup command.

## Fragile Areas

**Simulator-specific command assembly in `runSVUnit`:**
- Files: `bin/runSVUnit`
- Why fragile: Each simulator path has bespoke compile/runtime flags, special-case UVM handling, and custom filter propagation.
- Common failures: A fix for `xsim` or `verilator` can regress `modelsim`, `riviera`, `vcs`, `qrun`, `irun`, or `xrun` because all behaviors are encoded in one branching script.
- Safe modification: Change one simulator branch at a time, add explicit regression cases in `test/test_run_script.py` and `test/test_sim.py`, and avoid refactoring command construction without first normalizing argument handling.
- Test coverage: Partial; CI provisions only `verilator` in `.github/workflows/ci.yml`, and several simulator-specific paths are skipped or unimplemented in `test/test_sim.py`, `test/test_example.py`, and `test/test_util.py`.

**Testsuite and testrunner file generation:**
- Files: `bin/buildSVUnit`, `bin/create_testsuite.pl`, `bin/create_testrunner.pl`, `test/test_frmwrk.py`
- Why fragile: Generated filenames are derived from directory names by regex replacement, and discovery order depends on filesystem traversal and globbing.
- Common failures: Renaming directories, introducing special characters, or changing traversal behavior can silently alter generated suite names and expected goldens.
- Safe modification: Preserve current name-mangling behavior unless goldens are updated intentionally, and add explicit tests for paths with spaces, dots, and nested directories before changing discovery logic.
- Test coverage: Good for happy-path generation in `test/test_frmwrk.py`, but no coverage exists for whitespace-heavy paths or shell-sensitive characters.

**Experimental full-name parsing:**
- Files: `src/experimental/sv/full_name_extraction.svh`, `src/testExperimental/sv/full_name_extraction_unit_test.sv`
- Why fragile: The parser assumes `$typename` always contains `"extends "` and `"::"`, and the source file itself notes missing validation for failed substring searches.
- Common failures: Simulator-specific typename formats can produce out-of-range substring behavior or malformed names instead of a clean error.
- Safe modification: Add negative tests first, then convert the parsing helpers to validate markers before slicing strings.
- Test coverage: Narrow; `src/testExperimental/sv/full_name_extraction_unit_test.sv` covers only two happy-path strings.

**WaveDrom JSON-to-SystemVerilog conversion:**
- Files: `bin/wavedromSVUnit.py`, `test/test_wavedrom.py`, `examples/modules/wavedrom/README`, `examples/modules/wavedrom/dut_unit_test.sv`, `examples/modules/wavedrom/wavedrom.svh`
- Why fragile: The script assumes one matching clock entry, assumes edge metadata exists for waits, and relies on positional data popping.
- Common failures: Missing or reordered JSON fields can raise exceptions or generate broken task bodies.
- Safe modification: Add schema validation and golden tests around malformed inputs before touching the generator.
- Test coverage: Weak; `test/test_wavedrom.py` marks one suite skipped as flaky and conditionally skips simulator coverage for `verilator` and `xsim`.

## Scaling Limits

**Automated simulator coverage:**
- Files: `.github/workflows/ci.yml`, `test/utils.py`
- Current capacity: One open simulator family is provisioned in CI: `verilator`.
- Limit: Regressions for `modelsim`, `riviera`, `vcs`, `qrun`, `irun`, `xrun`, `dsim`, and `xsim` rely on contributors having those tools locally.
- Symptoms at limit: Support claims drift away from reality, and backend-specific bugs survive until a user reports them.
- Scaling path: Split CI into open and proprietary tiers, keep a mock-based contract suite for all backends, and make unsupported simulators explicit in docs and tests.

**Filesystem-driven discovery:**
- Files: `bin/buildSVUnit`, `bin/runSVUnit`
- Current capacity: Each invocation walks the current project tree and any selected `--directory` roots with no persistent cache.
- Limit: Large mono-repos or generated verification trees will pay full discovery cost on each run and magnify cleanup risk when `--out` defaults to `.`.
- Symptoms at limit: Slow startup, noisy generated artifacts, and accidental coupling between unrelated directories in the same workspace.
- Scaling path: Introduce explicit root configuration, cache discovery metadata, and isolate build output to dedicated temporary directories.

## Dependencies at Risk

**GitHub Actions runner and setup actions are dated (Confirmed):**
- Files: `.github/workflows/ci.yml`
- Risk: The CI job still uses `ubuntu-20.04`, `actions/checkout@v2`, `actions/setup-python@v2`, and Python `3.6`, all of which increase exposure to deprecation and ecosystem breakage.
- Impact: CI can fail because of runner retirement, action deprecation, or dependency incompatibility before the project code changes at all.
- Migration plan: Move to a supported Ubuntu image, upgrade the actions to current majors, and test against a supported Python baseline.

**Test dependencies are pinned to an old pytest stack (Confirmed):**
- Files: `test/requirements.txt`, `test/README`, `test/.envrc`
- Risk: The test environment is tied to `pytest==5.3.2` and similarly old plugins, which narrows compatible Python versions and makes future dependency upgrades harder.
- Impact: New contributors and CI refreshes are likely to hit packaging conflicts or plugin incompatibilities.
- Migration plan: Upgrade the pytest stack in controlled steps, add a lockfile or constraints file, and decouple installation from automatic `direnv` entry.

**Documentation generation depends on a hard-coded local tool path (Confirmed):**
- Files: `bin/create_docs.sh`
- Risk: `bin/create_docs.sh` assumes `/usr/local/NaturalDocs/NaturalDocs` exists on the machine.
- Impact: Docs generation is not portable across developer machines or CI without manual tool placement.
- Migration plan: Resolve the tool from `PATH`, document installation, or vendor docs generation into the main environment setup.

## Missing Critical Features

**A maintained mixed-language flow for VCS:**
- Files: `bin/runSVUnit`, `test/test_sim.py`, `docs/source/running_unit_tests.rst`
- Problem: The `-m/--mixedsim` interface exists, but `test/test_sim.py` explicitly skips the VCS path because multistage compilation has not been implemented.
- Current workaround: Use other simulators for VHDL/SystemVerilog mixed simulation, or avoid VCS mixed-language runs.
- Blocks: Reliable VCS support for mixed-language verification and a trustworthy support matrix for that feature.
- Implementation complexity: Medium; it needs simulator-specific build staging, docs updates, and regression coverage.

**Absolute-path support for `--directory`:**
- Files: `bin/runSVUnit`, `test/test_frmwrk.py`
- Problem: `runSVUnit` rejects absolute paths for `--directory`, which makes out-of-tree invocation and some CI/monorepo layouts harder than necessary.
- Current workaround: Use relative paths from the run directory.
- Blocks: Cleaner integration with external build systems and temporary workspaces.
- Implementation complexity: Low to medium; argument normalization and path-root tests are required, but the existing relative-path feature already exercises most of the flow.

**Stable first-class WaveDrom support across backends:**
- Files: `bin/buildSVUnit`, `bin/wavedromSVUnit.py`, `test/test_wavedrom.py`, `examples/modules/wavedrom/README`, `examples/modules/wavedrom/dut_unit_test.sv`, `examples/modules/wavedrom/wavedrom.svh`
- Problem: WaveDrom support remains flaky, is partly outside the normal `buildSVUnit` path, and is skipped on important backends.
- Current workaround: Use hand-curated examples and skip problematic simulators.
- Blocks: Confident adoption of the feature in real projects and reliable documentation/examples.
- Implementation complexity: Medium; it needs generator hardening, schema validation, and backend-aware regression tests.

## Test Coverage Gaps

**Non-Verilator simulator behavior:**
- Files: `.github/workflows/ci.yml`, `test/utils.py`, `test/test_sim.py`, `test/test_run_script.py`
- What's not tested: Most advertised simulator integrations are not exercised in CI.
- Risk: Backend-specific quoting, UVM, filter, and mixed-language issues will go unnoticed until users hit them locally.
- Priority: High
- Difficulty to test: Medium to high because most simulators are proprietary, but command-building behavior can still be contract-tested with fakes.

**Setup and environment bootstrap scripts:**
- Files: `Setup.zsh`, `Setup.bsh`, `Setup.csh`, `.envrc`, `test/.envrc`
- What's not tested: There is coverage for `Setup.csh` in `test/test_frmwrk.py`, but no automated check exists for `Setup.zsh`, repo-root `direnv`, or the implicit Python environment flow.
- Risk: Onboarding bugs can persist for long periods because they are outside the main pytest and simulator flows.
- Priority: High
- Difficulty to test: Low to medium; these are mostly shell-level smoke tests.

**WaveDrom, UVM report mock, and utility helper paths:**
- Files: `test/test_wavedrom.py`, `test/test_mock.py`, `test/test_util.py`
- What's not tested: One WaveDrom suite is permanently skipped as flaky, UVM report mock suites are skipped for UVM 1.2 breakage, and utility coverage is skipped for `verilator` and `xsim`.
- Risk: Optional but user-visible features can regress silently while the main suite still appears green.
- Priority: Medium
- Difficulty to test: Medium because several failures depend on simulator-specific behavior, but golden and fake-tool tests can cover part of the surface.

**Experimental parsing edge cases:**
- Files: `src/experimental/sv/full_name_extraction.svh`, `src/testExperimental/sv/full_name_extraction_unit_test.sv`
- What's not tested: Missing `"extends "`, missing `"::"`, unexpected whitespace, and simulator-specific typename variants.
- Risk: Experimental self-registered tests can fail unpredictably when used outside the narrow cases already covered.
- Priority: Medium
- Difficulty to test: Low; these are pure string transformation cases that can be covered with additional unit tests.

---

*Concerns audit: 2026-04-11*
*Update as issues are fixed or new ones discovered*
