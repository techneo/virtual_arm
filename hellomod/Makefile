# Specify the name of the kernel module
obj-m += hello_arm.o

# Define the architecture and cross-compiler prefix
ARCH := arm
CROSS_COMPILE := arm-linux-gnueabi- # Example prefix for ARM 32-bit (adjust as needed)

# Path to the compiled kernel source tree (headers and build system)
KDIR := /build/workspace/linux-6.6

# Default build target
all:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KDIR) M=$(PWD) modules

# Clean target
clean:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KDIR) M=$(PWD) clean
