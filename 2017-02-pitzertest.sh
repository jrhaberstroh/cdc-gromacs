#!/usr/bin/env bash

if [ ! -e 3eoj-topology ]; then
    echo "Error: 3eoj-topology not found. This folder is required at runtime!"
    exit 50001
fi

BUILDDIR="umbrellamacs-pitzer-4.6.7/build_mpi/src/kernel"

GROMPP=${BUILDDIR}/grompp_umb_mpi_3eoj ./test/simple_3eoj_test.sh "mpirun -n 4 ${BUILDDIR}/mdrun_umb_mpi_3eoj"
