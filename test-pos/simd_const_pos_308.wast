(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                                ;; type   section
  "\60\00\01\7b"                             ;; type 0 (func)
  "\03\02\01\00"                             ;; func   section
  "\07\0f\01\0b"                             ;; export section
  "\70\61\72\73\65\5f\69\31\36\78\38\00\00"  ;; export name (parse_i16x8)
  "\0a\16\01"                                ;; code   section
  "\14\00\fd\0c"                             ;; func body
  "\00\00\00\00"                             ;; data lane 0, 1 (0,      0)
  "\00\80\00\80"                             ;; data lane 2, 3 (-32768, -32768)
  "\ff\ff\ff\ff"                             ;; data lane 4, 5 (65535,  65535)
  "\ff\ff\ff\ff"                             ;; data lane 6, 7 (0xffff, 0xffff)
  "\0b"                                      ;; end
)
