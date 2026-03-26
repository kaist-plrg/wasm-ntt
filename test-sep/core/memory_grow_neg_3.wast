(assert_invalid
  (module
    (memory 0)
    (func $type-size-empty-vs-i32-in-block (result i32)
      (i32.const 0)
      (block (result i32) (memory.grow))
    )
  )
  "type mismatch"
)
