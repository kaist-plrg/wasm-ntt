(assert_invalid
  (module
    (memory 1)
    (func $type-size-f32-vs-i32 (result i32)
      (memory.grow (f32.const 0))
    )
  )
  "type mismatch"
)
