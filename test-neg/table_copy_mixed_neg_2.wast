(assert_invalid (module
  (table $t32 30 30 funcref)
  (table $t64 i64 30 30 funcref)

  (func (export "bad_src_idx")
    (table.copy $t32 $t64 (i32.const 13) (i32.const 2) (i32.const 3)))
  )
  "type mismatch"
)
