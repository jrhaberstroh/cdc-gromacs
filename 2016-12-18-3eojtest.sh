#!/bin/bash
set -o errexit
set -o nounset

./tests/simple_3eoj_test.sh "mpirun -np 6 $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi"
