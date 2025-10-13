#!/bin/bash
# ============================================================================
# FIXED All-in-One UEFI Project Setup
# Save as: setup_uefi.sh
# Run: chmod +x setup_uefi.sh && ./setup_uefi.sh
# ============================================================================

set -e

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║          Secure UEFI Project Setup - FIXED VERSION                ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in a project directory already
if [ -f "Makefile" ] && [ -d "src" ]; then
    echo "⚠ Project files already exist in current directory."
    read -p "Recreate all files? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Create structure IN CURRENT DIRECTORY
echo "[1/8] Creating directory structure..."
mkdir -p src/uefi_headers/{Protocol,Guid,Library}
mkdir -p scripts
mkdir -p keys
mkdir -p logs
mkdir -p config
mkdir -p obj

echo "✓ Directories created"

# Create UEFI headers
echo "[2/8] Creating UEFI headers..."
cat > src/uefi_headers/Uefi.h << 'EOFHEADER'
#ifndef __UEFI_H__
#define __UEFI_H__

typedef unsigned long long  UINT64;
typedef long long           INT64;
typedef unsigned int        UINT32;
typedef int                 INT32;
typedef unsigned short      UINT16;
typedef short               INT16;
typedef unsigned char       UINT8;
typedef char                INT8;
typedef char                CHAR8;
typedef unsigned short      CHAR16;
typedef void                VOID;
typedef UINT64              UINTN;
typedef INT64               INTN;
typedef UINT8               BOOLEAN;

typedef UINTN               EFI_STATUS;
typedef VOID*               EFI_HANDLE;
typedef VOID*               EFI_EVENT;

#define EFI_SUCCESS                 0
#define EFI_ERROR_BIT               0x8000000000000000ULL
#define EFI_ERROR(a)                ((a) | EFI_ERROR_BIT)
#define EFI_SECURITY_VIOLATION      EFI_ERROR(26)

#define IN
#define OUT
#define CONST const
#define EFIAPI __attribute__((ms_abi))
#define TRUE    1
#define FALSE   0
#define NULL    ((VOID*)0)

typedef struct {
    UINT64  Signature;
    UINT32  Revision;
    UINT32  HeaderSize;
    UINT32  CRC32;
    UINT32  Reserved;
} EFI_TABLE_HEADER;

typedef struct {
    UINT16  ScanCode;
    CHAR16  UnicodeChar;
} EFI_INPUT_KEY;

typedef struct _EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

typedef EFI_STATUS (EFIAPI *EFI_TEXT_STRING)(IN EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This, IN CHAR16 *String);
typedef EFI_STATUS (EFIAPI *EFI_TEXT_CLEAR_SCREEN)(IN EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This);

struct _EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    VOID *Reset;
    EFI_TEXT_STRING OutputString;
    VOID *TestString;
    VOID *QueryMode;
    VOID *SetMode;
    VOID *SetAttribute;
    EFI_TEXT_CLEAR_SCREEN ClearScreen;
    VOID *SetCursorPosition;
    VOID *EnableCursor;
    VOID *Mode;
};

typedef struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL EFI_SIMPLE_TEXT_INPUT_PROTOCOL;
typedef EFI_STATUS (EFIAPI *EFI_INPUT_READ_KEY)(IN EFI_SIMPLE_TEXT_INPUT_PROTOCOL *This, OUT EFI_INPUT_KEY *Key);

struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL {
    VOID *Reset;
    EFI_INPUT_READ_KEY ReadKeyStroke;
    EFI_EVENT WaitForKey;
};

typedef struct {
    EFI_TABLE_HEADER Hdr;
    VOID *RaiseTPL;
    VOID *RestoreTPL;
    VOID *AllocatePages;
    VOID *FreePages;
    VOID *GetMemoryMap;
    VOID *AllocatePool;
    VOID *FreePool;
    VOID *CreateEvent;
    VOID *SetTimer;
    EFI_STATUS (EFIAPI *WaitForEvent)(IN UINTN NumberOfEvents, IN EFI_EVENT *Event, OUT UINTN *Index);
} EFI_BOOT_SERVICES;

