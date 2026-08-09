(assert_invalid
  (module
    (memory 0)
    (memory $m 1)
    (memory 0)
    (func $type-result-i32-vs-empty
      (memory.size $m)
    )
  )
  "type mismatch"
)
