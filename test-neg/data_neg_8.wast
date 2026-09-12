(assert_invalid
  (module
    (memory 1)
    (data (ref.null func))
  )
  "type mismatch"
)
