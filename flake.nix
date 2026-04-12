{
  description = "SVUnit X development shell with qualified Altera Quartus Pro Podman tooling";

  inputs = {
    quartus-podman = {
      url = "path:/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v23_4_0_79";
    };
    nixpkgs.follows = "quartus-podman/nixpkgs";
  };

  outputs = { nixpkgs, quartus-podman, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      qualifiedQuartusRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v23_4_0_79";
      installerRoot = "/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/quartus-pro-linux/23.4.0.79/b_individual";
      licenseRoot = "/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch";
      imageTag = "localhost/quartus-pro-linux:23.4.0.79";
      quartusInstallRoot = "/eda/intelFPGA_pro/23.4";
      quartusContainerPath =
        "${quartusInstallRoot}/quartus/bin:"
        + "${quartusInstallRoot}/qsys/bin:"
        + "${quartusInstallRoot}/questa_fe/bin:"
        + "${quartusInstallRoot}/quartus/linux64/gnu:"
        + "${quartusInstallRoot}/quartus/sopc_builder/bin:"
        + "${quartusInstallRoot}/nios2eds:"
        + "${quartusInstallRoot}/nios2eds/bin:"
        + "${quartusInstallRoot}/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin:"
        + "${quartusInstallRoot}/nios2eds/sdk2/bin:"
        + "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";

      rawQuartusTools = quartus-podman.packages.${system}.quartus-tools;

      quartusTools = pkgs.writeShellApplication {
        name = "svunit-quartus-tools";
        runtimeInputs = [ rawQuartusTools ];
        text = ''
          set -euo pipefail

          export DOCKERFILE_DIR="${qualifiedQuartusRoot}"
          export LOCAL_INSTALLER_DIR="''${LOCAL_INSTALLER_DIR:-${installerRoot}}"
          export IMAGE_TAG="''${IMAGE_TAG:-${imageTag}}"

          exec quartus-tools "$@"
        '';
      };

      svunitQuartusPodman = pkgs.writeShellApplication {
        name = "svunit-quartus-podman";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gawk
          pkgs.gnugrep
          pkgs.podman
          pkgs.xorg.xhost
        ];
        text = ''
          set -euo pipefail

          IMAGE="''${IMAGE:-${imageTag}}"
          HOSTNAME="''${HOSTNAME:-svunit-quartus}"
          CONTAINER_RUNTIME="''${CONTAINER_RUNTIME:-podman}"
          REPO_ROOT="''${REPO_ROOT:-$(pwd)}"
          DATA_ROOT="''${DATA_ROOT:-$REPO_ROOT/.quartus}"
          ROOT_MOUNT="''${ROOT_MOUNT:-$DATA_ROOT/root}"
          SLL_MOUNT="''${SLL_MOUNT:-$REPO_ROOT}"
          LICENSE_DIR="''${LICENSE_DIR:-${licenseRoot}}"
          DISPLAY_ENV="''${DISPLAY:-}"
          XHOST_USERS="''${XHOST_USERS:-root,$USER}"
          XAUTH_SRC="''${XAUTHORITY:-$HOME/.Xauthority}"
          GUI_MODE=0

          mkdir -p "$ROOT_MOUNT"

          if [ "''${1:-}" = "--quartus" ]; then
            GUI_MODE=1
          fi

          if [ -z "$DISPLAY_ENV" ] && [ -S /tmp/.X11-unix/X0 ]; then
            DISPLAY_ENV=":0"
          fi

          if [ "$GUI_MODE" = "1" ] && [ -z "$DISPLAY_ENV" ]; then
            echo "DISPLAY is not set. Export DISPLAY before launching the Quartus GUI." >&2
            exit 1
          fi

          if [ ! -f "$LICENSE_DIR/quartus_license.dat" ] || [ ! -f "$LICENSE_DIR/questa_license.dat" ]; then
            echo "Quartus or Questa license file missing in $LICENSE_DIR." >&2
            echo "Set LICENSE_DIR to the directory containing quartus_license.dat and questa_license.dat." >&2
            exit 1
          fi

          if ! "$CONTAINER_RUNTIME" image exists "$IMAGE" >/dev/null 2>&1; then
            echo "Container image $IMAGE not found." >&2
            echo "Run 'nix run .#quartus-tools -- build-image' first." >&2
            exit 1
          fi

          CONTAINER_ENV=(
            -e LM_LICENSE_FILE=/opt/quartus_license.dat
            -e QUARTUS_PATH=${quartusInstallRoot}
            -e QUARTUS_ROOTDIR=${quartusInstallRoot}/quartus
            -e SOPC_KIT_NIOS2=${quartusInstallRoot}/nios2eds
            -e QSYS_ROOTDIR=${quartusInstallRoot}/qsys/bin
            -e QUARTUS_64BIT=1
            -e LANG=C.UTF-8
            -e LC_ALL=C.UTF-8
            -e PATH=${quartusContainerPath}
          )

          X11_SOCKET_MOUNT=()
          if [ -n "$DISPLAY_ENV" ]; then
            CONTAINER_ENV+=(-e DISPLAY="$DISPLAY_ENV" -e QT_X11_NO_MITSHM=1)
            if [[ "$DISPLAY_ENV" == :* ]]; then
              X11_SOCKET_MOUNT=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
              IFS=',' read -r -a _xhost_users <<< "$XHOST_USERS"
              for _u in "''${_xhost_users[@]}"; do
                DISPLAY="$DISPLAY_ENV" xhost +si:localuser:"$_u" >/dev/null
              done
            fi
          fi

          XAUTH_MOUNT=()
          XAUTH_ENV=()
          if [ -f "$XAUTH_SRC" ]; then
            XAUTH_MOUNT=(-v "$XAUTH_SRC:/tmp/.Xauthority:ro")
            XAUTH_ENV=(-e XAUTHORITY=/tmp/.Xauthority)
          fi

          CONTAINER_TTY_ARGS=()
          if [ -t 0 ] && [ -t 1 ]; then
            CONTAINER_TTY_ARGS=(-it)
          fi

          DEFAULT_CMD=(/bin/bash)
          if [ "''${1:-}" = "--quartus" ]; then
            shift
            DEFAULT_CMD=(/eda/intelFPGA_pro/23.4/quartus/bin/quartus "$@")
          elif [ "$#" -gt 0 ]; then
            DEFAULT_CMD=("$@")
          fi

          exec "$CONTAINER_RUNTIME" run --rm \
            --hostname="$HOSTNAME" \
            --net=host \
            --cap-add=NET_ADMIN \
            "''${CONTAINER_ENV[@]}" \
            "''${X11_SOCKET_MOUNT[@]}" \
            "''${XAUTH_ENV[@]}" \
            -v "$ROOT_MOUNT:/root" \
            -v "$SLL_MOUNT:/sll" \
            "''${XAUTH_MOUNT[@]}" \
            -v "$LICENSE_DIR/quartus_license.dat:/opt/quartus_license.dat:ro" \
            -v "$LICENSE_DIR/questa_license.dat:/opt/questa_license.dat:ro" \
            "''${CONTAINER_TTY_ARGS[@]}" \
            "$IMAGE" "''${DEFAULT_CMD[@]}"
        '';
      };

      svunitQuartusCheck = pkgs.writeShellApplication {
        name = "svunit-quartus-check";
        runtimeInputs = [ svunitQuartusPodman ];
        text = ''
          set -euo pipefail
          check_script="$(cat <<'EOF'
          set -euo pipefail
          missing=0
          for cmd in quartus_sh qrun vlog vsim; do
            if command -v "$cmd" >/dev/null 2>&1; then
              printf "%s=%s\n" "$cmd" "$(command -v "$cmd")"
            else
              printf "missing=%s\n" "$cmd" >&2
              missing=1
            fi
          done
          exit "$missing"
          EOF
          )"
          exec svunit-quartus-podman /bin/bash -c "$check_script"
        '';
      };
    in
    {
      packages.${system} = {
        default = svunitQuartusPodman;
        quartus-tools = quartusTools;
        svunit-quartus-podman = svunitQuartusPodman;
        svunit-quartus-check = svunitQuartusCheck;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${svunitQuartusPodman}/bin/svunit-quartus-podman";
        };
        quartus-tools = {
          type = "app";
          program = "${quartusTools}/bin/svunit-quartus-tools";
        };
        svunit-quartus-podman = {
          type = "app";
          program = "${svunitQuartusPodman}/bin/svunit-quartus-podman";
        };
        svunit-quartus-check = {
          type = "app";
          program = "${svunitQuartusCheck}/bin/svunit-quartus-check";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          quartusTools
          svunitQuartusPodman
          svunitQuartusCheck
          pkgs.git
          pkgs.perl
          pkgs.podman
          pkgs.python3
          pkgs.ripgrep
        ];

        shellHook = ''
          export QUARTUS_QUALIFIED_ROOT="${qualifiedQuartusRoot}"
          export QUARTUS_IMAGE_TAG="${imageTag}"
          if [ -f Setup.bsh ]; then
            source Setup.bsh
          fi
        '';
      };
    };
}
