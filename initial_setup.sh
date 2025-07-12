#!/usr/bin/env bash
############################################################################
# initial_setup.sh
#
#  ▸ Instala todas las herramientas, librerias y dependencias necesarios 
#    para utilizar corundum con las FPGAs.
#  ▸ Descarga corundum de su repositorio oficial en el home del usuario.
#  ▸ Crea un entorno virtualizado de python con las dependencias necesarias
#    y lanza todas las pruebas de corundum para garantizar su buen 
#    funcionamiento.
#
#  No ejecutar como root (o mediante sudo). Puede pedir la contraseña
#  durante su ejecución.
############################################################################

set -euo pipefail

bold() { printf "\e[1m%s\e[0m\n" "$*"; }

# Verificar privilegios
if (( EUID == 0 )); then
    echo "Este script requiere ejecutarse sin privilegios de superusuario." >&2
    exit 1
fi

bold "[+] Instalando herramientas, librerías y dependencias."
sudo apt update
#instalando herramientas básicas
sudo apt install -y make git mc
#instalando dependencias de corundum
sudo apt install -y iverilog gtkwave python3 python3-venv python3-envs python3-distutils
#instalando dependencias de vivado
sudo apt install -y libncurses5 libstdc++6 lib32z1 lib32ncurses6 lib32stdc++6
#instalando dependencias de petalinux (no se necesita)
#sudo apt install xterm autoconf libtool texinfo zlib1g-dev gcc-multilib libncurses5-dev libncursesw5-dev

bold "[+] Clonando repositorio de corundum."
cd ~

if [[ -d "corundum/.git" ]]; then
    echo "Repositorio ya presente en corundum/. Actualizando repositorio."
    cd corundum/
    git fetch --all --prune
    git reset --hard "origin/master"
else
    echo "Clonando repositorio en corundum/."
    git clone --branch "master" "https://github.com/corundum/corundum.git" "corundum/."
fi

cd ~/corundum/

bold "[+] Creando y configurando entorno virtual de python."
python3 -m venv .corundum-env
source .corundum-env/bin/activate

pip install cocotb
pip install cocotb-bus
pip install cocotb-test
pip install cocotbext-axi
pip install cocotbext-eth
pip install cocotbext-pcie
pip install pytest
pip install scapy
pip install "pytest-xdist[psutil]"
pip install pytest-sugar
pip install pytest-xdist
pip install tox

bold "[+] Ejecutando batería de pruebas."
tox

bold "[+] Finalizado script de configuración inicial. Si todos los test han pasado, se puede proceder a instalar Vivado."
