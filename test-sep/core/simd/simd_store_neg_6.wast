(assert_invalid
  (module (memory 0)
    (func $v128.store-arg-empty
      (v128.store)
    )
  )
  "type mismatch"
)
