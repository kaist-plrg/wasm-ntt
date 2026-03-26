(assert_invalid
  (module
    (memory 0)
    (func $type-param-arg-empty-vs-num-in-memory.grow (param i32)
      (memory.grow (local.tee 0)) (drop)
    )
  )
  "type mismatch"
)
