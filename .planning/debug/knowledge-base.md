# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## quartus-25-1-sim-only-pytest-subprocess-failure — Questa 2025.1 sim-only container: perl IO::Dir + SALT_LICENSE_SERVER stacked bugs
- **Date:** 2026-04-18
- **Error patterns:** subprocess.CalledProcessError, FileNotFoundError, Can't locate IO/Dir.pm, buildSVUnit, BEGIN failed--compilation aborted, SALT_LICENSE_SERVER, Unable to find the license file, Unable to checkout a license, Vsim is closing, Invalid license environment, Application closing, quartus-pro-linux, 25.1.1.125-sim-only, Questa 2025.1, vsim, vlog, qrun, modelsim
- **Root cause:** Two stacked bugs in the Quartus 25.1 sim-only container path: (1) the stripped sim-only image ships `perl-base` only, so SVUnit's `/sll/bin/buildSVUnit` aborts at `use IO::Dir;` on line 25; and (2) Questa 2025.1 migrated to SALT v2.4.2.0 and reads `SALT_LICENSE_SERVER` rather than the now-deprecated `LM_LICENSE_FILE`, so vsim fails license checkout after vlog/vopt succeed.
- **Fix:** (1) Install full `perl` apt metapackage in the container bootstrap (commit 0680482). (2) Set `SALT_LICENSE_SERVER=/opt/questa_license.dat` alongside the existing `LM_LICENSE_FILE` in both `scripts/certify.sh` podman run and `scripts/quartus-shell.sh` CONTAINER_ENV (commit 292a8a0). Questa 2023.3 ignores the unknown SALT var, so 23.4 path is unaffected.
- **Files changed:** scripts/certify.sh, scripts/quartus-shell.sh
---

