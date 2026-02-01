# QEDMMA v3.1 - FPGA Firmware Package
SUMMARY = "QEDMMA v3.1 FPGA Bitstream and Overlays"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Proprietary;md5=0557f9d92cf58f2ccdd50f62f8ac0b28"

SRC_URI = " \
    file://qedmma_v3.bit \
    file://qedmma_v3.dtbo \
    file://qedmma_v3.xclbin \
    file://qedmma_prbs15.bin \
    file://qedmma_prbs20.bin \
"

S = "${WORKDIR}"

FIRMWARE_DIR = "/lib/firmware/xilinx/qedmma"

do_install() {
    install -d ${D}${FIRMWARE_DIR}
    install -m 0644 ${S}/qedmma_v3.bit ${D}${FIRMWARE_DIR}/
    install -m 0644 ${S}/qedmma_v3.dtbo ${D}${FIRMWARE_DIR}/
    
    # Optional xclbin for Vitis acceleration
    if [ -f ${S}/qedmma_v3.xclbin ]; then
        install -m 0644 ${S}/qedmma_v3.xclbin ${D}${FIRMWARE_DIR}/
    fi
    
    # Mode-specific configurations
    install -m 0644 ${S}/qedmma_prbs15.bin ${D}${FIRMWARE_DIR}/
    install -m 0644 ${S}/qedmma_prbs20.bin ${D}${FIRMWARE_DIR}/
    
    # Create symlink for default mode
    ln -sf qedmma_prbs15.bin ${D}${FIRMWARE_DIR}/qedmma_default.bin
}

FILES:${PN} = "${FIRMWARE_DIR}/*"
INSANE_SKIP:${PN} = "arch"
