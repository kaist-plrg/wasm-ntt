(assert_invalid
  (module (func $arity-2 (result i32 i32)
    (select (result i32 i32)
      (i32.const 0) (i32.const 0)
      (i32.const 0) (i32.const 0)
      (i32.const 1)
    )
  ))
  "invalid result arity"
)
