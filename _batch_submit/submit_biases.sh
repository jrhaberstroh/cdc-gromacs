#!/bin/bash
#PBS -j oe

set -o nounset
set -o errexit

################################################################################
#  CONFIGURATION
################################################################################
# Manual config
OUTDIR=$SCRATCH/2015-10-FmoUmbrella2/27-debug
UMBRELLA=$HOME/Code/umbrellamacs2/gap-umbrella.sh
STARTDIR=$SCRATCH/2015-07-FmoEd/eq4-md_long/starts
MAX_REPEAT=5
njobs=${njobs-24}
name=bias

# Automatic config
nnodes=$(( ($njobs + 23) / 24 ))
width=$(( $nnodes * 24 ))
SRCDIR=${PBS_O_WORKDIR+$OUTDIR}
if [ -z $SRCDIR ]; then
    SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    SRCNAME=$(basename ${BASH_SOURCE[0]} | sed 's/\.sh//')
fi
SRCNAME=${SRCNAME?No SRCNAME set, this should be automatic!}
# Must stay set for configuration to be relative to submit folder???
cd $OUTDIR
################################################################################
#  Perform initial submission
################################################################################
if [ -z ${PBS_JOBID+x} ]; then
    if [ ${DEBUG-false} == true ]; then
        MODE=debug
    else
        MODE=regular
    fi
    chromo=${1-367}
    echo "Submitting with chromophore $chromo in $MODE mode"
    if [ $MODE = "debug" ]; then
	WALLTIME="00:03:00"
	QUEUE="debug"
    elif [ $MODE = "regular" ]; then
	WALLTIME="02:00:00"
	QUEUE="regular"
    fi
    JOBID=$(qsub -l mppwidth=$width \
            -l walltime=$WALLTIME \
            -q $QUEUE \
            -v CHROMO=$chromo,njobs=$njobs,SRCNAME=$SRCNAME\
            -N ${QUEUE}_${name}_${chromo} \
            -o $OUTDIR \
            -j oe \
            ${SRCDIR}/${SRCNAME}.sh)
    JOBID=${JOBID%%.*}
    SCRIPT_PATH=${OUTDIR}/${SRCNAME}_${chromo}_${JOBID}.sh
    echo "$JOBID"
    echo "Saving original submit script to $SCRIPT_PATH"
    cp ${SRCNAME}.sh $SCRIPT_PATH
    exit
fi


################################################################################
#  Initialize output and environment
################################################################################
module load taskfarmer
module load gromacs/4.6.7-sp
module unload PrgEnv-pgi
module load PrgEnv-intel

JOBID_CLEAN=${PBS_JOBID%%.*}
SIMDIR_PROPOSED=$OUTDIR/simout_${CHROMO}_${JOBID_CLEAN}
SIMDIR=${SIMDIR-$SIMDIR_PROPOSED}
PBS_FIRST_JOBID=$(echo $SIMDIR | sed 's/.*_//' | sed 's/\..*//')
SCRIPT_PATH=$OUTDIR/${SRCNAME}_${CHROMO}_${PBS_FIRST_JOBID}.sh
JOBDIR=$(echo $SIMDIR | sed 's/simout/jobout/')
echo "SIMDIR: $SIMDIR"
echo "JOBDIR: $JOBDIR"
if ! [ -e $JOBDIR ]; then
    mkdir $JOBDIR
fi
if [ -z ${PBS_MAGIC_REPEAT_NR+x} ]; then
    PBS_MAGIC_REPEAT_NR=1
    if ! [ -e $SIMDIR ]; then
        mkdir $SIMDIR
    fi
fi

################################################################################
#  Manage reruns
################################################################################

if [ $PBS_MAGIC_REPEAT_NR -lt $MAX_REPEAT ]; then
    echo "RESUBMIT INFORMATION:"
    echo "WALLTIME: $PBS_WALLTIME"
    echo "QUEUE: $PBS_O_QUEUE"
    INC=$(( $PBS_MAGIC_REPEAT_NR + 1))
    qsub -l mppwidth=$width \
        -l walltime=$PBS_WALLTIME \
        -q $PBS_O_QUEUE \
        -v PBS_MAGIC_REPEAT_NR=$INC,CHROMO=$CHROMO,njobs=$njobs,SIMDIR=$SIMDIR,SRCNAME=$SRCNAME \
        -W depend=afternotok:$PBS_JOBID \
        -N ${PBS_O_QUEUE}_${name}_${CHROMO}_$INC \
        -o $OUTDIR/${PBS_O_QUEUE}_${name}_${CHROMO}.o${PBS_FIRST_JOBID}_$INC \
        -j oe \
        $SCRIPT_PATH
fi

################################################################################
#  Create a temporary interface script and execute with taskfarmer
################################################################################
cd $JOBDIR

RESTART=false
if [ "$PBS_MAGIC_REPEAT_NR" -gt 1 ]; then
    RESTART=true
fi
# start_pos
while : ; do
    num=$(( $RANDOM % 500 ))
    start_pos="$STARTDIR/frame$num.gro"
    [ ! -e $start_pos ] || break
done


run_scr=$JOBDIR/submit_biases_${CHROMO}_${PBS_MAGIC_REPEAT_NR}.sh
echo "Building $run_scr..."
cat <<SUBMIT_HELPER > ${run_scr}
#!/bin/bash
set -o nounset
set -o errexit

# bias
i=\$TF_TASKID
if [ "\$i" -ge "$((njobs/2))" ]; then
    bias=\$(printf '%s%d' "-" \$(( \$i - $((njobs/2)) )))
elif [ "\$i" -lt "$((njobs/2))" ]; then
    bias=\$(printf "%d" \$((i+1)) )
fi

# run
echo "========================="
echo "REPEAT NUMBER: $PBS_MAGIC_REPEAT_NR"
echo "SUBMIT: OUTDIR=$SIMDIR RESTART=$RESTART"
echo "    $UMBRELLA $start_pos \$bias $CHROMO"
echo "========================="
OUTDIR=$SIMDIR RESTART=$RESTART $UMBRELLA $start_pos \$bias $CHROMO
SUBMIT_HELPER
chmod +x ${run_scr}
TFOUT="$JOBDIR/job_%t_${PBS_MAGIC_REPEAT_NR}.txt"
echo "Submitting $njobs jobs on $nnodes nodes in directory $(pwd)"
echo "PBS_MAGIC_REPEAT_NR=$PBS_MAGIC_REPEAT_NR"
tf -t $njobs -n $nnodes -o $TFOUT -e $TFOUT ${run_scr}
