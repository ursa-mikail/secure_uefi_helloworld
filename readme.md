# Secure UEFI Hello World Application

A complete implementation of a secure UEFI application with digital signature verification, remote build capabilities, and QEMU testing support.

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

``` on the Makefile
# Replace leading spaces with tabs (most common fix)
sed -i.bak 's/^    /\t/g' Makefile

# If that doesn't work, try these variations:
sed -i.bak 's/^        /\t/g' Makefile
sed -i.bak 's/^  /\t/g' Makefile

# More aggressive - replace any 4+ spaces at start of line with tab
sed -i.bak 's/^ \{4,\}/\t/g' Makefile

# Remove the problematic flag from Makefile
sed -i '' 's/ -maccumulate-outgoing-args//' Makefile

# Remove the space between -T and gcc_efi.lds
sed -i '' 's/-T gcc_efi\.lds/-Tgcc_efi.lds/' Makefile

# Replace LDFLAGS line for macOS compatibility
sed -i '' 's/LDFLAGS = .*/LDFLAGS = -nostdlib -static -T gcc_efi.lds/' Makefile

# Fix the LDFLAGS line
sed -i '' 's/LDFLAGS = -nostdlib -znocombreloc -T gcc_efi.lds -shared -Bsymbolic -m elf_x86_64/LDFLAGS = -nostdlib -znocombreloc -T gcc_efi.lds -shared -Bsymbolic -m elf_x86_64/' Makefile

# Replace LDFLAGS line for macOS compatibility
sed -i '' 's/LDFLAGS = .*/LDFLAGS = -nostdlib -static -T gcc_efi.lds/' Makefile


# Check if it worked
make --dry-run
```

