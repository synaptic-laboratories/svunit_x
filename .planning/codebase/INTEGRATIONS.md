# External Integrations

**Analysis Date:** 2026-04-11

## APIs & External Services

**EDA Toolchains:**
- External HDL simulators - `bin/runSVUnit` delegates compilation and execution to locally installed tools instead of embedding a simulator.
  - Integration method: CLI subprocess calls from `bin/runSVUnit`
  - Supported backends: `xrun`, `irun`, `vlog` plus `vsim`, `vcs`, `dsim`, `qrun`, `verilator`, and `xsim`
  - Auth: local vendor install and licensing outside this repo; no credentials are stored in `bin/`, `test/`, or `.github/workflows/ci.yml`
- UVM runtime assets - Some simulator paths require external UVM installations.
  - Integration method: environment-variable expansion in `bin/runSVUnit` and test coverage in `test/test_mock.py`
  - Auth: `UVM_HOME` is used for DSim in `bin/runSVUnit`; `INCISIV_HOME` appears in Cadence-specific tests in `test/test_mock.py`

**Source Hosting and Distribution:**
- GitHub (`svunit/svunit`) - Source download and clone target used for onboarding and compatibility testing.
  - Integration method: archive download link in `docs/source/installation_and_setup.rst` and `git clone` in `sv_test/run`
  - Auth: none declared in-repo; public URLs are used in `README.md`, `docs/source/installation_and_setup.rst`, and `sv_test/run`
- GitHub Discussions - Community feedback channel linked from `README.md`.
  - Integration method: outbound browser navigation only
  - Auth: handled outside the repo

**Documentation Hosting:**
- Read the Docs / `docs.svunit.org` - Published documentation target for the Sphinx docs under `docs/`.
  - Integration method: `.readthedocs.yaml` builds `docs/source/conf.py`; `README.md` links to `https://docs.svunit.org/en/latest/`
  - Auth: not specified in the repository
- Python package index for docs/test dependencies - Dependency resolution happens at install time for `docs/requirements.txt` and `test/requirements.txt`.
  - Integration method: `pip install -r ...` in `test/.envrc`, `.github/workflows/ci.yml`, and `.readthedocs.yaml`
  - Auth: none indicated in the repo

**Other Application APIs:**
- Not detected in `bin/`, `src/`, `svunit_base/`, `test/`, or `.github/workflows/ci.yml`. There are no HTTP client integrations for SaaS business APIs such as payments, email, chat, CRM, or AI services.

## Data Storage

**Databases:**
- None detected in `bin/`, `src/`, `svunit_base/`, `test/`, or `docs/`.

**File Storage:**
- Local filesystem only - The framework generates and consumes local artifacts such as `.svunit.f`, `.testrunner.sv`, `run.log`, `compile.log`, simulator work directories, and docs build output referenced by `bin/buildSVUnit`, `bin/runSVUnit`, `bin/cleanSVUnit`, and `docs/Makefile`.
- Repository-managed fixtures - Examples and regression fixtures are stored in-tree under `examples/`, `test/`, and `svunit_base/`.

**Caching:**
- GitHub Actions cache - `.github/workflows/ci.yml` caches `/opt/verilator` through `actions/cache@v3` to avoid rebuilding Verilator on every CI run.
- No runtime cache layer such as Redis or Memcached is present in `bin/`, `src/`, or `test/`.

## Authentication & Identity

**Auth Provider:**
- None detected. This repo does not implement user accounts, session handling, or identity flows in `bin/`, `src/`, `svunit_base/`, or `test/`.
  - Implementation: not applicable
- Commercial simulator access may rely on external vendor license infrastructure, but that licensing setup is outside the repository and is not configured by any tracked file.

**OAuth Integrations:**
- None detected in `README.md`, `docs/`, `bin/`, `src/`, `svunit_base/`, or `test/`.

## Monitoring & Observability

**Error Tracking:**
- None detected. There is no Sentry, Rollbar, Bugsnag, or similar integration in `bin/`, `test/`, `.github/workflows/ci.yml`, or `docs/`.

**Analytics:**
- None detected in the codebase or docs configuration.

**Logs:**
- Local simulator logs - `bin/runSVUnit` writes `run.log` and `compile.log`, and `bin/cleanSVUnit` removes simulator byproducts such as `vsim.wlf`, `irun.key`, `xsim.dir`, and `xvlog.pb`.
- JUnit XML output - `svunit_base/junit-xml/junit_xml.sv`, `svunit_base/svunit_testrunner.sv`, and `test/test_junit_xml.py` show that machine-readable test reports are generated locally.
- Pytest HTML output - `test/README` documents `pytest --html=report.html` for human-readable regression reports.

## CI/CD & Deployment

**Hosting:**
- Read the Docs - Documentation hosting is configured in `.readthedocs.yaml` for the Sphinx project under `docs/`.
  - Deployment: Read the Docs builds from `docs/source/conf.py`
  - Environment vars: none declared in tracked repo files
- Application hosting: not applicable. The repository ships a framework and scripts, not a deployable service.

**CI Pipeline:**
- GitHub Actions - The only tracked CI pipeline is `.github/workflows/ci.yml`.
  - Workflows: `ci.yml`
  - External steps: `actions/checkout@v2`, `actions/cache@v3`, `actions/setup-python@v2`, `apt-get`, `git clone`, and `direnv`
  - Secrets: no workflow secrets are referenced in `.github/workflows/ci.yml`
- Verilator source integration - CI clones `https://github.com/verilator/verilator` and builds tag `v5.012` in `.github/workflows/ci.yml`.

## Environment Configuration

**Development:**
- Required env vars: `SVUNIT_INSTALL` and a usable `PATH` for the SVUnit scripts, as documented in `README.md`; `Setup.bsh` and `Setup.csh` append `bin/`, while `Setup.zsh` also exports `SVUNIT_INSTALL` and mutates `PATH` for zsh users.
- Optional env vars: `UVM_HOME` for DSim UVM support in `bin/runSVUnit`; `INCISIV_HOME` for one Cadence-specific UVM test path in `test/test_mock.py`.
- Secrets location: not detected. The repo contains `.envrc` and `test/.envrc`, but no `.env`, `secrets.*`, or credential files are tracked.
- Mock/stub services: tests fake simulator executables in `test/test_frmwrk.py` and `test/test_run_script.py` instead of calling real vendor binaries in every case.
- Shell bootstrap: `.envrc` sources `Setup.bsh`, while `test/.envrc` uses `layout python3`, watches `test/requirements.txt`, and runs `pip install -r requirements.txt`.

**Staging:**
- Not applicable. No separate staging environment or staged external service endpoints are defined in the repository.

**Production:**
- Not applicable for runtime services. The closest production-like target is documentation publication via Read the Docs configured in `.readthedocs.yaml`.

## Webhooks & Callbacks

**Incoming:**
- None detected in `bin/`, `src/`, `svunit_base/`, `test/`, or `.github/workflows/ci.yml`.

**Outgoing:**
- No webhook emitters are implemented in the repository.
- Outbound network activity is limited to tooling and automation: `git clone` from GitHub in `sv_test/run` and `.github/workflows/ci.yml`, plus `pip install` dependency resolution from `test/.envrc`, `.github/workflows/ci.yml`, and `.readthedocs.yaml`.

---

*Integration audit: 2026-04-11*
