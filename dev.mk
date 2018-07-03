RELEASE ?= 1

BOARD_TARGET ?= rock64

ifeq (rock64,$(BOARD_TARGET))
UBOOT_DEFCONFIG ?= rock64-rk3328_defconfig
BL31 ?= tmp/rkbin/rk33/rk3328_bl31_v1.39.bin
DDR ?= tmp/rkbin/rk33/rk3328_ddr_786MHz_v1.13.bin
BOARD_CHIP ?= rk3328
ifneq (,$(FLASH_SPI))
LOADER_BIN ?= tmp/rkbin/rk33/rk3328_loader_v1.08.244_for_spi_nor_build_Aug_7_2017.bin
else
LOADER_BIN ?= tmp/rkbin/rk33/rk3328_loader_ddr333_v1.08.244.bin
endif
MINILOADER_BIN ?= tmp/rkbin/rk33/rk3328_miniloader_v2.44.bin
LOADERS = idbloader.img
else ifeq (rockpro64,$(BOARD_TARGET))
UBOOT_DEFCONFIG ?= rockpro64-rk3399_defconfig
BL31 ?= tmp/rkbin/rk33/rk3399_bl31_v1.16.elf
DDR ?= tmp/rkbin/rk33/rk3399_ddr_800MHz_v1.12.bin
BOARD_CHIP ?= rk3399
LOADER_BIN ?= tmp/rkbin/rk33/rk3399_loader_v1.10.112_support_1CS.bin
LOADER_RESTART ?= 1
MINILOADER_BIN ?= tmp/rkbin/rk33/rk3399_miniloader_v1.12.bin
RKSPI ?= 1
LOADERS = idbloader.img idbloader_spl.img
else
$(error Unsupported BOARD_TARGET)
endif

