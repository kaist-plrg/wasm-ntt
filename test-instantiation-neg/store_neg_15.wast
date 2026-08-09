(assert_invalid
  (module
    (memory 1)
    (func $type-value-empty-in-loop
      (i32.const 0)
      (loop (i32.const 0) (i32.store))
    )
  )
  "type mismatch"
)
