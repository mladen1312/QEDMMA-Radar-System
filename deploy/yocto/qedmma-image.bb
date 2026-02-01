# QEDMMA v3.1 - Yocto Image Recipe
# Target: Xilinx Zynq UltraScale+ ZU47DR
# Author: Dr. Mladen Mešter
# Copyright (c) 2026

SUMMARY = "QEDMMA v3.1 Quantum-Enhanced Radar System Image"
DESCRIPTION = "Production image for QEDMMA anti-stealth radar node"
LICENSE = "Proprietary"

inherit core-image

IMAGE_FEATURES += " \
    debug-tweaks \
    package-management \
    ssh-server-openssh \
"

IMAGE_INSTALL += " \
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    kernel-modules \
    fpga-manager-script \
    qedmma-firmware \
    qedmma-drivers \
    qedmma-control \
    openssh \
    ntp \
    linuxptp \
    python3 \
    python3-numpy \
    htop \
"

IMAGE_ROOTFS_SIZE = "2097152"
PREFERRED_PROVIDER_virtual/kernel = "linux-xlnx-rt"
