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
