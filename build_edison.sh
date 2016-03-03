#!/bin/bash
set -o nounset
set -o errexit
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
build_dir=$SRCDIR/umrellamacs-edison-4.6.7
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
    module load PrgEnv-intel
    module load cmake
    sed -i 's/\^#pragma omp .*\$//' src/*/*.c
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
            -DGMX_BINARY_SUFFIX="_umb_sE"                                   \
            -DCMAKE_INSTALL_PREFIX=$HOME/local/gromacs_umb_sE-4.6.7          
    MODE="MAKE"
#             -DFFTWF_INCLUDE_DIR=$HOME/local/fftw-334-float/include          \
#             -DFFTWF_LIBRARY=$HOME/local/fftw-334-float/lib/libfftw3f.a      \
fi

if [ "$MODE" = "MAKE" ]; then
    cd $SRCDIR
    cp mod-gromacs-4.6.7/src/mdlib/* $build_dir/src/mdlib
    cd $build_dir/build
    make -j 4 
    make install-mdrun
fi
