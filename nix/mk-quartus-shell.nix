# Factory for per-target `svunit-quartus-shell-<target>` interactive launchers.
#
# Only container-adapter targets are eligible.  Each wrapper exports the
# TARGET_* env vars then execs scripts/quartus-shell.sh to drop the user
# into a bash shell inside the Quartus Pro container (or into Quartus GUI
# with --quartus).

{ pkgs
, lib
, shellScript   # path to scripts/quartus-shell.sh
, licenseRoot
}:

{
  mkQuartusShell = name: target:
    pkgs.writeShellApplication {
      name = "svunit-quartus-shell-${name}";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.podman
        pkgs.xorg.xhost
      ];
      text = ''
        set -euo pipefail
        export TARGET_NAME=${lib.escapeShellArg name}
        export TARGET_IMAGE=${lib.escapeShellArg target.imageTag}
        export TARGET_INSTALL_ROOT=${lib.escapeShellArg target.installRoot}
        export TARGET_CONTAINER_PATH=${lib.escapeShellArg target.containerPath}
        export LICENSE_DIR="''${LICENSE_DIR:-${licenseRoot}}"
        export CONTAINER_RUNTIME="''${CONTAINER_RUNTIME:-podman}"
        exec ${shellScript} "$@"
      '';
    };
}
