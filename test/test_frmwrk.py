import fileinput
import os
import subprocess
import pathlib
import pytest
import shutil
from utils import *


# Need a possibility to remove tools from PATH, otherwise we can't test
def get_path_without_sims():
    paths = os.environ['PATH'].split(os.path.pathsep)
    for sim_name in ['xrun', 'dsim', 'vsim', "qrun", "verilator", 'xsim']:
        sim = shutil.which(sim_name)
        if sim:
            paths = list(filter(lambda p: pathlib.Path(p) != pathlib.Path(sim).parent, paths))
    return os.path.pathsep.join(paths)


def fake_tool(name, log_name_is_tool_name=False):
    executable = pathlib.Path(name)
    log_file = 'fake_tool.log' if not log_name_is_tool_name else f'fake_{name}.log'
    script = [
            'echo "{} called" > {}'.format(name, log_file),
            'echo "args:" >> {}'.format(log_file),
            'printf "%s\n" "$@" >> {}'.format(log_file),
            ]
    executable.write_text('\n'.join(script))
    executable.chmod(0o700)
    return executable


def fake_counting_tool(name, extra_lines=None):
    executable = pathlib.Path(name)
    log_file = f'fake_{name}.log'
    script = [
            'echo "{} called" >> {}'.format(name, log_file),
            'echo "args:" >> {}'.format(log_file),
            'printf "%s\n" "$@" >> {}'.format(log_file),
            ] + (extra_lines or [])
    executable.write_text('\n'.join(script))
    executable.chmod(0o700)
    return executable


@all_files_in_dir('frmwrk_0')
def test_frmwrk_0(datafiles):
    with datafiles.as_cwd():
        create_unit_test('test.sv')
        subprocess.check_call(['buildSVUnit'])

        golden_class_unit_test('test', 'test')
        golden_testsuite_with_1_unittest('test')
        golden_testrunner_with_1_testsuite()

        verify_file('test_unit_test.gold', 'test_unit_test.sv')
        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_')


@all_files_in_dir('frmwrk_1')
def test_frmwrk_1(datafiles):
    with datafiles.as_cwd():
        create_unit_test('test.sv')

        golden_class_unit_test('test', 'test0')

        verify_file('test_unit_test.gold', 'test_unit_test.sv')


@all_files_in_dir('frmwrk_2')
def test_frmwrk_2(datafiles):
    with datafiles.as_cwd():
        create_unit_test('test.sv')

        golden_class_unit_test('test', 'virtual_test')

        verify_file('test_unit_test.gold', 'test_unit_test.sv')


@all_files_in_dir('frmwrk_3')
def test_frmwrk_3(datafiles):
    with datafiles.as_cwd():
        create_unit_test('test.sv')
        subprocess.check_call(['buildSVUnit'])

        verify_file('test_unit_test.gold', 'test_unit_test.sv')
        verify_testsuite('testsuite.gold')


@all_files_in_dir('frmwrk_4')
def test_frmwrk_4(datafiles):
    with datafiles.as_cwd():
        create_unit_test('test.sv')
        with (datafiles / 'another_test').as_cwd():
            create_unit_test('test0.sv')
        subprocess.check_call(['buildSVUnit'])

        golden_testrunner_with_2_testsuites()

        verify_testrunner('testrunner.gold', '__another_test', '_')


@all_files_in_dir('frmwrk_6')
def test_frmwrk_6(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './test_unit_test.sv', 'test.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir0/subdir0_unit_test.sv', './subdir0/subdir0.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1_unit_test.sv', './subdir1/subdir1.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1a/subdir1a_unit_test.sv', './subdir1/subdir1a/subdir1a.sv'])

        subprocess.check_call(['buildSVUnit'])

        golden_testrunner_with_4_testsuites()

        verify_testrunner('testrunner.gold', '__subdir0', '__subdir1_subdir1a', '__subdir1', '_')


def test_frmwrk_7(tmpdir):
    with tmpdir.as_cwd():
        return_code = subprocess.call(['buildSVUnit'])
        assert return_code == 1

        # verify no new files were created
        assert not tmpdir.listdir()


@all_files_in_dir('frmwrk_8')
def test_frmwrk_8(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir0/subdir0_unit_test.sv', './subdir0/subdir0.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1_unit_test.sv', './subdir1/subdir1.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1a/subdir1a_unit_test.sv', './subdir1/subdir1a/subdir1a.sv'])

        subprocess.check_call(['buildSVUnit'])

        golden_testrunner_with_3_testsuites()

        verify_testrunner('testrunner.gold', '__subdir0', '__subdir1_subdir1a', '__subdir1')


@all_files_in_dir('frmwrk_9')
def test_frmwrk_9(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './test_unit_test.sv', 'test.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1a/subdir1a_unit_test.sv', './subdir1/subdir1a/subdir1a.sv'])

        subprocess.check_call(['buildSVUnit'])

        golden_testrunner_with_2_testsuites()

        verify_testrunner('testrunner.gold', '__subdir1_subdir1a', '_')


