(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                          ;; type section
  "\60\01\7f\00"                       ;; function type
  "\02\17\01"                          ;; import section
  "\88\00"                             ;; module name length 8, encoded with 2 bytes
  "\73\70\65\63\74\65\73\74"           ;; module name
  "\09"                                ;; entity name length
  "\70\72\69\6e\74\5f\69\33\32"        ;; entity name
  "\00"                                ;; import kind
  "\00"                                ;; import signature index
)
