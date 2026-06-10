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
## OnePlus 11 (SM8550) — Android 13 GKI 2.0, boot header version 4.
##
## Android 13 uses a 3-way split:
##   boot.img      = kernel Image only, NO ramdisk (ramdisk_size = 0)
##   init_boot.img = generic ramdisk (Droidian will provide its own here)
##   vendor_boot.img = vendor ramdisk + DTBs + vendor cmdline (left stock)
##
## Confirmed from AlphaDroid stock boot.img header:
##   header_version = 4, header_size = 1584, ramdisk_size = 0, cmdline = ""
KERNEL_BOOTIMAGE_VERSION = 4
KERNEL_BOOTIMAGE_PAGE_SIZE = 4096

# Standard GKI 2.0 / SM8550 boot image offsets
KERNEL_BOOTIMAGE_BASE = 0x00000000
KERNEL_BOOTIMAGE_KERNEL_OFFSET = 0x00008000
KERNEL_BOOTIMAGE_RAMDISK_OFFSET = 0x01000000
KERNEL_BOOTIMAGE_SECOND_OFFSET = 0x00000000
KERNEL_BOOTIMAGE_TAGS_OFFSET = 0x00000100

# cmdline is empty in boot.img v4; vendor cmdline lives in vendor_boot.img
KERNEL_BOOTIMAGE_CMDLINE =

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
# BUILD_TRIPLET is what kernel-snippet.mk uses to compute CROSS_COMPILE=$(BUILD_TRIPLET)-
# BUILD_CLANG_TRIPLET is passed as CLANG_TRIPLE= to make
BUILD_TRIPLET = aarch64-linux-gnu-
BUILD_CLANG_TRIPLET = aarch64-linux-gnu
CROSS_COMPILE = aarch64-linux-gnu-
CROSS_COMPILE_COMPAT = arm-linux-gnueabihf-
BUILD_ARCH = aarch64
BUILD_CROSS = 1

# Build dependencies (installed inside the Droidian build container)
KERNEL_BUILD_DEPENDS = clang llvm lld binutils binutils-aarch64-linux-gnu \
    libssl-dev bc bison flex rsync
