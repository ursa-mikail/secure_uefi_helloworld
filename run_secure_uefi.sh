#!/bin/bash

# ============================================================================
# Secure UEFI Runner - Main Orchestration Script
# ============================================================================
# This script orchestrates the entire process:
# 1. Push files to remote
# 2. Build and sign on remote
# 3. Verify and execute
# 4. Collect and display logs
# ============================================================================

set -e  # Exit on error

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/remote_config.sh"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    echo "Please run ./setup_local.sh first"
    exit 1
fi

# Default values
REMOTE_HOST="${SSH_HOST:-user@remote-host}"
REMOTE_PASS="${SSH_PASS:-}"
REMOTE_PATH="${REMOTE_PATH:-/home/m/}"
PROJECT_NAME="secure_uefi_helloworld"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOCAL_LOG_DIR="$PROJECT_ROOT/logs"
REMOTE_LOG_DIR="remote_logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "$1"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
}

# Create log directory
mkdir -p "$LOCAL_LOG_DIR"

FULL_LOG="$LOCAL_LOG_DIR/full_run_${TIMESTAMP}.log"
BUILD_LOG="$LOCAL_LOG_DIR/build_${TIMESTAMP}.log"
VERIFY_LOG="$LOCAL_LOG_DIR/verify_${TIMESTAMP}.log"
EXEC_LOG="$LOCAL_LOG_DIR/execution_${TIMESTAMP}.log"

# Initialize log files
{
    echo "════════════════════════════════════════════════════════════════════"
    echo "SECURE UEFI BUILD AND EXECUTION LOG"
    echo "════════════════════════════════════════════════════════════════════"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Local Path: $PROJECT_ROOT"
    echo "Remote Host: $REMOTE_HOST"
    echo "Remote Path: ${REMOTE_PATH}${PROJECT_NAME}"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
} | tee "$FULL_LOG"

# ============================================================================
# PHASE 1: File Transfer
# ============================================================================
phase_transfer() {
    print_header "PHASE 1: FILE TRANSFER" | tee -a "$FULL_LOG"
    log_info "Transferring project files to remote..." | tee -a "$FULL_LOG"
    
    # Check if sshpass is available
    if ! command -v sshpass &> /dev/null; then
        log_warning "sshpass not installed. Using SSH with key authentication"
        SSH_CMD="ssh $REMOTE_HOST"
        SCP_CMD="scp -r"
        RSYNC_CMD="rsync -avz --progress"
    else
        SSH_CMD="sshpass -p '$REMOTE_PASS' ssh $REMOTE_HOST"
        SCP_CMD="sshpass -p '$REMOTE_PASS' scp -r"
        RSYNC_CMD="sshpass -p '$REMOTE_PASS' rsync -avz --progress"
    fi
    
    # Create remote directory
    log_info "Creating remote directory..." | tee -a "$FULL_LOG"
    eval "$SSH_CMD 'mkdir -p ${REMOTE_PATH}${PROJECT_NAME}'"
    
    # Transfer files using rsync (efficient, only changed files)
    log_info "Transferring files..." | tee -a "$FULL_LOG"
    
    cd "$PROJECT_ROOT"
    eval "$RSYNC_CMD \
        --exclude='.git' \
        --exclude='logs' \
        --exclude='obj' \
        --exclude='*.efi' \
        --exclude='*.sig' \
        --exclude='keys/private_key.pem' \
        ./ ${REMOTE_HOST}:${REMOTE_PATH}${PROJECT_NAME}/" 2>&1 | tee -a "$FULL_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Files transferred successfully" | tee -a "$FULL_LOG"
        return 0
    else
        log_error "File transfer failed" | tee -a "$FULL_LOG"
        return 1
    fi
}

