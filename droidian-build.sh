#!/bin/bash
set -e
echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99insecure
echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99insecure
echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/99insecure
apt-get update -qq 2>/dev/null || true
apt-get install -y --no-install-recommends \
    linux-packaging-snippets cpio libelf-dev zlib1g-dev dwarves
SNIPPET=/usr/share/linux-packaging-snippets/kernel-snippet.mk
sed -i '/\$(MAKE)/s/CC=$(BUILD_CC)/LLVM=1 LLVM_IAS=1 CC=$(BUILD_CC) HOSTCC=gcc HOSTCXX=g++/g' "$SNIPPET"
releng-build-package
cp ../*.deb /workspace/ 2>/dev/null || true
