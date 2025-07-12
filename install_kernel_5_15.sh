#!/usr/bin/env bash
############################################################################
# install_kernel_5_15
#
#  ▸ Instala, o si ya existe, actualiza la rama GA 5.15 en Ubuntu 22.04.
#  ▸ Después llama a «update_ga_kernel_if_needed» (definida aparte) para
#    subir a la última versión del kernel 5.15.x.
#  ▸ Comprueba los drivers de red y deja el nuevo kernel como predeterminado
#
#  Ejecutar como root (o mediante sudo).  Reiniciar cuando el script 
#  finalice con «[OK]».
############################################################################

############################################################################
# update_ga_kernel_if_needed() Actualizar GA 5.15
############################################################################
update_ga_kernel_if_needed() {
    local PKG_IMG="linux-image-generic"
    local PKG_HDR="linux-headers-generic"
    local on_hold=false

    apt update -y

    # Versión instalada y candidata del meta-paquete GA (ambas 5.15.x)
    local installed candidate
    installed=$(apt-cache policy "$PKG_IMG" | awk '/Installed:/ {print $2}')
    candidate=$(apt-cache policy "$PKG_IMG" | awk '/Candidate:/ {print $2}')

    # Extraer número de versión del kernel
    local abi_installed abi_candidate
    abi_installed=$(echo "$installed"  | awk -F'[.-]' '{print $4}')
    abi_candidate=$(echo "$candidate" | awk -F'[.-]' '{print $4}')

    echo "[*] Kernel GA instalado:  $installed  (version del kernel $abi_installed)"
    echo "[*] Kernel GA disponible: $candidate (version del kernel $abi_candidate)"

    # Nada que hacer si ya estamos en la última version del kernel
    if [[ -z "$candidate" || "$candidate" == "(none)" ]] || \
       (( abi_candidate <= abi_installed )); then
        echo "[+] No hay version del kernel 5.15.x más reciente. Continuando."
        return 0
    fi

    echo "[+] Version del kernel más reciente detectada: actualizando."

    # Quitar hold si existe
    if apt-mark showhold | grep -q "^$PKG_IMG"; then
        echo "    → Quitando hold temporal"
        apt-mark unhold "$PKG_IMG" "$PKG_HDR"
        on_hold=true
    fi

    # Instalar nueva versión
    echo "    → Instalando $PKG_IMG / $PKG_HDR más recientes"
    apt -y install --only-upgrade "$PKG_IMG" "$PKG_HDR"

    # Restaurar hold si procedía
    $on_hold && apt-mark hold "$PKG_IMG" "$PKG_HDR"

    # Detectar nombre exacto del nuevo kernel y forzarlo como predeterminado
    local new_ver
    new_ver=$(dpkg -l | awk '/^ii  linux-image-5\.15/ {print $2}' | sort -V | tail -n1)
    echo "    → Kernel nuevo instalado: $new_ver"

    echo "[✓] Kernel GA actualizado a $new_ver."
}

set -euo pipefail

bold() { printf "\e[1m%s\e[0m\n" "$*"; }

# Verificar privilegios
if (( EUID != 0 )); then
    echo "Este script requiere privilegios de superusuario." >&2
    exit 1
fi


# Instalar meta-paquetes GA 5.15 (linux-image/headers-generic)
bold "[+] Instalando/asegurando kernel GA 5.15"
apt update -y
apt install -y --install-recommends \
    linux-image-generic \
    linux-headers-generic

# Mantener la rama fija en 5.15.x
apt-mark hold linux-image-generic linux-headers-generic

# Actualizar a la última versión del kernel 5.15.x si procede
bold "[+] Comprobando si hay nueva versión del kernel 5.15.x más reciente"
update_ga_kernel_if_needed

# Detectar la versión de kernel GA recién instalada
KVER="$(ls -1 /lib/modules | grep -E '^5\.15' | sort -V | tail -n1)"
bold "[+] Kernel GA detectado: $KVER"

# Verificar drivers de red (asume script externo disponible en PATH)
if command -v ./check_if_drivers.sh &>/dev/null; then
    bold "[+] Comprobando módulos de red"
    if ! ./check_if_drivers.sh "$KVER"; then
        echo "[ERROR] Faltan drivers de red para $KVER. Corrige y vuelve a ejecutar.\n No se debe reiniciar con el nuevo kernel o se perderan las funciones de red." >&2
        exit 2
    fi
else
    echo "[WARN] check_if_drivers.sh no encontrado: omitiendo verificación de Interfaces de red. Se recomienda fuertemente ejecutar el diagnostico de interfaces de red para el nuevo kernel, de lo contrario podrían perderse las funciones de red para el anfitrión."
fi

# Regenerar GRUB y fijar el kernel nuevo como predeterminado
bold "[+] Regenerando GRUB"
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
grub-set-default "Advanced options for Ubuntu>Ubuntu, with Linux $KVER"
update-grub
echo "Grub set to: grub-set-default \"Advanced options for Ubuntu>Ubuntu, with Linux $KVER\""
# Fin
bold "[OK] Operación completada. Reinicia el nodo para arrancar con $KVER."
