(module binary
  "\00asm" "\01\00\00\00"
  "\00"                                ;; custom section
  "\8a\00"                             ;; section size 10, encoded with 2 bytes
  "\01"                                ;; name byte count
  "1"                                  ;; name
  "23456789"                           ;; sequence of bytes
)
