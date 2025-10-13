TARGET = helloworld
LOADER_TARGET = secure_loader
SRC_DIR = src
OBJ_DIR = obj
INCLUDE_DIR = $(SRC_DIR)/uefi_headers
KEYS_DIR = keys

SRCS = $(SRC_DIR)/$(TARGET).c
LOADER_SRCS = $(SRC_DIR)/$(LOADER_TARGET).c
OBJS = $(OBJ_DIR)/$(TARGET).o
LOADER_OBJS = $(OBJ_DIR)/$(LOADER_TARGET).o

# Use system tools
CC = gcc
LD = ld
OBJCOPY = objcopy
OPENSSL = openssl

# Compiler flags for Ubuntu x86_64
CFLAGS = -I$(INCLUDE_DIR) \
         -I$(INCLUDE_DIR)/Protocol \
         -I$(INCLUDE_DIR)/Guid \
         -I$(INCLUDE_DIR)/Library \
         -DEFIAPI=__attribute__\(\(ms_abi\)\) \
         -fno-stack-protector \
         -fno-stack-check \
         -fshort-wchar \
         -mno-red-zone \
         -maccumulate-outgoing-args \
         -m64 \
         -fpic \
         -fno-builtin \
         -ffreestanding \
         -Wall \
         -O2

# Linker flags - Ubuntu uses GNU ld
LDFLAGS = -nostdlib \
          -znocombreloc \
          -T gcc_efi.lds \
          -shared \
          -Bsymbolic \
          -m elf_x86_64

# Use /bin/bash explicitly for shell commands
SHELL = /bin/bash

.PHONY: all
all: setup_dirs $(TARGET).efi $(LOADER_TARGET).efi
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "✓ Build complete!"
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "Generated files:"
	@ls -lh $(TARGET).efi $(LOADER_TARGET).efi 2>/dev/null || true
	@echo ""

.PHONY: setup_dirs
setup_dirs:
	@mkdir -p $(OBJ_DIR) $(KEYS_DIR) remote_logs

$(TARGET).efi: $(OBJ_DIR)/$(TARGET).so
	@echo "Creating EFI application: $@"
	$(OBJCOPY) -j .text \
	           -j .sdata \
	           -j .data \
	           -j .dynamic \
	           -j .dynsym \
	           -j .rel \
	           -j .rela \
	           -j .reloc \
	           --target=efi-app-x86-64 \
	           --subsystem=10 \
	           $< $@
	@echo "✓ $@ created"

$(LOADER_TARGET).efi: $(OBJ_DIR)/$(LOADER_TARGET).so
	@echo "Creating EFI application: $@"
	$(OBJCOPY) -j .text \
	           -j .sdata \
	           -j .data \
	           -j .dynamic \
	           -j .dynsym \
	           -j .rel \
	           -j .rela \
	           -j .reloc \
	           --target=efi-app-x86-64 \
	           --subsystem=10 \
	           $< $@
	@echo "✓ $@ created"

$(OBJ_DIR)/$(TARGET).so: $(OBJS)
	@echo "Linking: $@"
	$(LD) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/$(LOADER_TARGET).so: $(LOADER_OBJS)
	@echo "Linking: $@"
	$(LD) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "Compiling: $<"
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: sign
sign: $(TARGET).efi
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "Signing $(TARGET).efi"
	@echo "════════════════════════════════════════════════════════════════════"
	@if [ ! -f "$(KEYS_DIR)/private_key.pem" ]; then \
		echo "Generating RSA keys..."; \
		$(OPENSSL) genrsa -out $(KEYS_DIR)/private_key.pem 2048 2>/dev/null; \
		$(OPENSSL) rsa -in $(KEYS_DIR)/private_key.pem -pubout -out $(KEYS_DIR)/public_key.pem 2>/dev/null; \
		$(OPENSSL) rsa -in $(KEYS_DIR)/private_key.pem -pubout -outform DER -out $(KEYS_DIR)/public_key.der 2>/dev/null; \
		chmod 600 $(KEYS_DIR)/private_key.pem; \
		chmod 644 $(KEYS_DIR)/public_key.pem $(KEYS_DIR)/public_key.der; \
		echo "✓ Keys generated"; \
	fi
	@echo "Signing application..."
	$(OPENSSL) dgst -sha256 -sign $(KEYS_DIR)/private_key.pem -out $(TARGET).sig $(TARGET).efi
	@echo "✓ Signed: $(TARGET).sig"
	@echo ""

.PHONY: verify
verify: $(TARGET).efi $(TARGET).sig
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "Verifying signature"
	@echo "════════════════════════════════════════════════════════════════════"
	@if [ ! -f "$(KEYS_DIR)/public_key.pem" ]; then \
		echo "✗ Public key not found!"; \
		exit 1; \
	fi
	@if $(OPENSSL) dgst -sha256 -verify $(KEYS_DIR)/public_key.pem -signature $(TARGET).sig $(TARGET).efi >/dev/null 2>&1; then \
		echo "✓ Signature VERIFIED"; \
	else \
		echo "✗ Verification FAILED"; \
		exit 1; \
	fi
	@echo ""

.PHONY: test-build
test-build:
	@echo "Testing build environment..."
	@which gcc || echo "ERROR: gcc not found"
	@which ld || echo "ERROR: ld not found"
	@which objcopy || echo "ERROR: objcopy (binutils) not found"
	@which openssl || echo "ERROR: openssl not found"
	@gcc --version | head -n1
	@ld --version | head -n1
	@echo "✓ Build tools check complete"

.PHONY: clean
clean:
	@echo "Cleaning..."
	@rm -rf $(OBJ_DIR) *.efi *.so *.sig disk.img startup.nsh
	@echo "✓ Clean complete"

.PHONY: distclean
distclean: clean
	@echo "Removing keys and logs..."
	@rm -rf $(KEYS_DIR)/*.pem $(KEYS_DIR)/*.der remote_logs
	@echo "✓ Full clean complete"

.PHONY: help
help:
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "Secure UEFI Build System (Ubuntu)"
	@echo "════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "  make all        - Build EFI applications"
	@echo "  make sign       - Sign applications"
	@echo "  make verify     - Verify signatures"
	@echo "  make test-build - Test build environment"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make distclean  - Remove everything including keys"
	@echo "  make help       - Show this help"
	@echo ""
	@echo "Ubuntu Requirements:"
	@echo "  sudo apt install build-essential gcc make binutils openssl"
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════"
	@echo ""

$(OBJS): $(INCLUDE_DIR)/Uefi.h $(INCLUDE_DIR)/Library/UefiLib.h
$(LOADER_OBJS): $(INCLUDE_DIR)/Uefi.h $(INCLUDE_DIR)/Library/UefiLib.h