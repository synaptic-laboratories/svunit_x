---
phase: 03-quartus-verification-sign-off
reviewed: 2026-04-18T13:17:07Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - scripts/certify.sh
  - scripts/quartus-shell.sh
  - .planning/phases/03-quartus-verification-sign-off/03-reproduce.sh
findings:
  critical: 0
  warning: 2
  info: 6
  total: 8
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-18T13:17:07Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

All three shell scripts passed the security threat model: **no license-file
content access** (only path-referenced bind mounts and `test -f` existence
checks), **no shell injection vectors** (nix-layer `lib.escapeShellArg` on
export values, CLI args via `case` parsing, TSV fields written through jq
`--arg`/`--argjson`), and **no `rm -rf` on env-derived paths**. The
`container_script` heredoc uses a quoted `'CONTAINER_EOF'` delimiter and
relies on container-side env-var expansion from podman `-e` flags rather
than host-side string interpolation, which is the correct pattern.

Error propagation is generally sound: `set -euo pipefail` is on in all three
scripts, and the `|| true` annotations around `quartus_sh --version`,
`qrun -version`, and `pytest` are paired with downstream validation (grep
match on captured output, JUnit XML parsing). `03-reproduce.sh` captures
`PIPESTATUS[0]` correctly across the `nix run ... | tee` pipe.

Two real findings surface:

1. **WR-01** — a potential markdown-corruption path in `certify.sh` where raw
   `test-log.txt` contents are inlined into a triple-backtick fenced block
   of `qualification-results.md`. A pytest output line containing three
   backticks prematurely terminates the code fence. This is a data-quality
   / evidence-integrity concern rather than a security one, but it affects
   the sign-off artefact layout.
2. **WR-02** — a JUnit-XML attribute-parse fragility in `certify.sh` lines
   286–289. The `grep -oP | head -1 || echo "0"` pipeline is correct under
   pipefail, but the per-variable grep invocation assumes the first
   `<testsuite>` element contains the aggregate counters; on pytest runs
   that emit a `<testsuites>` wrapper with aggregate attrs, the numbers
   are captured correctly, but if the top-level element lacks them, the
   variables silently become `"0"` and `STATUS` becomes `FAIL` with no
   diagnostic distinguishing "test suite failed" from "parse fell
   through". The Phase 3 run evidenced working PASS status, so this is
   latent, not active.

Informational findings document portability and clarity issues consistent
with the "LOW priority" guidance in the phase context.

## Warnings

### WR-01: Raw test-log inlined into markdown code fence without backtick-escaping

**File:** `scripts/certify.sh:482-489`
**Issue:** The `RAWEOF` heredoc opens a ```` ```text ```` fence, then
expands `$(cat "${OUTPUT_DIR}/test-log.txt")`. If any pytest/stderr line
contains a run of three or more backticks (e.g. from a user-authored
assertion failure message or a tool that quotes markdown), the outer fence
terminates mid-output and the rest of the log renders as literal markdown,
corrupting `qualification-results.md`. Under the current SVUnit test
population this is latent — no current test produces backtick-heavy
output — but the file is declared an evidence artefact and the
qualification standard expects the Raw Output section to be verbatim.
Secondary concern: a command-substitution of a multi-MB log file forces
the whole log into bash memory and then into the heredoc, which is less
robust than a stream.
**Fix:** Bracket the embed with a fence whose length exceeds any embedded
run, or stream the file rather than substituting it:
```bash
# Option A — longer fence (matches CommonMark "enough backticks" rule):
cat <<'RAWHEAD'

## Raw Output

````text
RAWHEAD
cat "${OUTPUT_DIR}/test-log.txt"
printf '\n````\n'

# Option B — avoid the fence problem entirely by linking rather than inlining:
cat <<'RAWHEAD'

## Raw Output

