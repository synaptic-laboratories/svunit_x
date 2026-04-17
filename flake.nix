{
  description = "SVUnit X — qualification, certification and development shell";

  # ---------------------------------------------------------------------------
  # Dependency architecture
  #
  # Each supported simulator is a registry entry in nix/registry.nix.  For
  # every entry the flake emits:
  #   - packages.svunit-certify-<target>        qualification runner
  #   - packages.svunit-quartus-shell-<target>  interactive launcher (container only)
  #   - packages.svunit-quartus-tools-<target>  upstream image-build tool  (Quartus only)
  #   - matching apps.<name>
  #
  # A top-level `svunit-certify-all` package runs every target sequentially.
  #
  # Three adapter types are supported, corresponding to three upstream flake
  # shapes:
  #   container — Quartus Pro Podman images (qrun / modelsim inside podman)
  #   native    — Verilator binary on PATH
  #   fhs       — Vivado xsim via buildFHSEnv wrappers (stub for now)
  #
  # Adding a Quartus version is two lines in nix/registry.nix plus a new
  # flake input.  The adapter shell scripts (scripts/certify.sh,
  # scripts/quartus-shell.sh) are shared across versions.
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
      lib = pkgs.lib;

      # -----------------------------------------------------------------------
      # Host paths (not in any flake input)
      # -----------------------------------------------------------------------
      svunitArtefactsRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts";
      certToolsDir = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_sll_tools_qualified/r_cert_tools";
      licenseRoot = "/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch";

      # -----------------------------------------------------------------------
      # Python environment and helper scripts
      # -----------------------------------------------------------------------
      # pytest-datafiles pinned to 2.0: the SVUnit suite uses the .as_cwd()
      # API removed in 3.x.  The Questa container also pins 2.0 via pip.
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

      # flakeIgnore: E265 — writePython3 injects a shebang, so ours becomes
      # an ordinary comment; E501 — we do not enforce the 79-char line limit.
      pyWriterOpts = { flakeIgnore = [ "E265" "E501" ]; };
      timingSummaryScript = pkgs.writers.writePython3
        "timing-summary.py" pyWriterOpts
        (builtins.readFile ./scripts/timing-summary.py);
      timingReportScript = pkgs.writers.writePython3
        "timing-report.py" pyWriterOpts
        (builtins.readFile ./scripts/timing-report.py);

      # -----------------------------------------------------------------------
      # Simulator registry and adapter factories
      # -----------------------------------------------------------------------
      registry = import ./nix/registry.nix {
        inherit pkgs lib quartus-podman-23-4 quartus-podman-25-1 verilator-certified;
      };

      certifyShellScript = pkgs.writeShellApplication {
        name = "certify-impl.sh";
        runtimeInputs = [ pkgs.bash ];
        text = builtins.readFile ./scripts/certify.sh;
      };
      quartusShellScript = pkgs.writeShellApplication {
        name = "quartus-shell-impl.sh";
        runtimeInputs = [ pkgs.bash ];
        text = builtins.readFile ./scripts/quartus-shell.sh;
      };

      certifyFactory = import ./nix/mk-certify.nix {
        inherit pkgs lib pythonWithPytest certToolsDir licenseRoot;
        artefactsRoot = svunitArtefactsRoot;
        certifyScript = "${certifyShellScript}/bin/certify-impl.sh";
        inherit timingSummaryScript;
      };
      shellFactory = import ./nix/mk-quartus-shell.nix {
        inherit pkgs lib licenseRoot;
        shellScript = "${quartusShellScript}/bin/quartus-shell-impl.sh";
      };

      targetNames = builtins.attrNames registry;
      containerTargetNames = lib.filter
        (n: registry.${n}.adapter == "container")
        targetNames;

      # Quartus "bases" = distinct container images.  qrun and modelsim
      # targets that share an image collapse to a single base, so we emit
      # one shell launcher and one quartus-tools wrapper per image rather
      # than one per (image, tool) combination.
      #
      # baseName is derived by stripping the `-<tool>` suffix from the
      # target name, e.g. quartus-23-4-qrun → quartus-23-4.
      stripToolSuffix = name:
        let tools = [ "-qrun" "-modelsim" "-verilator" "-xsim" ]; in
        lib.foldl' (n: sfx: lib.removeSuffix sfx n) name tools;
      containerBases = lib.unique (map stripToolSuffix containerTargetNames);
      firstTargetForBase = base: lib.head (lib.filter
        (n: stripToolSuffix n == base)
        containerTargetNames);

      # Per-target packages derived from the registry.
      certifyPackages = lib.genAttrs targetNames
        (n: certifyFactory.mkCertify n registry.${n});
      shellPackages = lib.genAttrs containerBases
        (base: shellFactory.mkQuartusShell base registry.${firstTargetForBase base});

      # -----------------------------------------------------------------------
      # quartus-tools wrappers (per Quartus base) — thin wrappers around the
      # upstream flake's quartus-tools that pre-set DOCKERFILE_DIR,
      # LOCAL_INSTALLER_DIR and IMAGE_TAG for the base image.
      # -----------------------------------------------------------------------
      mkQuartusToolsWrapper = name: target:
        pkgs.writeShellApplication {
          name = "svunit-quartus-tools-${name}";
          runtimeInputs = [ target.upstreamTools ];
          text = ''
            set -euo pipefail
            export DOCKERFILE_DIR=${lib.escapeShellArg target.qualifiedRoot}
            export IMAGE_TAG="''${IMAGE_TAG:-${target.imageTag}}"
            ${lib.optionalString (target.installerRoot != null) ''
              export LOCAL_INSTALLER_DIR="''${LOCAL_INSTALLER_DIR:-${target.installerRoot}}"
            ''}
            exec quartus-tools "$@"
          '';
        };
      quartusToolsPackages = lib.genAttrs containerBases
        (base: mkQuartusToolsWrapper base registry.${firstTargetForBase base});

      # -----------------------------------------------------------------------
      # Aggregate packages
      # -----------------------------------------------------------------------
      svunitTimingReport = pkgs.writeShellApplication {
        name = "svunit-timing-report";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          set -euo pipefail
          ARTEFACTS_ROOT="''${1:-${svunitArtefactsRoot}}"
          exec ${timingReportScript} "$ARTEFACTS_ROOT"
        '';
      };

      # Runs every registered target sequentially.  Individual target failures
      # do not abort the run; the final timing report is printed regardless.
      svunitCertifyAll = pkgs.writeShellApplication {
        name = "svunit-certify-all";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          set -uo pipefail
          FAILED=()
          ${lib.concatMapStringsSep "\n" (n: ''
            echo ""
            echo "=========================================================="
            echo " Target: ${n}"
            echo "=========================================================="
            if ${certifyPackages.${n}}/bin/svunit-certify-${n} "$@"; then
              :
            else
              FAILED+=(${lib.escapeShellArg n})
            fi
          '') targetNames}
          echo ""
          echo "=========================================================="
          echo " Cross-target timing report"
          echo "=========================================================="
          ${svunitTimingReport}/bin/svunit-timing-report || true
          echo ""
          if [ "''${#FAILED[@]}" -gt 0 ]; then
            echo "FAILED targets: ''${FAILED[*]}" >&2
            exit 1
          fi
          echo "All targets passed."
        '';
      };

      # -----------------------------------------------------------------------
      # Per-target app entries
      # -----------------------------------------------------------------------
      mkApp = pkg: binName: { type = "app"; program = "${pkg}/bin/${binName}"; };
      certifyApps = lib.mapAttrs
        (n: pkg: mkApp pkg "svunit-certify-${n}")
        certifyPackages;
      shellApps = lib.mapAttrs
        (n: pkg: mkApp pkg "svunit-quartus-shell-${n}")
        shellPackages;
      toolsApps = lib.mapAttrs
        (n: pkg: mkApp pkg "svunit-quartus-tools-${n}")
        quartusToolsPackages;

      # Per-target app attribute names, e.g. "svunit-certify-quartus-23-4-qrun".
      prefixAttrs = prefix: attrs: lib.mapAttrs' (n: v: {
        name = "${prefix}-${n}";
        value = v;
      }) attrs;

      # First container base, used as the default interactive-shell pick.
      firstContainerBase = lib.head containerBases;
    in
    {
      packages.${system} =
        (prefixAttrs "svunit-certify" certifyPackages) //
        (prefixAttrs "svunit-quartus-shell" shellPackages) //
        (prefixAttrs "svunit-quartus-tools" quartusToolsPackages) //
        {
          svunit-certify-all = svunitCertifyAll;
          svunit-timing-report = svunitTimingReport;
          default = svunitCertifyAll;
        };

      apps.${system} =
        (prefixAttrs "svunit-certify" certifyApps) //
        (prefixAttrs "svunit-quartus-shell" shellApps) //
        (prefixAttrs "svunit-quartus-tools" toolsApps) //
        {
          svunit-certify-all = mkApp svunitCertifyAll "svunit-certify-all";
          svunit-timing-report = mkApp svunitTimingReport "svunit-timing-report";
          default = mkApp svunitCertifyAll "svunit-certify-all";
        };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          svunitCertifyAll
          svunitTimingReport
          pkgs.git
          pkgs.perl
          pkgs.podman
          pythonWithPytest
          pkgs.ripgrep
        ]
        ++ builtins.attrValues certifyPackages
        ++ builtins.attrValues shellPackages
        ++ builtins.attrValues quartusToolsPackages;

        shellHook = ''
          export SVUNIT_ARTEFACTS_ROOT=${lib.escapeShellArg svunitArtefactsRoot}
          export SVUNIT_TARGETS=${lib.escapeShellArg (lib.concatStringsSep " " targetNames)}
          export SVUNIT_DEFAULT_CONTAINER_BASE=${lib.escapeShellArg firstContainerBase}
          if [ -f Setup.bsh ]; then
            source Setup.bsh
          fi
        '';
      };
    };
}
