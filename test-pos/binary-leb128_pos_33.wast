(module binary
  "\00asm" "\01\00\00\00"
  "\04\04\01"                          ;; Table section with 1 entry
  "\70\00\00"                          ;; no max, minimum 0, funcref
  "\09\09\01"                          ;; Element section with 1 entry
  "\82\00"                             ;; Active segment, encoded with 2 bytes
  "\00"                                ;; explicit table index
  "\41\00\0b\00\00"                    ;; (i32.const 0) with no elements
)
