(assert_invalid
  (module binary
    "\00asm" "\01\00\00\00"
    "\05\03\01"                             ;; memory section
    "\00\00"                                ;; memory 0
    "\0b\07\01"                             ;; data section
    "\02\01\41\00\0b"                       ;; active data segment 0 for memory 1
    "\00"                                   ;; empty vec(byte)
  )
  "unknown memory 1"
)
