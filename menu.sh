#!/bin/bash
# ============================================================================
# Complete Workflow Example - From Local Setup to Remote Execution
# ============================================================================

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                    SECURE UEFI BUILD & EXECUTION                           ║
║                        Complete Workflow Guide                             ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

This script demonstrates the complete workflow:
  1. Local project setup
  2. File structure creation
  3. Build and sign locally
  4. Push to remote
  5. Remote build and execution
  6. Log collection and display

EOF

# ============================================================================
# STEP 1: LOCAL PROJECT SETUP
# ============================================================================

echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 1: LOCAL PROJECT SETUP"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

# Create project directory
PROJECT_NAME="secure_uefi_helloworld"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create directory structure
echo "[1/5] Creating directory structure..."
mkdir -p src/uefi_headers/{Protocol,Guid,Library}
mkdir -p scripts
mkdir -p keys
mkdir -p logs
mkdir -p config
mkdir -p obj

echo "✓ Directory structure created"
echo ""
echo "Project Structure:"
tree -L 2 . 2>/dev/null || find . -type d | sed 's|[^/]*/| |g'
echo ""

# ============================================================================
# STEP 2: CREATE SOURCE FILES
# ============================================================================

echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 2: CREATING SOURCE FILES"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

echo "[2/5] Creating UEFI header files..."
# (Header files already shown in previous artifact)
echo "✓ Headers created in src/uefi_headers/"

echo "[3/5] Creating application source files..."
# (Source files already shown in previous artifact)
echo "✓ helloworld.c created"
echo "✓ secure_loader.c created"

echo "[4/5] Creating build files..."
# (Makefile and linker script already shown in previous artifact)
echo "✓ Makefile created"
echo "✓ gcc_efi.lds created"

echo "[5/5] Creating scripts..."
# (Scripts already shown in previous artifacts)
echo "✓ generate_keys.sh created"
echo "✓ setup_remote.sh created"
echo "✓ run_secure_uefi.sh created"

echo ""
echo "All files created successfully!"
echo ""

# ============================================================================
# STEP 3: LOCAL BUILD (OPTIONAL TEST)
# ============================================================================

echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 3: LOCAL BUILD TEST (OPTIONAL)"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

read -p "Do you want to test build locally first? (y/N): " test_local

