#!/bin/bash

set -o nounset
set -o errexit

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $SRCDIR

# \t is delimiter, do not use tabs in HELPTEXT
read -r -d'\t' HELPTEXT << help 
Options:
    \$1       starting configuration
    \$2       bias (float)
    \$3       chromophore [367,373]
    GROMPP    grompp executable
    MDRUN     umbrella mdrun executable
    G_ENERGY  g_energy executable
    OUTDIR    output directory
    INDEX     index group file from forcefield with BCL_BCL_# entries
    TOP       forcefield topology
    RESTART   (true/false): run job as a restart?
    MDPIN     input mdp file (see mdp/test.mdp for template)\t
help

if [ ${1-} = '-h' ]; then
    echo "$HELPTEXT"
    exit 0
fi

START=${1?Requires \$1 START}
BIAS=${2?Requires \$2 BIAS}
CHROMO=${3?Requires \$3 CHROMO}

GROMPP=${GROMPP-grompp_sp}
MDRUN=${MDRUN-$HOME/local/gromacs_umb_serial-4.6.7/bin/mdrun_umb_serial}
G_ENERGY=${G_ENERGY-g_energy_sp}
OUTDIR=${OUTDIR-$SRCDIR}
MDPIN=${MDPIN-$SRCDIR/mdp/test.mdp}
INDEX=${INDEX-$SRCDIR/FMO_conf/index.ndx}
TOP=${TOP-$SRCDIR/FMO_conf/4BCL.top}
RESTART=${RESTART-false}
BIASSTR=$(printf '%+4.2f' $BIAS | sed 's/+/P/' | sed 's/-/M/')
BIASSTR=$(echo $BIASSTR | sed 's/\./p/')
file=bias_$BIASSTR

if [ "$RESTART" = "true" ]; then
    $MDRUN -v -deffnm $OUTDIR/$file -noappend \
        -cpi $OUTDIR/$file.cpt -cpo $OUTDIR/$file.cpt -cpt 1 
else
    MDP=$OUTDIR/${file}_IN.mdp
    cp $MDPIN $MDP
    sed -i "s/pull-group1.*/pull-group1 = BCL_BCL_$CHROMO/" $MDP
    sed -i "s/pull-k1.*/pull-k1 = $BIAS/" $MDP
    $GROMPP -c $START -n $INDEX -p $TOP \
            -f $MDP -o $OUTDIR/$file -po $OUTDIR/$file -maxwarn 1
    $MDRUN -v -deffnm $OUTDIR/$file -cpo $OUTDIR/$file.cpt -cpt 1
fi 

cd $OUTDIR
$G_ENERGY -f $file.edr -o $file-gap.xvg <<< COM-Pull-En
TWONUMMATCH="^ \+[0-9.]\+ \+\-\?[0-9.]\+ *$"
cat $file-gap.xvg | grep -v "$TWONUMMATCH" \
        > $file-gap_cm.xvg
cat $file-gap.xvg | grep "$TWONUMMATCH" | awk '{print "    " $1 "    " $2*349.757}' \
        >> $file-gap_cm.xvg
