#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

/* Module metadata */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A simple ARM Linux kernel module sample");
MODULE_VERSION("0.1");

static int __init hello_init(void)
{
    printk(KERN_INFO "Hello world from ARM kernel module!\n");
    return 0;
}

static void __exit hello_cleanup(void)
{
    printk(KERN_INFO "Goodbye world, module unloaded.\n");
}

module_init(hello_init);
module_exit(hello_cleanup);
