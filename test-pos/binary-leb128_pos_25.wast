(module binary
  "\00asm" "\01\00\00\00"
  "\06\0f\01"                          ;; Global section with 1 entry
  "\7e\00"                             ;; i64, immutable
  "\42\ff\ff\ff\ff\ff\ff\ff\ff\ff\7f"  ;; i64.const -1 with unused bits unset
  "\0b"                                ;; end
)
