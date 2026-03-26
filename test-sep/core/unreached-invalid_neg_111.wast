(assert_invalid
  (module
    (func $type-after-ref.as_non_null
      (unreachable)
      (ref.as_non_null)
      (f32.abs)
    )
  )
  "type mismatch"
)
