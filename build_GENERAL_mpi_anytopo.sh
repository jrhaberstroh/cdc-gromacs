#!/bin/bash
set -o nounset
set -o errexit
topology_version=${topology_version-3eoj_svnrhcdei}
HEADERMODE=${HEADERMODE-auto}
echo "ACTIVE TOPOLOGY: ${topology_version}"
echo "HEADER MODE: ${HEADERMODE}"

SRCDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
gromacs_base="$SRCDIR/gromacs-build-${topology_version}-4.6.7"
SUFFIX="_umb_mpi_${topology_version}"
BINDIR="$gromacs_base/build-mpi/src/kernel"
cd $SRCDIR

MODE_DEFAULT="MAKE"
if   [ ! -e "$gromacs_base/build_mpi" ]; then
    MODE_DEFAULT="ALL"
elif [ ! -e "$gromacs_base/build_mpi/CMakeCache.txt" ]; then
    MODE_DEFAULT="BUILD"
else
    MODE_DEFAULT="MAKE"
fi
MODE=${1-${MODE_DEFAULT}}
if [ -z ${1+x} ]; then
    echo "Falling back on mode default ${MODE}."
else
    echo "Running in mode ${1}."
fi

## Configure system setting
if [ $(hostname) = 'pitzer.cchem.berkeley.edu' ]; then
    echo "Detected pitzer.cchem.berkeley.edu host. Using that configuration."
    module load anaconda
    CMAKE_INCLUDE_PATH=$HOME/vlocal/fftw_333_float/include 
    CMAKE_LIBRARY_PATH=$HOME/vlocal/fftw_333_float/lib            
    CMAKE_PREFIX_PATH=$HOME/vlocal/fftw_333_float/lib        
    CMAKE="cmake .. -DGMX_MPI=ON                                          \
                  -DGMX_GPU=OFF                                         \
                  -DGMX_OPENMP=OFF                                      \
                  -DGMX_DOUBLE=OFF                                      \
                  -DCMAKE_SKIP_RPATH=YES                                \
                  -DCMAKE_INSTALL_PREFIX=$HOME/vlocal/gromacs_umb_mpi${topology_version}-4.6.7 \
                  -DBUILD_SHARED_LIBS=OFF                               \
                  -DGMX_PREFER_STATIC_LIBS=ON                            "
