#!/bin/bash
set -e

# ── Local bootstrap ──────────────────────────────────────────────────────────
# When run from outside the Droidian build container, re-exec this script
# inside it via Docker (or Podman) so a local build is identical to CI.
#
#   cd kernel_oneplus_sm8550
#   bash droidian-build.sh                    # auto-uses docker
#   CONTAINER_BIN=podman bash droidian-build.sh
#   IS_CONTAINER=true bash droidian-build.sh  # skip (already inside container)
#
# Output .deb files land in the parent directory (same as CI).
if [ -z "$IS_CONTAINER" ]; then
    CONTAINER_BIN="${CONTAINER_BIN:-docker}"
    if ! command -v "$CONTAINER_BIN" >/dev/null 2>&1; then
        echo "error: $CONTAINER_BIN not found; install Docker or set CONTAINER_BIN=podman" >&2
        exit 1
    fi
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PARENT="$(dirname "$SCRIPT_DIR")"
    CCACHE_VOL="${CCACHE_DIR:-$HOME/.cache/droidian-ccache}"
    mkdir -p "$CCACHE_VOL"
    exec "$CONTAINER_BIN" run --rm --privileged \
        -e IS_CONTAINER=true \
        -e RELENG_HOST_ARCH=arm64 \
        -e GIT_DISCOVERY_ACROSS_FILESYSTEM=1 \
        -e "DEB_BUILD_OPTIONS=parallel=$(nproc)" \
        -e CCACHE_DIR=/ccache \
        -e CCACHE_MAXSIZE=5G \
        -v "$PARENT:$PARENT" \
        -v "$CCACHE_VOL:/ccache" \
        -w "$SCRIPT_DIR" \
        quay.io/droidian/build-essential:bookworm-amd64 \
        bash "$SCRIPT_DIR/droidian-build.sh"
fi
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p /etc/apt/apt.conf.d
echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99insecure
echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99insecure
echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/99insecure
apt-get update -qq 2>/dev/null || true
apt-get install -y --no-install-recommends \
    linux-packaging-snippets cpio libelf-dev zlib1g-dev dwarves git ccache

# Prepend ccache's compiler masquerade directory so every clang/gcc invocation
# goes through ccache transparently without touching BUILD_CC.
export PATH="/usr/lib/ccache:$PATH"

# The bookworm-amd64 container ships the bookworm branch of
# linux-packaging-snippets which only supports boot header v0/v2.
# SM8550 needs header v4 — only the droidian branch handles v3/v4.
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

# Install the real Droidian initramfs (halium init that sets up the Halium
# environment, mounts rootfs, starts Android LXC).  The snippet's
# out/KERNEL_OBJ/initramfs.gz rule copies from this path:
INITRAMFS_DEST=/usr/lib/aarch64-linux-gnu/halium-generic-initramfs

# Widen apt sources from [arch=amd64] to [arch=amd64,arm64] so the arm64
# package lists are actually fetched after dpkg --add-architecture.
sed -i 's/\[arch=amd64\]/[arch=amd64,arm64]/g' \
    /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true
dpkg --add-architecture arm64
apt-get update -qq 2>/dev/null || true

# Try arm64 package → any-arch package → minimal cpio stub (non-zero so
# mkbootimg doesn't reject a zero-length ramdisk).
if apt-get install -y --no-install-recommends linux-initramfs-halium-generic:arm64 2>&1; then
    echo "Installed linux-initramfs-halium-generic:arm64"
elif apt-get install -y --no-install-recommends linux-initramfs-halium-generic 2>&1; then
    echo "Installed linux-initramfs-halium-generic (any-arch)"
    # If the package installed to a non-aarch64-linux-gnu path, symlink it.
    for src in /usr/lib/x86_64-linux-gnu/halium-generic-initramfs \
               /usr/lib/halium-generic-initramfs; do
        if [ -d "$src" ] && [ ! -e "$INITRAMFS_DEST" ]; then
            mkdir -p "$(dirname "$INITRAMFS_DEST")"
            ln -sfn "$src" "$INITRAMFS_DEST"
            echo "Symlinked $src -> $INITRAMFS_DEST"
        fi
    done
else
    echo "WARNING: linux-initramfs-halium-generic not in apt — building minimal cpio stub"
    echo "Boot image will NOT run Droidian until a real initramfs is provided."
    mkdir -p "$INITRAMFS_DEST" /tmp/initrd_build
    printf '#!/bin/sh\nexec /bin/sh\n' > /tmp/initrd_build/init
    chmod +x /tmp/initrd_build/init
    (cd /tmp/initrd_build && find . | cpio -H newc -o \
        | gzip -9 > "$INITRAMFS_DEST/initrd.img-halium-generic")
    cp "$INITRAMFS_DEST/initrd.img-halium-generic" \
       "$INITRAMFS_DEST/recovery-initramfs.img-halium-generic"
fi

releng-build-package

# dpkg-buildpackage drops .deb files one level above the source tree.
# Copy them into the workspace so CI upload-artifact and local users can find them.
find "$(dirname "$PWD")" -maxdepth 1 -name "*.deb" -exec cp -v {} "$PWD/" \; || true

ccache -s
