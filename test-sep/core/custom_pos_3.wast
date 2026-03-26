(module binary
  "\00asm" "\01\00\00\00"
  "\01\07\01\60\02\7f\7f\01\7f"                ;; type section
  "\00\1a\06" "custom" "this is the payload"   ;; custom section
  "\03\02\01\00"                               ;; function section
  "\07\0a\01\06\61\64\64\54\77\6f\00\00"       ;; export section
  "\0a\09\01\07\00\20\00\20\01\6a\0b"          ;; code section
  "\00\1b\07" "custom2" "this is the payload"  ;; custom section
)