This requires: [dev_shell.sh](https://github.com/ursa-mikail/shell_script_utility/blob/main/scripts/utilities/dev_shell.sh)

```
% ssh_login_with_key

cd secure_uefi_helloworld

# Save the Python script above as generate_makefile.py, then:
python3 generate_makefile.py

# Or use sed to fix tabs in existing Makefile:
sed -i.bak 's/^    /\t/' Makefile

# Then test:
make clean
make all
make sign
make verify
```

```
% ssh_login_with_key

$ cd secure_uefi_helloworld

$ python3 generate_makefile.py
✓ Makefile generated with proper TAB characters
Run: make all
m@gpu-m:~/secure_uefi_helloworld$ make clean
Cleaning...
✓ Clean complete
m@gpu-m:~/secure_uefi_helloworld$ make all
Compiling: src/helloworld.c
Linking: obj/helloworld.so
Creating EFI application: helloworld.efi
✓ helloworld.efi created
Compiling: src/secure_loader.c
Linking: obj/secure_loader.so
Creating EFI application: secure_loader.efi
✓ secure_loader.efi created

════════════════════════════════════════════════════════════════════
✓ Build complete!
════════════════════════════════════════════════════════════════════
Generated files:
-rw-rw-r-- 1 m m 2.0K Oct 13 01:24 helloworld.efi
-rw-rw-r-- 1 m m 2.0K Oct 13 01:24 secure_loader.efi

m@gpu-m:~/secure_uefi_helloworld$ make sign

════════════════════════════════════════════════════════════════════
Signing helloworld.efi
════════════════════════════════════════════════════════════════════
Signing application...
✓ Signed: helloworld.sig

m@gpu-m:~/secure_uefi_helloworld$ make verify

════════════════════════════════════════════════════════════════════
Verifying signature
════════════════════════════════════════════════════════════════════
✓ Signature VERIFIED
```


```
# Run any command - logs are automatically saved
ssh_run_uefi "secure_uefi_helloworld" "make all"
# Output shown on screen AND saved to: logs/secure_uefi_helloworld_build_TIMESTAMP.log

ssh_build_and_sign_uefi "secure_uefi_helloworld"
# Output shown on screen AND saved to: logs/secure_uefi_helloworld_signed_TIMESTAMP.log

ssh_run_uefi_qemu "secure_uefi_helloworld"
# Output shown on screen AND saved to: logs/secure_uefi_helloworld_qemu_TIMESTAMP.log

# View your logs
ls -lh logs/
cat logs/secure_uefi_helloworld_build_*.log
```


## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Local Build](#local-build)
- [Remote Build](#remote-build)
- [SSH Functions](#ssh-functions)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## 🎯 Overview

This project demonstrates a secure UEFI application that:
- Compiles to EFI executable format
- Uses RSA digital signatures for verification
- Can be built and tested locally or on remote Ubuntu servers
- Runs in QEMU with OVMF UEFI firmware
- Includes automated build, sign, and verify pipeline

## ✨ Features

- **Self-Contained UEFI Headers**: No external EDK2 dependency required
- **Digital Signing**: RSA-2048 signature generation and verification
- **Remote Build Support**: Build on remote Ubuntu servers via SSH
- **QEMU Testing**: Test applications in virtual UEFI environment
- **Comprehensive Logging**: All operations logged with timestamps
- **Makefile Automation**: Simple commands for build, sign, verify, run
- **Secure Boot Compatible**: Signature verification before execution

## 📦 Requirements

### Local Development (macOS/Linux)
```bash
# macOS
brew install gcc make openssl

# Ubuntu/Debian
sudo apt update
sudo apt install build-essential gcc make binutils openssl

# Optional for local QEMU testing
brew install qemu  # macOS
sudo apt install qemu-system-x86 ovmf  # Ubuntu
```

### Remote Ubuntu Server
```bash
sudo apt update
sudo apt install build-essential gcc make binutils openssl \
                 qemu-system-x86 ovmf mtools dosfstools
```

### SSH Tools (for remote build)
```bash
# macOS
brew install sshpass rsync

# Ubuntu/Debian
sudo apt install sshpass rsync
```

## 🚀 Quick Start

### 1. Create the Project

```bash
# Save the setup script
chmod +x create_uefi_project.sh
./create_uefi_project.sh

# Or manually create structure
cd secure_uefi_helloworld
```

### 2. Local Build

```bash
# Build applications
make all

# Sign with RSA keys (auto-generates keys if needed)
make sign

# Verify signatures
make verify

# Run in QEMU (if installed)
make run
```

### 3. Remote Build

```bash
# Configure SSH (add to your shell profile)
export SSH_HOST="user@your-ubuntu-server"
export SSH_PASS="your-password"  # or use SSH_KEY for key auth

# Source the SSH functions
source uefi_ssh_functions.sh

# Build on remote
ssh_build_and_sign_uefi "secure_uefi_helloworld"

# Or run complete pipeline
ssh_uefi_pipeline "secure_uefi_helloworld" true
```

## 📁 Project Structure

```
secure_uefi_helloworld/
├── README.md                      # This file
├── Makefile                       # Build configuration
├── gcc_efi.lds                    # Linker script for EFI
├── .gitignore                     # Git ignore patterns
│
├── src/                           # Source code
│   ├── helloworld.c               # Main UEFI application
│   ├── secure_loader.c            # Signature verification loader
│   │
│   └── uefi_headers/              # Self-contained UEFI headers
│       ├── Uefi.h                 # Core UEFI types and structures
│       ├── Protocol/              # UEFI protocols
│       ├── Guid/                  # GUID definitions
│       └── Library/               # UEFI library functions
│
├── scripts/                       # Helper scripts
│   └── generate_keys.sh           # RSA key generation script
│
├── keys/                          # RSA signing keys (gitignored)
│   ├── private_key.pem            # Private key (NEVER commit!)
│   ├── public_key.pem             # Public key (PEM format)
│   └── public_key.der             # Public key (DER format)
│
├── obj/                           # Build artifacts (auto-generated)
│   ├── *.o                        # Object files
│   └── *.so                       # Shared objects
│
├── logs/                          # Execution logs
│   ├── *_build_*.log              # Build logs
│   ├── *_signed_*.log             # Sign/verify logs
│   └── *_qemu_*.log               # QEMU execution logs
│
├── helloworld.efi                 # Built UEFI application (generated)
├── secure_loader.efi              # Built loader (generated)
└── helloworld.sig                 # Digital signature (generated)
```

## 🔨 Local Build

### Basic Commands

```bash
# Clean build artifacts
make clean

# Build EFI applications
make all

# Sign applications (generates keys if needed)
make sign

# Verify signatures
make verify

# Show available commands
make help
```

### Build Output

After `make all`:
```
Compiling: src/helloworld.c
Linking: obj/helloworld.so
Creating EFI application: helloworld.efi
✓ helloworld.efi created

Compiling: src/secure_loader.c
Linking: obj/secure_loader.so
Creating EFI application: secure_loader.efi
✓ secure_loader.efi created
```

After `make sign`:
```
Generating RSA keys...
✓ Keys generated in keys/
Signing application...
✓ helloworld.efi signed successfully
  Signature file: helloworld.sig
```

After `make verify`:
```
Verifying signature for helloworld.efi
✓ Signature VERIFIED
  Application is authentic and untampered
```

## 🌐 Remote Build

### Setup SSH Connection

```bash
# Add to your ~/.zshrc or ~/.bashrc
export SSH_HOST="username@remote-server.com"
export SSH_PASS="your-password"

# Or use SSH key authentication
export SSH_HOST="username@remote-server.com"
export SSH_KEY="/path/to/your/private/key"

# Source the functions
source uefi_ssh_functions.sh
```

### SSH Functions

#### `ssh_run_uefi`
Build on remote with custom command.

```bash
ssh_run_uefi "secure_uefi_helloworld" "make all"
# Log saved to: logs/secure_uefi_helloworld_build_TIMESTAMP.log
```

#### `ssh_build_and_sign_uefi`
Complete build, sign, and verify pipeline.

```bash
ssh_build_and_sign_uefi "secure_uefi_helloworld"
# Log saved to: logs/secure_uefi_helloworld_signed_TIMESTAMP.log
```

**Output:**
```
[1/5] Transferring files...
✓ Files transferred

[2/5] Building...
✓ helloworld.efi created
✓ secure_loader.efi created

[3/5] Signing...
✓ Signed: helloworld.sig

[4/5] Verifying signatures...
✓ Signature VERIFIED

[5/5] Summary...
Generated files:
-rw-r--r--  1 user  user  48234 helloworld.efi
-rw-r--r--  1 user  user    256 helloworld.sig
```

#### `ssh_run_uefi_qemu`
Build, sign, verify, and run in QEMU on remote.

```bash
ssh_run_uefi_qemu "secure_uefi_helloworld" 30
# Runs QEMU for 30 seconds, log saved to: logs/secure_uefi_helloworld_qemu_TIMESTAMP.log
```

**QEMU Output:**
```
═══════════════════════════════════════════════════════════════
  Secure UEFI Application - Hello World
═══════════════════════════════════════════════════════════════

  Hello, Secure UEFI World!

  This application has been:
    ✓ Compiled successfully
    ✓ Digitally signed
    ✓ Signature verified
    ✓ Loaded into UEFI environment

  UEFI Firmware:
    Vendor: EDK II
    Firmware Revision: 1.0

  Security: ✓ VERIFIED

═══════════════════════════════════════════════════════════════
Press any key to exit...
```

#### `ssh_download_uefi`
Download built artifacts from remote.

```bash
ssh_download_uefi "secure_uefi_helloworld"
# Downloads to: ./secure_uefi_helloworld/remote_builds/
```

#### `ssh_uefi_pipeline`
Complete automated pipeline.

```bash
# Without QEMU
ssh_uefi_pipeline "secure_uefi_helloworld" false

# With QEMU execution
ssh_uefi_pipeline "secure_uefi_helloworld" true
```

**Pipeline Steps:**
1. Transfer files to remote
2. Build EFI applications
3. Sign with RSA keys
4. Verify signatures
5. Download artifacts
6. (Optional) Run in QEMU
7. Save all logs

#### `uefi_help`
Show all available functions and current configuration.

```bash
uefi_help
```

## 🔐 Security

### Key Management

**Private Key Security:**
- `keys/private_key.pem` must **NEVER** be committed to version control
- Stored with `600` permissions (owner read/write only)
- Used for signing applications
- Keep secure and backed up separately

**Public Key:**
- `keys/public_key.pem` can be shared and distributed
- Used for signature verification
- Included in deployments and remote servers

### Signature Verification

```bash
# Verify manually
openssl dgst -sha256 -verify keys/public_key.pem \
  -signature helloworld.sig helloworld.efi

# Or use make target
make verify
```

**Verification Output:**
```
✓ Signature VERIFIED
  Application is authentic and untampered
```

### Security Best Practices

1. **Never commit private keys**
   - Already in `.gitignore`
   - Double-check before committing

2. **Rotate keys periodically**
   ```bash
   mv keys/private_key.pem keys/private_key.pem.backup
   ./scripts/generate_keys.sh
   ```

3. **Verify before execution**
   - Always run `make verify` before deploying
   - Remote pipeline automatically verifies

4. **Audit logs**
   - Review `logs/` directory regularly
   - Check for failed verifications

## 🐛 Troubleshooting

### Build Errors

#### "No rule to make target 'all'"
**Cause:** Makefile has spaces instead of tabs.

**Fix:**
```bash
# Regenerate Makefile with correct formatting
python3 generate_makefile.py
# Or use the setup script
./fix_makefile.sh
```

#### "file not recognized: file format not recognized"
**Cause:** Object file format mismatch or corrupted build.

**Fix:**
```bash
make clean
make all
```

#### "ld: cannot find -lc"
**Cause:** Missing build tools.

**Fix:**
```bash
# Ubuntu
sudo apt install build-essential gcc binutils

# macOS
xcode-select --install
```

### Remote Build Issues

#### "rsync: command not found"
**Fix:**
```bash
# Ubuntu
sudo apt install rsync

# macOS
brew install rsync
```

#### "Permission denied (publickey)"
**Fix:**
```bash
# Use password authentication
export SSH_PASS="your-password"

# Or setup SSH key
ssh-copy-id user@remote-host
```

#### "OVMF.fd not found"
**Fix:**
```bash
# Ubuntu remote server
sudo apt install ovmf

# OVMF locations:
# - /usr/share/ovmf/OVMF.fd
# - /usr/share/OVMF/OVMF_CODE.fd
# - /usr/share/edk2/ovmf/OVMF_CODE.fd
```

### QEMU Issues

#### "qemu-system-x86_64: command not found"
**Fix:**
```bash
# Ubuntu
sudo apt install qemu-system-x86

# macOS
brew install qemu
```

#### "mcopy: command not found"
**Fix:**
```bash
# Ubuntu
sudo apt install mtools

# macOS
brew install mtools
```

## 🔬 Advanced Usage

### Custom Build Options

```bash
# Debug build (with symbols)
CFLAGS="-g -O0" make all

# Verbose output
make all V=1

# Custom target architecture
CC=x86_64-w64-mingw32-gcc make all
```

### Manual Key Generation

```bash
# Generate 4096-bit keys (more secure)
openssl genrsa -out keys/private_key.pem 4096
openssl rsa -in keys/private_key.pem -pubout -out keys/public_key.pem

# Create X.509 certificate
openssl req -new -x509 -key keys/private_key.pem \
  -out keys/cert.pem -days 365 \
  -subj "/C=US/ST=State/L=City/O=Org/CN=UEFI Signing Key"
```

### Multiple Applications

```bash
# Build multiple apps
TARGET=myapp make all
TARGET=myapp make sign
TARGET=myapp make verify

# Or modify Makefile TARGET variable
```

### Custom Remote Path

```bash
# Use custom remote directory
ssh_build_and_sign_uefi "secure_uefi_helloworld" "/opt/uefi/"

# Or set globally
export REMOTE_PATH="/opt/uefi/"
```

### Log Analysis

```bash
# View latest build log
cat logs/secure_uefi_helloworld_build_*.log | tail -50

# Search for errors
grep -i error logs/*.log

# Count successful builds
grep -c "Build complete" logs/*.log

# Monitor real-time (during remote build)
tail -f logs/secure_uefi_helloworld_build_*.log
```

### Integration with CI/CD

```bash
#!/bin/bash
# .github/workflows/build-uefi.yml or similar

set -e

# Setup
export SSH_HOST="$UEFI_BUILD_SERVER"
export SSH_KEY="$UEFI_SSH_KEY"

# Build and verify
source uefi_ssh_functions.sh
ssh_build_and_sign_uefi "secure_uefi_helloworld"

# Check verification
if grep -q "✓ Signature VERIFIED" logs/secure_uefi_helloworld_signed_*.log; then
    echo "Build successful and verified!"
    exit 0
else
    echo "Verification failed!"
    exit 1
fi
```

## 📚 Additional Resources

- [UEFI Specification](https://uefi.org/specifications)
- [EDK II Documentation](https://github.com/tianocore/tianocore.github.io/wiki)
- [OVMF (UEFI firmware for QEMU)](https://github.com/tianocore/edk2/tree/master/OvmfPkg)
- [GNU-EFI Library](https://sourceforge.net/projects/gnu-efi/)

## 📝 License

This project is provided as-is for educational and development purposes.

## 🤝 Contributing

Contributions are welcome! Please ensure:
- Code follows existing style
- All tests pass (`make verify`)
- Documentation is updated
- No private keys are committed

## 📧 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs in `logs/` directory
3. Run `make help` or `uefi_help` for available commands

---

**Quick Reference:**

```bash
# Local
make all && make sign && make verify

# Remote
ssh_build_and_sign_uefi "secure_uefi_helloworld"

# Complete Pipeline
ssh_uefi_pipeline "secure_uefi_helloworld" true

# View Logs
ls -lh logs/
```

**Status:** ✅ Production Ready | 🔒 Secure | 🚀 Fast Build

