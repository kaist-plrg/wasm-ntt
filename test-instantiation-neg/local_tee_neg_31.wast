(assert_invalid
  (module
    (memory 0)
    (func $type-param-arg-empty-vs-num-in-load (param i32)
      (i32.load (local.tee 0)) (drop)
    )
  )
  "type mismatch"
)
