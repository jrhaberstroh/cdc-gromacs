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

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $SRCDIR/..

if ! [ -e $SRCDIR/out-ab_test ]; then
    mkdir $SRCDIR/out-ab_test
fi




GROMPP=grompp MDRUN=$HOME/local/gromacs_umb_serial-4.6.7/bin/mdrun_umb_serial \
    G_ENERGY=g_energy OUTDIR=$SRCDIR/out-ab_test \
    INDEX=???.ndx                   \
    TOP=???.top                       \
    MDPIN=test_10step.mdp          \
    RESTART=false                 \
    ./gap_umbrella.sh ???.gro 0.0 368
