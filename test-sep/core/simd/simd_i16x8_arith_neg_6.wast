(assert_invalid
  (module
    (func $i16x8.add-1st-arg-empty (result v128)
      (i16x8.add (v128.const i16x8 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
