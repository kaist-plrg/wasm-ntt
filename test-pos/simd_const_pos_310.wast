(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                                ;; type   section
  "\60\00\01\7b"                             ;; type 0 (func)
  "\03\02\01\00"                             ;; func   section
  "\07\0f\01\0b"                             ;; export section
  "\70\61\72\73\65\5f\69\36\34\78\32\00\00"  ;; export name (parse_i64x2)
  "\0a\16\01"                                ;; code   section
  "\14\00\fd\0c"                             ;; func body
  "\ff\ff\ff\ff\ff\ff\ff\7f"                 ;; data lane 0 (9223372036854775807)
  "\ff\ff\ff\ff\ff\ff\ff\7f"                 ;; data lane 1 (9223372036854775807)
  "\0b"                                      ;; end
)
