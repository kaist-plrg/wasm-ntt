(assert_invalid
  (module
    (table 0 funcref)
    (func $large-type (return_call_indirect (type 1012321300) (i32.const 0)))
  )
  "unknown type"
)
