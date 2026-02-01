# QEDMMA v3.1 - Yocto Production Image Recipe
# Target: Xilinx Zynq UltraScale+ ZU47DR RFSoC
# Author: Dr. Mladen Mešter
# Copyright (c) 2026

SUMMARY = "QEDMMA v3.1 Quantum-Enhanced Radar System Image"
DESCRIPTION = "Production Linux image for QEDMMA anti-stealth radar node"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Proprietary;md5=0557f9d92cf58f2ccdd50f62f8ac0b28"

inherit core-image

# Image features
IMAGE_FEATURES += " \
    debug-tweaks \
    package-management \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    hwcodecs \
"

# Core system packages
IMAGE_INSTALL += " \
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    kernel-modules \
    kernel-devsrc \
"

# FPGA and hardware support
IMAGE_INSTALL += " \
    fpga-manager-script \
    fpga-manager-util \
    xrt \
    zocl \
    libmetal \
    open-amp \
"

# QEDMMA application stack
IMAGE_INSTALL += " \
    qedmma-firmware \
    qedmma-drivers \
    qedmma-control \
    qedmma-calibration \
    qedmma-diagnostics \
    qedmma-webui \
"

# Networking
IMAGE_INSTALL += " \
    openssh \
    openssh-sftp-server \
    iproute2 \
    iptables \
    bridge-utils \
    ethtool \
"

# Precision timing (White Rabbit)
IMAGE_INSTALL += " \
    ntp \
    chrony \
    linuxptp \
    ptp4l \
    phc2sys \
    white-rabbit-tools \
"

# Python stack for control
IMAGE_INSTALL += " \
    python3 \
    python3-numpy \
    python3-scipy \
    python3-yaml \
    python3-flask \
    python3-requests \
    python3-pyserial \
"

# System monitoring
IMAGE_INSTALL += " \
    htop \
    iotop \
    perf \
    strace \
    tcpdump \
    lmsensors \
"

# Hardware tools
IMAGE_INSTALL += " \
    i2c-tools \
    spitools \
    devmem2 \
    usbutils \
    pciutils \
"

# Utilities
IMAGE_INSTALL += " \
    util-linux \
    coreutils \
    bash \
    vim \
    nano \
    less \
    rsync \
    tar \
    gzip \
    curl \
    wget \
"

# Systemd services
IMAGE_INSTALL += " \
    qedmma-systemd-services \
    qedmma-network-config \
"

# Root filesystem configuration
IMAGE_ROOTFS_SIZE = "2097152"
IMAGE_ROOTFS_EXTRA_SPACE = "524288"
IMAGE_OVERHEAD_FACTOR = "1.3"

# Real-time kernel
PREFERRED_PROVIDER_virtual/kernel = "linux-xlnx-rt"

# Enable hardware watchdog
IMAGE_INSTALL += "watchdog"

# Firmware update support
IMAGE_INSTALL += " \
    swupdate \
    swupdate-www \
"
