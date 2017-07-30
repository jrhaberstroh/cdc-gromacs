#!/bin/bash
set -o errexit
set -o nounset
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

./test/3eoj_basic_test.sh "mpirun -np $1  valgrind --num-callers=100 --leak-check=yes --show-reachable=yes --log-file=valgrind_out $HOME/local/gromacs_umb_mpi-4.6.7/bin/mdrun_umb_mpi_3eoj -npme 0"
