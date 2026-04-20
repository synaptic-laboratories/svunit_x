Running Unit Tests
==================

SVUnit unit tests are run using runSVUnit. Usage of runSVUnit is as follows::

  Usage:  runSVUnit [-s|--sim <simulator> -l|--log <log> -d|--define <macro> -f|--filelist <file> -U|-uvm -m|-mixedsim <vhdlfile>
                    -r|--r_arg <option> -c|--c_arg <option> -o|--out <dir> -t|--test <test> --filter <filter>
                    --sim-debug-level <none|low|medium|med|high|all> --sim-runtime-stats --xsim-run-mode <separate|standalone>]
    -s|--sim <simulator>     : simulator is either of questa, modelsim, riviera, ius, xcelium, vcs, dsim, verilator or xsim
    -l|--log <log>           : simulation log file (default: run.log)
    -d|--define <macro>      : appended to the command line as +define+<macro>
    -f|--filelist <file>     : some verilog file list
    -r|--r_arg <option>      : specify additional runtime options
    -c|--c_arg <option>      : specify additional compile options
    -e|--e_arg <option>      : specify additional elaboration options
    -U|--uvm                 : run SVUnit with UVM
    -o|--out                 : output directory for tmp and simulation files
    -t|--test                : specifies a unit test to run (multiple can be given)
    -m|--mixedsim <vhdlfile> : consolidated file list with VHDL files and command line switches
    -w|--wavedrom            : process json files as wavedrom output
       --filter <filter>     : specify which tests to run, as <test_module>.<test_name>
       --sim-debug-level     : normalized simulator debug level
       --sim-runtime-stats   : request simulator runtime statistics when supported
       --xsim-run-mode       : xsim run mode
    -h|--help                : prints this help screen

Choosing a Simulator
--------------------
SVUnit can be run using most commonly used EDA simulators using the '-s' switch. Supported simulators currently include Mentor Graphics Questa, Cadence Incisive, Synopsys VCS and Aldec Riviera PRO.


Logging
-------

By default, simulation output is written to run.log. The default location can be overridden using the '-l' switch.


Specifying Command-line Macros
------------------------------

SVUnit will pass command line macro defines specified by the '-d' switch directly to the simulator.


Adding Files For Simulation
---------------------------

