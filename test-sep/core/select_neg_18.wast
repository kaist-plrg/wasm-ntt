(assert_invalid
  (module
    (func $type-1st-operand-empty-in-block
      (i32.const 0) (i32.const 0) (i32.const 0)
      (block (select) (drop))
    )
  )
  "type mismatch"
)
