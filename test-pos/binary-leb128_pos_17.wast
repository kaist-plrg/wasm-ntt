(module binary
  "\00asm" "\01\00\00\00"
  "\01\04\01"                          ;; type section
  "\60\00\00"                          ;; fun type
  "\03\02\01\00"                       ;; function section
  "\0a"                                ;; code section
  "\05"                                ;; section size
  "\81\00"                             ;; num functions, encoded with 2 bytes
  "\02\00\0b"                          ;; function body
)
