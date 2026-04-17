{
  description = "SVUnit X — qualification, certification and development shell";

  # ---------------------------------------------------------------------------
  # Dependency architecture
  #
  # This flake provides a single svunit-certify command that supports multiple
  # simulators (qrun, modelsim, verilator, and later xsim).  All simulator
  # runtimes are bundled into one closure so a single `nix run .#svunit-certify`
  # works for any --simulator flag without per-simulator Nix packages.
  #
  # Execution model per simulator:
  #   qrun / modelsim  — Tests run INSIDE a Podman container (Quartus Pro image).
  #                       The container has its own python3 and bootstraps pip/pytest
  #                       at runtime.  Host python3 and Verilator deps are on PATH
  #                       but never visible to the container (isolated filesystem).
  #   verilator         — Tests run NATIVELY on the host.  Needs verilator, gcc,
  #                       make, and python3-with-pytest on the host PATH.
  #   xsim (planned)    — Will follow the container pattern (Vivado image).
  #
  # Why not per-simulator packages?  The shared script logic (argument parsing,
  # run-ID generation, JUnit XML parsing, artefact writing, symlink management)
  # would need to be duplicated or extracted.  The overhead of carrying unused
  # deps on PATH is negligible (Nix store deduplication), and the container
  # isolation means host-side deps cannot interfere with container-based runs.
  # ---------------------------------------------------------------------------

  inputs = {
    quartus-podman-23-4 = {
      url = "git+ssh://prv.git.i01.synaptic-labs.com/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v23_4_0_79";
    };
    quartus-podman-25-1 = {
      # TODO: switch to git+ssh://prv.git.i01.synaptic-labs.com/... once the
      # altera 25.1.1.125 Podman repo is pushed there.  Using git+file:// for
      # now because the repo at this path is still under development.
      url = "git+file:///srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v25_1_1_125";
      inputs.nixpkgs.follows = "quartus-podman-23-4/nixpkgs";
    };
    verilator-certified = {
      # Provides verilator 5.044 binary + cc + make.  Uses nixos-unstable
      # internally; we do NOT follow its nixpkgs — we only consume binaries.
      url = "git+ssh://prv.git.i01.synaptic-labs.com/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_verilator/r_v5_044";
    };
    nixpkgs.follows = "quartus-podman-23-4/nixpkgs";
  };

  outputs = { nixpkgs, quartus-podman-23-4, quartus-podman-25-1, verilator-certified, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      qualifiedQuartusRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v23_4_0_79";
      svunitArtefactsRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts";
      certToolsDir = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_sll_tools_qualified/r_cert_tools";
      qualifiedVerilatorRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_verilator/r_v5_044";
      verilatorPkg = verilator-certified.packages.${system}.default;
      verilatorCc = verilator-certified.packages.${system}.cc;
      verilatorMake = verilator-certified.packages.${system}.make;

      # Python with pytest for native (non-container) test runs.
      # Container-based simulators (qrun, modelsim) bootstrap their own
      # pip+pytest inside the container and never see this python.
      #
      # pytest-datafiles is pinned to 2.0: the SVUnit test suite uses the
      # .as_cwd() API which was removed in 3.x (returns PosixPath instead).
      # The Questa container also pins 2.0 via pip install.
      pytestDatafiles2 = pkgs.python3Packages.buildPythonPackage rec {
        pname = "pytest-datafiles";
        version = "2.0";
        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-FDMpy7HbuwevJPiPpGaOL1nOIzaWzxLEn9HJjRdW2/k=";
        };
        propagatedBuildInputs = [ pkgs.python3Packages.pytest ];
        doCheck = false;
      };
      pythonWithPytest = pkgs.python3.withPackages (ps: [
        ps.pytest
        pytestDatafiles2
      ]);

      # Python helpers used by svunit-certify and svunit-timing-report.
      # Kept as standalone files under ./scripts/ so editors give syntax
      # highlighting and pkgs.writers.writePython3 validates them at build
      # time (vs. previously embedding them in bash heredocs).
      #
      # flakeIgnore:
      #   E265 — writePython3 injects its own shebang, so ours becomes
      #          an ordinary comment and flake8 complains about spacing.
      #   E501 — we do not enforce the PEP 8 79-char line limit.
      pyWriterOpts = {
        flakeIgnore = [ "E265" "E501" ];
      };
      timingSummaryScript = pkgs.writers.writePython3
        "timing-summary.py" pyWriterOpts
        (builtins.readFile ./scripts/timing-summary.py);
      timingReportScript = pkgs.writers.writePython3
        "timing-report.py" pyWriterOpts
        (builtins.readFile ./scripts/timing-report.py);

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

      rawQuartusTools = quartus-podman-23-4.packages.${system}.quartus-tools;

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
            -e LM_LICENSE_FILE=/opt/quartus_license.dat:/opt/questa_license.dat
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

      # --- Timing comparison report ---
      # Scans artefacts root for timing-summary.json files, finds the latest
      # run per simulator per hostname, and produces a cross-simulator comparison.
      svunitTimingReport = pkgs.writeShellApplication {
        name = "svunit-timing-report";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail
          ARTEFACTS_ROOT="''${1:-${svunitArtefactsRoot}}"
          exec ${timingReportScript} "$ARTEFACTS_ROOT"
        '';
      };

      svunitCertify = pkgs.writeShellApplication {
        name = "svunit-certify";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gawk
          pkgs.gnugrep
          pkgs.jq
          pkgs.perl
          pkgs.podman
          pythonWithPytest
          verilatorPkg
          verilatorCc
          verilatorMake
        ];
        text = ''
          set -euo pipefail

          # --- Qualification helpers ---
          # shellcheck source=/dev/null
          source "${certToolsDir}/scripts/qualification-helpers.sh"

          TOOL_GROUP="g_svunit_x"
          TOOL_VERSION="r_v3_38_1_x0_2_0"
          QUALIFIED_VERSION="3.38.1-x0.2.0"
          ARTEFACTS_ROOT="${svunitArtefactsRoot}"

          SIMULATOR=""
          OUTPUT_DIR=""
          PYTEST_FILTER=""
          REPO_ROOT="''${REPO_ROOT:-$(pwd)}"

          usage() {
            cat <<USAGE
          Usage: svunit-certify --simulator <sim> [--output-dir DIR] [--filter EXPR]

          Simulators:
            qrun        Questa qrun (via Quartus Pro Podman container)
            modelsim    Questa modelsim (via Quartus Pro Podman container)
            verilator   Verilator 5.044 (native, no container)
            xsim        Xilinx xsim (via Vivado container) [not yet implemented]

          Options:
            --output-dir DIR   Artefact output directory (default: per qualification standard)
            --filter EXPR      Pytest -k filter expression (default: by simulator name)
          USAGE
            exit 2
          }

          while [ $# -gt 0 ]; do
            case "$1" in
              --simulator|-s) SIMULATOR="$2"; shift 2 ;;
              --output-dir|-o) OUTPUT_DIR="$2"; shift 2 ;;
              --filter|-k) PYTEST_FILTER="$2"; shift 2 ;;
              --help|-h) usage ;;
              *) echo "Unknown argument: $1" >&2; usage ;;
            esac
          done

          if [ -z "$SIMULATOR" ]; then
            echo "ERROR: --simulator is required" >&2
            usage
          fi

          # --- Simulator-specific configuration ---
          IMAGE=""
          IMAGE_ID="N/A"
          CONTAINER_RUNTIME=""
          LICENSE_DIR=""
          EXPECTED_QUARTUS_VERSION=""
          EXPECTED_QUESTA_VERSION=""
          EXPECTED_VERILATOR_VERSION=""
          VERILATOR_STORE_PATH=""
          SIM_DISPLAY_NAME=""

          case "$SIMULATOR" in
            qrun|modelsim)
              IMAGE="''${IMAGE:-${imageTag}}"
              CONTAINER_RUNTIME="''${CONTAINER_RUNTIME:-podman}"
              LICENSE_DIR="''${LICENSE_DIR:-${licenseRoot}}"
              EXPECTED_QUARTUS_VERSION="Version 23.4.0 Build 79"
              EXPECTED_QUESTA_VERSION="2023.3"
              SIM_DISPLAY_NAME="Questa FPGA Edition 2023.3 (via Quartus Pro 23.4.0.79 container)"
              # Exclude UVM tests that require svverification license (randomize())
              if [ -z "$PYTEST_FILTER" ]; then
                PYTEST_FILTER="$SIMULATOR and not uvm_simple_model"
              fi
              ;;
            verilator)
              EXPECTED_VERILATOR_VERSION="5.044"
              # shellcheck disable=SC2016
              VERILATOR_STORE_PATH='${verilatorPkg}'
              SIM_DISPLAY_NAME="Verilator $EXPECTED_VERILATOR_VERSION (native, qualified from g_verilator/r_v5_044)"
              if [ -z "$PYTEST_FILTER" ]; then
                PYTEST_FILTER="verilator"
              fi
              ;;
            xsim)
              echo "ERROR: Vivado/xsim certification not yet implemented." >&2
              exit 2
              ;;
            *)
              echo "ERROR: Unknown simulator: $SIMULATOR" >&2
              usage
              ;;
          esac

          PYTEST_FILTER="''${PYTEST_FILTER:-$SIMULATOR}"

          if [ ! -f "$REPO_ROOT/Setup.bsh" ]; then
            echo "ERROR: Setup.bsh not found. Run from the SVUnit repo root or set REPO_ROOT." >&2
            exit 2
          fi

          # --- Simulator-specific pre-validation ---
          case "$SIMULATOR" in
            qrun|modelsim)
              for lic in quartus_license.dat questa_license.dat; do
                if [ ! -f "$LICENSE_DIR/$lic" ]; then
                  echo "ERROR: Missing $LICENSE_DIR/$lic" >&2
                  exit 2
                fi
              done
              if ! "$CONTAINER_RUNTIME" image exists "$IMAGE" >/dev/null 2>&1; then
                echo "ERROR: Container image $IMAGE not found." >&2
                echo "Run 'nix run .#quartus-tools -- build-image' first." >&2
                exit 2
              fi
              ;;
            verilator)
              if ! command -v verilator >/dev/null 2>&1; then
                echo "ERROR: verilator binary not found on PATH." >&2
                exit 2
              fi
              if ! verilator --version 2>&1 | grep -qF "$EXPECTED_VERILATOR_VERSION"; then
                echo "ERROR: verilator version mismatch. Expected $EXPECTED_VERILATOR_VERSION, got: $(verilator --version 2>&1)" >&2
                exit 2
              fi
              if ! command -v gcc >/dev/null 2>&1; then
                echo "ERROR: gcc not found on PATH (required for Verilator compilation)." >&2
                exit 2
              fi
              if ! command -v make >/dev/null 2>&1; then
                echo "ERROR: make not found on PATH (required for Verilator compilation)." >&2
                exit 2
              fi
              ;;
          esac

          # --- Build run ID per qualification standard ---
          qh_detect_gpu
          qh_build_run_id --no-gpu-suffix

          OUTPUT_DIR="''${OUTPUT_DIR:-$ARTEFACTS_ROOT/$QH_RUN_ID}"
          mkdir -p "$OUTPUT_DIR"

          SVUNIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"

          # --- Simulator-specific pre-run setup ---
          case "$SIMULATOR" in
            qrun|modelsim)
              IMAGE_ID="$("$CONTAINER_RUNTIME" image inspect "$IMAGE" --format '{{.Id}}' 2>/dev/null || echo "unknown")"
              "$CONTAINER_RUNTIME" inspect "$IMAGE" > "$OUTPUT_DIR/image-inspect.json" 2>/dev/null || true
              ;;
          esac

          echo "=== SVUnit Qualification ==="
          echo "Tool:       $TOOL_GROUP $QUALIFIED_VERSION"
          echo "Simulator:  $SIMULATOR ($SIM_DISPLAY_NAME)"
          echo "Run ID:     $QH_RUN_ID"
          echo "Output:     $OUTPUT_DIR"
          echo "Filter:     $PYTEST_FILTER"
          echo ""

          # --- Run tests (simulator-specific) ---
          EXIT_CODE=0

          case "$SIMULATOR" in
            qrun|modelsim)
              echo "--- Running qualification inside container ---"

              # shellcheck disable=SC2016
              container_script="$(cat <<'CONTAINER_EOF'
          set -euo pipefail

          # --- Bootstrap pytest ---
          python3 -c "
          import urllib.request, tempfile, subprocess, sys
          f = tempfile.NamedTemporaryFile(suffix='.py', delete=False)
          urllib.request.urlretrieve('https://bootstrap.pypa.io/get-pip.py', f.name)
          subprocess.check_call([sys.executable, f.name, '--break-system-packages', '-q'])
          "
          pip3 install --break-system-packages -q "pytest>=7,<9" "pytest-datafiles==2.0" 2>&1

          # --- Version checks ---
          echo "--- version checks ---"
          fail=0
          if ! quartus_sh --version 2>&1 | grep -qF "$EXPECTED_QUARTUS_VERSION"; then
            echo "FAIL: quartus_sh version does not match $EXPECTED_QUARTUS_VERSION" >&2
            fail=1
          else
            echo "OK: quartus_sh version matches $EXPECTED_QUARTUS_VERSION"
          fi
          for tool in qrun vlog vsim; do
            if ! "$tool" -version 2>&1 | grep -qF "$EXPECTED_QUESTA_VERSION"; then
              echo "FAIL: $tool version does not match $EXPECTED_QUESTA_VERSION" >&2
              fail=1
            else
              echo "OK: $tool version matches $EXPECTED_QUESTA_VERSION"
            fi
          done
          if [ "$fail" -ne 0 ]; then
            echo "FAIL: version smoke checks failed" >&2
            exit 1
          fi

          # --- Run SVUnit test suite ---
          cd /sll
          source Setup.bsh
          cd test
          echo ""
          echo "--- pytest -k $PYTEST_FILTER ---"
          python3 -m pytest -v -k "$PYTEST_FILTER" \
            --tb=short \
            --durations=0 \
            --junitxml=/artefacts/tests.xml \
            2>&1 || true
          CONTAINER_EOF
              )"

              "$CONTAINER_RUNTIME" run --rm \
                --net=host \
                --cap-add=NET_ADMIN \
                -e LM_LICENSE_FILE=/opt/quartus_license.dat:/opt/questa_license.dat \
                -e QUARTUS_PATH="${quartusInstallRoot}" \
                -e QUARTUS_ROOTDIR="${quartusInstallRoot}/quartus" \
                -e SOPC_KIT_NIOS2="${quartusInstallRoot}/nios2eds" \
                -e QSYS_ROOTDIR="${quartusInstallRoot}/qsys/bin" \
                -e QUARTUS_64BIT=1 \
                -e LANG=C.UTF-8 \
                -e LC_ALL=C.UTF-8 \
                -e PATH="${quartusContainerPath}" \
                -e EXPECTED_QUARTUS_VERSION="$EXPECTED_QUARTUS_VERSION" \
                -e EXPECTED_QUESTA_VERSION="$EXPECTED_QUESTA_VERSION" \
                -e PYTEST_FILTER="$PYTEST_FILTER" \
                -v "$REPO_ROOT:/sll" \
                -v "$LICENSE_DIR/quartus_license.dat:/opt/quartus_license.dat:ro" \
                -v "$LICENSE_DIR/questa_license.dat:/opt/questa_license.dat:ro" \
                -v "$OUTPUT_DIR:/artefacts" \
                "$IMAGE" /bin/bash -c "$container_script" \
                > "$OUTPUT_DIR/test-log.txt" 2>&1 || EXIT_CODE=$?
              ;;

            verilator)
              echo "--- Running qualification natively (Verilator) ---"

              # --- Version checks ---
              echo "--- version checks ---"
              ACTUAL_VER="$(verilator --version 2>&1)"
              echo "OK: verilator version = $ACTUAL_VER"
              echo "OK: gcc version = $(gcc --version 2>&1 | head -1)"
              echo "OK: make version = $(make --version 2>&1 | head -1)"

              # --- Run SVUnit test suite natively ---
              # pytest is provided by pythonWithPytest in runtimeInputs (no pip needed)
              (
                cd "$REPO_ROOT"
                # shellcheck source=/dev/null
                source Setup.bsh
                cd test
                echo ""
                echo "--- pytest -k $PYTEST_FILTER ---"
                python3 -m pytest -v -k "$PYTEST_FILTER" \
                  --tb=short \
                  --durations=0 \
                  --junitxml="$OUTPUT_DIR/tests.xml" \
                  2>&1 || true
              ) > "$OUTPUT_DIR/test-log.txt" 2>&1 || EXIT_CODE=$?
              ;;
          esac

          # --- Determine pass/fail from JUnit XML ---
          if [ -f "$OUTPUT_DIR/tests.xml" ]; then
            TOTAL="$(grep -oP '\btests="\K[0-9]+' "$OUTPUT_DIR/tests.xml" | head -1 || echo "0")"
            FAILURES="$(grep -oP '\bfailures="\K[0-9]+' "$OUTPUT_DIR/tests.xml" | head -1 || echo "0")"
            ERRORS="$(grep -oP '\berrors="\K[0-9]+' "$OUTPUT_DIR/tests.xml" | head -1 || echo "0")"
            SKIPPED="$(grep -oP '\bskipped="\K[0-9]+' "$OUTPUT_DIR/tests.xml" | head -1 || echo "0")"
            PASSED=$((TOTAL - FAILURES - ERRORS - SKIPPED))
          else
            TOTAL=0; FAILURES=0; ERRORS=0; SKIPPED=0; PASSED=0
          fi

          if [ "$FAILURES" -eq 0 ] && [ "$ERRORS" -eq 0 ] && [ "$PASSED" -gt 0 ]; then
            STATUS="PASS"
          else
            STATUS="FAIL"
          fi

          # --- timing-summary.json from JUnit XML ---
          if [ -f "$OUTPUT_DIR/tests.xml" ]; then
            ${timingSummaryScript} "$OUTPUT_DIR/tests.xml" "$SIMULATOR" "$(hostname)" \
              "$QH_RUN_ID" "$OUTPUT_DIR/timing-summary.json"
            echo "Wrote timing-summary.json ($(jq '.tests | length' "$OUTPUT_DIR/timing-summary.json") tests)"
          fi

          # --- build-info.json via qh_build_info_json + simulator extensions ---
          qh_build_info_json "$OUTPUT_DIR/build-info.json" \
            "$TOOL_GROUP" "$TOOL_VERSION" "$QUALIFIED_VERSION" \
            "$REPO_ROOT" "nixos-25.05" "generic"

          # Append simulator-specific fields to build-info.json
          TMP_JSON="$(mktemp)"
          JQ_COMMON=(
            --arg sim "$SIMULATOR"
            --arg sim_display "$SIM_DISPLAY_NAME"
            --arg svunit_commit "$SVUNIT_COMMIT"
            --arg pytest_filter "$PYTEST_FILTER"
            --arg status "$STATUS"
            --argjson tests_total "$TOTAL"
            --argjson tests_passed "$PASSED"
            --argjson tests_failed "$FAILURES"
            --argjson tests_errors "$ERRORS"
            --argjson tests_skipped "$SKIPPED"
            --argjson exit_code "$EXIT_CODE"
          )

          case "$SIMULATOR" in
            qrun|modelsim)
              jq \
                "''${JQ_COMMON[@]}" \
                --arg image_tag "$IMAGE" \
                --arg image_id "$IMAGE_ID" \
                --arg quartus_version "$EXPECTED_QUARTUS_VERSION" \
                --arg questa_version "$EXPECTED_QUESTA_VERSION" \
                '. + {
                  simulator: $sim, simulator_display: $sim_display,
                  container_image_tag: $image_tag, container_image_id: $image_id,
                  quartus_version: $quartus_version, questa_version: $questa_version,
                  svunit_commit: $svunit_commit, pytest_filter: $pytest_filter,
                  qualification_status: $status,
                  tests_total: $tests_total, tests_passed: $tests_passed,
                  tests_failed: $tests_failed, tests_errors: $tests_errors,
                  tests_skipped: $tests_skipped, exit_code: $exit_code
                }' "$OUTPUT_DIR/build-info.json" > "$TMP_JSON"
              ;;
            verilator)
              jq \
                "''${JQ_COMMON[@]}" \
                --arg verilator_version "$EXPECTED_VERILATOR_VERSION" \
                --arg verilator_store_path "$VERILATOR_STORE_PATH" \
                '. + {
                  simulator: $sim, simulator_display: $sim_display,
                  verilator_version: $verilator_version,
                  verilator_store_path: $verilator_store_path,
                  svunit_commit: $svunit_commit, pytest_filter: $pytest_filter,
                  qualification_status: $status,
                  tests_total: $tests_total, tests_passed: $tests_passed,
                  tests_failed: $tests_failed, tests_errors: $tests_errors,
                  tests_skipped: $tests_skipped, exit_code: $exit_code
                }' "$OUTPUT_DIR/build-info.json" > "$TMP_JSON"
              ;;
          esac
          mv "$TMP_JSON" "$OUTPUT_DIR/build-info.json"

          # --- qualification-results.md ---
          OS_VER="$(grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo unknown)"
          NIX_VER="$(nix --version 2>/dev/null | awk '{print $NF}' || echo unknown)"
          KERNEL_VER="$(uname -r)"

          # Header (common)
          cat > "$OUTPUT_DIR/qualification-results.md" <<QREOF
          # Qualification Results — $TOOL_GROUP $TOOL_VERSION

          **Run ID:** $QH_RUN_ID
          **Pass:** generic
          **Executed:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
          **Overall:** $STATUS ($PASSED passed, $FAILURES failed, $SKIPPED skipped)

          ## Environment

          | Field | Value |
          |-------|-------|
          | OS | NixOS $OS_VER |
          | Kernel | $KERNEL_VER |
          | Nix | $NIX_VER |
          | Platform | x86_64-linux |
          | Hostname | $(hostname) |
          QREOF

          # Simulator section (per-simulator)
          case "$SIMULATOR" in
            qrun|modelsim)
              cat >> "$OUTPUT_DIR/qualification-results.md" <<SIMEOF

          ## Simulator

          | Field | Value |
          |-------|-------|
          | Simulator | $SIMULATOR |
          | Description | $SIM_DISPLAY_NAME |
          | Container Image | $IMAGE |
          | Container Image ID | $IMAGE_ID |
          | Quartus Version | $EXPECTED_QUARTUS_VERSION |
          | Questa Version | $EXPECTED_QUESTA_VERSION |
          SIMEOF
              ;;
            verilator)
              cat >> "$OUTPUT_DIR/qualification-results.md" <<SIMEOF

          ## Simulator

          | Field | Value |
          |-------|-------|
          | Simulator | $SIMULATOR |
          | Description | $SIM_DISPLAY_NAME |
          | Verilator Version | $EXPECTED_VERILATOR_VERSION |
          | Verilator Store Path | $VERILATOR_STORE_PATH |
          | Container | None (native execution) |
          SIMEOF
              ;;
          esac

          # SVUnit, Test Summary, Evidence, Raw Output (common)
          EVIDENCE_LIST="- tests.xml — JUnit XML results from the pytest run.
          - test-log.txt — full output including version checks and pytest output.
          - build-info.json — machine-readable qualification metadata.
          - timing-summary.json — per-test durations for cross-simulator profiling."

          case "$SIMULATOR" in
            qrun|modelsim)
              EVIDENCE_LIST="$EVIDENCE_LIST
          - image-inspect.json — container image metadata."
              ;;
          esac

          cat >> "$OUTPUT_DIR/qualification-results.md" <<TAILEOF

          ## SVUnit

          | Field | Value |
          |-------|-------|
          | Qualified Version | $QUALIFIED_VERSION |
          | Commit | $SVUNIT_COMMIT |
          | Pytest Filter | $PYTEST_FILTER |

          ## Test Summary

          | Metric | Count |
          |--------|-------|
          | Total | $TOTAL |
          | Passed | $PASSED |
          | Failed | $FAILURES |
          | Errors | $ERRORS |
          | Skipped | $SKIPPED |

          ## Evidence

          $EVIDENCE_LIST

          ## Raw Output

          \`\`\`text
          $(cat "$OUTPUT_DIR/test-log.txt")
          \`\`\`
          TAILEOF

          # --- Update latest symlink ---
          qh_update_latest_symlink "$ARTEFACTS_ROOT" "$QH_RUN_ID"

          echo ""
          echo "=== Qualification Complete ==="
          echo "Status:   $STATUS"
          echo "Results:  $PASSED passed, $FAILURES failed, $ERRORS errors, $SKIPPED skipped (of $TOTAL)"
          echo "Run ID:   $QH_RUN_ID"
          echo "Output:   $OUTPUT_DIR"

          if [ "$STATUS" = "FAIL" ]; then
            exit 1
          fi
        '';
      };
    in
    {
      packages.${system} = {
        default = svunitQuartusPodman;
        quartus-tools = quartusTools;
        svunit-quartus-podman = svunitQuartusPodman;
        svunit-quartus-check = svunitQuartusCheck;
        svunit-certify = svunitCertify;
        svunit-timing-report = svunitTimingReport;
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
        svunit-certify = {
          type = "app";
          program = "${svunitCertify}/bin/svunit-certify";
        };
        svunit-timing-report = {
          type = "app";
          program = "${svunitTimingReport}/bin/svunit-timing-report";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          quartusTools
          svunitQuartusPodman
          svunitQuartusCheck
          svunitCertify
          svunitTimingReport
          pkgs.git
          pkgs.perl
          pkgs.podman
          pythonWithPytest
          pkgs.ripgrep
          verilatorPkg
          verilatorCc
          verilatorMake
        ];

        shellHook = ''
          export QUARTUS_QUALIFIED_ROOT="${qualifiedQuartusRoot}"
          export QUARTUS_IMAGE_TAG="${imageTag}"
          export VERILATOR_QUALIFIED_ROOT="${qualifiedVerilatorRoot}"
          if [ -f Setup.bsh ]; then
            source Setup.bsh
          fi
        '';
      };
    };
}