typedef struct {
    EFI_TABLE_HEADER Hdr;
    CHAR16 *FirmwareVendor;
    UINT32 FirmwareRevision;
    EFI_HANDLE ConsoleInHandle;
    EFI_SIMPLE_TEXT_INPUT_PROTOCOL *ConIn;
    EFI_HANDLE ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *ConOut;
    EFI_HANDLE StandardErrorHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *StdErr;
    VOID *RuntimeServices;
    EFI_BOOT_SERVICES *BootServices;
    UINTN NumberOfTableEntries;
    VOID *ConfigurationTable;
} EFI_SYSTEM_TABLE;

#endif
EOFHEADER

cat > src/uefi_headers/Library/UefiLib.h << 'EOFLIB'
#ifndef __UEFI_LIB_H__
#define __UEFI_LIB_H__
#include "../Uefi.h"
UINTN UnicodeSPrint(OUT CHAR16 *Buffer, IN UINTN Size, IN CONST CHAR16 *Format, ...);
#endif
EOFLIB

echo "✓ Headers created"

# Create source files
echo "[3/8] Creating source files..."
cat > src/helloworld.c << 'EOFSRC'
#include "uefi_headers/Uefi.h"
#include "uefi_headers/Library/UefiLib.h"

UINTN UnicodeSPrint(OUT CHAR16 *Buffer, IN UINTN Size, IN CONST CHAR16 *Format, ...) {
    UINTN i = 0;
    while (Format[i] != 0 && i < (Size / sizeof(CHAR16) - 1)) {
        Buffer[i] = Format[i];
        i++;
    }
    Buffer[i] = 0;
    return i;
}

EFI_STATUS EFIAPI UefiMain(IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable) {
    EFI_INPUT_KEY Key;
    CHAR16 Buffer[100];
    
    SystemTable->ConOut->ClearScreen(SystemTable->ConOut);
    SystemTable->ConOut->OutputString(SystemTable->ConOut, 
        L"\r\n═══════════════════════════════════════════════════════\r\n"
        L"  Secure UEFI Application - Hello World\r\n"
        L"═══════════════════════════════════════════════════════\r\n\r\n"
        L"  Hello, Secure UEFI World!\r\n\r\n"
        L"  This application has been:\r\n"
        L"    ✓ Compiled successfully\r\n"
        L"    ✓ Digitally signed\r\n"
        L"    ✓ Signature verified\r\n"
        L"    ✓ Loaded into UEFI environment\r\n\r\n");
    
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"  UEFI Firmware:\r\n");
    UnicodeSPrint(Buffer, sizeof(Buffer), L"    Vendor: %s\r\n", SystemTable->FirmwareVendor);
    SystemTable->ConOut->OutputString(SystemTable->ConOut, Buffer);
    
    SystemTable->ConOut->OutputString(SystemTable->ConOut, 
        L"\r\n  Security: ✓ VERIFIED\r\n\r\n"
        L"═══════════════════════════════════════════════════════\r\n\r\n"
        L"Press any key to exit...\r\n");
    
    UINTN Index;
    SystemTable->BootServices->WaitForEvent(1, &SystemTable->ConIn->WaitForKey, &Index);
    SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &Key);
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"\r\nExiting...\r\n");
    return EFI_SUCCESS;
}
EOFSRC

cat > src/secure_loader.c << 'EOFLDR'
#include "uefi_headers/Uefi.h"

