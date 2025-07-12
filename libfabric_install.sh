#!/usr/bin/env bash
############################################################################
# libfabric_install.sh
#
#  ▸ Instala todas las dependencias y librerias para libfabric, lo configura 
#    y lo instala en la carpeta de usuario.
#  ▸ Descarga y configura libfabric en ~/libs/libfabric.
#  ▸ Instala libfabric en ~/libs/.
#  ▸ Valida la instalación de libfabric.
#
#  No ejecutar como root (o mediante sudo). Puede pedir la contraseña
#  durante su ejecución.
############################################################################

set -euo pipefail

bold() { printf "\e[1m%s\e[0m\n" "$*"; }

bold "[+] Instalando librerías y dependencias."
sudo apt update
sudo apt install -y autoconf automake libtool librdmacm-dev libibverbs-dev libucx-dev

bold "[+] Clonando repositorio de corundum."
cd  ~
mkdir -p libs
cd ~/libs

if [[ -d "libfabric/.git" ]]; then
    echo "Repositorio ya presente en libfabric/. Actualizando repositorio."
    cd ~/libs/libfabric/
    git fetch --all --prune
    git reset --hard "origin/main"
else
    echo "Clonando repositorio en libfabric/."
    git clone --branch "main" "https://github.com/ofiwg/libfabric.git" "libfabric/"
fi

cd ~/libs/libfabric

bold "[+] Configurando libfabric."
./autogen.sh
./configure --prefix=$HOME/libs/ --enable-debug=yes --enable-profile=yes --enable-verbs=yes --enable-udp=yes --enable-tcp=yes --enable-ucx=yes --enable-sockets=dl

bold "[+] Instalando libfabric."
make -j 32
make install

bold "[+] Verificando instalación y providers."
~/libs/bin/fi_info

bold "[OK] Lifabric instalado en ~/libs/"
