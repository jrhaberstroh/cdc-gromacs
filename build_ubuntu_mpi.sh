#!/bin/bash
set -o nounset
set -o errexit
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
gromacs_base=$SRCDIR/gromacs-srcmod-4.6.7
cd $SRCDIR

MODE=${1-MAKE}

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
    tar -xvf gromacs-4.6.7.tar.gz
    mv gromacs-4.6.7 $gromacs_base
    cd $gromacs_base
    if [ ! -e build-mpi ]; then
        mkdir build-mpi
    fi
fi

# BUILD
if [ "$MODE" = "BUILD" ] || [ "$MODE" == "ALL" ]; then
    echo "BUILDING..."
    cd $gromacs_base
    if [ ! -e build-mpi ]; then
        mkdir build-mpi
    fi
    cd build-mpi
    cmake ..                                        \
            -DGMX_MPI=on                            \
            -DGMX_GPU=off                           \
            -DGMX_OPENMM=off                        \
	        -DGMX_OPENMP=off                        \
            -DGMX_THREAD_MPI=off                    \
            -DGMX_X11=off                           \
            -DCMAKE_CXX_COMPILER=g++                \
            -DCMAKE_C_COMPILER=gcc                  \
            -DGMX_PREFER_STATIC_LIBS=ON             \
            -DGMX_BUILD_OWN_FFTW=ON                 \
            -DGMX_DEFAULT_SUFFIX=off                \
            -DGMX_BINARY_SUFFIX="_umb_mpi"          \
            -DCMAKE_INSTALL_PREFIX=$HOME/local/gromacs_umb_mpi-4.6.7
    MODE="MAKE"
fi

if [ "$MODE" = "MAKE" ]; then
    cd $SRCDIR

    f1=mod-gromacs-4.6.7/src/mdlib/pull.c
    f2=$gromacs_base/src/mdlib/pull.c
    cmp --silent $f1 $f2 || cp $f1 $f2
    cd $gromacs_base/build-mpi
    # Reverse the sed operations for _ump_mpi_tot (in case they happened)
    sed -i 's/^CMAKE_C_FLAGS:STRING=-DNO_PRINT_CDC_SITES /CMAKE_C_FLAGS:STRING=/' CMakeCache.txt
    sed -i 's/^GMX_BINARY_SUFFIX:STRING=_umb_mpi_tot/GMX_BINARY_SUFFIX:STRING=_umb_mpi/' CMakeCache.txt
    make -j 16 
    make install-mdrun
    sed -i 's/^CMAKE_C_FLAGS:STRING=/CMAKE_C_FLAGS:STRING=-DNO_PRINT_CDC_SITES /' CMakeCache.txt
    sed -i 's/^GMX_BINARY_SUFFIX:STRING=_umb_mpi/GMX_BINARY_SUFFIX:STRING=_umb_mpi_tot/' CMakeCache.txt
    make -j 16 
    make install-mdrun

fi