# ============================================================================
# PHASE 2: Environment Setup
# ============================================================================
phase_setup() {
    print_header "PHASE 2: ENVIRONMENT SETUP" | tee -a "$FULL_LOG"
    log_info "Setting up build environment on remote..." | tee -a "$FULL_LOG"
    
    eval "$SSH_CMD 'cd ${REMOTE_PATH}${PROJECT_NAME} && bash scripts/setup_remote.sh'" 2>&1 | tee -a "$FULL_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Environment setup complete" | tee -a "$FULL_LOG"
        return 0
    else
        log_error "Environment setup failed" | tee -a "$FULL_LOG"
        return 1
    fi
}

# ============================================================================
# PHASE 3: Build
# ============================================================================
phase_build() {
    print_header "PHASE 3: BUILD" | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
    log_info "Building UEFI applications on remote..." | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
    
    eval "$SSH_CMD 'cd ${REMOTE_PATH}${PROJECT_NAME} && \
        make clean && \
        make all && \
        make sign'" 2>&1 | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Build complete" | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
        
        # List generated files
        log_info "Generated files:" | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
        eval "$SSH_CMD 'cd ${REMOTE_PATH}${PROJECT_NAME} && ls -lh *.efi *.sig 2>/dev/null || true'" 2>&1 | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
        
        return 0
    else
        log_error "Build failed" | tee -a "$FULL_LOG" | tee -a "$BUILD_LOG"
        return 1
    fi
}

# ============================================================================
# PHASE 4: Signature Verification
# ============================================================================
phase_verify() {
    print_header "PHASE 4: SIGNATURE VERIFICATION" | tee -a "$FULL_LOG" | tee -a "$VERIFY_LOG"
    log_info "Verifying application signature..." | tee -a "$FULL_LOG" | tee -a "$VERIFY_LOG"
    
    eval "$SSH_CMD 'cd ${REMOTE_PATH}${PROJECT_NAME} && make verify'" 2>&1 | tee -a "$FULL_LOG" | tee -a "$VERIFY_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Signature VERIFIED" | tee -a "$FULL_LOG" | tee -a "$VERIFY_LOG"
        return 0
    else
        log_error "Signature verification FAILED" | tee -a "$FULL_LOG" | tee -a "$VERIFY_LOG"
        return 1
    fi
}

# ============================================================================
# PHASE 5: Execution
# ============================================================================
phase_execute() {
    print_header "PHASE 5: QEMU EXECUTION" | tee -a "$FULL_LOG" | tee -a "$EXEC_LOG"
    log_info "Starting UEFI virtual machine..." | tee -a "$FULL_LOG" | tee -a "$EXEC_LOG"
    
    # Create execution script on remote
    eval "$SSH_CMD 'cd ${REMOTE_PATH}${PROJECT_NAME} && cat > run_qemu.sh << \"EOF\"
#!/bin/bash
set -e

# Create FAT disk image
echo \"Creating disk image...\"
rm -f disk.img
dd if=/dev/zero of=disk.img bs=1M count=10 2>/dev/null
mkfs.fat -F 32 disk.img >/dev/null 2>&1

# Copy files to disk
echo \"Copying files to disk image...\"
mcopy -i disk.img helloworld.efi ::/
mcopy -i disk.img secure_loader.efi ::/
[ -f helloworld.sig ] && mcopy -i disk.img helloworld.sig ::/
[ -f keys/public_key.pem ] && mcopy -i disk.img keys/public_key.pem ::/

# Create startup script for UEFI shell
echo \"helloworld.efi\" > startup.nsh
mcopy -i disk.img startup.nsh ::/

echo \"\"
echo \"[UEFI CONSOLE OUTPUT]\"
echo \"─────────────────────────\"

# Run QEMU with timeout
timeout 30s qemu-system-x86_64 \\
    -bios /usr/share/ovmf/OVMF.fd \\
    -drive file=disk.img,format=raw,if=ide \\
    -net none \\
    -nographic \\
    -monitor none \\
    -serial stdio 2>/dev/null || true

echo \"─────────────────────────\"
echo \"\"
echo \"Execution complete\"
EOF
chmod +x run_qemu.sh
./run_qemu.sh
'" 2>&1 | tee -a "$FULL_LOG" | tee -a "$EXEC_LOG"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Execution complete" | tee -a "$FULL_LOG" | tee -a "$EXEC_LOG"
        return 0
    else
        log_error "Execution failed" | tee -a "$FULL_LOG" | tee -a "$EXEC_LOG"
        return 1
    fi
}

