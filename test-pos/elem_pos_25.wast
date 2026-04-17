(module binary
  "\00asm" "\01\00\00\00"    ;; Magic
  "\01\04\01\60\00\00"       ;; Type section: 1 type
  "\03\02\01\00"             ;; Function section: 1 function
  "\04\04\01"                ;; Table section: 1 table
    "\70\00\01"              ;; Table 0: [1..] funcref
  "\09\07\01"                ;; Elem section: 1 element segment
    "\00\41\00\0b\01\00"     ;; Segment 0: (i32.const 0) func 0
  "\0a\04\01"                ;; Code section: 1 function
    "\02\00\0b"              ;; Function 0: empty
)
