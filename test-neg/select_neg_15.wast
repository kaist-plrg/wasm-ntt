(assert_invalid
  (module
    (func $type-1st-operand-empty
      (select) (drop)
    )
  )
  "type mismatch"
)
