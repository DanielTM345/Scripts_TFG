#!/usr/bin/env bash
############################################################################
# check_nic_drivers.sh
# Verifica que todas las tarjetas de red dispongan de driver en el kernel 
# 5.15 más reciente instalado en el sistema (Ubuntu 22.04).
# Se recomienda ejecutar antes de reiniciar y cambiar de kernel.
############################################################################

set -euo pipefail

# 1. Seleccionar kernel destino
#    Si se pasa un argumento se usa; si no, se autodetecta el más nuevo 5.15.*
if [[ -n "${1:-}" ]]; then
    KVER="$1"
else
    KVER="$(ls -1 /lib/modules | grep -E '^5\.15' | sort -V | tail -n1 || true)"
    if [[ -z "$KVER" ]]; then
        echo "[ERROR] No se encontró ningún kernel 5.15 instalado." >&2
        echo "        Ejecuta primero deploy_kernel_5_15.sh e instala linux-image-generic." >&2
        exit 1
    fi
fi

echo "== Usando kernel objetivo: $KVER =="

# Inventario de dispositivos de red
echo -e "\n== Inventario de interfaces de red =="
mapfile -t DEVS < <(lspci -Dnn | grep -Ei 'ethernet|network' | awk '{print $1}')

faltan=false
for dev in "${DEVS[@]}"; do
    info=$(lspci -s "$dev" -nn)
    id=$(echo "$info" | grep -oP '\[\K[0-9a-f]{4}:[0-9a-f]{4}(?=\])')
    driver=$(lspci -k -s "$dev" | awk '/Kernel driver in use/{print $NF}')

    printf "\nDispositivo %s  ID %s  ->  driver %s\n" "$dev" "$id" "$driver"

    if modinfo -k "$KVER" "$driver" &>/dev/null; then
        echo "   ✔ Módulo presente en $KVER"
    else
        echo "   ✖ Módulo AUSENTE en $KVER"
        faltan=true
    fi
done

# Final y feedback
if $faltan; then
    cat <<EOF

[!] Algún driver falta en el kernel destino.
    • Instala linux-modules-extra-"$KVER" y/o linux-firmware
    • O bien compila/instala el paquete DKMS del fabricante.
    Vuelve a lanzar este script hasta que todos los módulos figuren como presentes.
EOF
    exit 2
else
    echo -e "\nTodo listo; puedes reiniciar con seguridad."
fi
    exit 0