@all_files_in_dir('frmwrk_10')
def test_frmwrk_10(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', 'test.sv'])

        golden_module_unit_test('test', 'test')

        verify_file('test_unit_test.gold', 'test_unit_test.sv')


@all_files_in_dir('frmwrk_11')
def test_frmwrk_11(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-overwrite', 'test_if.sv'])

        golden_if_unit_test('test_if', 'test_if')

        verify_file('test_if_unit_test.gold', 'test_if_unit_test.sv')


@all_files_in_dir('frmwrk_12')
def test_frmwrk_12(datafiles):
    with datafiles.as_cwd():
        for file in datafiles.listdir():
            subprocess.check_call(['create_unit_test.pl', file])
            assert pathlib.Path(file.purebasename + '_unit_test.sv').is_file()


@all_files_in_dir('frmwrk_13')
def test_frmwrk_13(datafiles):
    with datafiles.as_cwd():
        for file in (datafiles / 'second_dir').listdir():
            if not file.check(file=1):
                continue
            subprocess.check_call(['create_unit_test.pl', file])
            assert pathlib.Path(file.purebasename + '_unit_test.sv').is_file()

    with (datafiles / 'second_dir').as_cwd():
        for file in datafiles.listdir():
            if not file.check(file=1):
                continue
            subprocess.check_call(['create_unit_test.pl', file])
            assert pathlib.Path(file.purebasename + '_unit_test.sv').is_file()


@all_files_in_dir('frmwrk_14')
@all_available_simulators()
def test_frmwrk_14(datafiles, simulator):
    if not shutil.which('csh') or not shutil.which('tcsh'):
        pytest.skip()
    new_env = os.environ.copy()
    path_entries = new_env['PATH'].split(':')
    new_path_entries = [path_entry for path_entry in path_entries if not 'svunit-code' in path_entry]
    new_env['PATH'] = ':'.join(new_path_entries)
    new_env['SVUNIT_ROOT'] = get_svunit_root()

    with datafiles.as_cwd():
        subprocess.check_call(['csh', 'run.csh', simulator], env=new_env)
        subprocess.check_call(['tcsh', 'run.csh', simulator], env=new_env)


@all_files_in_dir('frmwrk_15')
def test_frmwrk_15(datafiles):
    with datafiles.as_cwd():
        os.mkdir('third_dir')
        for file in (datafiles / 'second_dir').listdir():
            if not file.check(file=1):
                continue
            destfile = os.path.join('third_dir', file.purebasename + '_unit_test.sv')
            subprocess.check_call(['create_unit_test.pl', file, '-out', destfile])
            assert pathlib.Path(destfile).is_file()

    with (datafiles / 'second_dir').as_cwd():
        for file in (datafiles / 'second_dir').listdir():
            if not file.check(file=1):
                continue
            destfile = os.path.join('..', file.purebasename + '_unit_test.sv')
            subprocess.check_call(['create_unit_test.pl', file, '-out', destfile])
            assert pathlib.Path(destfile).is_file()

    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-out', 'dud_unit_test.v', 'test2.sv'])
        assert not pathlib.Path('dud_unit_test.v').is_file()

        subprocess.check_call(['create_unit_test.pl', '-out', 'dud.v', 'test2.sv'])
        assert not pathlib.Path('dud.v').is_file()


@all_files_in_dir('frmwrk_16')
def test_frmwrk_16(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', 'test_if.sv'])
        subprocess.check_call(['create_unit_test.pl', 'test_if2.sv'])

        golden_if_unit_test('test_if', 'test_if')
        golden_if_unit_test('test_if2', 'test_if2')

        verify_file('test_if_unit_test.gold', 'test_if_unit_test.sv')
        verify_file('test_if2_unit_test.gold', 'test_if2_unit_test.sv')


def test_frmwrk_17(tmpdir):
    with tmpdir.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-class_name', 'class_under_test'])

        golden_class_unit_test('class_under_test', 'class_under_test')

        verify_file('class_under_test_unit_test.gold', 'class_under_test_unit_test.sv')


def test_frmwrk_18(tmpdir):
    with tmpdir.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-module_name', 'module_under_test'])

        golden_module_unit_test('module_under_test', 'module_under_test')

        verify_file('module_under_test_unit_test.gold', 'module_under_test_unit_test.sv')


def test_frmwrk_19(tmpdir):
    with tmpdir.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-if_name', 'if_under_test'])

        golden_if_unit_test('if_under_test', 'if_under_test')

        verify_file('if_under_test_unit_test.gold', 'if_under_test_unit_test.sv')


@all_files_in_dir('frmwrk_20')
def test_frmwrk_20(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', 'test_automatic.sv'])
        subprocess.check_call(['create_unit_test.pl', 'test_static.sv'])

        golden_if_unit_test('test_automatic', 'test_automatic')
        verify_file('test_automatic_unit_test.gold', 'test_automatic_unit_test.sv')

        golden_if_unit_test('test_static', 'test_static')
        verify_file('test_static_unit_test.gold', 'test_static_unit_test.sv')


@pytest.mark.skip(reason="create_svunit.pl doesn't exist. The original test still passes, though.")
@all_files_in_dir('frmwrk_22')
def test_frmwrk_22(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_svunit.pl'])

        subprocess.check_call(['make', '.testrunner.sv'])

        golden_testsuite_with_1_unittest('test')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '.')


@all_files_in_dir('frmwrk_23')
def test_frmwrk_23(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './test_unit_test.sv', 'test.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir0/subdir0_unit_test.sv', './subdir0/subdir0.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1_unit_test.sv', './subdir1/subdir1.sv'])
        subprocess.check_call(['create_unit_test.pl', '-overwrite', '-out', './subdir1/subdir1a/subdir1a_unit_test.sv', './subdir1/subdir1a/subdir1a.sv'])

        subprocess.check_call(['buildSVUnit', '-o', '/tmp/rundir'])

        golden_testrunner_with_4_testsuites()

        verify_testrunner('testrunner.gold', '__subdir0', '__subdir1_subdir1a', '__subdir1', '_', '/tmp/rundir/.testrunner.sv')


@all_files_in_dir('frmwrk_24')
def test_frmwrk_24(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['buildSVUnit', '-t', 'test_unit_test.sv'])

        golden_testsuite_with_1_unittest('test')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


@all_files_in_dir('frmwrk_25')
def test_frmwrk_25(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['buildSVUnit', '-t', 'test_unit_test.sv', '-t', 'test2_unit_test.sv'])

        golden_testsuite_with_2_unittests('test', 'test2')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


@all_files_in_dir('frmwrk_26')
def test_frmwrk_26(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['buildSVUnit', '-t', 'test_unit_test.sv'])

        golden_testsuite_with_1_unittest('test')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


@all_files_in_dir('frmwrk_27')
def test_frmwrk_27(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['buildSVUnit', '-t', 'subdir/test3_unit_test.sv'])

        golden_testsuite_with_1_unittest('test3')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


@all_files_in_dir('frmwrk_28')
def test_frmwrk_28(datafiles, monkeypatch):
    '''Test that the 'runSVUnit' script passes a '-t' argument to 'buildSVUnit.'''
    with datafiles.as_cwd():
        fake_tool('xrun')
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        subprocess.check_call(['runSVUnit', '-s', 'xrun', '-t', 'test_unit_test.sv'])

        golden_testsuite_with_1_unittest('test')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


@all_files_in_dir('frmwrk_29')
def test_frmwrk_29(datafiles, monkeypatch):
    '''Test that the 'runSVUnit' script passes all '-t' arguments to 'buildSVUnit.'''
    with datafiles.as_cwd():
        fake_tool('xrun')
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        subprocess.check_call(['runSVUnit', '-s', 'xrun', '-t', 'test_unit_test.sv', '-t', 'test2_unit_test.sv'])

        golden_testsuite_with_2_unittests('test', 'test2')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


@all_files_in_dir('frmwrk_30')
def test_frmwrk_30(datafiles):
    with datafiles.as_cwd():
        subprocess.check_call(['create_unit_test.pl', '-p', 'a_pkg::*', 'test.sv'])

        golden_class_unit_test('test', 'test')
        for line in fileinput.input(files=('test_unit_test.gold'), inplace=True):
            print(line.replace('`include "test.sv"', 'import a_pkg::*;'), end='')

        verify_file('test_unit_test.gold', 'test_unit_test.sv')


# TODO Remove as this is the same as 'frmwrk_29'. Left in to make review easier
@all_files_in_dir('frmwrk_31')
def test_frmwrk_31(datafiles, monkeypatch):
    '''Test that the 'runSVUnit' script passes all '-t' arguments to 'buildSVUnit.'''
    with datafiles.as_cwd():
        fake_tool('xrun')
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        subprocess.check_call(['runSVUnit', '-s', 'xrun', '-t', 'test_unit_test.sv', '-t', 'test2_unit_test.sv'])

        golden_testsuite_with_2_unittests('test', 'test2')
        golden_testrunner_with_1_testsuite()

        verify_testsuite('testsuite.gold')
        verify_testrunner('testrunner.gold', '_', '.')


def test_frmwrk_32(tmpdir):
    with tmpdir.as_cwd():
        return_code = subprocess.call(['runSVUnit', '-s', 'questa', 'blunt_object_unit_test.sv'])
        assert return_code == 255


def test_create_unit_test_help(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(['create_unit_test.pl', '-help'],
                                capture_output=True, text=True)
        assert result.returncode == 0
        assert 'Usage' in result.stdout
        assert 'ERROR' not in result.stdout


@pytest.mark.parametrize("sim", ["xrun", "irun", "vsim", "vcs", "qrun", "verilator", "xsim"])
def test_called_without_simulator__extract_sim_if_on_path(sim, tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool(sim)
        if (sim == 'vsim'):
            fake_tool('vlib')
            fake_tool('vlog')
        if sim == 'xsim':
            fake_tool('xvlog')
            fake_tool('xelab')
        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit'])

        assert pathlib.Path('fake_tool.log').is_file()
        assert 'called' in pathlib.Path('fake_tool.log').read_text()


def test_called_without_simulator__extract_xrun_even_if_irun_also_on_path(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xrun')
        fake_tool('irun')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit'])

        assert pathlib.Path('fake_tool.log').is_file()
        assert 'xrun called' in pathlib.Path('fake_tool.log').read_text()


def test_called_without_simulator__extract_qrun_even_if_vsim_also_on_path(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('qrun')
        fake_tool('vsim')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit'])

        assert pathlib.Path('fake_tool.log').is_file()
        assert 'qrun called' in pathlib.Path('fake_tool.log').read_text()


def test_called_with_simulator__override_simulator_extracted_from_path(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xrun')
        fake_tool('irun')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit', '-s', 'irun'])

        assert pathlib.Path('fake_tool.log').is_file()
        assert 'irun called' in pathlib.Path('fake_tool.log').read_text()


def test_called_without_simulator__nothing_on_path(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        monkeypatch.setenv('PATH', get_path_without_sims())

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        proc = subprocess.run(['runSVUnit'], stdout=subprocess.PIPE, universal_newlines=True)

        assert proc.returncode != 0
        assert "Could not determine simulator" in proc.stdout


def test_called_with_unknown_simulator(tmpdir):
    with tmpdir.as_cwd():
        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        proc = subprocess.run(['runSVUnit', '--sim', 'bogus'], stdout=subprocess.PIPE, universal_newlines=True)

        assert proc.returncode != 0
        assert "Unknown simulator 'bogus'" in proc.stdout


def test_uut_name_contains_static(tmpdir):
    with tmpdir.as_cwd():
        with open('something_with_static_in_name.sv',  'w+') as f:
            f.write('\n'.join(['module something_with_static_in_name;',
                               'endmodule']))
        create_unit_test('something_with_static_in_name.sv')
        subprocess.check_call(['buildSVUnit'])

        golden_module_unit_test('something_with_static_in_name', 'something_with_static_in_name')
        golden_testsuite_with_1_unittest('something_with_static_in_name')

        verify_file('something_with_static_in_name_unit_test.gold',
                    'something_with_static_in_name_unit_test.sv')
        verify_testsuite('testsuite.gold')


def test_uut_name_contains_automatic(tmpdir):
    with tmpdir.as_cwd():
        with open('something_with_automatic_in_name.sv',  'w+') as f:
            f.write('\n'.join(['module something_with_automatic_in_name;',
                               'endmodule']))
        create_unit_test('something_with_automatic_in_name.sv')
        subprocess.check_call(['buildSVUnit'])

        golden_module_unit_test('something_with_automatic_in_name',
                                'something_with_automatic_in_name')
        golden_testsuite_with_1_unittest('something_with_automatic_in_name')

        verify_file('something_with_automatic_in_name_unit_test.gold',
                    'something_with_automatic_in_name_unit_test.sv')
        verify_testsuite('testsuite.gold')


def test_collects_test_from_dir_passed_with_directory_option(tmp_path, monkeypatch):
    tmp_path.joinpath('run_dir').mkdir()
    tmp_path.joinpath('test_dir1').mkdir()
    tmp_path.joinpath('test_dir1/test_in_dir1_unit_test.sv').write_text('module test_in_dir1_unit_test;\nendmodule')
    tmp_path.joinpath('test_dir2').mkdir()
    tmp_path.joinpath('test_dir2/test_in_dir2_unit_test.sv').write_text('module test_in_dir2_unit_test;\nendmodule')

    with working_directory(tmp_path/'run_dir'):
        fake_tool('xrun')
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        subprocess.check_call(['runSVUnit', '-s', 'xrun', '--directory', '../test_dir1'])

        golden_testsuite_with_1_unittest('test_in_dir1')
        verify_testsuite('testsuite.gold', '__test_dir1')

        golden_testrunner_with_1_testsuite()
        verify_testrunner('testrunner.gold', '___test_dir1')


def test_collects_test_from_dirs_passed_with_directory_option(tmp_path, monkeypatch):
    tmp_path.joinpath('run_dir').mkdir()
    tmp_path.joinpath('test_dir1').mkdir()
    tmp_path.joinpath('test_dir1/test_in_dir1_unit_test.sv').write_text('module test_in_dir1_unit_test;\nendmodule')
    tmp_path.joinpath('test_dir2').mkdir()
    tmp_path.joinpath('test_dir2/test_in_dir2_unit_test.sv').write_text('module test_in_dir2_unit_test;\nendmodule')
    tmp_path.joinpath('test_dir3').mkdir()
    tmp_path.joinpath('test_dir3/test_in_dir3_unit_test.sv').write_text('module test_in_dir3_unit_test;\nendmodule')

    with working_directory(tmp_path/'run_dir'):
        fake_tool('xrun')
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        subprocess.check_call(['runSVUnit', '-s', 'xrun', '--directory', '../test_dir1', '--directory', '../test_dir2'])

        golden_testsuite_with_1_unittest('test_in_dir1')
        verify_testsuite('testsuite.gold', '__test_dir1')
        golden_testsuite_with_1_unittest('test_in_dir2')
        verify_testsuite('testsuite.gold', '__test_dir2')

        golden_testrunner_with_2_testsuites()
        verify_testrunner('testrunner.gold', '___test_dir1', '___test_dir2')


def test_does_not_collect_test_from_cwd_passed_with_directory_option(tmp_path, monkeypatch):
    tmp_path.joinpath('run_dir').mkdir()
    tmp_path.joinpath('run_dir/test_in_run_dir_unit_test.sv').write_text('module test_in_run_dir_unit_test;\nendmodule')
    tmp_path.joinpath('test_dir1').mkdir()
    tmp_path.joinpath('test_dir1/test_in_dir1_unit_test.sv').write_text('module test_in_dir1_unit_test;\nendmodule')

    with working_directory(tmp_path/'run_dir'):
        fake_tool('xrun')
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        subprocess.check_call(['runSVUnit', '-s', 'xrun', '--directory', '../test_dir1'])

        golden_testsuite_with_1_unittest('test_in_dir1')
        verify_testsuite('testsuite.gold', '__test_dir1')

        golden_testrunner_with_1_testsuite()
        verify_testrunner('testrunner.gold', '___test_dir1')


def test_absolute_path_for_directory_option_issues_error(tmp_path):
    tmp_path.joinpath('run_dir').mkdir()
    tmp_path.joinpath('test_dir1').mkdir()

    with working_directory(tmp_path/'run_dir'):
        run_result = subprocess.run(['runSVUnit', '-s', 'questa', '--directory', tmp_path.joinpath('test_dir1').resolve()], stdout=subprocess.PIPE)

        assert run_result.returncode == 4
        assert b'absolute paths' in run_result.stdout
        assert b'not yet supported' in run_result.stdout


def test_called_without_filter_option__no_plusarg_passed(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xrun')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit'])

        assert '+SVUNIT_FILTER' not in pathlib.Path('fake_tool.log').read_text()


def test_called_with_filter_option__plusarg_passed(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xrun')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit', '--filter', 'foo.bar'])

        assert '+SVUNIT_FILTER=foo.bar' in pathlib.Path('fake_tool.log').read_text()


def test_vivado_can_take_elab_args(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab',log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-e_arg', 'some-arg'])

        assert 'some-arg' in pathlib.Path('fake_xelab.log').read_text()


def test_vivado_defaults_to_full_xelab_debug(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim'])

        assert '--debug\nall' in pathlib.Path('fake_xelab.log').read_text()


def test_vivado_sim_debug_level_maps_to_xelab_debug(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim', '--sim-debug-level', 'none'])

        assert '--debug\noff' in pathlib.Path('fake_xelab.log').read_text()


def test_vivado_sim_debug_level_accepts_env_and_med_alias(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)
        monkeypatch.setenv('SVUNIT_SIM_DEBUG_LEVEL', 'med')

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim'])

        assert '--debug\ntypical' in pathlib.Path('fake_xelab.log').read_text()


def test_vivado_explicit_elab_debug_overrides_sim_debug_level(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        result = subprocess.run(
                [
                    'runSVUnit',
                    '-s',
                    'xsim',
                    '--sim-debug-level',
                    'none',
                    '-e_arg',
                    '--debug typical',
                    ],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 0
        assert b'-e_arg/--e_arg' in result.stdout
        xelab_log = pathlib.Path('fake_xelab.log').read_text()
        assert xelab_log.count('--debug') == 1
        assert '--debug\ntypical' in xelab_log
        assert 'off' not in xelab_log


def test_unmapped_sim_debug_level_warns_without_passing_flags(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('qrun', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        result = subprocess.run(
                ['runSVUnit', '-s', 'qrun', '--sim-debug-level', 'low'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 0
        assert b'not mapped for qrun' in result.stdout
        assert 'debug' not in pathlib.Path('fake_qrun.log').read_text()


def test_modelsim_sim_debug_level_maps_to_vopt_access_and_vsim_lineinfo(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('vlib', log_name_is_tool_name=True)
        fake_tool('vlog', log_name_is_tool_name=True)
        fake_tool('vsim', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'modelsim', '--sim-debug-level', 'medium'])

        vsim_log = pathlib.Path('fake_vsim.log').read_text()
        assert '-voptargs=+access+rw' in vsim_log
        assert '-lineinfo' in vsim_log


def test_modelsim_high_sim_debug_level_adds_class_and_assert_debug(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('vlib', log_name_is_tool_name=True)
        fake_tool('vlog', log_name_is_tool_name=True)
        fake_tool('vsim', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'modelsim', '--sim-debug-level', 'high'])

        vsim_log = pathlib.Path('fake_vsim.log').read_text()
        assert '-voptargs=+access+rw' in vsim_log
        assert '-classdebug' in vsim_log
        assert '-assertdebug' in vsim_log


def test_verilator_sim_debug_level_maps_to_compile_and_runtime_debug(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('verilator', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        result = subprocess.run(
                ['runSVUnit', '-s', 'verilator', '--sim-debug-level', 'all'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 0
        verilator_log = pathlib.Path('fake_verilator.log').read_text()
        assert '--runtime-debug' in verilator_log
        assert '--debug' in verilator_log
        assert b'+verilator+debug' in result.stdout
        assert b'+verilator+debugi+3' in result.stdout


def test_vivado_sim_runtime_stats_maps_to_xsim_stats(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim', '--sim-runtime-stats'])

        assert '-stats' in pathlib.Path('fake_xsim.log').read_text()


def test_vivado_sim_runtime_stats_accepts_env(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)
        monkeypatch.setenv('SVUNIT_SIM_RUNTIME_STATS', '1')

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim'])

        assert '-stats' in pathlib.Path('fake_xsim.log').read_text()


def test_unmapped_sim_runtime_stats_warns_without_passing_flags(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xrun', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        result = subprocess.run(
                ['runSVUnit', '-s', 'xrun', '--sim-runtime-stats'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 0
        assert b'--sim-runtime-stats is not mapped for xrun' in result.stdout
        assert 'stats' not in pathlib.Path('fake_xrun.log').read_text()


def test_modelsim_sim_runtime_stats_maps_to_printsimstats(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('vlib', log_name_is_tool_name=True)
        fake_tool('vlog', log_name_is_tool_name=True)
        fake_tool('vsim', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'modelsim', '--sim-runtime-stats'])

        assert '-printsimstats' in pathlib.Path('fake_vsim.log').read_text()


def test_qrun_sim_runtime_stats_maps_to_qrun_stats(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('qrun', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'qrun', '--sim-runtime-stats'])

        assert '-stats=all' in pathlib.Path('fake_qrun.log').read_text()


def test_verilator_sim_runtime_stats_maps_to_compile_stats(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('verilator', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'verilator', '--sim-runtime-stats'])

        assert '--stats' in pathlib.Path('fake_verilator.log').read_text()


def test_vivado_xsim_standalone_run_mode_uses_xelab_without_xsim(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xsim', log_name_is_tool_name=True)
        fake_tool('xvlog', log_name_is_tool_name=True)
        fake_tool('xelab', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)
        monkeypatch.delenv('SVUNIT_SIM_RUNTIME_STATS', raising=False)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim', '--xsim-run-mode', 'standalone'])

        xelab_log = pathlib.Path('fake_xelab.log').read_text()
        assert '-standalone' in xelab_log
        assert '-R' in xelab_log
        assert not pathlib.Path('fake_xsim.log').exists()


def test_vivado_xsim_standalone_run_mode_rejects_filter(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(
                [
                    'runSVUnit',
                    '-s',
                    'xsim',
                    '--xsim-run-mode',
                    'standalone',
                    '--filter',
                    'some_ut.some_test',
                    ],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 4
        assert b'cannot be combined with --filter' in result.stdout


def test_vivado_xsim_standalone_run_mode_rejects_runtime_stats(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(
                [
                    'runSVUnit',
                    '-s',
                    'xsim',
                    '--xsim-run-mode',
                    'standalone',
                    '--sim-runtime-stats',
                    ],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 4
        assert b'cannot be combined with --sim-runtime-stats' in result.stdout


def test_invalid_xsim_run_mode_is_rejected(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(
                ['runSVUnit', '-s', 'xsim', '--xsim-run-mode', 'turbo'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 4
        assert b'--xsim-run-mode must be one of' in result.stdout


def test_invalid_sim_debug_level_is_rejected(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(
                ['runSVUnit', '-s', 'xsim', '--sim-debug-level', 'verbose'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 4
        assert b'--sim-debug-level must be one of' in result.stdout


def test_vivado_xsim_tcl_exception_in_run_log_fails_even_when_xsim_exits_zero(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xvlog')
        fake_tool('xelab')
        fake_counting_tool(
                'xsim',
                [
                    'echo "ERROR: unexpected exception when evaluating tcl command" > run.log',
                    ],
                )

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        result = subprocess.run(['runSVUnit', '-s', 'xsim'], stdout=subprocess.PIPE)

        assert result.returncode == 3
        assert b'unexpected exception when evaluating tcl command' in result.stdout


def test_vivado_xsim_simtcl_engine_failed_in_run_log_fails_even_when_xsim_exits_zero(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xvlog')
        fake_tool('xelab')
        fake_counting_tool(
                'xsim',
                [
                    'echo "ERROR: [Simtcl 6-50] Simulation engine failed to start: Cannot create simulation database file at: /dev/null.wdb" > run.log',
                    ],
                )

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        result = subprocess.run(['runSVUnit', '-s', 'xsim'], stdout=subprocess.PIPE)

        assert result.returncode == 3
        assert b'Simulation engine failed to start' in result.stdout


def test_vivado_xsim_does_not_fail_on_svunit_error_lines_in_run_log(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xvlog')
        fake_tool('xelab')
        fake_counting_tool(
                'xsim',
                [
                    'echo "ERROR: [0][dut_ut]: fail_if: expected user test failure" > run.log',
                    ],
                )

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-s', 'xsim'])


def test_vivado_xsim_rejects_nolog_runtime_arg(tmpdir):
    with tmpdir.as_cwd():
        for nolog_arg in ['--nolog', '-nolog']:
            result = subprocess.run(
                    ['runSVUnit', '-s', 'xsim', '--r_arg', nolog_arg],
                    stdout=subprocess.PIPE,
                    )

            assert result.returncode == 4
            assert b'cannot include -nolog/--nolog' in result.stdout


def test_vivado_xsim_reuse_build_skips_compile_and_elab_on_cache_hit(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_counting_tool('xvlog')
        fake_counting_tool(
                'xelab',
                [
                    'mkdir -p xsim.dir/testrunner',
                    'touch xsim.dir/testrunner/xsimk',
                    ],
                )
        fake_counting_tool('xsim')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit', '-s', 'xsim', '--xsim-reuse-build'])
        subprocess.check_call(['runSVUnit', '-s', 'xsim', '--xsim-reuse-build'])

        pathlib.Path('dummy_unit_test.sv').write_text('dummy changed')
        subprocess.check_call(['runSVUnit', '-s', 'xsim', '--xsim-reuse-build'])

        assert pathlib.Path('fake_xvlog.log').read_text().count('xvlog called') == 2
        assert pathlib.Path('fake_xelab.log').read_text().count('xelab called') == 2
        assert pathlib.Path('fake_xsim.log').read_text().count('xsim called') == 3

        reuse_log = pathlib.Path('.svunit_xsim_reuse.log').read_text()
        assert reuse_log.count('miss') == 2
        assert reuse_log.count('hit') == 1


def test_modelsim_reuse_build_skips_vlog_on_cache_hit(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_counting_tool(
                'vlib',
                [
                    'mkdir -p work',
                    'touch work/_info',
                    ],
                )
        fake_counting_tool('vlog')
        fake_counting_tool('vsim')

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit', '-s', 'modelsim', '--reuse-build'])
        subprocess.check_call(['runSVUnit', '-s', 'modelsim', '--reuse-build'])

        pathlib.Path('dummy_unit_test.sv').write_text('dummy changed')
        subprocess.check_call(['runSVUnit', '-s', 'modelsim', '--reuse-build'])

        assert pathlib.Path('fake_vlib.log').read_text().count('vlib called') == 2
        assert pathlib.Path('fake_vlog.log').read_text().count('vlog called') == 2
        assert pathlib.Path('fake_vsim.log').read_text().count('vsim called') == 3

        reuse_log = pathlib.Path('.svunit_modelsim_reuse.log').read_text()
        assert reuse_log.count('miss') == 2
        assert reuse_log.count('hit') == 1


def test_qrun_reuse_build_uses_compile_once_then_simulate_on_cache_hit(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        executable = pathlib.Path('qrun')
        executable.write_text('\n'.join([
                'echo "qrun called" >> fake_qrun.log',
                'echo "args:" >> fake_qrun.log',
                'printf "%s\n" "$@" >> fake_qrun.log',
                'for arg in "$@"; do',
                '  if [ "$arg" = "-compile" ] || [ "$arg" = "-optimize" ]; then',
                '    echo compile >> fake_qrun_phase.log',
                '    mkdir -p qrun.out/work',
                '    touch qrun.out/work/qrun_opt',
                '  fi',
                '  if [ "$arg" = "-simulate" ]; then',
                '    echo simulate >> fake_qrun_phase.log',
                '  fi',
                'done',
                ]))
        executable.chmod(0o700)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')

        subprocess.check_call(['runSVUnit', '-s', 'qrun', '--reuse-build'])
        subprocess.check_call(['runSVUnit', '-s', 'qrun', '--reuse-build'])

        pathlib.Path('dummy_unit_test.sv').write_text('dummy changed')
        subprocess.check_call(['runSVUnit', '-s', 'qrun', '--reuse-build'])

        phase_log = pathlib.Path('fake_qrun_phase.log').read_text()
        assert phase_log.count('compile') == 2
        assert phase_log.count('simulate') == 3

        reuse_log = pathlib.Path('.svunit_qrun_reuse.log').read_text()
        assert reuse_log.count('miss') == 2
        assert reuse_log.count('hit') == 1


def test_xsim_reuse_build_rejected_for_non_xsim(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(
                ['runSVUnit', '-s', 'xrun', '--xsim-reuse-build'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 4
        assert b'only supported with xsim' in result.stdout


def test_reuse_build_rejected_for_unsupported_simulator(tmpdir):
    with tmpdir.as_cwd():
        result = subprocess.run(
                ['runSVUnit', '-s', 'xrun', '--reuse-build'],
                stdout=subprocess.PIPE,
                )

        assert result.returncode == 4
        assert b'only supported with qrun, modelsim, or xsim' in result.stdout


def test_xcelium_can_take_elab_args(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('xrun', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-e_arg', 'some-arg'])

        assert 'some-arg' in pathlib.Path('fake_xrun.log').read_text()


def test_questasim_can_take_elab_args(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('vsim', log_name_is_tool_name=True)
        fake_tool('vlib', log_name_is_tool_name=True)
        fake_tool('vlog', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-e_arg', 'some-arg'])

        assert '-voptargs=some-arg' in pathlib.Path('fake_vsim.log').read_text()


def test_questasim_can_handle_no_elab_args(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('vsim', log_name_is_tool_name=True)
        fake_tool('vlib', log_name_is_tool_name=True)
        fake_tool('vlog', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit'])

        assert '-voptargs' not in pathlib.Path('fake_vsim.log').read_text()


def test_verilator_can_take_elab_args(tmpdir, monkeypatch):
    with tmpdir.as_cwd():
        fake_tool('verilator', log_name_is_tool_name=True)

        monkeypatch.setenv('PATH', get_path_without_sims())
        monkeypatch.setenv('PATH', '.', prepend=os.pathsep)

        pathlib.Path('dummy_unit_test.sv').write_text('dummy')
        subprocess.check_call(['runSVUnit', '-e_arg', 'some-arg'])

        assert 'some-arg' in pathlib.Path('fake_verilator.log').read_text()
