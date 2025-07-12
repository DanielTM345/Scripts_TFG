
export FI_PROVIDER=tcp
export FI_TCP_IFACE=eth4

export OMPI_MCA_pml=cm
export OMPI_MCA_mtl=ofi

export OMPI_MCA_btl_tcp_if_include=eth4
export OMPI_MCA_oob_tcp_if_include=eth4

export PATH=/home/dtomas/openmpi-ofi/bin:/home/dtomas/libs/bin:$PATH
export LD_LIBRARY_PATH=/home/dtomas/libs/lib:/home/dtomas/openmpi-ofi/lib:$LD_LIBRARY_PATH