See `test-log.txt` in this directory for the full unmodified output.
RAWHEAD
```
Option B is preferable: `test-log.txt` is already listed in the Evidence
section (line 473), so inlining it doubles storage and introduces the
fence-escape hazard without adding evidentiary value.

### WR-02: JUnit XML counter parse silently falls back to 0 on malformed XML

**File:** `scripts/certify.sh:285-290`
**Issue:** Each of
```bash
TOTAL="$(grep -oP '\btests="\K[0-9]+' "${OUTPUT_DIR}/tests.xml" | head -1 || echo "0")"
```
independently greps the same file. If pytest writes a `<testsuites>`
wrapper without the aggregate attrs on its top element (for example if a
plugin reorders output), each grep falls through to `"0"` and
`STATUS=FAIL` with `0 passed`, which is indistinguishable in
`build-info.json` from "tests.xml missing entirely" (same zero counters).
The distinction matters for triage: the first case is a pytest-emitter
regression; the second is an infra failure. Second concern: running four
independent regexes over the same file is slower than a single jq-style
pass and can produce mismatched counters if the file changes between
greps (non-issue here since it's a finished run, but fragile as a
pattern).
**Fix:** Use a single xmllint or python one-liner that either succeeds
atomically or emits a diagnostic. Since `python3` is already required
(line 171, 219), this is zero additional dependency:
```bash
if [ -f "${OUTPUT_DIR}/tests.xml" ]; then
  read -r TOTAL FAILURES ERRORS SKIPPED < <(python3 - "${OUTPUT_DIR}/tests.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
# Handle both <testsuites> wrapper and bare <testsuite>.
node = root if root.tag == "testsuites" else root
# Walk one level if needed.
if root.tag == "testsuites" and len(root):
    attrs = root.attrib if "tests" in root.attrib else root[0].attrib
else:
    attrs = root.attrib
print(attrs.get("tests", 0), attrs.get("failures", 0),
      attrs.get("errors", 0), attrs.get("skipped", 0))
PY
  )
  PASSED=$((TOTAL - FAILURES - ERRORS - SKIPPED))
else
  TOTAL=0; FAILURES=0; ERRORS=0; SKIPPED=0; PASSED=0
fi
```
If keeping the grep approach, at minimum emit a diagnostic when a grep
falls through so the "parse failure" vs "no tests ran" cases are
distinguishable in `test-log.txt`.

## Info

### IN-01: `pytest -k "${PYTEST_FILTER}"` inside the container heredoc is not robust to quoted filters

**File:** `scripts/certify.sh:219`
**Issue:** The container-side script receives `PYTEST_FILTER` via
`-e PYTEST_FILTER=...` (line 250) and expands it inside `bash -c
"$container_script"`. With current fixed filters (`"qrun and not
uvm_simple_model"`) this is safe, but any future filter containing a
double-quote character would break the container bash parse. Also, the
`echo "--- pytest -k ${PYTEST_FILTER} ---"` at line 218 is unquoted, so
a filter containing a glob metacharacter would pathname-expand. These
are latent — the filter values are fully controlled by `mk-certify.nix`
— but worth guarding if the filter surface ever widens.
**Fix:** Single-quote the inner expansion (`pytest -k '"${PYTEST_FILTER}"'`
is not right; the right pattern is to use an array or a `printf %q`
reformat). Simplest mitigation: document the filter-grammar constraint
in the `Required env vars` block at the top of `certify.sh`.

### IN-02: Container `--cap-add=NET_ADMIN` is likely over-granted for node-locked license files

**File:** `scripts/certify.sh:236` and `scripts/quartus-shell.sh:111`
**Issue:** Both scripts pass `--cap-add=NET_ADMIN` alongside `--net=host`.
Node-locked Intel/Siemens license files (path-referenced via
`LM_LICENSE_FILE=/opt/*.dat`) are read from disk, not served over a
socket. `NET_ADMIN` permits interface reconfiguration, iptables changes,
etc. — far broader than the MAC-address interrogation that node-locked
license tooling typically needs. `--net=host` alone already exposes host
interfaces for MAC matching. If `NET_ADMIN` is retained, the inline
comment block (certify.sh:227-233, quartus-shell.sh:57-62) is the right
place to document *why*.
**Fix:** Remove `--cap-add=NET_ADMIN` and re-run the qualification suite.
If a target fails, add a comment citing which tool needs the capability
and for what. If it was added speculatively during Phase 3 bring-up,
drop it — there is no evidence in the commit history
(`292a8a0 fix(certify): set SALT_LICENSE_SERVER`) that the capability
was added in response to a reproduced failure.

