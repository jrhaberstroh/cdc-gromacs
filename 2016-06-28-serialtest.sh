#!/bin/bash
set -o errexit
set -o nounset


SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
build_dir=$SRCDIR/gromacs-srcmod-4.6.7
f1=mod-gromacs-4.6.7/src/mdlib/pull.c
f2=$build_dir/src/mdlib/pull.c
cmp --silent $f1 $f2 || ./build_ubuntu.sh
#l8r ./tests/simple_test.sh $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi
#l8r sleep 2
./tests/simple_test.sh "/home/jhaberstroh/local/gromacs_umb_serial-4.6.7/bin/mdrun_umb_serial"
