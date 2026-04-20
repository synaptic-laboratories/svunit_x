# Timing Report — slldev01

| Simulator | Run ID | Wall Time | Tests | Passed | Skipped |
|-----------|--------|-----------|-------|--------|---------|
| modelsim | 20260419-1605--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70 | 59.9s | 49 | 46 | 3 |
| qrun | 20260419-1603--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70 | 59.0s | 51 | 48 | 3 |
| verilator | 20260419-1606--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70 | 2m7.2s | 56 | 47 | 9 |
| xsim | 20260419-1608--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70 | 4m9.0s | 52 | 46 | 6 |

## Per-test comparison (modelsim vs qrun vs verilator vs xsim)

| Test | modelsim (s) | qrun (s) | verilator (s) | xsim (s) | Ratio |
|---|---|---|---|---|---|
| test_example_uvm_report_mock | 3.821 | 3.846 | N/A | 10.626 | 2.8x |
| test_filter_with_partial_widlcard | 3.604 | 3.180 | 3.169 | 14.452 | 4.0x |
| test_filter | 2.351 | 2.152 | 3.260 | 9.857 | 4.2x |
| test_filter_wildcards | 2.340 | 2.201 | 3.312 | 9.804 | 4.2x |
| test_sim_12 | 1.252 | 1.226 | N/A | 5.763 | 4.6x |
| test_sim_7 | 1.215 | 1.210 | 3.167 | 4.957 | 4.1x |
| test_wavedrom_1 | 1.214 | 1.218 | N/A | N/A | N/A |
| test_example_modules_apb_slave | 1.211 | 1.192 | 3.686 | 5.100 | 4.2x |
| test_sim_9 | 1.209 | 1.173 | 3.023 | 4.815 | 4.0x |
| test_that_nothing_is_run_when_option_used | 1.208 | 1.153 | 3.066 | 4.878 | 4.0x |
| test_sim_0 | 1.208 | 1.189 | 2.977 | 4.923 | 4.1x |
| test_multiple_failing_tests | 1.207 | 1.198 | 3.111 | 4.848 | 4.0x |
| test_sim_11 | 1.207 | 1.207 | 3.543 | 4.965 | 4.1x |
| test_multiple_passing_tests | 1.206 | 1.167 | 3.145 | 4.982 | 4.1x |
| test_multiple_test_modules | 1.206 | 1.188 | 3.184 | 4.841 | 4.0x |
| test_filter_without_dot | 1.205 | 1.146 | 3.051 | 4.765 | 4.0x |
| test_util_clk_reset | 1.205 | 1.205 | N/A | N/A | N/A |
| test_that_test_case_is_printed_when_option_used | 1.203 | 1.198 | 3.064 | 4.900 | 4.1x |
| test_positive_and_negative_filter | 1.203 | 1.182 | 3.253 | 4.905 | 4.1x |
| test_sim_5 | 1.203 | 1.173 | 3.098 | 4.927 | 4.1x |
| test_writes_junit_xml | 1.202 | 1.180 | 3.118 | 4.902 | 4.1x |
| test_single_passing_test | 1.201 | 1.160 | 3.087 | 4.789 | 4.0x |
| test_that_tests_are_not_run_when_option_used | 1.201 | 1.156 | 3.085 | 4.805 | 4.0x |
| test_filter_with_extra_dot | 1.200 | 1.194 | 3.000 | 4.874 | 4.1x |
| test_negative_filter | 1.200 | 1.183 | 3.205 | 4.933 | 4.1x |
| test_sim_13 | 1.200 | 1.193 | 3.211 | N/A | N/A |
| test_single_test_suite | 1.199 | 1.178 | 3.028 | 4.903 | 4.1x |
| test_multiple_filter_expressions | 1.199 | 1.180 | 3.231 | 4.967 | 4.1x |
| test_fail_macros | 1.196 | 1.202 | 3.478 | 4.979 | 4.2x |
| test_sim_4 | 1.192 | 1.185 | 3.077 | 4.942 | 4.1x |
| test_that_test_cases_are_not_run_when_option_used | 1.190 | 1.198 | 3.042 | 4.805 | 4.0x |
| test_sim_3 | 1.178 | 1.190 | 4.014 | 5.203 | 4.4x |
| test_sim_8 | 1.175 | 1.199 | 3.030 | 4.809 | 4.1x |
| test_sim_1 | 1.171 | 1.201 | 2.961 | 4.876 | 4.2x |
| test_multiple_test_suites | 1.169 | 1.193 | 3.257 | 4.984 | 4.3x |
| test_sim_6 | 1.169 | 1.187 | 3.041 | 4.967 | 4.2x |
| test_sim_10 | 1.169 | 1.192 | 3.436 | 4.924 | 4.2x |
| test_nothing_printed_for_module_where_no_tests_selected | 1.167 | 1.188 | 3.103 | 4.855 | 4.2x |
| test_single_failing_test | 1.164 | 1.157 | 3.065 | 4.852 | 4.2x |
| test_xml_special_chars_in_message | 1.162 | 1.186 | 3.082 | 4.804 | 4.1x |
| test_that_status_is_not_reported_when_option_used | 1.160 | 1.175 | 3.111 | 4.908 | 4.2x |
| test_sim_2 | 1.160 | 1.168 | 2.940 | 4.826 | 4.2x |
| test_that_test_suites_are_not_run_when_option_used | 1.158 | 1.196 | 3.059 | 4.907 | 4.2x |
| test_that_test_from_test_case_is_printed_when_option_used | 1.154 | 1.156 | 3.117 | 4.879 | 4.2x |
| test_example_uvm_uvm_express | 0.001 | 0.001 | 0.001 | 0.001 | 1.0x |
| test_mock_uvm_report_ius | 0.001 | 0.001 | 0.001 | 0.001 | 1.0x |
| test_frmwrk_14 | N/A | N/A | N/A | N/A | N/A |
| test_mock_uvm_report | N/A | N/A | N/A | N/A | N/A |
| test_mock_uvm_report_ius_uvm1_2 | N/A | N/A | N/A | N/A | N/A |
| test_called_without_simulator__extract_sim_if_on_path | N/A | 0.049 | 0.076 | 0.088 | N/A |
| test_called_without_simulator__extract_qrun_even_if_vsim_also_on_path | N/A | 0.048 | N/A | N/A | N/A |
| test_verilator_can_take_elab_args | N/A | N/A | 0.075 | N/A | N/A |
| test_compile_error_from_verilator_signals_internal_execution_error | N/A | N/A | 0.055 | N/A | N/A |
| test_verilator_does_not_accept_uvm | N/A | N/A | 0.017 | N/A | N/A |
| test_verilator_does_not_accept_mixedsim | N/A | N/A | 0.016 | N/A | N/A |
| test_example_uvm_simple_model | N/A | N/A | N/A | 10.972 | N/A |
| test_example_uvm_simple_model_2 | N/A | N/A | N/A | 10.869 | N/A |

**modelsim**: 46 tests, total 59.8s, avg 1.30s/test
**qrun**: 48 tests, total 58.9s, avg 1.23s/test
**verilator**: 47 tests, total 127.1s, avg 2.70s/test
**xsim**: 46 tests, total 248.9s, avg 5.41s/test
**Mean ratio** (xsim/modelsim): 3.96x across 43 common tests
