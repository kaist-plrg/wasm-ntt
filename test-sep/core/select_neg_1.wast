(assert_invalid
  (module (func $arity-0-implicit (select (nop) (nop) (i32.const 1))))
  "type mismatch"
)
