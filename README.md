# Scripts de aprovisionamiento de entorno para Corundum y comunicaciones HPC

Este repositorio contiene los scripts necesarios para automatizar la preparación y configuración de los nodos, así como la instalación de Corundum y el software de comunicaciones.
Orden recomendado de ejecución y funcion de cada script:

### 1. check_if_drivers.sh
Comprueba si el hardware de red está soportado en el kernel que se va a instalar. Si algún driver necesario no está presente, lo instala antes de actualizar el kernel.
Es importante ejecutar este script antes de actualizar el kernel para evitar perder conectividad de red.

### 2. install_kernel_5_15.sh
Actualiza el kernel del sistema a la versión 5.15.x más reciente y compatible.
Se recomienda reiniciar el sistema tras finalizar este paso.

### 3. initial_setup.sh
Instala las herramientas, dependencias y utilidades necesarias para el resto del proceso. Descarga el repositorio de Corundum y ejecuta una batería de pruebas iniciales.

> Nota: Tras esto, la instalación de Vivado debe realizarse manualmente,
>       siguiendo la guía de instalación oficial de la memoria, antes de continuar.

### 4. corundum_setup.sh
Configura y prepara el entorno de Corundum, compila el bitstream y las herramientas asociadas, e integra los servicios necesarios. Finalmente, carga el bitstream en la FPGA mediante PCIe.

### 5. libfabric_install.sh
Descarga, compila e instala la versión estable 1.22 de libfabric, habilitando los providers requeridos para el proyecto y comprobando su correcta instalación.

### 6. openmpi_install.sh
Descarga, compila e instala OpenMPI con soporte para SLURM, vinculado a la instalación de libfabric realizada en el paso anterior. Actualiza las variables de entorno y verifica la funcionalidad básica.

> Recomendación:
> Ejecuta cada script en el orden indicado. Para operaciones críticas (por ejemplo, la carga de bitstream),
> utiliza una terminal robusta (como tmux) para evitar interrupciones.
