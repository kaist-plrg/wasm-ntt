(assert_invalid
  (module binary
    "\00asm" "\01\00\00\00"
    "\0b\06\01"                             ;; data section
    "\00\41\00\0b"                          ;; active data segment 0 for memory 0
    "\00"                                   ;; empty vec(byte)
  )
  "unknown memory 0"
)
