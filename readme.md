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

