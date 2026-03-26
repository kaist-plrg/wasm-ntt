(assert_invalid
  (module
    (func $i16x8.sub-arg-empty (result v128)
      (i16x8.sub)
    )
  )
  "type mismatch"
)
