#!/usr/bin/env bash
############################################################################
# corundum_setup.sh
#
# Prepara un nodo Ubuntu 22.04 para trabajar con Corundum sobre tarjetas
# Xilinx Varium C1100 (o Alveo AU55N):
#   1) Compila la bitstream FPGA (MQNIC 100 G).
#   2) Compila el módulo de núcleo `mqnic` y las utilidades de usuario.
#   3) Recarga el bitstream en la FPGA por PCIe
#   5) Carga el módulo `mqnic` en el kernel.
#
# Requisitos:
#   • Vivado 2025.1 instalado bajo $HOME/Xilinx/2025.1
#   • Repositorio Corundum clonado en $HOME/corundum
#
#  No ejecutar como root (o mediante sudo). Puede pedir la contraseña de
#  sudo durante su ejecución.
############################################################################

set -euo pipefail

bold() { printf "\e[1m%s\e[0m\n" "$*"; }
die()  { printf "\e[1;31m[ERROR]\e[0m %s\n" "$*" >&2; } #exit 1; }

CORUNDUM_DIR="${CORUNDUM_DIR:-$HOME/corundum}"
FPGA_DIR="$CORUNDUM_DIR/fpga/mqnic/Alveo/fpga_100g/fpga_AU55N"
MODULE_DIR="$CORUNDUM_DIR/modules/mqnic"
UTILS_DIR="$CORUNDUM_DIR/utils"
SCRIPTS_DIR="$CORUNDUM_DIR/scripts"
VIVADO_BASE="${VIVADO_BASE:-$HOME/Xilinx/2025.1}"
VIVADO_SETTINGS="$VIVADO_BASE/Vivado/settings64.sh"
CABLE_DRIVER="$VIVADO_BASE/Vivado/data/xicom/cable_drivers/lin64/install_script/install_drivers/install_drivers"

[[ -d "$CORUNDUM_DIR" ]]      || die "Directorio $CORUNDUM_DIR no encontrado"
[[ -f "$VIVADO_SETTINGS" ]]   || die "Vivado no hallado en $VIVADO_SETTINGS"


#Compilar configuración de FPGA
bold "[+] Compilando bitstream FPGA (puede tardar)"
cd $FPGA_DIR
source $VIVADO_SETTINGS
make

#Compilar nucleo
bold "[+] Compilando módulo kernel mqniq"
cd $MODULE_DIR
source $VIVADO_SETTINGS
make -C /lib/modules/$(uname -r)/build M=$PWD modules
sudo make -C /lib/modules/$(uname -r)/build M=$PWD modules_install
sudo depmod -a
make

#Compilamos las herramientas del espacio de trabajo
bold "[+] Compilando utilidades de usuario"
cd "$UTILS_DIR"
source "$VIVADO_SETTINGS"
make

#Instalar drivers para usar el puerto jtag. (Debe estar ceonctada la tarjeta y debe reconectarse tras instalarlos.)
#if ! lsusb | grep -qi "Xilinx"; then
#    bold "[+] Instalando drivers USB/JTAG"
#    sudo "$CABLE_DRIVER"
#    sudo udevadm control --reload
#else
#    bold "[+] Drivers JTAG ya presentes; omitiendo instalación"
#fi

#Encendemos el hw_server y comprobamos que vivado ve el hardware por el puerto jtag
#if ! pgrep -x hw_server &>/dev/null; then
#    bold "[+] Iniciando hw_server en segundo plano"
#    ( source "$VIVADO_SETTINGS" && hw_server &>/dev/null & disown )
#    sleep 3
#else
#    bold "[+] hw_server ya se está ejecutando"
#fi
#bold "[+] Verificando detección de hardware con Vivado"
#vivado -mode tcl -nolog -nojournal -notrace <<'EOF'
#open_hw_manager
#connect_hw_server
#puts "TARGETS: [get_hw_targets *]"
#exit
#EOF

#Recargamos corundum en la tarjeta via pcie
bold "[+] Recargando bitstream Corundum a través de PCIe"

# Detectar la primera tarjeta Xilinx/Corundum en el bus
PCI_ADDR=$(lspci -Dn | grep -Ei 'Xilinx|Alveo|1234:1001' | head -n1 | awk '{print $1}')

if [[ -z "$PCI_ADDR" ]]; then
    bold "[WARN] No se detectó ninguna tarjeta Corundum en PCIe; omitiendo recarga"
else
    sudo $UTILS_DIR/mqnic-fw -d "$PCI_ADDR" -w $FPGA_DIR/fpga.bit
    sleep 8          # dar tiempo a que el dispositivo se reinicialice
    bold "[+] FPGA reiniciada correctamente en $PCI_ADDR"
fi

#Cargamos el núcleo preferentemente con modprobe
bold "[+] Cargando módulo mqnic en el kernel"
if ! lsmod | grep -q "^mqnic"; then
    sudo modprobe mqnic || sudo insmod "$MODULE_DIR/mqnic.ko"
else
    bold "[+] mqnic ya estaba cargado"
fi

#Fin
bold "[OK] Entorno Corundum listo."
