#!/bin/bash
# simple_test.sh
#
# Tests executable mdrun program passed to $1 for a 10-step execution
# and writes all output files to files matching the following pattern:
#    test-output/simple*
# 
set -o nounset
set -o errexit

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
base="$SRCDIR/.."

    
MDP=$base/test-output/simple-cat.mdp
## Create the MDP file to use
cat << MDP > $MDP
title       = Generic NVT equilibration 
define      =                   ; position restrain the protein
; Run parameters
integrator  = md                ; leap-frog integrator
nsteps      = 2                 ; 20 fs
dt          = 0.002             ; 2 fs
; Output control
nstxout     = 2000              ; save coordinates every 0.2 ps
nstvout     = 2000              ; save velocities every 0.2 ps
nstxtcout   = 2000               
nstenergy   = 1                 ; save energies every 0.2 ps
nstlog      = 2000              ; update log file every 0.2 ps

; Bond parameters
continuation    = no            ; first dynamics run
constraint_algorithm = lincs    ; holonomic constraints 
constraints = all-bonds         ; all bonds (even heavy atom-H bonds) constrained
lincs_iter  = 1                 ; accuracy of LINCS
lincs_order = 4                 ; also related to accuracy

; Cutoffs and electrostatics
pbc          = xyz              ; 3-D PBC
nstlist     = 10
ns_type     = grid              ; search neighboring grid cells
rlist       = 1.2               ; short-range neighborlist cutoff (in nm)
rcoulomb    = 1.2               ; short-range electrostatic cutoff (in nm)
rvdw        = 1.2               ; short-range van der Waals cutoff (in nm)
DispCorr    = EnerPres          ; account for cut-off vdW scheme
coulombtype = PME               ; Particle Mesh Ewald for long-range electrostatics
pme_order   = 4                 ; cubic interpolation
fourierspacing  = 0.24          ; grid spacing for FFT

; Velocity generation
gen_vel     = yes               ; assign velocities from Maxwell distribution

; Temperature coupling is on
tcoupl          = v-rescale
tc-grps         = Protein    non-protein
tau-t           = 0.1  0.1
ref-t           = 300  300
ld-seed         = 90210

; Pressure coupling is off
pcoupl      = no                ; no pressure coupling in NVT

; Pulling for CDC
pull                    = constant-force
pull-nstxout            = 0
pull-nstfout            = 0
pull-geometry           = direction-periodic
pull-dim                = Y Y Y
pull-ngroups            = 1
pull-group1		        = BCL_1_373
pull-k1                 = 10.0
MDP
    
for HEADERMODE in 'auto' 'manual'; do
    HEADERMODE=$HEADERMODE $base/build_ubuntu_mpi_anytopo.sh MAKE

    GMX_C=${GMX_C-$base/3eoj-topology/em/em.gro}
    GMX_P=${GMX_P-$base/3eoj-topology/top/3eoj_xmshbsri.top}
    GMX_N=${GMX_N-$base/3eoj-topology/3eoj_xmshbsri.ndx }
    GMX_F=$MDP
    GMX_O=$base/test-output/simple         
    GMX_PO=$base/test-output/simple          
    
    
    ## Setup the environment and read command line arguments
    MY_MDRUN=${1?pass the mdrun executable that you would like to test as \$1}
    export GMX_MAXBACKUP=-1
    GROMPP=${GROMPP-grompp}
    
    echo "MDRUN for simple_test: $MY_MDRUN"
    echo "GROMPP for simple_test: $GROMPP"
    
    
    $GROMPP -c  $GMX_C  \
            -p  $GMX_P  \
            -n  $GMX_N  \
            -f  $GMX_F  \
            -o  $GMX_O  \
            -po $GMX_PO \
            -maxwarn 1
    
    $MY_MDRUN  -v -deffnm $base/test-output/simple > $base/test-output/basicCDC-${HEADERMODE}.cdc
done
