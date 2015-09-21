#!/bin/bash

set -o nounset
set -o errexit

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $SRCDIR

if [ ! -e testdir ]; then
    mkdir testdir
fi

GROMPP=$SRCDIR/mod-gromacs-4.6.7/build/src/kernel/grompp
MDRUN=$SRCDIR/mod-gromacs-4.6.7/build/src/kernel/mdrun

cd $SRCDIR/mod-gromacs-4.6.7/build/
make -j 16
cd $SRCDIR

$GROMPP -c FMO_conf/em/em.gro -n FMO_conf/index.ndx -p FMO_conf/4BCL.top \
        -f mdp/test.mdp -o testdir/testdir -po testdir/testdir -maxwarn 1

$MDRUN -v -deffnm testdir/testdir
