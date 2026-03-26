(assert_invalid
  (module
    (memory 1)
    (func $type-value-empty
     (i32.const 0) (i32.store)
    )
  )
  "type mismatch"
)
