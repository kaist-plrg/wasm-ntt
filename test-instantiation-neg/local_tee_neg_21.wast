(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-br_if (param i32)
      (i32.const 0)
      (block (br_if 0 (local.tee 0) (i32.const 1)) (drop))
    )
  )
  "type mismatch"
)
