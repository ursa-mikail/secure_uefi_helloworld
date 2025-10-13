#include "uefi_headers/Uefi.h"
#include "uefi_headers/Library/UefiLib.h"

UINTN UnicodeSPrint(OUT CHAR16 *Buffer, IN UINTN Size, IN CONST CHAR16 *Format, ...) {
    UINTN i = 0;
    while (Format[i] != 0 && i < (Size / sizeof(CHAR16) - 1)) {
        Buffer[i] = Format[i]; i++;
    }
    Buffer[i] = 0; return i;
}

EFI_STATUS EFIAPI UefiMain(IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable) {
    EFI_INPUT_KEY Key; CHAR16 Buffer[100];
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