### IN-03: `mkdir -p "$ARTEFACTS_ROOT"` happens before `flock`, leaving a small preflight-race window

**File:** `.planning/phases/03-quartus-verification-sign-off/03-reproduce.sh:127` vs `:164-166`
**Issue:** Preflight E (line 121-128) probes or creates `ARTEFACTS_ROOT`
before preflight H (line 162-166) acquires the flock. Two concurrent
invocations both passing preflights E, F, G race on `touch "$LOCKFILE"`
and `flock -n`. The loser bails cleanly with "another sign-off session
holds", so this is not a correctness bug — but it means preflight G can
emit spurious `FAIL` chatter before the clean lock-held message. The
semantics are also slightly surprising: creating the artefacts-root
directory is a side-effect that happens before the lock is held.
**Fix:** Reorder so the lock is acquired as the very first host-side
action, and move `mkdir -p "$ARTEFACTS_ROOT"` inside the locked region.
Alternatively, use `/run/lock/svunit-signoff-${toolVersion}.lock` so the
lockfile location is not dependent on the artefacts-root existing.

### IN-04: `nix eval --raw ".#apps.$(uname -m)-linux..."` assumes x86_64/aarch64 mapping

**File:** `.planning/phases/03-quartus-verification-sign-off/03-reproduce.sh:147,155`
**Issue:** On an aarch64 host, `uname -m` returns `aarch64`, matching
Nix's `aarch64-linux` system string — fine. On an i686 host, `uname -m`
returns `i686`, which does not match any Nix system string the flake
exposes. On Darwin, `uname -m` returns `arm64` which also doesn't match
Nix's `aarch64-darwin`. The Quartus images are x86_64-only so a
mismatched system was never going to work anyway; this is clarity of
the error, not correctness.
**Fix:** Either hardcode `x86_64-linux` (correct for every supported
target in this qualification) or compute it via
`nix eval --raw --impure --expr 'builtins.currentSystem'`.

### IN-05: `grep '^# ' "$0" | sed 's/^# //'` for `--help` may surprise under bash aliasing of `$0`

**File:** `.planning/phases/03-quartus-verification-sign-off/03-reproduce.sh:71`
**Issue:** When invoked as `bash path/to/03-reproduce.sh --help`, `$0` is
`path/to/03-reproduce.sh` and the `grep` works. When sourced
(`source 03-reproduce.sh --help`) `$0` becomes the parent shell name
(usually `bash`) and the help emits the parent script's `#` lines — or
nothing. Sourcing is not a documented invocation path, so this is
edge-case only. Minor.
**Fix:** Use `${BASH_SOURCE[0]}` instead of `$0` for intra-script file
references:
```bash
-h|--help)
  grep '^# ' "${BASH_SOURCE[0]}" | sed 's/^# //'; exit 0 ;;
```

### IN-06: `XHOST_USERS="${XHOST_USERS:-root,${USER:-$(id -un)}}"` splits on commas without validating

**File:** `scripts/quartus-shell.sh:24,81-84`
**Issue:** If `USER` or `id -un` output contains a literal comma or
newline, the `IFS=',' read -r -a _xhost_users` split mis-parses. On
standard NixOS and any POSIX-compliant system, usernames cannot contain
commas, so this is theoretical. However, the for-loop at line 82-84
invokes `xhost +si:localuser:"${_u}"` with whatever tokens result from
the split — worth a `[[ "${_u}" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]`
validation before the xhost call if you want defense-in-depth. Not a
real bug on the target platform.
**Fix (optional):**
```bash
for _u in "${_xhost_users[@]}"; do
  if ! [[ "${_u}" =~ ^[a-zA-Z_][a-zA-Z0-9_-]{0,31}$ ]]; then
    echo "skipping invalid xhost user token: ${_u}" >&2
    continue
  fi
  DISPLAY="${DISPLAY_ENV}" xhost +si:localuser:"${_u}" >/dev/null
done
```

---

_Reviewed: 2026-04-18T13:17:07Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
