(module binary
  "\00asm" "\01\00\00\00"
  "\00"                                ;; custom section
  "\0b"                                ;; section size
  "\88\00"                             ;; name byte count 8, encoded with 2 bytes
  "12345678"                           ;; name
  "9"                                  ;; sequence of bytes
)