UBOOT_BLOBS = $(addprefix u-boot-,$(addsuffix -$(BOARD_TARGET).img.xz,$(basename $(notdir $(wildcard dev-ayufan/blobs/*.cmd)))))

.PHONY: all
all: u-boot-package

info:
	echo $(UBOOT_BLOBS)

ifneq (,$(LOADER_BIN))
include dev.loader.rk.mk
endif

UBOOT_MAKE ?= make \
	BL31=$(realpath $(BL31)) \
	CROSS_COMPILE="ccache aarch64-linux-gnu-"

$(BL31) $(DDR) $(LOADER_BIN):
	mkdir -p $$(dirname "$@")
	curl --fail -L https://github.com/ayufan-rock64/rkbin/raw/master/$(subst tmp/rkbin/,,$@) > $@.tmp
	mv $@.tmp $@

.config: configs/$(UBOOT_DEFCONFIG)
	$(UBOOT_MAKE) $(UBOOT_DEFCONFIG)

u-boot.itb: .config $(BL31)
	$(UBOOT_MAKE) -j $$(nproc)
	$(UBOOT_MAKE) -j $$(nproc) u-boot.itb

idbloader.img: u-boot.itb $(DDR)
ifneq (,$(USE_UBOOT_SPL))
	tools/mkimage -n $(BOARD_CHIP) -T rksd -d spl/u-boot-spl.bin $@.tmp
else ifneq (,$(USE_UBOOT_TPL))
	tools/mkimage -n $(BOARD_CHIP) -T rksd -d tpl/u-boot-tpl.bin $@.tmp
	cat spl/u-boot-spl.bin >> $@.tmp
else ifneq (,$(DDR))
	tools/mkimage -n $(BOARD_CHIP) -T rksd -d $(DDR) $@.tmp
	cat spl/u-boot-spl.bin >> $@.tmp
else
	@echo "Invalid $(BOARD_TARGET)"
	@exit 1
endif
	dd if=u-boot.itb of=$@.tmp seek=$$((0x200-64)) conv=notrunc
	mv $@.tmp $@

idbloader_spl.img: u-boot.itb $(DDR)
ifneq (,$(USE_UBOOT_SPL))
	tools/mkimage -n $(BOARD_CHIP) -T rkspi -d spl/u-boot-spl.bin $@.tmp
else ifneq (,$(USE_UBOOT_TPL))
	tools/mkimage -n $(BOARD_CHIP) -T rkspi -d tpl/u-boot-tpl.bin $@.tmp
	cat spl/u-boot-spl.bin >> $@.tmp
else ifneq (,$(DDR))
	tools/mkimage -n $(BOARD_CHIP) -T rkspi -d $(DDR) $@.tmp
	cat spl/u-boot-spl.bin >> $@.tmp
else
	@echo "Invalid $(BOARD_TARGET)"
	@exit 1
endif
	dd if=u-boot.itb of=$@.tmp seek=$$((0x200-64)) conv=notrunc
	mv $@.tmp $@

.PHONY: u-boot-menuconfig		# edit u-boot config and save as defconfig
u-boot-menuconfig:
	$(UBOOT_MAKE) ARCH=arm64 $(UBOOT_DEFCONFIG)
	$(UBOOT_MAKE) ARCH=arm64 menuconfig
	$(UBOOT_MAKE) ARCH=arm64 savedefconfig
	mv $(UBOOT_OUTPUT_DIR)/defconfig $(UBOOT_DIR)/configs/$(UBOOT_DEFCONFIG)

.PHONY: u-boot-build		# compile u-boot
u-boot-build:
	rm -f $(LOADERS)
	make $(LOADERS)

.PHONY: u-boot-clear
u-boot-clear:
	rm -rf $(LOADERS)

out/u-boot/%/boot.scr: dev-ayufan/blobs/%.cmd
	mkdir -p $$(dirname $@)
	mkimage -C none -A arm -T script -d $< $@

out/u-boot/%/boot-$(BOARD_TARGET).img: out/u-boot/%/boot.scr
	dd if=/dev/zero of=$@.tmp bs=1M count=32
	mkfs.vfat -n "u-boot-script" $@.tmp
	mcopy -sm -i $@.tmp $< ::
	mcopy -sm -i $@.tmp $(LOADERS) ::
	mv $@.tmp $@

u-boot-%-$(BOARD_TARGET).img: out/u-boot/%/boot-$(BOARD_TARGET).img $(LOADERS)
	dd if=/dev/zero of=$@.tmp bs=1M count=128
	parted -s $@.tmp mklabel gpt
	parted -s $@.tmp unit s mkpart bootloader 64 8127
	parted -s $@.tmp unit s mkpart boot fat16 8192 100%
	parted -s $@.tmp set 2 legacy_boot on
	dd if=$(word 2,$^) of=$@.tmp conv=notrunc seek=64
	dd if=$(word 1,$^) of=$@.tmp conv=notrunc seek=8192
	mv "$@.tmp" $@

%.img.xz: %.img
	xz $<

$(UBOOT_PACKAGE): $(LOADERS)
	fpm -s dir -t deb -n u-boot-$(BOARD_TARGET) -v $(RELEASE_NAME) \
		-p $@ \
		--deb-priority optional --category admin \
		--force \
		--depends debsums \
		--depends mtd-utils \
		--deb-compression bzip2 \
		--deb-field "Multi-Arch: foreign" \
		--after-install dev-ayufan/scripts/postinst.deb \
		--before-remove dev-ayufan/scripts/prerm.deb \
		--url https://gitlab.com/ayufan-rock64/linux-build \
		--description "Rock64 U-boot package" \
		-m "Kamil Trzciński <ayufan@ayufan.eu>" \
		--license "MIT" \
		--vendor "Kamil Trzciński" \
		-a all \
		dev-ayufan/root/=/ \
		$(patsubst %,%=/usr/lib/u-boot-$(BOARD_TARGET)/%,$<)

.PHONY: u-boot-package
u-boot-package: $(UBOOT_PACKAGE) $(UBOOT_BLOBS)

.PHONY: u-boot-flash-spi-$(BOARD_TARGET)
u-boot-flash-spi-$(BOARD_TARGET): u-boot-flash-spi-$(BOARD_TARGET).img.xz

.PHONY: u-boot-erase-spi-$(BOARD_TARGET)
u-boot-erase-spi-$(BOARD_TARGET): u-boot-erase-spi-$(BOARD_TARGET).img.xz
