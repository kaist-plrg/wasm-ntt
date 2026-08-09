(assert_invalid
  (module (func $arity-0 (select (result) (nop) (nop) (i32.const 1))))
  "invalid result arity"
)
