(module binary
  "\00asm" "\01\00\00\00"
  "\05\05\02"                          ;; Memory section with 2 entries
  "\00\00"                             ;; no max, minimum 0
  "\00\00"                             ;; no max, minimum 0
  "\0b\06\01"                          ;; Data section with 1 entry
  "\00"                                ;; Memory index 0
  "\41\00\0b\00"                       ;; (i32.const 0) with contents ""
)
