# Testing Patterns

**Analysis Date:** 2026-04-11

## Test Framework

**Runner:**
- `pytest 5.3.2`, pinned in `test/requirements.txt`.
- Config: `test/pytest.ini`.
- CI entrypoint: `.github/workflows/*` installs `test/requirements.txt`, changes into `test/`, then runs `direnv allow` and `direnv exec . pytest`.

**Assertion Library:**
- Python tests use bare `assert`, `subprocess.check_call()`, `subprocess.call()`, and `subprocess.run()`, with helper assertions in `test/utils.py`.
- SystemVerilog tests use the framework macros in `svunit_base/svunit_defines.svh`: `FAIL_IF`, `FAIL_UNLESS`, `FAIL_IF_EQUAL`, `FAIL_UNLESS_EQUAL`, `FAIL_IF_STR_EQUAL`, and `FAIL_UNLESS_STR_EQUAL`.
- XML assertions use `xml.etree.ElementTree` in `test/test_junit_xml.py`.

**Run Commands:**
```bash
cd test && pytest                               # Run the Python regression suite
cd test && pytest --html=report.html           # HTML report path documented in `test/README`
cd test && pytest test_run_script.py -k filter # Narrow to runner/filter behavior
cd test && direnv allow && direnv exec . pytest
```

## Test File Organization

**Location:**
- Host-side regression tests live in `test/test_*.py`.
- Directory fixtures sit beside them under `test/frmwrk_*`, `test/sim_*`, `test/junit-xml/*`, `test/mock_uvm_report*`, `test/util_clk_reset`, and `test/wavedrom_*`.
- Stable framework self-tests live in `src/test/sv`.
- Experimental framework self-tests live in `src/testExperimental/sv`.
- Example directories under `examples/` double as executable end-to-end tests through `test/test_example.py`.

**Naming:**
- Python test modules are named `test_<area>.py`; functions are named `test_<scenario>`, for example `test_filter_wildcards` in `test/test_run_script.py`.
- SystemVerilog unit-test modules are named `<uut>_unit_test.sv`, for example `src/test/sv/string_utils_unit_test.sv` and `examples/classes/mock/client_unit_test.sv`.
- Generated suite and runner modules are named `<dir>_testsuite.sv` and `testrunner.sv`, with dot-prefixed output artifacts created by `bin/buildSVUnit`.
- Experimental package-style tests use names such as `factorial_test.sv`, `queue_test.sv`, and `test_data_structures.sv` in `examples/experimental/`.

**Structure:**
```text
test/
  test_frmwrk.py            # Generator/build discovery regressions
  test_run_script.py        # `runSVUnit` CLI and filter behavior
  test_sim.py               # Simulator integration and log semantics
  test_junit_xml.py         # XML output validation
  test_example.py           # Runs example projects
  utils.py                  # Shared fixtures, helpers, fake tools
  templates/*.gold          # Golden files for generated SV output
  frmwrk_*/                 # Directory fixtures for generation/build tests
  sim_*/                    # Directory fixtures for simulator tests

src/test/sv/
  string_utils_unit_test.sv # Stable SVUnit self-test

src/testExperimental/sv/
  *_unit_test.sv            # Experimental framework self-tests

examples/**/
  *_unit_test.sv            # Example test modules exercised by Python
```

## Test Structure

**Suite Organization:**
```python
@all_files_in_dir('sim_3')
@all_available_simulators()
def test_sim_3(datafiles, simulator):
    with datafiles.as_cwd():
        subprocess.check_call(['runSVUnit', '-s', simulator])
        expect_string(br'INFO:  \[0\]\[dut_ut\]: RUNNING', 'run.log')
        expect_testrunner_fail('run.log')
```

**Patterns:**
- Python tests usually arrange a copied fixture directory with `@all_files_in_dir(...)`, run a CLI through `subprocess`, then assert on generated files or log contents. See `test/test_frmwrk.py`, `test/test_sim.py`, and `test/test_junit_xml.py`.
- Temporary ad hoc scenarios use `tmp_path` or `tmpdir`, then write small inline SystemVerilog modules with `write_text()`. `test/test_run_script.py` is the main example.
- Generated and handwritten SystemVerilog unit tests follow the same lifecycle skeleton:
```systemverilog
module string_utils_unit_test;
  string name = "string_utils_ut";
  svunit_testcase svunit_ut;

  function void build();
    svunit_ut = new(name);
  endfunction

  task setup();
    svunit_ut.setup();
  endtask

  task teardown();
    svunit_ut.teardown();
  endtask

  `SVUNIT_TESTS_BEGIN
    `SVTEST(can_split_string_by_underscore)
      `FAIL_UNLESS_EQUAL(parts, exp_parts)
    `SVTEST_END
  `SVUNIT_TESTS_END
