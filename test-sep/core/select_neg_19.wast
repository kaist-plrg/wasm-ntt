(assert_invalid
  (module
    (func $type-2nd-operand-empty-in-block
      (i32.const 0) (i32.const 0)
      (block (i32.const 0) (select) (drop))
    )
  )
  "type mismatch"
)
