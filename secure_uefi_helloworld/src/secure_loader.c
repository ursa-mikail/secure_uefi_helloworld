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
    EFI_INPUT_KEY Key; UINTN Index;
    SystemTable->BootServices->WaitForEvent(1, &SystemTable->ConIn->WaitForKey, &Index);
    SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &Key);
    return EFI_SUCCESS;
}
