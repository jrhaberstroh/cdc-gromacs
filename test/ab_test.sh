#!/bin/bash
# ab_test.sh
set -o errexit
set -o nounset

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OUT=$SRCDIR/out-ab_test
cd $SRCDIR/..
base=$SRCDIR/..
cdctraj=$SRCDIR/cdc-fmo/cdctraj.sh
ALL=$OUT/allsite-cdc.txt
NALL=$OUT/allsite-noise.txt
RESID=${1?Please pass resid to \$1}
S_CDC=$OUT/site-cdc.txt
S_MD=$OUT/site-MD.txt
S_NOISE=$OUT/site-noise.txt
NOISE=${NOISE-false}
PROTO=${PROTO-false}
PYEXTRA=${PYEXTRA-}
FAST=${FAST-false}
OUTDIR=${OUTDIR-}

if [ "$PROTO" == "true" ]; then
    PYEXTRA="$PYEXTRA -proto"
fi

compare () {
# Comparison
#==============================================================================
cd $OUT
num=$(echo $RESID - 366 | bc)
COMP=$OUT/comparison.txt
cd $OUT
if [ -e $COMP ]; then
    rm $COMP
fi

# Leave exactly two of three sections uncommented
awk "(NR - $num) % 7 == 0" $ALL   > $S_CDC
< $S_CDC head -n 1 | tail -n 1 | while read l; do
    echo "$l" | cut -d' ' -f1- | wc -w
    # echo "$l" | cut -d' ' -f1-
    echo "$l" | cut -d' ' -f1- >> $COMP
done


if [ "$NOISE" == true ]; then
    awk "(NR - $num) % 7 == 0" $NALL  > $S_NOISE
    < $S_NOISE head -n 1 | tail -n 1 | while read l; do
        echo "$l" | cut -d' ' -f1- | wc -w
        # echo "$l" | cut -d' ' -f1-
        echo "$l" | cut -d' ' -f1- >> $COMP
    done
else
    # cat site-cdc.txt | head -n 2 | tail -n 1
    < $S_MD head -n 2 | tail -n 1 | while read l; do
        echo "$l" | cut -d',' -f2- | wc -w
        # echo "$l" | cut -d',' -f2-
        echo "$l" | cut -d',' -f2- >> $COMP
    done
fi

cd $SRCDIR
name_append=""
if [ "$NOISE" == true ]; then
    name_append="${name_append}N"
fi
if [ "$PROTO" == true ]; then
    name_append="${name_append}P"
fi
if [ ! -z $OUTDIR ]; then
    python scplot.py -out $OUTDIR/s${RESID}${name_append}.png -final 350
else
    python scplot.py -final 350
fi
}

if [ "$FAST" == "true" ]; then
    compare
    exit
fi



./build_ubuntu.sh
if [ -e $SRCDIR/out-ab_test ]; then
    rm -r $SRCDIR/out-ab_test
fi

if ! [ -e $SRCDIR/out-ab_test ]; then
    mkdir $SRCDIR/out-ab_test
fi



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
GROMPP=grompp MDRUN=$HOME/local/gromacs_umb_serial-4.6.7/bin/mdrun_umb_serial \
    G_ENERGY=g_energy OUTDIR=$OUT                                             \
    INDEX=$base/FMO_conf/index.ndx                                            \
    TOP=$base/FMO_conf/4BCL.top                                               \
    MDPIN=$base/mdp/test_10step.mdp                                           \
    RESTART=false                                                             \
    $base/gap-umbrella.sh $base/FMO_conf/em/em.gro 0.0 $RESID | grep "^CDC" > $S_MD

cd $OUT
# G_ENERGY
g_energy -f bias_P0p00.edr -o bias_P0p00.xvg <<out
COM-Pull

out
# # END G_ENERGY


# TRJCONV
trjconv -f bias_P0p00.trr -s bias_P0p00.tpr -o traj.gro <<out
System

out
# # END TRJCONV


cat bias_P0p00.xvg | grep -v ^@  | grep -v ^# | \
    awk '{print $2}' > site-B.txt 



# cdctraj.sh
#==============================================================================
# Converts a .gro trajectory of length (frames >= TRJLEN) into a series of cdc
# computations. 
#   Usage: 
#     $1       - .gro format trajectory to pass in
#     TOP      - Preprocessed GROMACS topology file
#     ATOMS    - Number of atoms in each frame of $1
#     TRJLEN   - Number of frames to process within gro file ($1). If 
#                successive files repeat the final frame, take care to
#                set TRJLEN to a small number.
#                NOTE: Not error checked to assert that TRJLEN <= numframes
#     NODEL    - If true, do not delete temp folder upon initiation


TOP=$base/FMO_conf/4BCL_pp.top                                                \
    ATOMS=99548                                                               \
    TRJLEN=2                                                                  \
    NODEL=false                                                               \
    PYARGS="-debug $PYEXTRA"                                                  \
    $SRCDIR/cdc-fmo/cdctraj.sh $OUT/traj.gro                                  \
     > $ALL


if [ "$NOISE" == true ]; then
    TOP=$base/FMO_conf/4BCL_pp.top                                                \
        ATOMS=99548                                                               \
        TRJLEN=2                                                                  \
        NODEL=false                                                               \
        PYARGS="-debug $PYEXTRA -noise .001"                                      \
        $SRCDIR/cdc-fmo/cdctraj.sh $OUT/traj.gro                                  \
         > $NALL
fi



compare
