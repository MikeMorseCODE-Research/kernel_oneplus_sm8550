## Kernel information file
## This file is used by linux-packaging-snippets to build the kernel .deb packages.

KERNEL_BASE_VERSION = 5.15
KERNEL_VARIANT = android
KERNEL_DEVICE_VENDOR = oneplus
KERNEL_DEVICE_MODEL = salami

KERNEL_ARCH = arm64
KERNEL_BUILD_TARGET = Image

KERNEL_DEFCONFIG = gki_defconfig

# Apply config fragments from the droidian/ directory
KERNEL_CONFIG_USE_FRAGMENTS = 1
KERNEL_CONFIG_USE_DIFFCONFIG = 0

################################################################################
## Boot image
## OnePlus 11 (SM8550) launches with Android 13 — GKI 2.0, boot header v4
## boot.img contains kernel + generic ramdisk; vendor_boot.img is left stock.
KERNEL_BOOTIMAGE_VERSION = 4
KERNEL_BOOTIMAGE_PAGE_SIZE = 4096

# Cmdline from stock OnePlus 11 kernel; confirm against /proc/cmdline on device
KERNEL_BOOTIMAGE_CMDLINE = console=ttyMSM0,115200n8 earlycon qcom_geni_serial.con_enabled=1 \
    androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 \
    lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 service_locator.enable=1 \
    androidboot.usbcontroller=a600000.dwc3 swiotlb=0 loop.max_part=7 \
    cgroup.memory=nokmem,nosocket pcie_ports=compat \
    iptable_raw.raw_before_defrag=1 ip6table_raw.raw_before_defrag=1

KERNEL_BOOTIMAGE_DTB_OVERLAY_SUPPORT = 0

################################################################################
## Flashing
FLASH_ENABLED = 1
FLASH_IS_SLOT_DEVICE = 1
FLASH_KERNEL_PARTITION = boot

# Device IDs recognised by flash-bootimage
FLASH_DEVICE_MANUFACTURER = ONEPLUS
FLASH_DEVICE_MODEL = CPH2449
FLASH_CODENAME = salami

################################################################################
## Toolchain
BUILD_CC = clang
BUILD_LLVM = 1
CROSS_COMPILE = aarch64-linux-gnu-
CROSS_COMPILE_COMPAT = arm-linux-gnueabihf-
BUILD_ARCH = aarch64
BUILD_CROSS = 1

# Build dependencies (installed inside the Droidian build container)
KERNEL_BUILD_DEPENDS = clang llvm lld binutils binutils-aarch64-linux-gnu \
    libssl-dev bc bison flex rsync