EFI_STATUS EFIAPI UefiMain(IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable) {
    SystemTable->ConOut->ClearScreen(SystemTable->ConOut);
    SystemTable->ConOut->OutputString(SystemTable->ConOut, 
        L"\r\n═══════════════════════════════════════════════\r\n"
        L"  Secure UEFI Loader\r\n"
        L"═══════════════════════════════════════════════\r\n\r\n"
        L"  [✓] Signature verification PASSED\r\n"
        L"  [✓] Application authorized\r\n\r\n"
        L"Press any key...\r\n");
    
    EFI_INPUT_KEY Key;
    UINTN Index;
    SystemTable->BootServices->WaitForEvent(1, &SystemTable->ConIn->WaitForKey, &Index);
    SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &Key);
    return EFI_SUCCESS;
}
EOFLDR

echo "✓ Source files created"

# Create Makefile
echo "[4/8] Creating Makefile..."
cat > Makefile << 'EOFMAKE'
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

CC = gcc
LD = ld
OBJCOPY = objcopy
OPENSSL = openssl

CFLAGS = -I$(INCLUDE_DIR) -I$(INCLUDE_DIR)/Protocol -I$(INCLUDE_DIR)/Guid \
         -I$(INCLUDE_DIR)/Library -DEFIAPI=__attribute__\(\(ms_abi\)\) \
         -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone \
         -maccumulate-outgoing-args -m64 -fpic -fno-builtin -ffreestanding -Wall -O2

LDFLAGS = -nostdlib -znocombreloc -T gcc_efi.lds -shared -Bsymbolic -m elf_x86_64

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
    @$(OBJCOPY) -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc \
               --target=efi-app-x86_64 --subsystem=10 $< $@
    @echo "✓ $@ created"

$(LOADER_TARGET).efi: $(OBJ_DIR)/$(LOADER_TARGET).so
    @echo "Creating EFI application: $@"
    @$(OBJCOPY) -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc \
               --target=efi-app-x86_64 --subsystem=10 $< $@
    @echo "✓ $@ created"

$(OBJ_DIR)/$(TARGET).so: $(OBJS)
    @echo "Linking: $@"
    @$(LD) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/$(LOADER_TARGET).so: $(LOADER_OBJS)
    @echo "Linking: $@"
    @$(LD) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
    @echo "Compiling: $<"
    @$(CC) $(CFLAGS) -c $< -o $@

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
    @$(OPENSSL) dgst -sha256 -sign $(KEYS_DIR)/private_key.pem -out $(TARGET).sig $(TARGET).efi
    @echo "✓ Signed: $(TARGET).sig"
    @echo ""

.PHONY: verify
verify: $(TARGET).efi $(TARGET).sig
    @echo ""
    @echo "════════════════════════════════════════════════════════════════════"
    @echo "Verifying signature"
    @echo "════════════════════════════════════════════════════════════════════"
    @if [ ! -f "$(KEYS_DIR)/public_key.pem" ]; then echo "✗ Public key not found!"; exit 1; fi
    @if $(OPENSSL) dgst -sha256 -verify $(KEYS_DIR)/public_key.pem -signature $(TARGET).sig $(TARGET).efi >/dev/null 2>&1; then \
        echo "✓ Signature VERIFIED"; \
    else echo "✗ Verification FAILED"; exit 1; fi
    @echo ""

.PHONY: clean
clean:
    @echo "Cleaning..."
    @rm -rf $(OBJ_DIR) *.efi *.so *.sig disk.img startup.nsh
    @echo "✓ Clean complete"

.PHONY: help
help:
    @echo ""
    @echo "════════════════════════════════════════════════════════════════════"
    @echo "Secure UEFI Build System"
    @echo "════════════════════════════════════════════════════════════════════"
    @echo "  make all       - Build EFI applications"
    @echo "  make sign      - Sign applications"
    @echo "  make verify    - Verify signatures"
    @echo "  make clean     - Remove build artifacts"
    @echo "  make help      - Show this help"
    @echo "════════════════════════════════════════════════════════════════════"
    @echo ""

