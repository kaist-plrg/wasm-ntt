(assert_invalid
  (module
    (memory 1)
    (func $type-i32-vs-f32 (result i32)
      (memory.grow (f32.const 0))
    )
  )
  "type mismatch"
)
