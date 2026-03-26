(assert_invalid
  (module
    (func $type-2nd-operand-empty
      (i32.const 0) (select) (drop)
    )
  )
  "type mismatch"
)
