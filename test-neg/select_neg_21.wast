(assert_invalid
  (module
    (func $type-1st-operand-empty-in-loop
      (i32.const 0) (i32.const 0) (i32.const 0)
      (loop (select) (drop))
    )
  )
  "type mismatch"
)
