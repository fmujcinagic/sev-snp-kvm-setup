sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
# create the module as the .c file (e.g. guest_probe.c)

# create the Makefile (in the same folder)
# example:
```bash
obj-m += guest_probe.o

all:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```
# we dont need the newly cloned kernel, just check for the following: ls /lib/modules/$(shell uname -r)/build -> should succeed

make
sudo insmod guest_probe.ko
