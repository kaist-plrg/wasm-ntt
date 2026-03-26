(assert_invalid
  (module
    (memory 1)
    (func $type-result-i32-vs-empty
      (memory.grow (i32.const 0))
    )
  )
  "type mismatch"
)
