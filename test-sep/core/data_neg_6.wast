(assert_invalid
  (module binary
    "\00asm" "\01\00\00\00"
    "\0b\45\01"                             ;; data section
    "\02"                                   ;; active segment
    "\01"                                   ;; memory index
    "\41\00\0b"                             ;; offset constant expression
    "\3e"                                   ;; vec(byte) length
    "\00\01\02\03\04\05\06\07\08\09\0a\0b\0c\0d\0e\0f"
    "\10\11\12\13\14\15\16\17\18\19\1a\1b\1c\1d\1e\1f"
    "\20\21\22\23\24\25\26\27\28\29\2a\2b\2c\2d\2e\2f"
    "\30\31\32\33\34\35\36\37\38\39\3a\3b\3c\3d"
  )
  "unknown memory 1"
)
