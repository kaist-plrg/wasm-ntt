(assert_invalid
  (module
    (memory 1)
    (func $type-value-empty-in-br
      (i32.const 0)
      (block (br 0 (i32.const 0) (i32.store)))
    )
  )
  "type mismatch"
)
