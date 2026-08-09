(assert_invalid
  (module
    (func $type-3rd-operand-empty-in-loop
      (i32.const 0)
      (loop (i32.const 0) (i32.const 0) (select) (drop))
    )
  )
  "type mismatch"
)
