#!/bin/bash
set -e

echo "[*] Compiling KVM modules out-of-tree..."
make -C /lib/modules/$(uname -r)/build M=$(pwd)/arch/x86/kvm modules

echo "[*] Unloading existing modules..."
# || true ensures the script doesn't stop if the modules are already unloaded
sudo rmmod kvm_amd kvm || true

echo "[*] Loading modified modules..."
sudo insmod arch/x86/kvm/kvm.ko
sudo insmod arch/x86/kvm/kvm-amd.ko

printf "\n\n[+] Success! Custom KVM modules are live.\n\n"
sudo dmesg | tail -n 20
