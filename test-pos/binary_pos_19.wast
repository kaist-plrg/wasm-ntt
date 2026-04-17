(module binary
  "\00asm" "\01\00\00\00"
  "\01\04\01"                               ;; type section
  "\60\00\00"                               ;; type 0
  "\03\02\01\00"                            ;; func section
  "\0a\11\01"                               ;; code section
  "\0f\00"                                  ;; func 0
  "\02\40"                                  ;; block 0
  "\41\01"                                  ;; condition of if 0
  "\04\40"                                  ;; if 0
  "\41\01"                                  ;; index of br_table element
  "\0e\00"                                  ;; br_table target count can be zero
  "\02"                                     ;; break depth for default
  "\0b\0b\0b"                               ;; end
)
