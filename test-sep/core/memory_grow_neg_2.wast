(assert_invalid
  (module
    (memory 0)
    (func $type-size-empty-vs-i32 (result i32)
      (memory.grow)
    )
  )
  "type mismatch"
)
