# Factory for per-target `svunit-certify-<target>` wrappers.
#
# Each wrapper exports the TARGET_* env vars describing its target, then
# execs scripts/certify.sh which runs the pytest suite, parses JUnit XML,
# writes timing-summary.json, build-info.json and qualification-results.md.
#
# Shared constants (tool identifiers, artefacts root, license dir) are
# baked in once at the top of this file rather than replicated per target.

{ pkgs
, lib
, certifyScript        # path to scripts/certify.sh
, timingSummaryScript  # derivation producing timing-summary.py
, pythonWithPytest
, certToolsDir
, artefactsRoot
, licenseRoot
}:

let
  toolGroup = "g_svunit_x";
  toolVersion = "r_v3_38_1_x0_2_0";
  qualifiedVersion = "3.38.1-x0.2.0";

  # Runtime deps common to every target.  Target-specific deps are appended
  # in mkCertify based on the adapter type.
  commonRuntimeInputs = [
    pkgs.coreutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.jq
    pkgs.perl
    pythonWithPytest
  ];

  adapterRuntimeInputs = target:
    if target.adapter == "container" then [ pkgs.podman ]
    else if target.adapter == "native" then [
      target.verilatorPkg
      target.verilatorCc
      target.verilatorMake
    ]
    else [];

  exportsForTarget = name: target:
    let
      common = ''
        export TARGET_NAME=${lib.escapeShellArg name}
        export TARGET_ADAPTER=${lib.escapeShellArg target.adapter}
        export TARGET_TOOL=${lib.escapeShellArg target.tool}
        export TARGET_DISPLAY_NAME=${lib.escapeShellArg target.displayName}
        export TARGET_PYTEST_FILTER=${lib.escapeShellArg target.pytestFilter}
        export TOOL_GROUP=${lib.escapeShellArg toolGroup}
        export TOOL_VERSION=${lib.escapeShellArg toolVersion}
        export QUALIFIED_VERSION=${lib.escapeShellArg qualifiedVersion}
        export ARTEFACTS_ROOT=${lib.escapeShellArg artefactsRoot}
        export CERT_TOOLS_DIR=${lib.escapeShellArg certToolsDir}
        export TIMING_SUMMARY_SCRIPT=${timingSummaryScript}
      '';
      containerExports = ''
        export TARGET_IMAGE=${lib.escapeShellArg target.imageTag}
        export TARGET_INSTALL_ROOT=${lib.escapeShellArg target.installRoot}
        export TARGET_CONTAINER_PATH=${lib.escapeShellArg target.containerPath}
        export TARGET_EXPECTED_QUARTUS=${lib.escapeShellArg (target.expectedQuartus or "")}
        export TARGET_EXPECTED_QUESTA=${lib.escapeShellArg target.expectedQuesta}
        export TARGET_HAS_QUARTUS_SH=${if target.hasQuartusSh then "1" else "0"}
        export LICENSE_DIR="''${LICENSE_DIR:-${licenseRoot}}"
        export CONTAINER_RUNTIME="''${CONTAINER_RUNTIME:-podman}"
      '';
      nativeExports = ''
        export TARGET_EXPECTED_VERILATOR=${lib.escapeShellArg target.expectedVerilator}
        export TARGET_VERILATOR_STORE_PATH=${target.verilatorPkg}
      '';
    in
    common + (
      if target.adapter == "container" then containerExports
      else if target.adapter == "native" then nativeExports
      else ""
    );
in
{
  mkCertify = name: target:
    pkgs.writeShellApplication {
      name = "svunit-certify-${name}";
      runtimeInputs = commonRuntimeInputs ++ adapterRuntimeInputs target;
      text = ''
        set -euo pipefail
        ${exportsForTarget name target}
        exec ${certifyScript} "$@"
      '';
    };

  inherit toolGroup toolVersion qualifiedVersion;
}
