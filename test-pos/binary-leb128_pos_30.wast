(module binary
  "\00asm" "\01\00\00\00"
  "\05\03\01"                          ;; Memory section with 1 entry
  "\00\00"                             ;; no max, minimum 0
  "\0b\09\01"                          ;; Data section with 1 entry
  "\82\00"                             ;; Active segment, encoded with 2 bytes
  "\80\00"                             ;; explicit memory index, encoded with 2 bytes
  "\41\00\0b\00"                       ;; (i32.const 0) with contents ""
)
