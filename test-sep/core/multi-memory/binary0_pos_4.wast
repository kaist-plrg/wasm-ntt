(module binary
  "\00asm" "\01\00\00\00"
  "\05\05\02"                          ;; Memory section with 2 entries
  "\00\00"                             ;; no max, minimum 0
  "\00\01"                             ;; no max, minimum 1
  "\0b\07\01"                          ;; Data section with 1 entry
  "\02\01"                             ;; Memory index 1
  "\41\00\0b\00"                       ;; (i32.const 0) with contents ""
)
