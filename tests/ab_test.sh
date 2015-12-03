#!/bin/bash
# ab_test.sh
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $SRCDIR/..

if [ -e $SRCDIR/out-ab_test ]; then
    rm -r $SRCDIR/out-ab_test
fi

if ! [ -e $SRCDIR/out-ab_test ]; then
    mkdir $SRCDIR/out-ab_test
fi

base=$SRCDIR/..

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
    G_ENERGY=g_energy OUTDIR=$SRCDIR/out-ab_test                              \
    INDEX=$base/FMO_conf/index.ndx                                            \
    TOP=$base/FMO_conf/4BCL.top                                               \
    MDPIN=$base/mdp/test_10step.mdp                                           \
    RESTART=false                                                             \
    $base/gap-umbrella.sh $base/FMO_conf/em/em.gro 0.0 368

cd $SRCDIR/out-ab_test
# G_ENERGY
g_energy -f bias_P0p00.edr -o bias_P0p00.xvg <<out
COM-Pull

out
# G_ENERGY
# TRJCONV
trjconv -f bias_P0p00.trr -s bias_P0p00.tpr -o traj.gro <<out
System

out
# TRJCONV
cat bias_P0p00.xvg | grep -v ^@  | grep -v ^# | \
    awk '{print $2}' > site368-B.txt 



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

cdctraj=$SRCDIR/cdc-fmo/cdctraj.sh

TOP=$base/FMO_conf/4BCL_pp.top                                                \
    ATOMS=99548                                                               \
    TRJLEN=10                                                                 \
    NODEL=false                                                               \
    $SRCDIR/cdc-fmo/cdctraj.sh $SRCDIR/out-ab_test/traj.gro                   \
     > $SRCDIR/out-ab_test/cdc-fmo.txt

cd $SRCDIR/out-ab_test
awk '(NR + 1) % 7 == 0' cdc-fmo.txt  > site368_split.txt

(
cat <<'pysum'
with open("site368_split.txt") as f:
    for l in f:
        larr = [float(x) for x in l.split()]
        print sum(larr)
pysum
) > .pysum.py
python .pysum.py > site368-A.txt
rm .pysum.py




# Comparison
#==============================================================================
print site368-A.txt
print site368-B.txt
