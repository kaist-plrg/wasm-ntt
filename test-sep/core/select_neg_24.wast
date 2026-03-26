(assert_invalid
  (module
    (func $type-1st-operand-empty-in-then
      (i32.const 0) (i32.const 0) (i32.const 0)
      (if (then (select) (drop)))
    )
  )
  "type mismatch"
)
