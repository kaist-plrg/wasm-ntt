(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-br_table (param i32)
      (i32.const 0)
      (block (br_table 0 (local.set 0)))
    )
  )
  "type mismatch"
)
