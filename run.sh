#!/bin/bash

set -o nounset
set -o errexit

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $SRCDIR



GROMPP=$SRCDIR/mod-gromacs-4.6.7/build/src/kernel/grompp
MDRUN=$SRCDIR/mod-gromacs-4.6.7/build/src/kernel/mdrun

cd $SRCDIR/mod-gromacs-4.6.7/build/
make -j 16
cd $SRCDIR

for chromo in 367 370 373; do
    if [ ! -e testdir_$chromo ]; then
        mkdir testdir_$chromo
    fi
    
    sed -i "s/pull-group1.*/pull-group1 = BCL_BCL_$chromo/" mdp/test.mdp
    sed -i "s/pull-k1.*/pull-k1 = 10.0/" mdp/test.mdp
    $GROMPP -c FMO_conf/em/em.gro -n FMO_conf/index.ndx -p FMO_conf/4BCL.top \
            -f mdp/test.mdp -o testdir_$chromo/test_p -po testdir_$chromo/test_p \
            -maxwarn 1
    $MDRUN -nt 1 -v -deffnm testdir_$chromo/test_p &
    
    sed -i "s/pull-k1.*/pull-k1 = -10.0/" mdp/test.mdp
    $GROMPP -c FMO_conf/em/em.gro -n FMO_conf/index.ndx -p FMO_conf/4BCL.top \
            -f mdp/test.mdp -o testdir_$chromo/test_m -po testdir_$chromo/test_m \
            -maxwarn 1
    
    $MDRUN -nt 1 -v -deffnm testdir_$chromo/test_m &
done

FAIL=0
for job in `jobs -p`
do
    echo $job
    wait $job || let "FAIL+=1"
done
echo "Jobs that failed: $FAIL"

for chromo in 367 370 373; do
    for file in test_p test_m; do
        dir=testdir_$chromo
        cd $dir
        g_energy -f $file.edr -o $file-gap.xvg <<< COM-Pull-En
        TWONUMMATCH="^ \+[0-9.]\+ \+[0-9.]\+ *$"
        cat $file-gap.xvg | grep -v "$TWONUMMATCH" \
                > $file-gap_cm.xvg
        cat $file-gap.xvg | grep "$TWONUMMATCH" | awk '{print "    " $1 "    " $2*349.757}' \
                >> $file-gap_cm.xvg
        cd ..
    done
done
