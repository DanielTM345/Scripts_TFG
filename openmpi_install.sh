#!/usr/bin/env bash
###############################################################################
# openmpi-install.sh
#
#  ▸ Configura e instala OpenMPI para usarse con libfabric
#
#  No ejecutar como root (o mediante sudo). Puede pedir la contraseña durante
#  su ejecución.
###############################################################################

set -euo pipefail

bold() { printf "\e[1m%s\e[0m\n" "$*"; }

bold "[+] Descargando OpenMPI."
cd ~
wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.8.tar.gz
tar -xzf openmpi-5.0.8.tar.gz
rm openmpi-5.0.8.tar.gz
cd openmpi-5.0.8

rm -rfd /home/dtomas/openmpi-ofi

export LIBFABRIC_ROOT=/home/dtomas/libs
export PKG_CONFIG_PATH=/home/dtomas/libs/lib/pkgconfig:${PKG_CONFIG_PATH:-}
export PATH="$LIBFABRIC_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$LIBFABRIC_ROOT/lib:${LD_LIBRARY_PATH:-}"
export CPPFLAGS="-I$LIBFABRIC_ROOT/include"
export LDFLAGS="-L$LIBFABRIC_ROOT/lib"


bold "[+] Configurando OpenMPI."
make clean
make distclean

./configure --prefix=/home/dtomas/openmpi-ofi \
    --with-libfabric=$LIBFABRIC_ROOT \
	--with-slurm \
	--enable-mpi1-compatibility \
	--enable-mca-dso  | tee configure.log
#    --enable-mpirun-prefix-by-default \
#    CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"  

bold "[+] Compilando OpenMPI."
make -j$(nproc) | tee make.log

bold "[+] Instalando OpenMPI."
make install | tee install.log

bold "[OK] OpenMPI instalado en /home/dtomas/openmpi-ofi"



