(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                                ;; type   section
  "\60\00\01\7b"                             ;; type 0 (func)
  "\03\02\01\00"                             ;; func   section
  "\07\0f\01\0b"                             ;; export section
  "\70\61\72\73\65\5f\66\36\34\78\32\00\00"  ;; export name (parse_f64x2)
  "\0a\16\01"                                ;; code   section
  "\14\00\fd\0c"                             ;; func body
  "\ff\ff\ff\ff\ff\ff\ef\7f"                 ;; data lane 0 (0x1.fffffffffffffp+1023)
  "\ff\ff\ff\ff\ff\ff\ef\7f"                 ;; data lane 1 (0x1.fffffffffffffp+1023)
  "\0b"                                      ;; end
)
