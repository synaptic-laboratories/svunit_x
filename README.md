# SVUnit

SVUnit is an open-source test framework for ASIC and FPGA developers writing Verilog/SystemVerilog
code. SVUnit is automated, fast, lightweight and easy to use making it the only SystemVerilog test
framework in existence suited to both design and verification engineers that aspire to high quality
code and low bug rates.

NOTE: for instructions on how to get going with SVUnit, go to
      www.agilesoc.com/svunit.

NOTE: Refer also to the FAQ at: www.agilesoc.com/svunit/svunit-FAQ


## Release Notes

Go [here](CHANGELOG.md) for release notes.

## Documentation

Read the [latest documentation](https://docs.svunit.org/en/latest/)

## Step-by-step instructions to get a first unit test going

### 1. Set up the `SVUNIT_INSTALL` and `PATH` environment variables

```shell
export SVUNIT_INSTALL=`pwd`
export PATH=$PATH:$SVUNIT_INSTALL"/bin"
```

You can source `Setup.bsh` if you use the bash shell.

```shell
source Setup.bsh
```

You can source `Setup.csh` if you use the csh shell.

```shell
source Setup.csh
```

On this box, you can also enter the qualified Quartus Podman workflow through the repo flake.

```shell
nix develop
```

### 2. Go somewhere outside `SVUNIT_INSTALL` (i.e. where you are right now)

Start a class-under-test:


    // file: bogus.sv
    class bogus;
    endclass

### 3. Generate the unit test

```shell
create_unit_test.pl bogus.sv
```

### 4. Add tests using the helper macros

    // file: bogus_unit_test.sv
    `SVUNIT_TESTS_BEGIN

      //===================================
      // Unit test: test_mytest
      //===================================
      `SVTEST(test_mytest)
      `SVTEST_END

    `SVUNIT_TESTS_END

### 5. Run the unit tests

```shell
runSVUnit -s <simulator> # simulator is ius, questa, modelsim, riviera or vcs
```

### 6. Repeat steps 4 and 5 until done

### 7. Pat self on back

## Qualified Quartus Podman workflow

This repo now includes a `flake.nix` that consumes the qualified Altera Quartus Pro Podman source at `g_altera_quartus_pro_podman/r_src_v23_4_0_79` and exposes repo-local wrappers for this stage's Quartus sign-off flow.

Build or refresh the local container image:

```shell
nix run .#quartus-tools -- build-image
```

Check that the container exposes the expected Quartus and Questa commands:

```shell
nix run .#svunit-quartus-check
```

Open a shell inside the Quartus container with this repo mounted at `/sll`:

```shell
nix run .#svunit-quartus-podman
```

Launch the Quartus GUI when `DISPLAY` is available:

```shell
nix run .#svunit-quartus-podman -- --quartus
```

By default the wrapper:

- uses `localhost/quartus-pro-linux:23.4.0.79`
- mounts the repo root into the container at `/sll`
- persists container root state under `.quartus/root`
- looks for `quartus_license.dat` and `questa_license.dat` in `/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch`


## Feedback

Tell us about what you like,
what you don't like,
new features you'd like to see...
basically anything
you think would make SVUnit more valuable to you.

The best place for feedback is https://github.com/svunit/svunit/discussions.
If you don't have a GitHub account, you can send an email to *contact[at]svunit[dot]org*.
