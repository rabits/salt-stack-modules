#
# Python virtualenv utils
#

python-dev:
  pkg.installed

python-virtualenv:
  pkg.installed:
   - require:
     - pkg: python-dev
