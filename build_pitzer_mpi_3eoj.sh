#!/bin/bash
set -o nounset
set -o errexit
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
build_dir=$SRCDIR/umbrellamacs-pitzer-4.6.7
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
if [ ! -e $build_dir ]; then
    echo "INITIALIZING..."
    if [ ! -e gromacs-4.6.7.tar.gz ]; then
        wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-4.6.7.tar.gz
    fi
    if [ ! -e gromacs-4.6.7 ]; then
        tar -xvf gromacs-4.6.7.tar.gz
    fi
    mv gromacs-4.6.7 $build_dir
    cd $build_dir
    if [ ! -e build_mpi ]; then
        mkdir build_mpi
    fi
fi

# BUILD
echo "BUILDING..."
cd $build_dir
sed -i 's/\^#pragma omp .*\$//' src/*/*.c
cd build_mpi
CMAKE_INCLUDE_PATH=$HOME/vlocal/fftw_333_float/include \
     CMAKE_LIBRARY_PATH=$HOME/vlocal/fftw_333_float/lib     \
     CMAKE_PREFIX_PATH=$HOME/vlocal/fftw_333_float/lib      \
     cmake .. -DGMX_MPI=ON                                         \
             -DGMX_GPU=OFF                                         \
             -DGMX_OPENMP=OFF                                      \
             -DGMX_DOUBLE=OFF                                      \
             -DCMAKE_SKIP_RPATH=YES                                \
             -DCMAKE_INSTALL_PREFIX=$HOME/vlocal/gromacs_umb_mpi-4.6.7 \
             -DBUILD_SHARED_LIBS=OFF                               \
             -DGMX_PREFER_STATIC_LIBS=ON                           \
             -DGMX_BINARY_SUFFIX=_umb_mpi_3eoj                     \
             -DGMX_DEFAULT_SUFFIX=OFF                              \
             -DGMX_LIBS_SUFFIX=_umb_mpi_3eoj                       
MODE="MAKE"


cd $SRCDIR

## Merge 3eoj modifications into base code and copy to build-source
echo "Merging cdc header into pull.c..."
sed -e '/%%CDC-INSERTION%%/r modifications-4.6.7/src/mdlib/pull.3eoj.c' \
     modifications-4.6.7/src/mdlib/pull.BASE.c >  $build_dir/src/mdlib/pull.c
cd $build_dir/build_mpi
make -j 8
make install

