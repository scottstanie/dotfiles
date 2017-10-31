#!/usr/bin/env python
"""Pre-commit git hook to check style

Based off https://github.com/peterjc/biopython/blob/pre_commit_linting/Scripts/git_pre_commit_hook.py

In order to set up locally, you must run

    $ ln -s -f ../../fleet/pre-commit.py .git/hooks/pre-commit

The extra ../ are because git looks at the .git/hooks as the
current directory when running hooks

If you get Traceback errors, make sure you have flake8 and pep8:

    pip install -U flake8
    pip install -U pep8

To alter your settings for linting, create or edit the files
    ~/.config/pep8 and ~/.config/flake8

See http://pep8.readthedocs.io/en/release-1.7.x/intro.html#configuration

This script will by default (such as when run by git when you run the
``git commit`` command) determine all new or changed files according
to git, and apply style checks to the version staged in git. (Note
it will not lint the current version of the file on disk, which might
be newer if you've edited a file but not yet done "git add").
The script can alternatively be run with filenames or folders to check,
in which case the git status of the files is ignored. This can be used
for example when working on this script itself (e.g. as part of work to
tighten the style checks), or for continous integration testing via
TravisCI and/or Tox.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

try:
    from subprocess import getoutput
except ImportError:
    # Python 2
    from commands import getoutput

# These assume we can append one or more filenames/directories to the end...
python_check_templates = (
    ("pep8", "--max-line-length=130"),
    ("flake8", "--max-line-length=130"),
    # If we want to ignore certain errors:
    # ("pep8", "--ignore", "E121,E122,E123,E124,E125,E126,E127,E128,E129,E131,E501"),
    # ("flake8", "--ignore", "E121,E122,E123,E124,E125,E126,E127,E128,E129,E131,E501"),
    # See http://pep8.readthedocs.io/en/release-1.7.x/intro.html#error-codes for codes
)

if len(sys.argv) > 1:
    # assume called with list of local directories and/or files to lint
    py_files = tuple(sys.argv[1:])
    tempdir = None
    cwd = "."
else:
    # Assume called via 'git commit' and ask git for changed/new files
    modified_py = re.compile("^[AM]+\s+(?P<name>.*\.py)", re.MULTILINE)
    py_files = tuple(modified_py.findall(getoutput("git status --porcelain")))
    if not py_files:
        sys.stderr.write("Seems nothing has changed which needs linting...\n")
        sys.exit(0)
    elif len(py_files) <= 5:
        sys.stderr.write("Linting files: %s\n" % " ".join(py_files))
    else:
        sys.stderr.write("Linting %i files...\n" % len(py_files))

    # Prepare temp directory of the files as staged in git
    # Can't just lint in place as would see changes pending git add
    tempdir = tempfile.mkdtemp()
    for name in py_files:
        filename = os.path.join(tempdir, name)
        filepath = os.path.dirname(filename)

        if not os.path.exists(filepath):
            os.makedirs(filepath)
        with open(filename, "w") as f:
            subprocess.check_call(("git", "show", ":" + name), stdout=f)
    cwd = tempdir

# We run all the checks up front so user doesn't get a false sense of
# what is wrong if we just showed problems from the first tool.
failed = False

for cmd_template in python_check_templates:
    child = subprocess.Popen(cmd_template + py_files, cwd=cwd)
    child.communicate()
    return_code = child.returncode
    if return_code:
        sys.stderr.write("Return code %i from %s\n" % (return_code, cmd_template[0]))
        failed = True

if tempdir:
    shutil.rmtree(tempdir)
if failed:
    sys.stderr.write("Style validation failed. Please fix, or force with 'git commit --no-verify'\n")
    sys.exit(1)
