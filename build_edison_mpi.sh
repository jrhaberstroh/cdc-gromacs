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
    if [ ! -e build_mpi ]; then
        mkdir build_mpi
    fi
    echo "BUILDING..."
    cd $build_dir
    module swap PrgEnv-intel PrgEnv-gnu
    module load cmake
    sed -i 's/\^#pragma omp .*\$//' src/*/*.c
    CC=cc CPP=cpp CXXCPP=cpp CXX=CC \
         CMAKE_INCLUDE_PATH=/opt/cray/fftw/3.3.4.6/sandybridge/include \
         CMAKE_LIBRARY_PATH=/opt/cray/fftw/3.3.4.6/sandybridge/lib     \
         CMAKE_PREFIX_PATH=/opt/cray/fftw/3.3.4.6/sandybridge/lib      \
         cmake .. -DGMX_MPI=ON                                         \
                 -DGMX_OPENMP=OFF                                      \
                 -DGMX_DOUBLE=OFF                                      \
                 -DCMAKE_SKIP_RPATH=YES                                \
                 -DCMAKE_INSTALL_PREFIX=$HOME/local/gromacs_umb_sE-4.6.7 \
                 -DBUILD_SHARED_LIBS=OFF                               \
                 -DGMX_PREFER_STATIC_LIBS=ON                           \
                 -DGMX_BINARY_SUFFIX=_umb_mpi_ed                       \
                 -DGMX_DEFAULT_SUFFIX=OFF                              \
                 -DGMX_LIBS_SUFFIX=_mpi_sp                             \
                 -DGMX_BUILD_MDRUN_ONLY=ON
    MODE="MAKE"
fi

if [ "$MODE" = "MAKE" ]; then
    cd $SRCDIR
    cp mod-gromacs-4.6.7/src/mdlib/* $build_dir/src/mdlib
    cd $build_dir/build_mpi
    make -j 4 
    make install
fi
