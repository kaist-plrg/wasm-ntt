(assert_invalid
  (module binary 
    "\00asm" "\01\00\00\00"
    "\01\04\01\60\00\00"       ;; Type section: 1 type
    "\03\02\01\00"             ;; Function section: 1 function
    "\05\03\01\00\01"          ;; Memory section: 1 memory
    "\0a\0a\01"                ;; Code section: 1 function

    ;; function 0
    "\08\00"
    "\41\00"                   ;; i32.const 0
    "\28\3f\00"                ;; i32.load offset=0 align=2**63
    "\1a"                      ;; drop
    "\0b"                      ;; end
  )
  "alignment must not be larger than natural"
)