Through the use of \`include directives, both the unit test template and corresponding UUT file are included in compilation making it possible to build and verify on simple designs without any need to specify or maintain file lists. As designs grow, however, more files can be added using standard simulator file lists and the '-f' switch.

.. note::

    The file svunit.f is automatically included for compilation provided it exists. Thus, files can be added to svunit.f without having to specify '-f svunit.f' on the command line.


Adding Run Time and/or Compile and/or Elaboration Options
---------------------------------------------------------

It is possible to specify compile and run time options using the '-c_arg', '-e_arg' and '-r_arg' switches respectively. All compile, elaboration and run time arguments are passed directly to the simulator command line.

Vivado xsim is the exception for runtime options that disable the run log:
``-r_arg -nolog`` and ``-r_arg --nolog`` are rejected.  SVUnit scans the xsim
run log after the process exits because Vivado xsim can report a simulator
startup failure in ``run.log`` while still returning exit code 0.  The guarded
patterns include ``ERROR: unexpected exception when evaluating tcl command`` and
``ERROR: [Simtcl ...] Simulation engine failed to start``.


Simulator Debug Levels
----------------------

SVUnit X adds ``--sim-debug-level`` as a normalized front-end for simulator debug
options. The accepted levels are ``none``, ``low``, ``medium`` (or ``med``),
``high``, and ``all``. It can also be set with the ``SVUNIT_SIM_DEBUG_LEVEL``
environment variable.

Vivado xsim converts the level to ``xelab --debug`` as follows:

* ``none`` -> ``off``
* ``low`` -> ``line``
* ``medium``/``med`` -> ``typical``
* ``high``/``all`` -> ``all``

For backward compatibility, ``runSVUnit -s xsim`` still defaults to
``xelab --debug all`` when no level is specified. If an explicit xsim debug
option is passed through ``-e_arg``/``--e_arg``, that explicit elaboration
argument wins and SVUnit prints a warning.

ModelSim/Questa debug levels are mapped through documented vopt visibility and
vsim debug options from the installed Questa help:

* ``none`` -> no added debug flags
* ``low`` -> ``+access+r`` plus ``-lineinfo``
* ``medium``/``med`` -> ``+access+rw`` plus ``-lineinfo``
* ``high``/``all`` -> ``+access+rw`` plus ``-lineinfo``, ``-classdebug``, and
  ``-assertdebug``

Verilator debug levels use its documented runtime-debug surface:

* ``none`` -> no added debug flags
* ``low`` -> ``--runtime-debug`` plus runtime ``+verilator+debug``
* ``medium``/``med`` -> ``--runtime-debug`` plus runtime
  ``+verilator+debug`` and ``+verilator+debugi+1``
* ``high``/``all`` -> ``--runtime-debug --debug`` plus runtime
  ``+verilator+debug`` and ``+verilator+debugi+3``

For simulators whose debug mapping is not known yet, SVUnit prints a warning and
does not add guessed vendor flags.


Simulator Runtime Statistics
----------------------------

SVUnit X adds ``--sim-runtime-stats`` as a normalized request for simulator
runtime diagnostics. It can also be enabled with the
``SVUNIT_SIM_RUNTIME_STATS`` environment variable.

The current mappings are:

* Vivado xsim -> ``xsim -stats``
* ModelSim/Questa ``vsim`` -> ``-printsimstats``
* qrun -> ``-stats=all``
* Verilator -> ``--stats``

The xsim mapping reports kernel memory usage and simulation CPU usage in
``run.log``. ModelSim/Questa ``vsim`` reports memory plus vopt,
elaboration, simulation, and total timing. qrun reports separate ``vlog``,
``vopt``, and ``vsim`` phase statistics. Verilator writes compile statistics
under ``obj_dir/*__stats*.txt`` and the certifier parses the generated model's
standard simulation report for wall time, CPU time, thread count, and allocated
memory. Certifier runs retain the pytest workspaces and write supported parsed
statistics to ``sim-runtime-stats.tsv`` and ``sim-runtime-stats.json``. For
simulators whose runtime-statistics mapping is not known yet, SVUnit prints a
warning and does not add guessed vendor flags.


Vivado xsim Run Modes
---------------------

SVUnit X adds ``--xsim-run-mode separate|standalone`` for Vivado xsim. The
default, ``separate``, uses the traditional ``xelab`` followed by ``xsim --R``
flow. The ``standalone`` mode uses AMD's ``xelab -standalone -R`` path and can
avoid the cost of launching a separate xsim frontend for unfiltered full-suite
runs.

Standalone mode is rejected when SVUnit needs xsim runtime arguments:
``--filter``, ``--list-tests``, ``--reuse-build``, ``--sim-runtime-stats``, or
explicit ``-r_arg``/``--r_arg`` values. Those paths stay on the default
``xsim --R`` flow because ``xelab -standalone -R`` does not accept xsim
``--testplusarg`` runtime options.


Enable UVM Component Unit Testing
---------------------------------

For verification engineers unit testing UVM-based components, the '-U' switch must be specified to include relevant run-flow handling.


Specifying a Simulation Directory
---------------------------------

By default, SVUnit is run in the current working directory. However, to avoid mixing source files with simulation output, it is possible to change the location where SVUnit is built and simulated using the '-o' switch. It is an error to use the '-o' switch to runSVUnit that doesn't exist.


Specifying Unit Tests to be Run
-------------------------------

By default, runSVUnit finds and simulates all unit test templates within a given parent directory. For short runs, this is recommended practice. However, if simulation times grow to the point where they are long and cumbersome, it is possible to specify specific unit test templates to be run using the '-t' switch. For example, if a parent directory has 12 unit test templates but you only want to run mine_unit_test.sv, you can use the '-t' switch as::

    runSVunit -t mine_unit_test.sv -s <your simulator>

The '-t' switch can be used to specify multiple unit test templates as:

    runSVunit -t mine_unit_test.sv -t yours_unit_test.sv -s <your simulator>

It's also possible to restrict which individual tests should run. This is done using the '--filter' option.

The following call runs only some_test defined in some_testcase::

    runSVUnit --filter some_testcase.some_test

The following call runs all tests called some_test regardless of which testcase they are defined in::

    runSVUnit --filter *.some_test

The following call runs all tests defined in some_testcase::

    runSVUnit --filter some_testcase.*

The previous command is conceptually similar to using the '-t' option.
While the runtime behavior is the same, it is slightly different in terms of what gets compiled.
Using '-t' selects what gets compiled and by extension limits what can be run.
Using '--filter' only affects which of the tests that were compiled should run, but doesn't control what gets compiled.
Both options are useful, as they serve different purposes.
The '-t' option is helpful when API changes would require modifications to many unit test files, but you would like to update them one after the other.
It is also a very blunt tool, as compilation can only be handled at the file level.
The '--filter' option can be used to focus on finer subsets of tests.

Listing Test Names
------------------

It is possible to list available tests without actually running them::

    runSVUnit --list-tests