elif [ $(cat /etc/*-release | grep 'DISTRIB_ID' | cut -d'=' -f2) = 'Ubuntu' ]; then
    echo "Detected Ubuntu system. Using that configuration."
    CMAKE_INCLUDE_PATH=""
    CMAKE_LIBRARY_PATH=""
    CMAKE_PREFIX_PATH=""
    CMAKE="cmake ..                                                   \
            -DGMX_MPI=on                                       \
            -DGMX_GPU=off                                      \
            -DGMX_OPENMM=off                                   \
	        -DGMX_OPENMP=off                                   \
            -DGMX_THREAD_MPI=off                               \
            -DGMX_X11=off                                      \
            -DCMAKE_CXX_COMPILER=g++                           \
            -DCMAKE_C_COMPILER=gcc                             \
            -DCMAKE_INSTALL_PREFIX=$HOME/local/gromacs_umb_mpi_${topology_version}-4.6.7 \
            -DGMX_PREFER_STATIC_LIBS=ON                        \
            -DGMX_BUILD_OWN_FFTW=ON                              "
else 
    echo "System not recognized. Aborting."
    exit 403
fi

sleep 2

INSTRUCTIONS="Pass any of {ALL, BUILD, COMPILE, INITIALIZE, MAKE, TOTAL-ONLY, INSTALL, TEST} to \$1"

if [ "$MODE" = '-h' ]; then
    echo $INSTRUCTIONS
    exit 0
fi

# if ! ( [ "$MODE" = "MAKE" ] || [ "$MODE" = "BUILD" ] || [ "$MODE" = "INITIALIZE" ] || [ "$MODE" = "TOTAL-ONLY" ] || [ "$MODE" = "TEST" ] || [ "$MODE" = "INSTALL"] || [ "$MODE" = "ALL" ] ); then
#     echo "Input Error: $INSTRUCTIONS"
#     exit 300
# fi

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
    ## Remove all omp directives for poor little pitzer
    sed -i 's/\^#pragma omp .*\$//' src/*/*.c
    if [ ! -e build-mpi ]; then
        mkdir build-mpi
    fi
    cd build-mpi

    CMAKE_INCLUDE_PATH=$CMAKE_INCLUDE_PATH                         \
    CMAKE_LIBRARY_PATH=$CMAKE_LIBRARY_PATH                         \
    CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH                           \
    ${CMAKE} -DGMX_BINARY_SUFFIX="${SUFFIX}"                       \
             -DGMX_LIBS_SUFFIX="${SUFFIX}"                         \
             -DGMX_DEFAULT_SUFFIX=OFF                              
    MODE="MAKE"
fi

if [ "$MODE" = "MAKE" ]; then
    cd $SRCDIR
    ## Generate automagic header
    python modifications-4.6.7/src/mdlib/generate_3eoj.py                      \
            ${topology_version}-topology/${topology_version}.gro >             \
            modifications-4.6.7/src/mdlib/pull.${topology_version}_auto.c

    ## Merge topology modifications into base code, then write it to build-source
    echo "Merging cdc header into pull.c..."
    ## BEGIN: NEW DIR
    cd modifications-4.6.7/src/mdlib
    ln -sf pull.${topology_version}_${HEADERMODE}.c pull.${topology_version}.c
    cd -
    ## END: NEW DIR
    sed -e '/%%CDC-INSERTION%%'"/r modifications-4.6.7/src/mdlib/pull.${topology_version}.c" \
         modifications-4.6.7/src/mdlib/pull.BASE.c >  $gromacs_base/src/mdlib/pull.c
    cd $gromacs_base/build-mpi

    # Reverse the sed operations for [MODE = TOTAL_ONLY] (in case that was used)
    sed -i 's/^CMAKE_C_FLAGS:STRING=-DNO_PRINT_CDC_SITES/CMAKE_C_FLAGS:STRING=/' CMakeCache.txt
    sed -i 's/^GMX_BINARY_SUFFIX:STRING=_umb_mpi_tot/GMX_BINARY_SUFFIX:STRING=_umb_mpi/' CMakeCache.txt
    make -j 16 
fi


if [ "$MODE" = "TOTAL-ONLY" ]; then
    cd $gromacs_base/build-mpi
    sed -i 's/^CMAKE_C_FLAGS:STRING=/CMAKE_C_FLAGS:STRING=-DNO_PRINT_CDC_SITES /' CMakeCache.txt
    sed -i 's/^GMX_BINARY_SUFFIX:STRING=_umb_mpi/GMX_BINARY_SUFFIX:STRING=_umb_mpi_tot/' CMakeCache.txt
    make -j 16 
fi

if [ "$MODE" = "INSTALL" ]; then
    cd $gromacs_base/build-mpi
    make install-mdrun
fi

if [ "$MODE" = "TEST" ]; then
    GMX_C=$SRCDIR/${topology_version}-topology/${topology_version}_em/em.gro                    \
    GMX_P=$SRCDIR/${topology_version}-topology/top/${topology_version}.top  \
    GMX_N=$SRCDIR/${topology_version}-topology/${topology_version}.ndx      \
    GROMPP=$BINDIR/grompp${SUFFIX}                              \
        $SRCDIR/test/3eoj_basic_test.sh "mpirun -np 6 $BINDIR/mdrun${SUFFIX}"

    GMX_C=$SRCDIR/${topology_version}-topology/${topology_version}_em/em.gro                    \
    GMX_P=$SRCDIR/${topology_version}-topology/top/${topology_version}.top  \
    GMX_N=$SRCDIR/${topology_version}-topology/${topology_version}.ndx      \
    GROMPP=$BINDIR/grompp${SUFFIX}                              \
        $SRCDIR/test/3eoj_pme_test.sh "$BINDIR/mdrun${SUFFIX}"

fi

