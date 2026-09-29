(module binary
  "\00asm" "\01\00\00\00"
  "\04\04\01"                          ;; Table section with 1 entry
  "\70\00\00"                          ;; no max, minimum 0, funcref
  "\09\07\01"                          ;; Element section with 1 entry
  "\80\00"                             ;; Active segment
  "\41\00\0b\00"                       ;; (i32.const 0) with no elements
)
