(assert_invalid
  (module
    (memory 1)
    (func $type-result-i32-vs-f32 (result f32)
      (memory.grow (i32.const 0))
    )
  )
  "type mismatch"
)
