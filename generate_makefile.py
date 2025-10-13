#!/usr/bin/env python3
"""
Generate a properly formatted Makefile with tabs
Save as: generate_makefile.py
Run: python3 generate_makefile.py
"""

makefile_content = """TARGET = helloworld
LOADER_TARGET = secure_loader
SRC_DIR = src
OBJ_DIR = obj
INCLUDE_DIR = $(SRC_DIR)/uefi_headers
KEYS_DIR = keys

SRCS = $(SRC_DIR)/$(TARGET).c
LOADER_SRCS = $(SRC_DIR)/$(LOADER_TARGET).c
OBJS = $(OBJ_DIR)/$(TARGET).o
LOADER_OBJS = $(OBJ_DIR)/$(LOADER_TARGET).o

CC = gcc
LD = ld
OBJCOPY = objcopy
OPENSSL = openssl

CFLAGS = -I$(INCLUDE_DIR) -I$(INCLUDE_DIR)/Protocol -I$(INCLUDE_DIR)/Guid \\
         -I$(INCLUDE_DIR)/Library -DEFIAPI=__attribute__\\(\\(ms_abi\\)\\) \\
         -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone \\
         -maccumulate-outgoing-args -m64 -fpic -fno-builtin -ffreestanding -Wall -O2

LDFLAGS = -nostdlib -znocombreloc -T gcc_efi.lds -shared -Bsymbolic -m elf_x86_64

.PHONY: all
all: setup_dirs $(TARGET).efi $(LOADER_TARGET).efi
<TAB>@echo ""
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo "✓ Build complete!"
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo "Generated files:"
<TAB>@ls -lh $(TARGET).efi $(LOADER_TARGET).efi 2>/dev/null || true
<TAB>@echo ""

.PHONY: setup_dirs
setup_dirs:
<TAB>@mkdir -p $(OBJ_DIR) $(KEYS_DIR) remote_logs

$(TARGET).efi: $(OBJ_DIR)/$(TARGET).so
<TAB>@echo "Creating EFI application: $@"
<TAB>@$(OBJCOPY) -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64 --subsystem=10 $< $@
<TAB>@echo "✓ $@ created"

$(LOADER_TARGET).efi: $(OBJ_DIR)/$(LOADER_TARGET).so
<TAB>@echo "Creating EFI application: $@"
<TAB>@$(OBJCOPY) -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64 --subsystem=10 $< $@
<TAB>@echo "✓ $@ created"

$(OBJ_DIR)/$(TARGET).so: $(OBJS)
<TAB>@echo "Linking: $@"
<TAB>@$(LD) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/$(LOADER_TARGET).so: $(LOADER_OBJS)
<TAB>@echo "Linking: $@"
<TAB>@$(LD) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
<TAB>@echo "Compiling: $<"
<TAB>@$(CC) $(CFLAGS) -c $< -o $@

.PHONY: sign
sign: $(TARGET).efi
<TAB>@echo ""
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo "Signing $(TARGET).efi"
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@if [ ! -f "$(KEYS_DIR)/private_key.pem" ]; then \\
<TAB><TAB>echo "Generating RSA keys..."; \\
<TAB><TAB>$(OPENSSL) genrsa -out $(KEYS_DIR)/private_key.pem 2048 2>/dev/null; \\
<TAB><TAB>$(OPENSSL) rsa -in $(KEYS_DIR)/private_key.pem -pubout -out $(KEYS_DIR)/public_key.pem 2>/dev/null; \\
<TAB><TAB>$(OPENSSL) rsa -in $(KEYS_DIR)/private_key.pem -pubout -outform DER -out $(KEYS_DIR)/public_key.der 2>/dev/null; \\
<TAB><TAB>chmod 600 $(KEYS_DIR)/private_key.pem; \\
<TAB><TAB>chmod 644 $(KEYS_DIR)/public_key.pem $(KEYS_DIR)/public_key.der; \\
<TAB><TAB>echo "✓ Keys generated"; \\
<TAB>fi
<TAB>@echo "Signing application..."
<TAB>@$(OPENSSL) dgst -sha256 -sign $(KEYS_DIR)/private_key.pem -out $(TARGET).sig $(TARGET).efi
<TAB>@echo "✓ Signed: $(TARGET).sig"
<TAB>@echo ""

.PHONY: verify
verify: $(TARGET).efi $(TARGET).sig
<TAB>@echo ""
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo "Verifying signature"
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@if [ ! -f "$(KEYS_DIR)/public_key.pem" ]; then echo "✗ Public key not found!"; exit 1; fi
<TAB>@if $(OPENSSL) dgst -sha256 -verify $(KEYS_DIR)/public_key.pem -signature $(TARGET).sig $(TARGET).efi >/dev/null 2>&1; then \\
<TAB><TAB>echo "✓ Signature VERIFIED"; \\
<TAB>else echo "✗ Verification FAILED"; exit 1; fi
<TAB>@echo ""

.PHONY: clean
clean:
<TAB>@echo "Cleaning..."
<TAB>@rm -rf $(OBJ_DIR) *.efi *.so *.sig disk.img startup.nsh
<TAB>@echo "✓ Clean complete"

.PHONY: distclean
distclean: clean
<TAB>@echo "Removing keys and logs..."
<TAB>@rm -rf $(KEYS_DIR)/*.pem $(KEYS_DIR)/*.der remote_logs
<TAB>@echo "✓ Full clean complete"

.PHONY: help
help:
<TAB>@echo ""
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo "Secure UEFI Build System"
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo ""
<TAB>@echo "  make all       - Build EFI applications"
<TAB>@echo "  make sign      - Sign applications"
<TAB>@echo "  make verify    - Verify signatures"
<TAB>@echo "  make clean     - Remove build artifacts"
<TAB>@echo "  make distclean - Remove everything including keys"
<TAB>@echo "  make help      - Show this help"
<TAB>@echo ""
<TAB>@echo "════════════════════════════════════════════════════════════════════"
<TAB>@echo ""

$(OBJS): $(INCLUDE_DIR)/Uefi.h $(INCLUDE_DIR)/Library/UefiLib.h
$(LOADER_OBJS): $(INCLUDE_DIR)/Uefi.h $(INCLUDE_DIR)/Library/UefiLib.h
"""

# Replace <TAB> with actual tab characters
makefile_content = makefile_content.replace('<TAB>', '\t')

# Write to Makefile
with open('Makefile', 'w') as f:
    f.write(makefile_content)

print("✓ Makefile generated with proper TAB characters")
print("Run: make all")
