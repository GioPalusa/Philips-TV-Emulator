ENTRY(_start)
PHDRS { code PT_LOAD FILEHDR PHDRS FLAGS(5); }
SECTIONS {
  . = 0x10000 + SIZEOF_HEADERS;
  .text : { *(.text*) } :code
  .rodata : { *(.rodata*) } :code
  /DISCARD/ : { *(.comment) *(.ARM.attributes) }
}
