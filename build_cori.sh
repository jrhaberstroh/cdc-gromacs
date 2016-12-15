#!/bin/bash
set -o nounset
set -o errexit
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
build_dir=$SRCDIR/gromacs-srcmod-4.6.7
cd $SRCDIR

MODE=${1-ALL}

INSTRUCTIONS="Pass ALL, BUILD, COMPILE, or INITIALIZE to \$1"

if [ "$MODE" = '-h' ]; then
    echo $INSTRUCTIONS
    exit 0
fi

if ! ( [ "$MODE" = "MAKE" ] || [ "$MODE" = "BUILD" ] || [ "$MODE" = "INITIALIZE" ] || [ "$MODE" = "ALL" ] ); then
    echo "Input Error: $INSTRUCTIONS"
    exit 300
fi


# INITIALIZE
if [ "$MODE" = "INITIALIZE" ] || [ "$MODE" = "ALL" ]; then
    echo "INITIALIZING..."
    wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-4.6.7.tar.gz
fi

# BUILD
if [ "$MODE" = "BUILD" ] || [ "$MODE" == "ALL" ]; then
    tar -xvf gromacs-4.6.7.tar.gz
    mv gromacs-4.6.7 $build_dir
    cd $build_dir
    if [ ! -e build ]; then
        mkdir build
    fi
    echo "BUILDING..."
    cd $build_dir
    module purge
    module load nsg/1.2.0
    module load modules/3.2.10.3
    module load eswrap/1.1.0-1.020200.1231.0
    module load switch/1.0-1.0502.60522.1.61.ari
    module load intel/16.0.0.109
    module load craype-network-aries
    module load craype/2.5.1
    module load cray-libsci/13.3.0
    module load udreg/2.3.2-1.0502.10518.2.17.ari
    module load ugni/6.0-1.0502.10863.8.29.ari
    module load pmi/5.0.10-1.0000.11050.0.0.ari
    module load dmapp/7.0.1-1.0502.11080.8.76.ari
    module load gni-headers/4.0-1.0502.10859.7.8.ari
    module load xpmem/0.1-2.0502.64982.5.3.ari
    module load dvs/2.5_0.9.0-1.0502.2188.1.116.ari
    module load alps/5.2.4-2.0502.9774.31.11.ari
    module load rca/1.0.0-2.0502.60530.1.62.ari
    module load atp/1.8.3
    module load PrgEnv-intel/5.2.82
    module load craype-haswell
    module load cray-shmem/7.3.1
    module load cray-mpich/7.3.1
    module load slurm/cori
    module load darshan/3.0.0-pre3
    module load PrgEnv-intel
    module load cmake
    cd build
    cmake .. -DGMX_MPI=off                                                  \
            -DGMX_GPU=off                                                   \
            -DGMX_OPENMM=off                                                \
	        -DGMX_OPENMP=off                                                \
            -DGMX_THREAD_MPI=off                                            \
            -DGMX_X11=off                                                   \
            -DCMAKE_CXX_COMPILER=icpc                                       \
            -DCMAKE_C_COMPILER=icc                                          \
            -DGMX_PREFER_STATIC_LIBS=ON                                     \
            -DGMX_BUILD_OWN_FFTW=ON                                         \
            -DGMX_DEFAULT_SUFFIX=off                                        \
            -DGMX_BINARY_SUFFIX="_umb_serial"                               \
            -DCMAKE_INSTALL_PREFIX=$HOME/local/gromacs_umb_serial-4.6.7          
    MODE="MAKE"
#             -DFFTWF_INCLUDE_DIR=$HOME/local/fftw-334-float/include          \
#             -DFFTWF_LIBRARY=$HOME/local/fftw-334-float/lib/libfftw3f.a      \
fi

if [ "$MODE" = "MAKE" ]; then
    cd $SRCDIR
    cp modifications-4.6.7/src/mdlib/* $build_dir/src/mdlib
    cd $build_dir/build
    make -j 4 
    make install-mdrun
fi
