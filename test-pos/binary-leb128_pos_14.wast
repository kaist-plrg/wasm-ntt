(module binary
  "\00asm" "\01\00\00\00"
  "\01\04\01"                          ;; type section
  "\60\00\00"                          ;; function type
  "\03\03\01"                          ;; function section
  "\80\00"                             ;; function 0 signature index, encoded with 2 bytes
  "\0a\04\01"                          ;; code section
  "\02\00\0b"                          ;; function body
)
