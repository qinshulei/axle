# Functions
findfiles = $(foreach ext, c cpp m mm s, $(shell find $(1) -name '*.$(ext)'))
getobjs = $(foreach ext, c cpp m mm s, $(filter %.o,$(patsubst %.$(ext),%.o,$(1))))

# Toolchain
TOOLCHAIN ?= ./i686-toolchain

AS = $(TOOLCHAIN)/bin/i686-elf-as
LD = $(TOOLCHAIN)/bin/i686-elf-ld
CC = $(TOOLCHAIN)/bin/i686-elf-gcc
ISO_MAKER = $(TOOLCHAIN)/bin/grub-mkrescue
EMU = qemu-system-x86_64

# turn off annoying warnings
CC_WARNING_FLAGS = -Wno-unused-parameter
CFLAGS = -ffreestanding -std=gnu99 -Wall -Wextra -I./src -O2 $(CC_WARNING_FLAGS)
LDFLAGS = -ffreestanding -nostdlib -lgcc -O2

# Directories
SRC_DIR = src
OBJ_DIR = objs
ISO_DIR = isodir

# Files
FILES = $(call findfiles,$(SRC_DIR))
OBJECTS = $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/$(SRC_DIR)/%,$(call getobjs, $(FILES)))
ISO = axle.iso

# Rules
all: axle.iso
	@echo OK

clean:
	@rm -r $(OBJ_DIR) $(ISO_DIR) $(ISO)

run:
	$(EMU) -monitor stdio -cdrom $(ISO)

$(OBJ_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $$(dirname $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $$(dirname $@)
	$(AS) -c $< -o $@

$(ISO_DIR)/boot/axle.bin: $(OBJECTS)
	@mkdir -p $$(dirname $@)
	$(CC) $(LDFLAGS) -T link.ld -o $@ $^

$(ISO_DIR)/boot/grub/grub.cfg: grub.cfg
	@mkdir -p $$(dirname $@)
	cp $< $@

$(ISO): $(ISO_DIR)/boot/axle.bin $(ISO_DIR)/boot/grub/grub.cfg
	$(ISO_MAKER) -d $(TOOLCHAIN)/lib/grub/i386-pc -o $@ $(ISO_DIR)
