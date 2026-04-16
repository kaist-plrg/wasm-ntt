(module binary
  "\00asm" "\01\00\00\00"
  "\01\05\01"                          ;; type section
  "\60\01\7f\00"                       ;; function type
  "\02\17\01"                          ;; import section
  "\08"                                ;; module name length
  "\73\70\65\63\74\65\73\74"           ;; module name
  "\89\00"                             ;; entity name length 9, encoded with 2 bytes
  "\70\72\69\6e\74\5f\69\33\32"        ;; entity name
  "\00"                                ;; import kind
  "\00"                                ;; import signature index
)
