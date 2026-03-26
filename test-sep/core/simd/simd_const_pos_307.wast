(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                                ;; type   section
  "\60\00\01\7b"                             ;; type 0 (func)
  "\03\02\01\00"                             ;; func   section
  "\07\0f\01\0b"                             ;; export section
  "\70\61\72\73\65\5f\69\38\78\31\36\00\00"  ;; export name (parse_i8x16)
  "\0a\16\01"                                ;; code   section
  "\14\00\fd\0c"                             ;; func body
  "\00\00\00\00"                             ;; data lane 0~3   (0,    0,    0,    0)
  "\80\80\80\80"                             ;; data lane 4~7   (-128, -128, -128, -128)
  "\ff\ff\ff\ff"                             ;; data lane 8~11  (0xff, 0xff, 0xff, 0xff)
  "\ff\ff\ff\ff"                             ;; data lane 12~15 (255,  255,  255,  255)
  "\0b"                                      ;; end
)
