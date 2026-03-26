(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-call (param i32)
      (call 1 (local.tee 0)) (drop)
    )
    (func (param i32) (result i32) (local.get 0))
  )
  "type mismatch"
)
