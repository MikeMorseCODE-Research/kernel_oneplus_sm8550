#!/bin/bash
set -e
echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99insecure
echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99insecure
echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/99insecure
apt-get update -qq 2>/dev/null || true
apt-get install -y --no-install-recommends \
    linux-packaging-snippets cpio libelf-dev zlib1g-dev dwarves
SNIPPET=/usr/share/linux-packaging-snippets/kernel-snippet.mk

# Add LLVM flags to all $(MAKE) invocations
sed -i '/\$(MAKE)/s/CC=$(BUILD_CC)/LLVM=1 LLVM_IAS=1 CC=$(BUILD_CC) HOSTCC=gcc HOSTCXX=g++/g' "$SNIPPET"

# Force BTF off: patch the snippet's defconfig target to sed the .config
# after olddefconfig runs but before compilation starts.
sed -i '/olddefconfig/a\\tsed -i '"'"'s/^CONFIG_DEBUG_INFO_BTF=y/# CONFIG_DEBUG_INFO_BTF is not set/'"'"' out/KERNEL_OBJ/.config && sed -i '"'"'s/^CONFIG_DEBUG_INFO_BTF_MODULES=y/# CONFIG_DEBUG_INFO_BTF_MODULES is not set/'"'"' out/KERNEL_OBJ/.config' "$SNIPPET"

# Nuclear fallback: neuter ALL BTF checks in link-vmlinux.sh so even if
# CONFIG_DEBUG_INFO_BTF leaks through .config, the linker won't call pahole.
sed -i 's/CONFIG_DEBUG_INFO_BTF/DISABLED_BTF_FOR_DROIDIAN/g' /workspace/scripts/link-vmlinux.sh

releng-build-package
cp ../*.deb /workspace/ 2>/dev/null || true
