# Simulator target registry.
#
# Each attr is a fully concrete qualification target: one simulator binary,
# one version, one execution path.  The registry is consumed by the factory
# functions in nix/mk-certify.nix and nix/mk-quartus-shell.nix, and is the
# single source of truth for `svunit-certify --target NAME`.
#
# Adapter values:
#   container — run pytest inside a Quartus Pro Podman image
#   native    — run pytest natively against tools on PATH (Verilator)
#   fhs       — run pytest natively with tools wrapped in a Nix FHS env (Vivado, stub)
#
# Adding a target: append another attr, then regenerate flake.lock if a new
# input was introduced.  No other code changes are needed — the flake
# iterates over attrNames to emit per-target packages and apps.

{ pkgs
, lib
, quartus-podman-23-4
, quartus-podman-25-1
, verilator-certified
}:

let
  # PATH inside a Quartus Pro 23.x/25.x container.  The install-root prefix
  # differs per version (/eda/intelFPGA_pro/<MAJ.MIN>) but the suffix list
  # is identical across versions we support today.
  mkQuartusContainerPath = installRoot: lib.concatStringsSep ":" [
    "${installRoot}/quartus/bin"
    "${installRoot}/qsys/bin"
    "${installRoot}/questa_fe/bin"
    "${installRoot}/quartus/linux64/gnu"
    "${installRoot}/quartus/sopc_builder/bin"
    "${installRoot}/nios2eds"
    "${installRoot}/nios2eds/bin"
    "${installRoot}/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
    "${installRoot}/nios2eds/sdk2/bin"
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/sbin"
    "/usr/bin"
    "/sbin"
    "/bin"
  ];

  quartus-23-4 = {
    version = "23.4.0.79";
    installRoot = "/eda/intelFPGA_pro/23.4";
    imageTag = "localhost/quartus-pro-linux:23.4.0.79";
    expectedQuartus = "Version 23.4.0 Build 79";
    expectedQuesta = "2023.3";
    hasQuartusSh = true;
    installerRoot = "/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/quartus-pro-linux/23.4.0.79/b_individual";
    qualifiedRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v23_4_0_79";
    upstreamTools = quartus-podman-23-4.packages.${pkgs.system}.quartus-tools;
  };

  # 25.1 sim-only: Questa + FlexLM only, no quartus_sh.  Runs the same
  # pytest tests that filter on the simulator name (qrun / modelsim).
  quartus-25-1-sim-only = {
    version = "25.1.1.125";
    installRoot = "/eda/intelFPGA_pro/25.1";
    imageTag = "localhost/quartus-pro-linux:25.1.1.125-sim-only";
    expectedQuartus = null; # sim-only image, quartus_sh is not installed
    expectedQuesta = "2025.1";
    hasQuartusSh = false;
    installerRoot = null; # built via S3, not from local installers
    qualifiedRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_altera_quartus_pro_podman/r_src_v25_1_1_125";
    upstreamTools = quartus-podman-25-1.packages.${pkgs.system}.quartus-tools;
  };

  mkQuartusTarget = { base, tool, extraFilter ? "" }:
    let
      filter =
        if extraFilter == ""
        then "${tool}"
        else "${tool} and ${extraFilter}";
    in {
      adapter = "container";
      tool = tool;
      displayName = "Questa ${base.expectedQuesta} ${tool} (Quartus Pro ${base.version} container)";
      pytestFilter = filter;
      imageTag = base.imageTag;
      installRoot = base.installRoot;
      containerPath = mkQuartusContainerPath base.installRoot;
      expectedQuartus = base.expectedQuartus;
      expectedQuesta = base.expectedQuesta;
      hasQuartusSh = base.hasQuartusSh;
      installerRoot = base.installerRoot;
      qualifiedRoot = base.qualifiedRoot;
      upstreamTools = base.upstreamTools;
    };

  verilatorTarget = {
    adapter = "native";
    tool = "verilator";
    displayName = "Verilator 5.044 (native, qualified from g_verilator/r_v5_044)";
    pytestFilter = "verilator";
    expectedVerilator = "5.044";
    verilatorPkg = verilator-certified.packages.${pkgs.system}.default;
    verilatorCc = verilator-certified.packages.${pkgs.system}.cc;
    verilatorMake = verilator-certified.packages.${pkgs.system}.make;
    qualifiedRoot = "/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_verilator/r_v5_044";
  };
in
{
  # Quartus 23.4 — full Pro image, supports qrun and modelsim.
  # UVM tests excluded: they require svverification license (randomize()).
  "quartus-23-4-qrun" = mkQuartusTarget {
    base = quartus-23-4;
    tool = "qrun";
    extraFilter = "not uvm_simple_model";
  };
  "quartus-23-4-modelsim" = mkQuartusTarget {
    base = quartus-23-4;
    tool = "modelsim";
    extraFilter = "not uvm_simple_model";
  };

  # Quartus 25.1 sim-only — Questa-only image, no quartus_sh.
  "quartus-25-1-sim-only-qrun" = mkQuartusTarget {
    base = quartus-25-1-sim-only;
    tool = "qrun";
    extraFilter = "not uvm_simple_model";
  };
  "quartus-25-1-sim-only-modelsim" = mkQuartusTarget {
    base = quartus-25-1-sim-only;
    tool = "modelsim";
    extraFilter = "not uvm_simple_model";
  };

  "verilator-5-044" = verilatorTarget;
}
