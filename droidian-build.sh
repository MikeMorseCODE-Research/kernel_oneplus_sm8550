#!/bin/bash
set -e
echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99insecure
echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99insecure
echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/99insecure
apt-get update -qq 2>/dev/null || true
apt-get install -y --no-install-recommends \
    linux-packaging-snippets cpio libelf-dev zlib1g-dev dwarves git

# The bookworm-amd64 container ships the bookworm branch of
# linux-packaging-snippets which only supports boot header v0/v2.
# SM8550 needs header v4 — only the master branch handles v3/v4.
# Master also has native BUILD_LLVM support, so no sed hacking needed.
git clone --depth 1 -b droidian https://github.com/droidian/linux-packaging-snippets.git /tmp/lps-master
cp -v /tmp/lps-master/*.mk /tmp/lps-master/*.in /tmp/lps-master/*.sh \
    /usr/share/linux-packaging-snippets/ 2>/dev/null || true

# The droidian branch sets HOSTLDFLAG to use lld + compiler-rt builtins,
# but libclang_rt.builtins-x86_64.a is not present in this container.
# Host tools (fixdep etc.) must link with GCC/libgcc instead.
SNIPPET=/usr/share/linux-packaging-snippets/kernel-snippet.mk
sed -i 's|HOSTLDFLAG := "-fuse-ld=lld --rtlib=compiler-rt"|HOSTLDFLAG :=|' "$SNIPPET"

# Neuter BTF in link-vmlinux.sh — pahole may not be available and
# Droidian doesn't need BTF. This makes the check variable unrecognizable
# so both BTF code blocks in the linker script evaluate to false.
sed -i 's/CONFIG_DEBUG_INFO_BTF/DISABLED_BTF_FOR_DROIDIAN/g' "$PWD/scripts/link-vmlinux.sh"

# The snippet's initramfs.gz rule requires halium-generic-initramfs (not installed).
# Stub it out with a zero-byte file. The snippet does a plain `cp` of it to
# out/KERNEL_OBJ/initramfs.gz, so a 0-byte stub produces a 0-byte ramdisk →
# mkbootimg records ramdisk_size=0 in the boot header, which is correct for v4.
DEB_HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
mkdir -p "/usr/lib/${DEB_HOST_MULTIARCH}/halium-generic-initramfs"
touch "/usr/lib/${DEB_HOST_MULTIARCH}/halium-generic-initramfs/initrd.img-halium-generic"

releng-build-package
cp ../*.deb "$PWD/" 2>/dev/null || true
