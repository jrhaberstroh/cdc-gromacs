#!/bin/bash
set -o errexit
set -o nounset


SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
build_dir=$SRCDIR/gromacs-srcmod-4.6.7
f1=mod-gromacs-4.6.7/src/mdlib/pull.c
f2=$build_dir/src/mdlib/pull.c
cmp --silent $f1 $f2 || ./build_ubuntu_mpi.sh
#l8r ./tests/simple_test.sh $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi
#l8r sleep 2
CHROMO=371 ./tests/simple_test.sh "mpirun -np 6 $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi"
CHROMO=371 ./tests/simple_test.sh "mpirun -np 6 $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi_tot"