# ============================================================================
# PHASE 6: Log Collection
# ============================================================================
phase_collect_logs() {
    print_header "PHASE 6: LOG COLLECTION" | tee -a "$FULL_LOG"
    log_info "Collecting logs from remote..." | tee -a "$FULL_LOG"
    
    # Create remote log collection script
    eval "$SSH_CMD 'cd ${REMOTE_PATH}${PROJECT_NAME} && \
        mkdir -p ${REMOTE_LOG_DIR} && \
        echo \"Remote execution completed at \$(date)\" > ${REMOTE_LOG_DIR}/remote_summary.log'"
    
    # Download remote logs if they exist
    eval "$SCP_CMD ${REMOTE_HOST}:${REMOTE_PATH}${PROJECT_NAME}/${REMOTE_LOG_DIR}/* ${LOCAL_LOG_DIR}/ 2>/dev/null || true"
    
    log_success "Logs collected" | tee -a "$FULL_LOG"
}

# ============================================================================
# PHASE 7: Summary
# ============================================================================
phase_summary() {
    print_header "EXECUTION SUMMARY" | tee -a "$FULL_LOG"
    
    echo "Total Runtime: $SECONDS seconds" | tee -a "$FULL_LOG"
    echo "" | tee -a "$FULL_LOG"
    
    # Create summary log
    SUMMARY_LOG="$LOCAL_LOG_DIR/summary_${TIMESTAMP}.log"
    {
        echo "════════════════════════════════════════════════════════════════════"
        echo "SECURE UEFI EXECUTION SUMMARY"
        echo "════════════════════════════════════════════════════════════════════"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Runtime: $SECONDS seconds"
        echo ""
        echo "Status:"
        echo "  Build: ${BUILD_STATUS:-UNKNOWN}"
        echo "  Verification: ${VERIFY_STATUS:-UNKNOWN}"
        echo "  Execution: ${EXEC_STATUS:-UNKNOWN}"
        echo ""
        echo "Log Files:"
        echo "  Full Log: $FULL_LOG"
        echo "  Build Log: $BUILD_LOG"
        echo "  Verify Log: $VERIFY_LOG"
        echo "  Execution Log: $EXEC_LOG"
        echo "  Summary: $SUMMARY_LOG"
        echo "════════════════════════════════════════════════════════════════════"
    } > "$SUMMARY_LOG"
    
    cat "$SUMMARY_LOG"
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    local start_time=$SECONDS
    
    print_header "SECURE UEFI BUILD AND EXECUTION PIPELINE"
    
    # Execute phases
    if phase_transfer; then
        BUILD_STATUS="✓ SUCCESS"
    else
        BUILD_STATUS="✗ FAILED"
        log_error "Transfer failed. Aborting."
        exit 1
    fi
    
    if phase_setup; then
        BUILD_STATUS="✓ SUCCESS"
    else
        BUILD_STATUS="✗ FAILED"
        log_error "Setup failed. Aborting."
        exit 1
    fi
    
    if phase_build; then
        BUILD_STATUS="✓ SUCCESS"
    else
        BUILD_STATUS="✗ FAILED"
        log_error "Build failed. Aborting."
        exit 1
    fi
    
    if phase_verify; then
        VERIFY_STATUS="✓ VERIFIED"
    else
        VERIFY_STATUS="✗ FAILED"
        log_error "Verification failed. Aborting for security."
        exit 1
    fi
    
    if phase_execute; then
        EXEC_STATUS="✓ SUCCESS"
    else
        EXEC_STATUS="✗ FAILED"
        log_warning "Execution completed with errors"
    fi
    
    phase_collect_logs
    
    SECONDS=$((SECONDS - start_time))
    phase_summary
    
    log_success "Pipeline completed successfully!"
    log_info "Check logs in: $LOCAL_LOG_DIR"
}

# Run main function
main "$@"
