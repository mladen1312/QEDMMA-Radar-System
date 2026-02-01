# QEDMMA v3.1 - Linux Kernel Drivers
SUMMARY = "QEDMMA v3.1 Kernel Drivers"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=12f884d2ae1ff87c09e5b7ccc2c4ca7e"

inherit module

SRC_URI = " \
    file://qedmma_correlator.c \
    file://qedmma_fusion.c \
    file://qedmma_eccm.c \
    file://qedmma_quantum.c \
    file://qedmma_wrptp.c \
    file://Makefile \
    file://COPYING \
"

S = "${WORKDIR}"

RPROVIDES:${PN} += "kernel-module-qedmma"

do_install:append() {
    install -d ${D}${sysconfdir}/modules-load.d
    echo "qedmma_correlator" > ${D}${sysconfdir}/modules-load.d/qedmma.conf
    echo "qedmma_fusion" >> ${D}${sysconfdir}/modules-load.d/qedmma.conf
    echo "qedmma_eccm" >> ${D}${sysconfdir}/modules-load.d/qedmma.conf
    echo "qedmma_quantum" >> ${D}${sysconfdir}/modules-load.d/qedmma.conf
    echo "qedmma_wrptp" >> ${D}${sysconfdir}/modules-load.d/qedmma.conf
}

FILES:${PN} += "${sysconfdir}/modules-load.d/qedmma.conf"
