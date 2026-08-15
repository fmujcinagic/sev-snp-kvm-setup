#!/bin/bash
set -e

KERNEL_VER=$(uname -r)
WORKSPACE="$HOME/kvm-dev-env"

echo "[*] 1. Installing dependencies..."
sudo apt update
sudo apt install -y dpkg-dev build-essential linux-headers-$KERNEL_VER

echo "[*] 2. Preparing workspace at $WORKSPACE..."
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
    
echo "[*] 3. Downloading exact Ubuntu kernel source..."
# unsigned first (common for HWE), fallback to standard if it fails
apt source linux-image-unsigned-$KERNEL_VER || apt source linux-image-$KERNEL_VER

# findthe newly downloaded folder (usually starts with "linux-")
LINUX_DIR=$(find . -maxdepth 1 -type d -name "linux-*" | head -n 1)
if [ -z "$LINUX_DIR" ]; then
    echo "[-] Error: Failed to find downloaded source directory."
    exit 1
fi

echo "[*] 4. Bypassing GCC macro bug (Renaming directory)..."
# If the directory name contains "linux", GCC's preprocessor replaces it with "1" inside unquoted macros. We rename it to safely remove the word "linux".
SAFE_DIR="kvm-src-$KERNEL_VER"
mv "$LINUX_DIR" "$SAFE_DIR"
cd "$SAFE_DIR"
ABS_PATH=$(pwd)

echo "[*] 5. Patching KVM Trace Paths to absolute paths..."
# trace.h
sed -i "s|^#define TRACE_INCLUDE_PATH.*|#define TRACE_INCLUDE_PATH $ABS_PATH/arch/x86/kvm|" arch/x86/kvm/trace.h
# mmutrace.h (has a different path)
sed -i "s|^#define TRACE_INCLUDE_PATH.*|#define TRACE_INCLUDE_PATH $ABS_PATH/arch/x86/kvm/mmu|" arch/x86/kvm/mmu/mmutrace.h

echo "[*] 6. Patching Makefile for local includes..."
sed -i '/ccflags-y += -I/d' arch/x86/kvm/Makefile
echo "ccflags-y += -I$ABS_PATH/arch/x86/kvm" >> arch/x86/kvm/Makefile

echo "[*] 7. Running initial verification build..."
make -C /lib/modules/$KERNEL_VER/build M=$ABS_PATH/arch/x86/kvm modules

echo "[+] Setup Complete!"
echo "[+] Your source tree is ready at: $ABS_PATH"