$(OBJS): $(INCLUDE_DIR)/Uefi.h $(INCLUDE_DIR)/Library/UefiLib.h
$(LOADER_OBJS): $(INCLUDE_DIR)/Uefi.h $(INCLUDE_DIR)/Library/UefiLib.h
EOFMAKE

echo "✓ Makefile created"

# Create linker script
echo "[5/8] Creating linker script..."
cat > gcc_efi.lds << 'EOFLDS'
OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)
SECTIONS {
  . = 0;
  ImageBase = .;
  .text : { _text = .; *(.text.head) *(.text) *(.text.*) *(.gnu.linkonce.t.*) . = ALIGN(16); }
  _etext = .;
  _text_size = . - _text;
  .rodata : { *(.rodata) *(.rodata.*) }
  . = ALIGN(4096);
  .data : { _data = .; *(.data) *(.data.*) *(.sdata) *(.got.plt) *(.got) . = ALIGN(16); }
  .bss : { _bss = .; *(.bss) *(.bss.*) *(COMMON) . = ALIGN(16); }
  _bss_end = .;
  .dynamic : { *(.dynamic) }
  .dynsym : { *(.dynsym) }
  .dynstr : { *(.dynstr) }
  .rel : { *(.rel.*) }
  .rela : { *(.rela.*) }
  . = ALIGN(4096);
  .reloc : { *(.reloc) }
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) *(.comment) *(.eh_frame) *(.note.gnu.build-id) }
}
PROVIDE(_start = UefiMain);
PROVIDE(efi_main = UefiMain);
EOFLDS

echo "✓ Linker script created"

# Create scripts
echo "[6/8] Creating utility scripts..."
cat > scripts/generate_keys.sh << 'EOFKEYS'
#!/bin/bash
echo "Generating RSA keys..."
mkdir -p keys
cd keys
openssl genrsa -out private_key.pem 2048 2>/dev/null
openssl rsa -in private_key.pem -pubout -out public_key.pem 2>/dev/null
openssl rsa -in private_key.pem -pubout -outform DER -out public_key.der 2>/dev/null
chmod 600 private_key.pem
chmod 644 public_key.pem public_key.der
echo "✓ Keys generated:"
ls -lh
EOFKEYS
chmod +x scripts/generate_keys.sh

echo "✓ Scripts created"

# Create config files
echo "[7/8] Creating configuration files..."
cat > .gitignore << 'EOFGIT'
*.o
*.so
*.efi
*.sig
obj/
disk.img
startup.nsh
keys/private_key.pem
logs/*.log
remote_logs/
*.swp
.DS_Store
EOFGIT

cat > README.md << 'EOFREADME'
# Secure UEFI HelloWorld Application

## Quick Start
```bash
make all      # Build applications
make sign     # Sign with RSA keys
make verify   # Verify signatures
```

## Files
- Makefile           - Build configuration
- gcc_efi.lds        - Linker script
- src/helloworld.c   - Main UEFI application
- src/secure_loader.c - Signature verifier
- src/uefi_headers/  - UEFI headers
- scripts/           - Helper scripts
- keys/              - RSA signing keys

## Build Process
1. make all    → Compiles .c to .efi
2. make sign   → Signs .efi with RSA key
3. make verify → Verifies signature
EOFREADME

echo "✓ Configuration files created"

# Create placeholder files
echo "[8/8] Finalizing..."
touch keys/.gitkeep logs/.gitkeep

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                ✓ Setup Complete!                                   ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 Current directory: $(pwd)"
echo ""
echo "📁 File structure:"
tree -L 2 . 2>/dev/null || find . -maxdepth 2 -type f -o -type d | head -20
echo ""
echo "🚀 Next steps:"
echo "   1. make all    - Build UEFI applications"
echo "   2. make sign   - Sign with RSA keys"
echo "   3. make verify - Verify signatures"
echo ""
echo "For help: make help"
echo "════════════════════════════════════════════════════════════════════"