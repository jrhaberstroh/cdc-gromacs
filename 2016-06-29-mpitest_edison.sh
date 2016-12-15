#!/bin/bash

export COUNTER=${COUNTER-0}
export O_SRCDIR=${O_SRCDIR-${PBS_O_WORKDIR-$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )}}

NODES=1
CORES=$((NODES*24))
OUTDIR="/scratch2/scratchdirs/jhabers/2016-06-umbreallamacs_mpi"
MDRUN="/global/homes/j/jhabers/local/gromacs_umb_mpi_E-4.6.7/bin/mdrun_umb_mpi_ed"
GROMPP="/global/homes/j/jhabers/local/gromacs_umb_sE-4.6.7/bin/grompp_umb_sE"

if [ ! -d $O_SRCDIR/FMO_conf ]; then
    echo "ERROR: This script requires copy or link to FMO_conf in base directory"
    exit
fi

if [ "$COUNTER" -eq 0 ]; then
    export COUNTER=$((COUNTER+1))
    sbatch -N $NODES -p debug -t 10 -o $OUTDIR/test_mpi-%j.txt -J test_mpi "${BASH_SOURCE[0]}"
    exit
fi

GROMPP=$GROMPP $O_SRCDIR/tests/simple_test.sh "srun -n 6 $MDRUN"