endmodule
```
- Python teardown is usually implicit through temp directories and context managers; explicit cleanup helpers such as `working_directory()` live in `test/utils.py`.

## Mocking

**Framework:**
- Python tests do not use `unittest.mock`. They mock process-level dependencies by writing fake executables and changing `PATH` with `monkeypatch`.
- SystemVerilog mocking is handwritten. Examples include `examples/classes/mock/server_mock.sv` and the UVM report mocking package in `svunit_base/uvm-mock/`.

**Patterns:**
```python
fake_tool('xrun')
monkeypatch.setenv('PATH', '.', prepend=os.pathsep)
subprocess.check_call(['runSVUnit', '-s', 'xrun', '-t', 'test_unit_test.sv'])
```

```systemverilog
server_mock s = new();
client c = new(s);
c.do_something();
s.verify_perform(server::ACTION0);
```

**What to Mock:**
- Simulator executables and tool failures, via `fake_tool()` in `test/test_frmwrk.py` and `FakeTool` in `test/utils.py`.
- Environment discovery and command routing, via `monkeypatch.setenv()` in `test/test_frmwrk.py` and `test/test_run_script.py`.
- Collaborator classes inside SystemVerilog tests, as in `examples/classes/mock/server_mock.sv`.
- UVM report callbacks, through `svunit_base/uvm-mock/svunit_uvm_mock_pkg.sv` and `examples/uvm/uvm_report_mock/uut_unit_test.sv`.

**What NOT to Mock:**
- Do not mock generated `.svunit.f`, testsuite, or testrunner files when verifying generator behavior. `test/test_frmwrk.py` compares the real outputs against `test/templates/*.gold`.
- Do not mock `runSVUnit` or `buildSVUnit` for normal integration tests. Most tests execute the real commands and inspect `run.log`, `tests.xml`, or generated `.sv` files.

## Fixtures and Factories

**Test Data:**
```python
def all_files_in_dir(dirname):
    dirpath = os.path.join(os.path.dirname(os.path.realpath(__file__)), dirname)
    return pytest.mark.datafiles(
            *pathlib.Path(dirpath).iterdir(),
            keep_top_dir=True,
            )

def golden_class_unit_test(FILE, MYNAME):
    template = open('{}/test/templates/class_unit_test.gold'.format(os.environ['SVUNIT_INSTALL']))
    with open('{}_unit_test.gold'.format(FILE), 'w') as output:
        for line in template:
            output.write(line.replace('FILE', FILE).replace('MYNAME', MYNAME))
```

**Location:**
- Shared Python fixtures and factory helpers live in `test/utils.py`.
- Golden template files live in `test/templates/*.gold`.
- Scenario directories used by `pytest-datafiles` live under `test/frmwrk_*`, `test/sim_*`, `test/junit-xml/*`, `test/mock_uvm_report*`, `test/util_clk_reset`, and `test/wavedrom_*`.
- Example project fixtures come from `examples/`, pulled in through `test/test_example.py`.

## Coverage

**Requirements:**
- No line or branch coverage target was detected.
- CI blocks on `pytest` failures and simulator failures only; there is no `coverage.py` or HDL coverage enforcement.

**Configuration:**
- `pytest-html` is installed through `test/requirements.txt`, and `test/README` documents `pytest --html=report.html`.
- SVUnit itself writes `tests.xml` from `svunit_base/svunit_testrunner.sv`; that file is functional test output, not Python coverage data.
- No exclusions or thresholds for code coverage were detected.

**View Coverage:**
```bash
cd test && pytest --html=report.html
ls tests.xml run.log
```

## Test Types

**Unit Tests:**
- Stable framework self-tests target individual helper behavior inside SystemVerilog, for example `src/test/sv/string_utils_unit_test.sv`.
- Experimental framework self-tests target registry and name-extraction behavior in `src/testExperimental/sv/test_registry_unit_test.sv` and `src/testExperimental/sv/full_name_extraction_unit_test.sv`.
- Python unit-style tests around CLI argument handling and failure codes live in `test/test_run_script.py` and parts of `test/test_frmwrk.py`, although they still execute external commands.

**Integration Tests:**
- Most of the suite is integration-heavy: it runs `create_unit_test.pl`, `buildSVUnit`, and `runSVUnit`, then validates generated files, logs, or XML. `test/test_frmwrk.py`, `test/test_sim.py`, and `test/test_junit_xml.py` are the main entry points.
- Example regressions in `test/test_example.py` exercise real example projects under `examples/`.

**E2E Tests:**
- There is no browser or UI E2E layer.
- The closest end-to-end tests are the example runs in `test/test_example.py` and the simulator-backed scenarios in `test/test_sim.py`, which execute from CLI invocation through simulator output.

## Simulator Expectations

- Simulator discovery is dynamic. `test/utils.py::all_available_simulators()` checks for `irun`, `xrun`, `vcs`, `vlog` (mapped to ModelSim/Questa), `dsim`, `qrun`, `verilator`, and `xsim`.
- At least one simulator must be on `PATH`; otherwise `all_available_simulators()` emits a warning and simulator-parametrized tests become inert.
- CI currently installs Verilator in `.github/workflows/*`, so the GitHub-hosted run exercises the suite mostly through the Verilator-compatible subset.
- `test/test_sim.py` skips VHDL for `dsim` and `verilator`, and skips timeout coverage for `xsim`.
- `test/test_example.py` skips UVM examples for `verilator` and skips one UVM example for `dsim`.
- `test/test_util.py` skips `verilator` and `xsim` for the clock/reset helper scenario.
- `test/test_wavedrom.py` skips the entire `wavedrom_0` case and conditionally skips `verilator` and `xsim` for `wavedrom_1`.
- `test/test_mock.py` skips UVM report mock tests for known-broken UVM 1.2 paths.
- Environment setup matters. `README.md`, `Setup.bsh`, and `Setup.csh` establish `SVUNIT_INSTALL` and `PATH`; `test/README` and `.github/workflows/*` assume the `test/` directory is run inside that environment. The `test/` directory also contains a `.envrc`.

## Common Patterns

**Async Testing:**
```systemverilog
`SVTEST(connectivity)
  bfm_mstr.write('hfc, 0);
  `FAIL_IF(my_apb_coverage_agent.coverage.cg.addr_max_cp.get_coverage() != 100);
`SVTEST_END
```
- SystemVerilog tests express asynchronous behavior with tasks, clocks, and simulator time, not with a host async framework. See `examples/uvm/uvm_express/apb_coverage_agent_unit_test.sv` and helper tasks in `examples/modules/apb_slave/apb_slave_unit_test.sv`.
- Python tests wait synchronously for subprocess completion. No async Python framework is used.

**Error Testing:**
```python
returncode = subprocess.call(['runSVUnit', '--sim', 'verilator', '--uvm'], cwd=tmp_path)
assert returncode == 4
```

```python
expect_string(br'ERROR: \[0\]\[dut_ut\]: fail_unless_str_equal: \"abd\" != \"abcd\"', 'run.log')
expect_testrunner_fail('run.log')
```
- CLI failure behavior is usually asserted through exit codes in `test/test_run_script.py` and `test/test_frmwrk.py`.
- HDL failure behavior is asserted through `run.log` regexes in `test/test_sim.py` and `test/utils.py`.

**Snapshot Testing:**
- Traditional snapshot testing is not used.
- Golden-file diffing is the nearest equivalent. `test/test_frmwrk.py` generates expected `.gold` files from `test/templates/*.gold` and compares them to produced `.sv` output through `verify_file()`.

## Practical Gaps

- Static analysis is not part of automated verification. No lint or formatter checks run in `.github/workflows/*`.
- Coverage is not measured. The suite proves behavior through pass/fail regressions only.
- The CI simulator matrix is narrow. `.github/workflows/*` installs Verilator, while the broader `all_available_simulators()` matrix is only exercised on developer machines that already have those tools installed.
- `test/test_wavedrom.py` skips `wavedrom_0` entirely as flaky.
- `test/test_mock.py` skips UVM 1.2 report-mock cases.
- `test/test_sim.py` documents unimplemented or unsupported mixed-language paths.
- Some tests are duplicated or called out as redundant in comments, for example `test_example_uvm_simple_model_2` in `test/test_example.py`, `test_mock_uvm_report_ius` in `test/test_mock.py`, and `test_frmwrk_31` in `test/test_frmwrk.py`.
- Experimental DSL paths in `src/experimental/sv/` have self-tests under `src/testExperimental/sv/`, but no Python regression was found that exercises `runSVUnit --enable-experimental` end to end.
- Perl internals and `bin/wavedromSVUnit.py` are mostly tested through generated outputs and integration scenarios, not through direct unit tests of internal functions.

---

*Testing analysis: 2026-04-11*
*Update when test patterns change*
