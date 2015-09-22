#!/bin/bash

set -o nounset
set -o errexit

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $SRCDIR

GROMPP=${GROMPP-grompp_sp}
MDRUN=${MDRUN-$SRCDIR/mod-gromacs-4.6.7/build/src/kernel/mdrun}
G_ENERGY=${G_ENERGY-g_energy_sp}
BIAS=${BIAS-0}
CHROMO=${CHROMO-367}
OUTDIR=${OUTDIR-$SRCDIR}
dir=$OUTDIR/testdir_$CHROMO
BIASSTR=$(printf '%+4.2f' $BIAS | sed 's/+/P/' | sed 's/-/M/')
BIASSTR=$(echo $BIASSTR | sed 's/\./p/')
file=bias_$BIASSTR

if [ ! -e $dir ]; then
    mkdir $dir
fi

sed -i "s/pull-group1.*/pull-group1 = BCL_BCL_$CHROMO/" mdp/test.mdp
sed -i "s/pull-k1.*/pull-k1 = $BIAS/" mdp/test.mdp

$GROMPP -c FMO_conf/em/em.gro -n FMO_conf/index.ndx -p FMO_conf/4BCL.top \
        -f mdp/test.mdp -o $dir/$file -po $dir/$file -maxwarn 1
$MDRUN -nt 1 -v -deffnm $dir/$file

cd $dir
$G_ENERGY -f $file.edr -o $file-gap.xvg <<< COM-Pull-En
TWONUMMATCH="^ \+[0-9.]\+ \+[0-9.]\+ *$"
cat $file-gap.xvg | grep -v "$TWONUMMATCH" \
        > $file-gap_cm.xvg
cat $file-gap.xvg | grep "$TWONUMMATCH" | awk '{print "    " $1 "    " $2*349.757}' \
        >> $file-gap_cm.xvg
