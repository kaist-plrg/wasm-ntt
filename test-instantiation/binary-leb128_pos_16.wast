(module binary
  "\00asm" "\01\00\00\00"
  "\01\04\01"                          ;; type section
  "\60\00\00"                          ;; fun type
  "\03\02\01\00"                       ;; function section
  "\07\07\01"                          ;; export section
  "\02"                                ;; string length 2
  "\66\31"                             ;; export name f1
  "\00"                                ;; export kind
  "\80\00"                             ;; export func index, encoded with 2 bytes
  "\0a\04\01"                          ;; code section
  "\02\00\0b"                          ;; function body
)
