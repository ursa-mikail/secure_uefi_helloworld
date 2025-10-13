# Secure UEFI HelloWorld Application

## Quick Start
```bash
make all      # Build applications
make sign     # Sign with RSA keys
make verify   # Verify signatures
make run      # Run in QEMU (requires OVMF)
```

## Project Structure
- src/               Source code
- src/uefi_headers/  UEFI headers (self-contained)
- keys/              RSA signing keys
- logs/              Execution logs
- Makefile           Build configuration
- gcc_efi.lds        Linker script

## Security
- Private key stays local only
- All binaries are signed and verified
- UEFI Secure Boot compliant

## Requirements
- gcc (x86_64)
- ld, objcopy
- openssl
- qemu-system-x86_64 (optional, for testing)
- ovmf (optional, for UEFI BIOS)
