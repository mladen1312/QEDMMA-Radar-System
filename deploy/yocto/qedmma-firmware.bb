# QEDMMA Firmware Package
SUMMARY = "QEDMMA v3.1 FPGA Firmware"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Proprietary;md5=0557f9d92cf58f2ccdd50f62f8ac0b28"

SRC_URI = " \
    file://qedmma_v3.bit \
    file://qedmma_v3.dtbo \
    file://qedmma_v3.xclbin \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/lib/firmware/xilinx/qedmma
    install -m 0644 ${S}/qedmma_v3.bit ${D}/lib/firmware/xilinx/qedmma/
    install -m 0644 ${S}/qedmma_v3.dtbo ${D}/lib/firmware/xilinx/qedmma/
    install -m 0644 ${S}/qedmma_v3.xclbin ${D}/lib/firmware/xilinx/qedmma/
}

FILES:${PN} = "/lib/firmware/xilinx/qedmma/*"
