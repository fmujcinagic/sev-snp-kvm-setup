// This kernel module serves as an example of how to implement a guest probe in a Linux environment.
// to test this module, you can write '1' to the /proc/sensitive_trigger file, which will trigger a sensitive timeframe for 1 minute.
// dont forget to load the module using insmod and unload it using rmmod after testing.
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/delay.h>
#include <asm/io.h>

#define PROCS_FILE "sensitive_trigger"

static ssize_t proc_write(struct file *file, const char __user *buffer, size_t count, loff_t *pos) {
    char cmd;
    if (copy_from_user(&cmd, buffer, 1)) return -EFAULT;
    if (cmd == '1') {
        printk(KERN_INFO "Guest: Entering sensitive timeframe for 1 minute...\n");
        outb(0x1, 0x99);
        mdelay(10000); // blocking all interrupts for 10 seconds 
        printk(KERN_INFO "Guest: Exiting sensitive timeframe.\n");
        outb(0x0, 0x99);
    }
    return count;
}

static const struct proc_ops proc_fops = {
    .proc_write = proc_write,
};

static int __init guest_probe_init(void) {
    proc_create(PROCS_FILE, 0666, NULL, &proc_fops);
    printk(KERN_INFO "Guest: Module loaded. Write '1' to /proc/%s to start 1min sensitive mode.\n", PROCS_FILE);
    return 0;
}

static void __exit guest_probe_exit(void) {
    remove_proc_entry(PROCS_FILE, NULL);
}

module_init(guest_probe_init);
module_exit(guest_probe_exit);
MODULE_LICENSE("GPL");
