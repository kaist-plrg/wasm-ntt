(module binary
  "\00asm" "\01\00\00\00"
  "\01\04\01"                               ;; type section
  "\60\00\00"                               ;; type 0
  "\03\02\01\00"                            ;; func section
  "\04\04\01"                               ;; table section
  "\70\00\01"                               ;; table 0
  "\09\01\00"                               ;; elem segment count can be zero
  "\0a\04\01"                               ;; code section
  "\02\00\0b"                               ;; function body
)
