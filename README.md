# KVM Out-of-Tree Development Toolkit - Guide for AMD SEV-SNP Modifications

Guide/scripts to instantly set up a working out-of-tree development environment for KVM (specifically targeting AMD SEV-SNP modifications on Ubuntu).

> **_NOTE:_**  for easier starting of CVMs, pleaase refer to the following repo: [sev-step](https://github.com/sev-step/sev-step)


## The Pitfalls (Why this script exists)

If you try to simply run `make M=arch/x86/kvm` on a downloaded kernel source, you will hit four major roadblocks. This toolkit automatically resolves all of them:

1. **The GCC `linux` Macro Bug:** 
   example: GCC has a legacy built-in macro that expands the unquoted word `linux` to `1`. If your downloaded kernel folder is named `linux-hwe-7.0`, the C preprocessor will silently mangle your trace paths into `1-hwe-7.0`, causing fatal "No such file" errors. *Fix: The script automatically renames the source folder to `kvm-src-*`.*
2. **Hardcoded Trace Paths:** 
   KVM's `trace.h` and `mmu/mmutrace.h` use relative paths (`../../arch/x86/kvm`). When compiled out-of-tree using the system headers (`-C /lib/modules/...`), the compiler looks inside `/usr/src/...` instead of your local directory. *Fix: The script dynamically injects your absolute paths.*
3. **Missing Subdirectory Includes:** 
   Files inside `arch/x86/kvm/mmu/` and `svm/` rely on headers in `arch/x86/kvm/`. Out-of-tree builds fail to link these properly. *Fix: The script appends `ccflags-y += -I$(pwd)/arch/x86/kvm` to the KVM Makefile.*
4. **Vermagic / Version Mismatches:** 
   Compiling a vanilla mainline kernel will result in module rejection (`Invalid parameters`) if you are running an Ubuntu-patched kernel. *Fix: The script directly targets `apt source` to perfectly match your running system's specific patches.*

## Usage - Part 1: Hypervisor

Boot into the kernel you want to develop on, clone this repository, and run the setup script:

\`\`\`bash
chmod +x hypervisor-setup/setup-kvm-dev.sh
./setup-kvm-dev.sh
\`\`\`
This will download the exact kernel source matching your `uname -r`, apply all path fixes, and verify the build. 

Once setup is complete, navigate to your new source tree (e.g., `~/kvm-dev-env/kvm-src-7.0.0-28-generic`). 

Make your modifications to `arch/x86/kvm/svm/svm.c`, `svm.h`, etc., and use the rebuild script to instantly compile and insert your changes into the running kernel:

\`\`\`bash
chmod +x hypervisor-setup/rebuild.sh
./hypervisor-setup/rebuild.sh
\`\`\`

## Part 2: Guest (CVM)
```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
```
- create the module as the .c file (e.g. guest_probe.c)
- create the Makefile (in the same folder)
- example:

```bash
obj-m += guest_probe.o

all:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```
- we dont need the newly cloned kernel, just check for the following: ls /lib/modules/$(shell uname -r)/build -> should succeed
```bash
make
sudo insmod guest_probe.ko
```

## Part 3: Testing/debugging

- On the Host, watch the kernel logs: `sudo dmesg -w`
- Inside the Guest, trigger the signal (example: `echo "1" | sudo tee /proc/sensitive_trigger`)
- Watch the host logs.


If you are using the SEV-Step ([https://github.com/sev-step/sev-step](https://github.com/sev-step/sev-step)) `launch-qemu-new.sh` script, it mangles standard `-monitor` flags. To get a working TCP monitor on port 55555, edit the script directly and add this line to the QEMU command:

```bash
-monitor tcp:127.0.0.1:55555,server,nowait
```

Once the VM is running, you can monitor from the separate host terminal:

```bash
# Connect to the monitor
nc 127.0.0.1 55555
```
