#!/bin/bash
set -o errexit
set -o nounset

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
CHROMO=371 $basedir/tests/simple_test.sh "mpirun -np 6 $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi" \
        | grep "CDC" > $basedir/test-output/cdc-mpi.txt
CHROMO=371 $basedir/tests/simple_test.sh "$HOME/local/gromacs_umb_serial-4.6.7/bin/mdrun_umb_serial" \
        | grep "CDC" > $basedir/test-output/cdc-serial.txt
