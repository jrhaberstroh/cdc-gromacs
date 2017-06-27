#!/bin/bash
set -o nounset
set -o errexit
SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
topology_version='3eoj_svnrhcdei'
gromacs_base="$SRCDIR/gromacs-build-${topology_version}-4.6.7"
SUFFIX="_umb_mpi_${topology_version}"
BINDIR="$gromacs_base/build-mpi/src/kernel"
cd $SRCDIR

MODE=${1-MAKE}

INSTRUCTIONS="Pass any of {ALL, BUILD, COMPILE, INITIALIZE, MAKE, TOTAL-ONLY, INSTALL, TEST} to \$1"

if [ "$MODE" = '-h' ]; then
    echo $INSTRUCTIONS
    exit 0
fi

if ! ( [ "$MODE" = "MAKE" ] || [ "$MODE" = "BUILD" ] || [ "$MODE" = "INITIALIZE" ] || [ "$MODE" = "TOTAL-ONLY" ] || [ "$MODE" = "TEST" ] || [ "$MODE" = "INSTALL"] || [ "$MODE" = "ALL" ] ); then
    echo "Input Error: $INSTRUCTIONS"
    exit 300
fi


# INITIALIZE
if [ "$MODE" = "INITIALIZE" ] || [ "$MODE" = "ALL" ]; then
    echo "INITIALIZING..."
    if [ ! -e $gromacs_base ]; then 
        if [ ! -e gromacs-4.6.7.tar.gz ]; then
            wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-4.6.7.tar.gz
        fi
        tar -xvf gromacs-4.6.7.tar.gz
        mv gromacs-4.6.7 $gromacs_base
    fi
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
    cmake ..                                                   \
            -DGMX_MPI=on                                       \
            -DGMX_GPU=off                                      \
            -DGMX_OPENMM=off                                   \
	        -DGMX_OPENMP=off                                   \
            -DGMX_THREAD_MPI=off                               \
            -DGMX_X11=off                                      \
            -DCMAKE_CXX_COMPILER=g++                           \
            -DCMAKE_C_COMPILER=gcc                             \
            -DGMX_PREFER_STATIC_LIBS=ON                        \
            -DGMX_BUILD_OWN_FFTW=ON                            \
            -DGMX_DEFAULT_SUFFIX=off                           \
            -DGMX_BINARY_SUFFIX="${SUFFIX}"                    \
            -DCMAKE_INSTALL_PREFIX=$HOME/local/gromacs_umb_mpi-4.6.7
    MODE="MAKE"
fi

if [ "$MODE" = "MAKE" ]; then
    cd $SRCDIR

    ## Merge topology modifications into base code and copy to build-source
    echo "Merging cdc header into pull.c..."
    sed -e '/%%CDC-INSERTION%%'"/r modifications-4.6.7/src/mdlib/pull.${topology_version}.c" \
         modifications-4.6.7/src/mdlib/pull.BASE.c >  $gromacs_base/src/mdlib/pull.c
    cd $gromacs_base/build-mpi
    # Reverse the sed operations for _ump_mpi_tot (in case they happened)
    sed -i 's/^CMAKE_C_FLAGS:STRING=-DNO_PRINT_CDC_SITES/CMAKE_C_FLAGS:STRING=/' CMakeCache.txt
    sed -i 's/^GMX_BINARY_SUFFIX:STRING=_umb_mpi_tot/GMX_BINARY_SUFFIX:STRING=_umb_mpi/' CMakeCache.txt
    make -j 16 
    MODE="TEST"
fi


if [ "$MODE" = "TOTAL-ONLY" ]; then
    sed -i 's/^CMAKE_C_FLAGS:STRING=/CMAKE_C_FLAGS:STRING=-DNO_PRINT_CDC_SITES /' CMakeCache.txt
    sed -i 's/^GMX_BINARY_SUFFIX:STRING=_umb_mpi/GMX_BINARY_SUFFIX:STRING=_umb_mpi_tot/' CMakeCache.txt
    make -j 16 
fi

if [ "$MODE" = "INSTALL" ]; then
    make install-mdrun
fi

if [ "$MODE" = "TEST" ]; then
    GMX_C=$SRCDIR/3eoj_sv-topology/em/em.gro                    \
    GMX_P=$SRCDIR/3eoj_sv-topology/top/${topology_version}.top  \
    GMX_N=$SRCDIR/3eoj_sv-topology/${topology_version}.ndx      \
    GROMPP=$BINDIR/grompp${SUFFIX}                              \
        $SRCDIR/test/3eoj_basic_test.sh "mpirun -np 2 $BINDIR/mdrun${SUFFIX}"
fi



