(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                                ;; type   section
  "\60\00\01\7b"                             ;; type 0 (func)
  "\03\02\01\00"                             ;; func   section
  "\07\0f\01\0b"                             ;; export section
  "\70\61\72\73\65\5f\66\33\32\78\34\00\00"  ;; export name (parse_f32x4)
  "\0a\16\01"                                ;; code   section
  "\14\00\fd\0c"                             ;; func body
  "\00\00\80\4f"                             ;; data lane 0 (4294967249)
  "\00\00\80\4f"                             ;; data lane 1 (4294967249)
  "\00\00\80\4f"                             ;; data lane 2 (4294967249)
  "\00\00\80\4f"                             ;; data lane 3 (4294967249)
  "\0b"                                      ;; end
)
