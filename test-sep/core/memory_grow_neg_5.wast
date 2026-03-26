(assert_invalid
  (module
    (memory 0)
    (func $type-size-empty-vs-i32-in-then (result i32)
      (i32.const 0) (i32.const 0)
      (if (result i32) (then (memory.grow)))
    )
  )
  "type mismatch"
)