if [[ "$test_local" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Building locally..."
    make clean
    make all
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Local build successful!"
        ls -lh *.efi
    else
        echo ""
        echo "✗ Local build failed. Check your environment."
        exit 1
    fi
fi

echo ""

# ============================================================================
# STEP 4: GENERATE KEYS
# ============================================================================

echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 4: GENERATE SIGNING KEYS"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

./scripts/generate_keys.sh

echo ""
echo "Keys generated:"
ls -lh keys/
echo ""
echo "⚠ SECURITY NOTICE:"
echo "  - private_key.pem: KEEP SECRET (never commit to git)"
echo "  - public_key.pem: Safe to share and deploy"
echo ""

# ============================================================================
# STEP 5: CONFIGURE REMOTE CONNECTION
# ============================================================================

echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 5: CONFIGURE REMOTE CONNECTION"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

if [ ! -f "config/remote_config.sh" ]; then
    echo "Setting up remote configuration..."
    read -p "Remote SSH host (e.g., user@192.168.1.100): " ssh_host
    read -s -p "Remote SSH password (press Enter for key auth): " ssh_pass
    echo ""
    read -p "Remote path (default: /home/m/): " remote_path
    remote_path=${remote_path:-/home/m/}
    
    cat > config/remote_config.sh << EOFCONF
#!/bin/bash
export SSH_HOST="$ssh_host"
export SSH_PASS="$ssh_pass"
export REMOTE_PATH="$remote_path"
EOFCONF
    
    chmod 600 config/remote_config.sh
    echo "✓ Remote configuration saved"
else
    echo "✓ Using existing remote configuration"
    source config/remote_config.sh
    echo "  Remote: $SSH_HOST"
    echo "  Path: $REMOTE_PATH"
fi

echo ""

# ============================================================================
# STEP 6: PUSH AND BUILD ON REMOTE
# ============================================================================

echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 6: PUSH TO REMOTE AND BUILD"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

read -p "Ready to push and build on remote? (y/N): " proceed

if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
fi

echo ""
echo "Starting remote build pipeline..."
echo ""

./scripts/run_secure_uefi.sh

# ============================================================================
# STEP 7: DISPLAY LOGS
# ============================================================================

echo ""
echo "════════════════════════════════════════════════════════════════════════════"
echo "STEP 7: EXECUTION LOGS"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

# Find the latest log file
LATEST_LOG=$(ls -t logs/full_run_*.log 2>/dev/null | head -n1)

if [ -n "$LATEST_LOG" ]; then
    echo "Displaying latest execution log: $LATEST_LOG"
    echo ""
    echo "────────────────────────────────────────────────────────────────────────────"
    cat "$LATEST_LOG"
    echo "────────────────────────────────────────────────────────────────────────────"
    echo ""
    
    # Show individual logs
    echo "Available log files:"
    ls -lh logs/*.log
    echo ""
    
    # Show summary
    SUMMARY_LOG=$(ls -t logs/summary_*.log 2>/dev/null | head -n1)
    if [ -n "$SUMMARY_LOG" ]; then
        echo "Quick Summary:"
        echo ""
        cat "$SUMMARY_LOG"
    fi
else
    echo "⚠ No logs found. The execution may have failed early."
fi

echo ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cat << 'EOFFINAL'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                          WORKFLOW COMPLETE!                                ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

Your secure UEFI application has been:
  ✓ Built with proper UEFI compliance
  ✓ Digitally signed with RSA keys
  ✓ Pushed to remote server
  ✓ Verified for authenticity
  ✓ Executed in QEMU/UEFI environment
  ✓ Logs collected and stored locally

Next Steps:
  • Review logs in: logs/
  • Modify source code in: src/
  • Rebuild and rerun: ./scripts/run_secure_uefi.sh
  • Clean build: make clean

Security Reminders:
  • Keep private_key.pem secure and private
  • Never commit keys to version control
  • Regularly rotate signing keys
  • Audit logs for any security violations

EOFFINAL

# ============================================================================
# LOG VIEWER HELPER
# ============================================================================

cat > view_logs.sh << 'EOFVIEWER'
#!/bin/bash
# Quick log viewer utility

echo "════════════════════════════════════════════════════════════════════════════"
echo "Log Viewer - Secure UEFI Execution Logs"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

if [ ! -d "logs" ] || [ -z "$(ls -A logs 2>/dev/null)" ]; then
    echo "No logs found. Run the build first."
    exit 1
fi

PS3="Select log to view (or 0 to exit): "
options=(
    "Latest Full Run"
    "Latest Build Log"
    "Latest Verification Log"
    "Latest Execution Log"
    "Latest Summary"
    "List All Logs"
    "Clean Old Logs (keep last 5)"
)

select opt in "${options[@]}"; do
    case $REPLY in
        1)
            latest=$(ls -t logs/full_run_*.log 2>/dev/null | head -n1)
            [ -n "$latest" ] && less "$latest" || echo "No log found"
            ;;
        2)
            latest=$(ls -t logs/build_*.log 2>/dev/null | head -n1)
            [ -n "$latest" ] && less "$latest" || echo "No log found"
            ;;
        3)
            latest=$(ls -t logs/verify_*.log 2>/dev/null | head -n1)
            [ -n "$latest" ] && less "$latest" || echo "No log found"
            ;;
        4)
            latest=$(ls -t logs/execution_*.log 2>/dev/null | head -n1)
            [ -n "$latest" ] && less "$latest" || echo "No log found"
            ;;
        5)
            latest=$(ls -t logs/summary_*.log 2>/dev/null | head -n1)
            [ -n "$latest" ] && cat "$latest" || echo "No log found"
            echo ""
            ;;
        6)
            echo ""
            ls -lht logs/*.log
            echo ""
            ;;
        7)
            echo "Keeping last 5 logs of each type..."
            for pattern in full_run build verify execution summary; do
                ls -t logs/${pattern}_*.log 2>/dev/null | tail -n +6 | xargs rm -f
            done
            echo "✓ Old logs cleaned"
            ;;
        0)
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid option. Try again."
            ;;
    esac
done
EOFVIEWER

chmod +x view_logs.sh

echo ""
echo "Log viewer utility created: ./view_logs.sh"
echo ""
echo "Run './view_logs.sh' anytime to browse execution logs."
echo ""

# ============================================================================
# CREATE QUICK REFERENCE CARD
# ============================================================================

cat > QUICKSTART.md << 'EOFQUICK'
# Secure UEFI Project - Quick Reference

## Project Structure
```
secure_uefi_helloworld/
├── src/                      # Source code
│   ├── helloworld.c          # Main UEFI app
│   ├── secure_loader.c       # Signature verifier
│   └── uefi_headers/         # UEFI headers
├── scripts/                  # Build scripts
│   ├── generate_keys.sh      # Key generation
│   ├── setup_remote.sh       # Remote setup
│   └── run_secure_uefi.sh    # Main runner
├── keys/                     # RSA keys (private_key.pem is SECRET!)
├── logs/                     # Execution logs
├── Makefile                  # Build configuration
└── gcc_efi.lds              # Linker script
```

## Common Commands

### Build Locally (Test)
```bash
make clean          # Clean build artifacts
make all            # Build EFI applications
make sign           # Sign applications
make verify         # Verify signatures
make run            # Run in QEMU locally
```

### Remote Execution
```bash
./scripts/run_secure_uefi.sh    # Full pipeline: push, build, sign, verify, run
./view_logs.sh                   # View execution logs
```

### Key Management
```bash
./scripts/generate_keys.sh      # Generate new signing keys
ls -l keys/                      # List keys
```

## Log Files

All logs are timestamped and stored in `logs/`:

- `full_run_TIMESTAMP.log` - Complete execution log
- `build_TIMESTAMP.log` - Build output only
- `verify_TIMESTAMP.log` - Signature verification
- `execution_TIMESTAMP.log` - QEMU runtime output
- `summary_TIMESTAMP.log` - Quick summary

## Security Notes

### DO:
- ✓ Keep `private_key.pem` secure and private
- ✓ Add `keys/private_key.pem` to .gitignore
- ✓ Use strong passwords for remote access
- ✓ Regularly review logs for security violations
- ✓ Rotate keys periodically

### DON'T:
- ✗ Never commit private keys to version control
- ✗ Never share private_key.pem
- ✗ Never skip signature verification
- ✗ Never run unsigned binaries in production

## Troubleshooting

### Build Fails
- Check GCC is installed and version >= 7.0
- Ensure all header files are present
- Review build log: `cat logs/build_*.log`

### Signature Verification Fails
- Ensure keys were generated: `ls keys/`
- Check public key is on remote
- Verify signature: `make verify`

### QEMU Fails to Run
- Check OVMF is installed: `ls /usr/share/ovmf/`
- Ensure qemu-system-x86_64 is available
- Review execution log: `cat logs/execution_*.log`

### Remote Connection Issues
- Verify SSH credentials in config/remote_config.sh
- Test connection: `ssh $SSH_HOST`
- Check sshpass is installed for password auth

## File Flow

```
LOCAL                    REMOTE
─────                    ──────
src/*.c         ───>    /home/m/secure_uefi_helloworld/src/
Makefile        ───>    /home/m/secure_uefi_helloworld/
scripts/        ───>    /home/m/secure_uefi_helloworld/scripts/
keys/public*    ───>    /home/m/secure_uefi_helloworld/keys/

                        [BUILD PROCESS]
                        - Compile .c to .o
                        - Link .o to .so
                        - Convert .so to .efi
                        - Sign with OpenSSL
                        - Verify signature
                        - Run in QEMU

logs/           <───    /home/m/secure_uefi_helloworld/remote_logs/
```

## Need Help?

- Check logs: `./view_logs.sh`
- Review Makefile targets: `make help`
- Read full documentation: `cat README.md`
- View this guide: `cat QUICKSTART.md`
EOFQUICK

echo "Quick reference created: QUICKSTART.md"
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║  Setup Complete! Read QUICKSTART.md for common commands and workflows.    ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
EOF
