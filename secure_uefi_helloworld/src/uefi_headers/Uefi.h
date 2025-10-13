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
    VOID *Reset; EFI_TEXT_STRING OutputString; VOID *TestString; VOID *QueryMode;
    VOID *SetMode; VOID *SetAttribute; EFI_TEXT_CLEAR_SCREEN ClearScreen;
    VOID *SetCursorPosition; VOID *EnableCursor; VOID *Mode;
};

typedef struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL EFI_SIMPLE_TEXT_INPUT_PROTOCOL;
typedef EFI_STATUS (EFIAPI *EFI_INPUT_READ_KEY)(IN EFI_SIMPLE_TEXT_INPUT_PROTOCOL *This, OUT EFI_INPUT_KEY *Key);

struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL {
    VOID *Reset; EFI_INPUT_READ_KEY ReadKeyStroke; EFI_EVENT WaitForKey;
};

typedef struct {
    EFI_TABLE_HEADER Hdr; VOID *RaiseTPL; VOID *RestoreTPL; VOID *AllocatePages;
    VOID *FreePages; VOID *GetMemoryMap; VOID *AllocatePool; VOID *FreePool;
    VOID *CreateEvent; VOID *SetTimer;
    EFI_STATUS (EFIAPI *WaitForEvent)(IN UINTN NumberOfEvents, IN EFI_EVENT *Event, OUT UINTN *Index);
} EFI_BOOT_SERVICES;

typedef struct {
    EFI_TABLE_HEADER Hdr; CHAR16 *FirmwareVendor; UINT32 FirmwareRevision;
    EFI_HANDLE ConsoleInHandle; EFI_SIMPLE_TEXT_INPUT_PROTOCOL *ConIn;
    EFI_HANDLE ConsoleOutHandle; EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *ConOut;
    EFI_HANDLE StandardErrorHandle; EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *StdErr;
    VOID *RuntimeServices; EFI_BOOT_SERVICES *BootServices;
    UINTN NumberOfTableEntries; VOID *ConfigurationTable;
} EFI_SYSTEM_TABLE;
#endif
