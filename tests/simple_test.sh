#!/bin/bash
# simple_test.sh
#
# Requires: 
#    * gap-umbrella.sh is in the parent folder of simple_test.sh
#
# Have fun!
# 

set -o nounset
set -o errexit

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OUT=$SRCDIR/out-simple_test
cd $SRCDIR/..

if [ -e $OUT ]; then
    rm -r $OUT
fi

if ! [ -e $OUT ]; then
    mkdir $OUT
fi

base=$SRCDIR/..

export GMX_MAXBACKUPS=-1
MY_MDRUN=${1?pass the mdrun executable that you would like to test as \$1}

# MY_MDRUN=$HOME/local/gromacs_umb_serial-4.6.7/bin/mdrun_umb_serial

# gap-umbrella.sh
#==============================================================================
#     $1       starting configuration
#     $2       bias (float)
#     $3       chromophore [367,373]
#     GROMPP    grompp executable
#     MDRUN     umbrella mdrun executable
#     G_ENERGY  g_energy executable
#     OUTDIR    output directory
#     INDEX     index group file from forcefield with BCL_BCL_# entries
#     TOP       forcefield topology
#     RESTART   (true/false): run job as a restart?
#     MDPIN     input mdp file (see mdp/test.mdp for template)
GROMPP=grompp MDRUN=$MY_MDRUN                                                 \
    G_ENERGY=g_energy OUTDIR=$SRCDIR/out-simple_test                          \
    INDEX=$base/FMO_conf/index.ndx                                            \
    TOP=$base/FMO_conf/4BCL.top                                               \
    MDPIN=$base/mdp/test_10step.mdp                                           \
    RESTART=false                                                             \
    $base/gap-umbrella.sh $base/FMO_conf/em/em.gro 10.0 368

